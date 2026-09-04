import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/usuario.dart';
import 'push_notification_service.dart';

class AuthService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  Usuario? _currentUser;
  bool _isLoading = false;

  Usuario? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;
  bool get isDirectora => _currentUser?.esDirectora ?? false;
  bool get esPadre => _currentUser?.esPadre ?? false;
  bool get esProfesor => _currentUser?.esProfesor ?? false;
  bool get esStaff => _currentUser?.esStaff ?? false;
  bool get esMaestraIngles => _currentUser?.esMaestraIngles ?? false;
  bool get esCaja => _currentUser?.esCaja ?? false;
  bool get puedeGestionarPagos =>
      _currentUser?.puedeGestionarPagos ?? false;
  bool get isPadre => esPadre; // Backward compatibility
  bool get isStaff => esStaff;

  AuthService() {
    _supabase.auth.onAuthStateChange.listen(_onAuthStateChanged);
    _loadInitialUser();
  }

  Future<void> _loadInitialUser() async {
    final session = _supabase.auth.currentSession;
    if (session != null) {
      await _loadUserData(session.user.id);
    }
  }

  void _onAuthStateChanged(AuthState authState) async {
    if (authState.session != null) {
      await _loadUserData(authState.session!.user.id);
    } else {
      _currentUser = null;
      notifyListeners();
    }
  }

  Future<void> _loadUserData(String uid) async {
    try {
      final response = await _supabase
          .from('usuarios')
          .select()
          .eq('id', uid)
          .single();

      var usuario = Usuario.fromJson(response);
      if (!usuario.activo) {
        await _supabase.auth.signOut();
        _currentUser = null;
        notifyListeners();
        return;
      }

      if (usuario.esProfesor) {
        try {
          final rows = await _supabase
              .from('profesores')
              .select('especialidad, grado_id')
              .eq('usuario_id', uid)
              .eq('activo', true);
          final list = List<Map<String, dynamic>>.from(rows as List);
          if (list.isNotEmpty) {
            usuario = usuario.conPerfilProfesor(
              especialidad: list.first['especialidad'] as String?,
              gradoId: list.first['grado_id'] as String?,
            );
          }
        } catch (e) {
          debugPrint('perfil profesor: $e');
        }
      }

      _currentUser = usuario;
      notifyListeners();
    } catch (e) {
      debugPrint('Error cargando datos de usuario: $e');
    }
  }

  // Login con email y contraseña
  Future<String?> login(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      if (response.user != null) {
        await _loadUserData(response.user!.id);
        if (_currentUser == null) {
          _isLoading = false;
          notifyListeners();
          return 'Tu acceso está desactivado. Contacta a la escuela.';
        }
        // ignore: unawaited_futures
        PushNotificationService.instance.registrarTokenUsuarioActual();
      }

      _isLoading = false;
      notifyListeners();
      return null; // Sin errores
    } on AuthException catch (e) {
      _isLoading = false;
      notifyListeners();

      if (e.message.contains('Invalid login credentials')) {
        return 'Correo o contraseña incorrectos';
      } else if (e.message.contains('Email not confirmed')) {
        return 'Por favor confirma tu correo electrónico';
      } else {
        return 'Error al iniciar sesión: ${e.message}';
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return 'Error inesperado: $e';
    }
  }

  // Registrar nuevo usuario (solo directora puede hacerlo)
  Future<String?> registrarUsuario({
    required String email,
    required String password,
    required String nombre,
    String? apellidos,
    String? telefono,
    String? whatsapp,
    required String rol, // 'directora', 'profesor', 'padre'
  }) async {
    try {
      // Crear cuenta en Supabase Auth
      final response = await _supabase.auth.signUp(
        email: email.trim(),
        password: password,
      );

      if (response.user == null) {
        return 'Error al crear la cuenta';
      }

      // Crear registro en tabla usuarios
      await _supabase.from('usuarios').insert({
        'id': response.user!.id,
        'email': email.trim(),
        'nombre': nombre,
        'apellidos': apellidos,
        'telefono': telefono,
        'whatsapp': whatsapp,
        'rol': rol,
      });

      return null; // Sin errores
    } on AuthException catch (e) {
      if (e.message.contains('already registered')) {
        return 'Ya existe una cuenta con este correo';
      } else {
        return 'Error al registrar: ${e.message}';
      }
    } catch (e) {
      return 'Error inesperado: $e';
    }
  }

  /// Al dar de alta padre/profesora con `signUp` estando staff logueado,
  /// Supabase cambia la sesión al usuario nuevo → fallan INSERT (RLS) y
  /// la UI cree que “hay que salir y entrar”. Siempre restauramos la sesión.
  Future<void> restaurarSesionTrasSignUpDesdeDirectora({
    required String userIdAntes,
    required String refreshAntes,
  }) async {
    try {
      // Preferir setSession: rehidrata la sesión del staff de forma explícita.
      await _supabase.auth.setSession(refreshAntes);
    } catch (e) {
      debugPrint('setSession tras signUp: $e — intentando refreshSession');
      try {
        await _supabase.auth.refreshSession(refreshAntes);
      } catch (e2) {
        debugPrint('refreshSession tras signUp: $e2');
        rethrow;
      }
    }

    // Esperar un tick por si onAuthStateChange aún procesa al usuario nuevo.
    await Future<void>.delayed(const Duration(milliseconds: 50));

    if (_supabase.auth.currentUser?.id != userIdAntes) {
      try {
        await _supabase.auth.setSession(refreshAntes);
      } catch (_) {}
    }

    if (_supabase.auth.currentUser?.id != userIdAntes) {
      throw Exception(
        'Tu sesión cambió al crear el usuario. Vuelve a iniciar sesión. '
        'Si el correo ya quedó en Auth sin perfil, bórralo en Supabase → Authentication.',
      );
    }

    await _loadUserData(userIdAntes);
    notifyListeners();
  }

  /// Crea cuenta Auth + fila en `usuarios` sin perder la sesión del staff.
  /// Devuelve el id del nuevo usuario.
  Future<String> crearUsuarioAuthComoStaff({
    required String email,
    required String password,
    required String rol,
    required String nombre,
    String? apellidos,
    String? telefono,
    String? whatsapp,
  }) async {
    final emailNorm = email.trim().toLowerCase();

    // Preferir RPC: no cambia la sesión (crítico al crear papá 1 y papá 2 en la misma alta).
    try {
      final id = await _supabase.rpc(
        'crear_usuario_escuela',
        params: {
          'p_email': emailNorm,
          'p_password': password,
          'p_nombre': nombre,
          if (apellidos != null && apellidos.isNotEmpty) 'p_apellidos': apellidos,
          if (telefono != null && telefono.isNotEmpty) 'p_telefono': telefono,
          if (whatsapp != null && whatsapp.isNotEmpty) 'p_whatsapp': whatsapp,
          'p_rol': rol,
        },
      );
      if (id != null && id.toString().isNotEmpty) {
        return id.toString();
      }
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('ya existe')) {
        final existente = await _supabase
            .from('usuarios')
            .select('id')
            .eq('email', emailNorm)
            .eq('rol', rol)
            .maybeSingle();
        if (existente != null) {
          return existente['id'] as String;
        }
      }
      debugPrint('crear_usuario_escuela RPC: $e — fallback signUp');
    }

    final prevId = _supabase.auth.currentUser?.id;
    final prevRefresh = _supabase.auth.currentSession?.refreshToken;
    if (prevId == null || prevRefresh == null || prevRefresh.isEmpty) {
      throw Exception('Sesión inválida. Vuelve a iniciar sesión.');
    }

    AuthResponse response;
    try {
      response = await _supabase.auth.signUp(
        email: emailNorm,
        password: password,
      );
    } on AuthException catch (e) {
      if (e.message.toLowerCase().contains('already') ||
          e.message.toLowerCase().contains('registered')) {
        throw Exception('Ya existe una cuenta con este correo.');
      }
      throw Exception('No se pudo crear la cuenta: ${e.message}');
    }

    if (response.user == null) {
      throw Exception('No se pudo crear el usuario en Auth.');
    }

    await restaurarSesionTrasSignUpDesdeDirectora(
      userIdAntes: prevId,
      refreshAntes: prevRefresh,
    );

    // Si el perfil ya existe (reintento), no fallar.
    final existente = await _supabase
        .from('usuarios')
        .select('id')
        .eq('id', response.user!.id)
        .maybeSingle();
    if (existente == null) {
      await _supabase.from('usuarios').insert({
        'id': response.user!.id,
        'email': emailNorm,
        'rol': rol,
        'nombre': nombre,
        if (apellidos != null && apellidos.isNotEmpty) 'apellidos': apellidos,
        if (telefono != null && telefono.isNotEmpty) 'telefono': telefono,
        if (whatsapp != null && whatsapp.isNotEmpty) 'whatsapp': whatsapp,
      });
    }

    // Asegurar que AuthService sigue con el staff.
    await _loadUserData(prevId);
    notifyListeners();
    return response.user!.id;
  }

  // Cerrar sesión
  Future<void> logout() async {
    await PushNotificationService.instance.desactivarTokensUsuario();
    await _supabase.auth.signOut();
    _currentUser = null;
    notifyListeners();
  }

  /// Contraseña nueva (usuario ya autenticado). Mínimo 6 caracteres (Supabase).
  Future<String?> cambiarPassword(String newPassword) async {
    final clave = newPassword.trim();
    if (clave.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    if (_supabase.auth.currentSession == null ||
        _supabase.auth.currentUser == null) {
      return 'Tu sesión expiró. Cierra sesión, entra otra vez y vuelve a intentar.';
    }
    try {
      await _supabase.auth.updateUser(
        UserAttributes(password: clave),
      );
      return null;
    } on AuthException catch (e) {
      final m = e.message.toLowerCase();
      if (m.contains('session') || m.contains('jwt') || m.contains('expired')) {
        return 'Tu sesión expiró. Cierra sesión, entra otra vez y vuelve a intentar.';
      }
      if (m.contains('same') || m.contains('different') || m.contains('should be different')) {
        return 'Elige una contraseña distinta a la actual.';
      }
      if (m.contains('leaked') || m.contains('pwned') || m.contains('weak')) {
        return 'Esa contraseña es muy débil o aparece en filtraciones. Elige otra.';
      }
      if (m.contains('not confirmed') || m.contains('email not confirmed')) {
        return 'Confirma el correo (revisa spam) o pide a la directora que te confirme la cuenta.';
      }
      return 'No se pudo cambiar: ${e.message}';
    } catch (e) {
      return 'No se pudo cambiar la contraseña. Revisa internet e intenta de nuevo.';
    }
  }

  // Recuperar contraseña
  Future<String?> recuperarPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email.trim());
      return null;
    } on AuthException catch (e) {
      return 'Error: ${e.message}';
    } catch (e) {
      return 'Error inesperado: $e';
    }
  }
}
