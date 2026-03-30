import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/permiso.dart';
import '../models/rol.dart';

class PermisosService {
  final _client = Supabase.instance.client;

  // Cache de permisos del usuario actual
  Map<String, bool> _permisosCache = {};
  String? _usuarioIdCache;

  // ============================================
  // VERIFICAR PERMISOS
  // ============================================

  /// Verifica si el usuario actual tiene un permiso específico
  Future<bool> tienePermiso(String codigoPermiso) async {
    final usuarioId = _client.auth.currentUser?.id;
    if (usuarioId == null) return false;

    // Si cambió el usuario, limpiar cache
    if (_usuarioIdCache != usuarioId) {
      _permisosCache.clear();
      _usuarioIdCache = usuarioId;
    }

    // Si ya está en cache, retornar
    if (_permisosCache.containsKey(codigoPermiso)) {
      return _permisosCache[codigoPermiso]!;
    }

    try {
      // Llamar a la función RPC en Supabase
      final resultado = await _client.rpc(
        'usuario_tiene_permiso',
        params: {
          'p_usuario_id': usuarioId,
          'p_codigo_permiso': codigoPermiso,
        },
      );

      final tienePermiso = resultado as bool? ?? false;
      _permisosCache[codigoPermiso] = tienePermiso;
      return tienePermiso;
    } catch (e) {
      print('Error verificando permiso $codigoPermiso: $e');
      return false;
    }
  }

  /// Verifica múltiples permisos a la vez
  Future<Map<String, bool>> tienePermisos(List<String> codigosPermisos) async {
    final resultado = <String, bool>{};
    
    for (final codigo in codigosPermisos) {
      resultado[codigo] = await tienePermiso(codigo);
    }
    
    return resultado;
  }

  /// Obtiene todos los permisos del usuario actual
  Future<List<Permiso>> obtenerPermisosUsuario() async {
    final usuarioId = _client.auth.currentUser?.id;
    if (usuarioId == null) return [];

    try {
      final response = await _client
          .from('v_permisos_usuario')
          .select()
          .eq('usuario_id', usuarioId);

      final permisos = <Permiso>[];
      final permisosUnicos = <String>{};

      for (final item in response as List) {
        final codigo = item['permiso_codigo'] as String?;
        if (codigo != null && !permisosUnicos.contains(codigo)) {
          permisosUnicos.add(codigo);
          permisos.add(Permiso(
            id: item['permiso_codigo'], // Usar código como ID temporal
            codigo: codigo,
            nombre: item['permiso_nombre'] ?? codigo,
            modulo: item['modulo'] ?? '',
            tipo: item['permiso_tipo'] ?? 'lectura',
            createdAt: DateTime.now(),
          ));
        }
      }

      return permisos;
    } catch (e) {
      print('Error obteniendo permisos: $e');
      return [];
    }
  }

  // ============================================
  // GESTIÓN DE PERMISOS (SOLO DIRECTORA)
  // ============================================

  /// Obtener todos los permisos del catálogo
  Future<List<Permiso>> obtenerTodosLosPermisos() async {
    try {
      final response = await _client
          .from('permisos')
          .select()
          .eq('activo', true)
          .order('modulo')
          .order('nombre');

      return (response as List)
          .map((json) => Permiso.fromJson(json))
          .toList();
    } catch (e) {
      print('Error obteniendo permisos: $e');
      return [];
    }
  }

  /// Obtener todos los roles
  Future<List<Rol>> obtenerRoles() async {
    try {
      final response = await _client
          .from('roles')
          .select()
          .order('nivel_jerarquia');

      return (response as List)
          .map((json) => Rol.fromJson(json))
          .toList();
    } catch (e) {
      print('Error obteniendo roles: $e');
      return [];
    }
  }

  /// Obtener permisos de un rol específico
  Future<List<Permiso>> obtenerPermisosDeRol(String rolId) async {
    try {
      final response = await _client
          .from('roles_permisos')
          .select('permisos(*)')
          .eq('rol_id', rolId);

      return (response as List)
          .map((item) => Permiso.fromJson(item['permisos']))
          .toList();
    } catch (e) {
      print('Error obteniendo permisos del rol: $e');
      return [];
    }
  }

  /// Obtener permisos adicionales de un usuario específico
  Future<List<Permiso>> obtenerPermisosAdicionalesDeUsuario(String usuarioId) async {
    try {
      final response = await _client
          .from('usuarios_permisos')
          .select('permisos(*)')
          .eq('usuario_id', usuarioId);

      return (response as List)
          .map((item) => Permiso.fromJson(item['permisos']))
          .toList();
    } catch (e) {
      print('Error obteniendo permisos adicionales: $e');
      return [];
    }
  }

  /// Otorgar permiso adicional a un usuario
  Future<bool> otorgarPermisoAUsuario({
    required String usuarioId,
    required String permisoId,
  }) async {
    try {
      final otorgadoPor = _client.auth.currentUser?.id;
      
      await _client.from('usuarios_permisos').insert({
        'usuario_id': usuarioId,
        'permiso_id': permisoId,
        'otorgado_por': otorgadoPor,
      });

      return true;
    } catch (e) {
      print('Error otorgando permiso: $e');
      return false;
    }
  }

  /// Revocar permiso adicional de un usuario
  Future<bool> revocarPermisoDeUsuario({
    required String usuarioId,
    required String permisoId,
  }) async {
    try {
      await _client
          .from('usuarios_permisos')
          .delete()
          .eq('usuario_id', usuarioId)
          .eq('permiso_id', permisoId);

      return true;
    } catch (e) {
      print('Error revocando permiso: $e');
      return false;
    }
  }

  /// Limpiar cache de permisos
  void limpiarCache() {
    _permisosCache.clear();
    _usuarioIdCache = null;
  }
}
