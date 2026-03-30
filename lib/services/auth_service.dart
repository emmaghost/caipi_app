import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/usuario.dart';

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
  bool get isPadre => esPadre; // Backward compatibility

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
      
      _currentUser = Usuario.fromJson(response);
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

  /// Al dar de alta padre/profesora con `signUp` estando la directora logueada,
  /// Supabase puede cambiar la sesión al usuario recién creado y fallan los INSERT (RLS).
  /// Guarda [userIdAntes] y [refreshAntes] **antes** del signUp; llama esto **después**.
  Future<void> restaurarSesionTrasSignUpDesdeDirectora({
    required String userIdAntes,
    required String refreshAntes,
  }) async {
    final ahora = _supabase.auth.currentUser?.id;
    if (ahora == userIdAntes) return;
    try {
      await _supabase.auth.refreshSession(refreshAntes);
    } catch (e) {
      debugPrint('refreshSession tras signUp: $e');
      rethrow;
    }
    if (_supabase.auth.currentUser?.id != userIdAntes) {
      throw Exception(
        'Tu sesión cambió al crear el usuario. Vuelve a iniciar sesión como directora. '
        'Si el correo ya quedó en Auth sin perfil, bórralo en Supabase → Authentication.',
      );
    }
    await _loadUserData(userIdAntes);
    notifyListeners();
  }

  // Cerrar sesión
  Future<void> logout() async {
    await _supabase.auth.signOut();
    _currentUser = null;
    notifyListeners();
  }

  /// Contraseña nueva (usuario ya autenticado). Mínimo 6 caracteres (Supabase).
  Future<String?> cambiarPassword(String newPassword) async {
    if (newPassword.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    try {
      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      return null;
    } on AuthException catch (e) {
      return 'Error al cambiar contraseña: ${e.message}';
    } catch (e) {
      return 'Error inesperado: $e';
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
