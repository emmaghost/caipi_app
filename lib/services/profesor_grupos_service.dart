import 'package:supabase_flutter/supabase_flutter.dart';

/// Grados asignados a una profesora (soporta multi-grupo).
class ProfesorGruposService {
  ProfesorGruposService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  /// IDs de grado activos para el usuario (junction + legado grado_id).
  Future<List<String>> gradoIdsDeUsuario(String usuarioId) async {
    try {
      final viaRpc = await _client.rpc(
        'grados_de_profesor',
        params: {'p_usuario_id': usuarioId},
      );
      if (viaRpc is List && viaRpc.isNotEmpty) {
        return viaRpc.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
      }
    } catch (_) {}

    final rows = await _client
        .from('profesores')
        .select('id, grado_id')
        .eq('usuario_id', usuarioId)
        .eq('activo', true);

    final list = List<Map<String, dynamic>>.from(rows as List);
    if (list.isEmpty) return [];

    final ids = <String>{};
    final profesorIds = <String>[];
    for (final r in list) {
      final gid = r['grado_id'] as String?;
      if (gid != null && gid.isNotEmpty) ids.add(gid);
      final pid = r['id'] as String?;
      if (pid != null) profesorIds.add(pid);
    }

    if (profesorIds.isNotEmpty) {
      try {
        final junc = await _client
            .from('profesores_grados')
            .select('grado_id')
            .inFilter('profesor_id', profesorIds);
        for (final r in junc as List) {
          final gid = r['grado_id'] as String?;
          if (gid != null) ids.add(gid);
        }
      } catch (_) {}
    }

    return ids.toList();
  }

  /// Primer grado (compat con pantallas que aún usan uno solo).
  Future<String?> primerGradoId(String usuarioId) async {
    final ids = await gradoIdsDeUsuario(usuarioId);
    return ids.isEmpty ? null : ids.first;
  }

  Future<void> guardarGrados({
    required String profesorId,
    required List<String> gradoIds,
  }) async {
    await _client.from('profesores_grados').delete().eq('profesor_id', profesorId);
    if (gradoIds.isEmpty) return;
    await _client.from('profesores_grados').insert([
      for (final g in gradoIds)
        {'profesor_id': profesorId, 'grado_id': g},
    ]);
  }

  Future<List<String>> gradoIdsDeProfesorRow(String profesorId) async {
    try {
      final junc = await _client
          .from('profesores_grados')
          .select('grado_id')
          .eq('profesor_id', profesorId);
      final ids = (junc as List)
          .map((r) => r['grado_id'] as String?)
          .whereType<String>()
          .toList();
      if (ids.isNotEmpty) return ids;
    } catch (_) {}

    final row = await _client
        .from('profesores')
        .select('grado_id')
        .eq('id', profesorId)
        .maybeSingle();
    final gid = row?['grado_id'] as String?;
    return gid == null ? <String>[] : [gid];
  }
}
