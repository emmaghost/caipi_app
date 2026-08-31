import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/liga_drive.dart';

class LigaDriveService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<LigaDrive>> listarTodas() async {
    final response = await _supabase
        .from('ligas_drive')
        .select('*, ligas_drive_grados(grado_id)')
        .order('created_at', ascending: false);

    return (response as List)
        .map((j) => LigaDrive.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<LigaDrive?> obtener(String id) async {
    final response = await _supabase
        .from('ligas_drive')
        .select('*, ligas_drive_grados(grado_id)')
        .eq('id', id)
        .maybeSingle();
    return response == null ? null : LigaDrive.fromJson(response);
  }

  /// Ligas visibles para un alumno: generales + las de su grado.
  Future<List<LigaDrive>> listarParaAlumno(String alumnoId) async {
    final alumno = await _supabase
        .from('alumnos')
        .select('grado_id')
        .eq('id', alumnoId)
        .maybeSingle();
    final gradoId = alumno?['grado_id'] as String?;

    final generales = await _supabase
        .from('ligas_drive')
        .select()
        .eq('activa', true)
        .eq('alcance', 'general')
        .order('nombre');

    final mapa = <String, LigaDrive>{};
    for (final row in generales as List) {
      final liga = LigaDrive.fromJson(row as Map<String, dynamic>);
      if (liga.activa) mapa[liga.id] = liga;
    }

    if (gradoId != null) {
      final porGrado = await _supabase
          .from('ligas_drive_grados')
          .select('liga_id, ligas_drive(*)')
          .eq('grado_id', gradoId);
      for (final row in porGrado as List) {
        final ligaJson = row['ligas_drive'];
        if (ligaJson is Map<String, dynamic>) {
          final liga = LigaDrive.fromJson(ligaJson);
          if (liga.activa) mapa[liga.id] = liga;
        }
      }
    }

    final list = mapa.values.toList()
      ..sort((a, b) => a.nombre.compareTo(b.nombre));
    return list;
  }

  Future<LigaDrive> crear({
    required String nombre,
    required String url,
    required String alcance,
    required String createdBy,
    List<String> gradoIds = const [],
  }) async {
    final response = await _supabase
        .from('ligas_drive')
        .insert({
          'nombre': nombre.trim(),
          'url': url.trim(),
          'alcance': alcance,
          'created_by': createdBy,
          'activa': true,
        })
        .select()
        .single();

    final liga = LigaDrive.fromJson(response);
    if (alcance == 'grados' && gradoIds.isNotEmpty) {
      await _reemplazarGrados(liga.id, gradoIds);
    }
    return (await obtener(liga.id)) ?? liga;
  }

  Future<LigaDrive> actualizar({
    required String id,
    required String nombre,
    required String url,
    required String alcance,
    bool? activa,
    List<String> gradoIds = const [],
  }) async {
    await _supabase.from('ligas_drive').update({
      'nombre': nombre.trim(),
      'url': url.trim(),
      'alcance': alcance,
      if (activa != null) 'activa': activa,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', id);

    await _supabase.from('ligas_drive_grados').delete().eq('liga_id', id);
    if (alcance == 'grados' && gradoIds.isNotEmpty) {
      await _reemplazarGrados(id, gradoIds);
    }
    return (await obtener(id))!;
  }

  Future<void> eliminar(String id) async {
    await _supabase.from('ligas_drive').delete().eq('id', id);
  }

  Future<void> _reemplazarGrados(String ligaId, List<String> gradoIds) async {
    final rows = gradoIds
        .where((id) => id.isNotEmpty)
        .map((gradoId) => {'liga_id': ligaId, 'grado_id': gradoId})
        .toList();
    if (rows.isEmpty) return;
    await _supabase.from('ligas_drive_grados').insert(rows);
  }
}
