import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/portage.dart';

class PortageService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // --- Listas ---

  Future<List<PortageLista>> listarListasPorGrado(String gradoId) async {
    final response = await _supabase
        .from('portage_listas')
        .select()
        .eq('grado_id', gradoId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => PortageLista.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<PortageLista?> obtenerLista(String listaId) async {
    final response = await _supabase
        .from('portage_listas')
        .select()
        .eq('id', listaId)
        .maybeSingle();

    return response != null
        ? PortageLista.fromJson(response)
        : null;
  }

  Future<PortageLista> crearLista({
    required String gradoId,
    required String nombre,
    required String createdBy,
    bool activa = true,
  }) async {
    final response = await _supabase
        .from('portage_listas')
        .insert({
          'grado_id': gradoId,
          'nombre': nombre.trim(),
          'activa': activa,
          'created_by': createdBy,
        })
        .select()
        .single();

    return PortageLista.fromJson(response);
  }

  Future<PortageLista> actualizarLista({
    required String listaId,
    String? nombre,
    bool? activa,
  }) async {
    final payload = <String, dynamic>{
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    if (nombre != null) payload['nombre'] = nombre.trim();
    if (activa != null) payload['activa'] = activa;

    final response = await _supabase
        .from('portage_listas')
        .update(payload)
        .eq('id', listaId)
        .select()
        .single();

    return PortageLista.fromJson(response);
  }

  Future<void> eliminarLista(String listaId) async {
    await _supabase.from('portage_listas').delete().eq('id', listaId);
  }

  // --- Indicadores ---

  Future<List<PortageIndicador>> listarIndicadores(String listaId) async {
    final response = await _supabase
        .from('portage_indicadores')
        .select()
        .eq('lista_id', listaId)
        .order('orden', ascending: true);

    return (response as List)
        .map((json) => PortageIndicador.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Reemplaza todos los indicadores de la lista por [nombres] (orden = índice).
  Future<List<PortageIndicador>> guardarIndicadores(
    String listaId,
    List<String> nombres,
  ) async {
    await _supabase
        .from('portage_indicadores')
        .delete()
        .eq('lista_id', listaId);

    final rows = <Map<String, dynamic>>[];
    for (var i = 0; i < nombres.length; i++) {
      final nombre = nombres[i].trim();
      if (nombre.isEmpty) continue;
      rows.add({
        'lista_id': listaId,
        'nombre': nombre,
        'orden': rows.length,
      });
    }

    if (rows.isEmpty) return [];

    final response = await _supabase
        .from('portage_indicadores')
        .insert(rows)
        .select();

    return (response as List)
        .map((json) => PortageIndicador.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // --- Evaluaciones ---

  Future<PortageEvaluacion> crearEvaluacion({
    required String listaId,
    required String gradoId,
    required String createdBy,
    String? titulo,
    DateTime? fechaInicio,
  }) async {
    final response = await _supabase
        .from('portage_evaluaciones')
        .insert({
          'lista_id': listaId,
          'grado_id': gradoId,
          'titulo': titulo?.trim().isEmpty ?? true ? null : titulo!.trim(),
          'fecha_inicio':
              (fechaInicio ?? DateTime.now()).toIso8601String().split('T')[0],
          'created_by': createdBy,
        })
        .select()
        .single();

    return PortageEvaluacion.fromJson(response);
  }

  Future<List<PortageEvaluacion>> listarEvaluacionesPorGrado(
    String gradoId,
  ) async {
    final response = await _supabase
        .from('portage_evaluaciones')
        .select()
        .eq('grado_id', gradoId)
        .order('fecha_inicio', ascending: false);

    return (response as List)
        .map((json) => PortageEvaluacion.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<PortageEvaluacion>> listarEvaluacionesPorLista(
    String listaId,
  ) async {
    final response = await _supabase
        .from('portage_evaluaciones')
        .select()
        .eq('lista_id', listaId)
        .order('fecha_inicio', ascending: false);

    return (response as List)
        .map((json) => PortageEvaluacion.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<PortageEvaluacion?> obtenerEvaluacion(String evaluacionId) async {
    final response = await _supabase
        .from('portage_evaluaciones')
        .select()
        .eq('id', evaluacionId)
        .maybeSingle();

    return response != null
        ? PortageEvaluacion.fromJson(response)
        : null;
  }

  // --- Resultados ---

  Future<List<PortageResultado>> obtenerResultados(
    String evaluacionId,
    String alumnoId,
  ) async {
    final response = await _supabase
        .from('portage_resultados')
        .select()
        .eq('evaluacion_id', evaluacionId)
        .eq('alumno_id', alumnoId);

    return (response as List)
        .map((json) => PortageResultado.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<PortageResultado> upsertResultado({
    required String evaluacionId,
    required String alumnoId,
    required String indicadorId,
    String? estado,
    String? observaciones,
    required String actualizadoPor,
  }) async {
    final estadoNorm = PortageEstado.parse(estado);
    final obs = observaciones?.trim();
    final payload = {
      'evaluacion_id': evaluacionId,
      'alumno_id': alumnoId,
      'indicador_id': indicadorId,
      'estado': estadoNorm,
      'observaciones': obs == null || obs.isEmpty ? null : obs,
      'actualizado_por': actualizadoPor,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    final response = await _supabase
        .from('portage_resultados')
        .upsert(
          payload,
          onConflict: 'evaluacion_id,alumno_id,indicador_id',
        )
        .select()
        .single();

    return PortageResultado.fromJson(response);
  }

  // --- Alumno / grado auxiliares ---

  Future<void> setPortageVisiblePadre(String alumnoId, bool visible) async {
    await _supabase
        .from('alumnos')
        .update({'portage_visible_padre': visible})
        .eq('id', alumnoId);
  }

  Future<void> setGuiaDriveUrl(String gradoId, String? url) async {
    final limpio = url?.trim();
    await _supabase.from('grados').update({
      'guia_drive_url': limpio == null || limpio.isEmpty ? null : limpio,
    }).eq('id', gradoId);
  }

  Future<String?> obtenerGuiaDriveUrl(String gradoId) async {
    final response = await _supabase
        .from('grados')
        .select('guia_drive_url')
        .eq('id', gradoId)
        .maybeSingle();

    return response?['guia_drive_url'] as String?;
  }

  /// Última evaluación del grado del alumno (vista padre).
  Future<PortageEvaluacion?> ultimaEvaluacionParaAlumno(String alumnoId) async {
    final alumno = await _supabase
        .from('alumnos')
        .select('grado_id')
        .eq('id', alumnoId)
        .maybeSingle();

    final gradoId = alumno?['grado_id'] as String?;
    if (gradoId == null) return null;

    final response = await _supabase
        .from('portage_evaluaciones')
        .select()
        .eq('grado_id', gradoId)
        .order('fecha_inicio', ascending: false)
        .limit(1)
        .maybeSingle();

    return response != null
        ? PortageEvaluacion.fromJson(response)
        : null;
  }

  Future<String?> obtenerGradoIdProfesor(String usuarioId) async {
    final rows = await _supabase
        .from('profesores')
        .select('grado_id')
        .eq('usuario_id', usuarioId)
        .eq('activo', true)
        .limit(1);
    final list = List<Map<String, dynamic>>.from(rows as List);
    if (list.isEmpty) return null;
    return list.first['grado_id'] as String?;
  }
}
