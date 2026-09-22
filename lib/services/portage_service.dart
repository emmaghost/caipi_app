import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/portage.dart';
import 'profesor_grupos_service.dart';

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
    String tipo = 'habilidades',
    int? mesesEdad,
  }) async {
    final response = await _supabase
        .from('portage_listas')
        .insert({
          'grado_id': gradoId,
          'nombre': nombre.trim(),
          'activa': activa,
          'tipo': tipo,
          'created_by': createdBy,
          if (mesesEdad != null) 'meses_edad': mesesEdad,
        })
        .select()
        .single();

    return PortageLista.fromJson(response);
  }

  Future<PortageLista> actualizarLista({
    required String listaId,
    String? nombre,
    bool? activa,
    String? tipo,
  }) async {
    final payload = <String, dynamic>{
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    if (nombre != null) payload['nombre'] = nombre.trim();
    if (activa != null) payload['activa'] = activa;
    if (tipo != null) payload['tipo'] = tipo;

    final response = await _supabase
        .from('portage_listas')
        .update(payload)
        .eq('id', listaId)
        .select()
        .single();

    return PortageLista.fromJson(response);
  }

  /// Crea las 5 listas de habilidades de la plantilla Viri en un grado.
  /// Omite nombres que ya existan (mismo grado + tipo habilidades).
  Future<int> cargarPlantillaHabilidades({
    required String gradoId,
    required String createdBy,
    required List<({String nombre, List<String> items})> plantillas,
  }) async {
    final existentes = await listarListasPorGrado(gradoId);
    final nombresExistentes = existentes
        .where((l) => l.tipo == 'habilidades')
        .map((l) => l.nombre.toLowerCase())
        .toSet();

    var creadas = 0;
    for (final p in plantillas) {
      if (nombresExistentes.contains(p.nombre.toLowerCase())) continue;
      final lista = await crearLista(
        gradoId: gradoId,
        nombre: p.nombre,
        createdBy: createdBy,
        tipo: 'habilidades',
      );
      await guardarIndicadores(lista.id, p.items);
      creadas++;
    }
    return creadas;
  }

  Future<PortageLista> cargarPlantillaAlertas({
    required String gradoId,
    required String createdBy,
    required List<String> items,
    String nombre = 'Signos de alerta',
  }) async {
    final existentes = await listarListasPorGrado(gradoId);
    final ya = existentes.any(
      (l) => l.tipo == 'alertas' && l.nombre.toLowerCase() == nombre.toLowerCase(),
    );
    if (ya) {
      return existentes.firstWhere(
        (l) => l.tipo == 'alertas' && l.nombre.toLowerCase() == nombre.toLowerCase(),
      );
    }
    final lista = await crearLista(
      gradoId: gradoId,
      nombre: nombre,
      createdBy: createdBy,
      tipo: 'alertas',
    );
    await guardarIndicadores(lista.id, items);
    return lista;
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
    List<String> nombres, {
    List<String?>? areas,
  }) async {
    await _supabase
        .from('portage_indicadores')
        .delete()
        .eq('lista_id', listaId);

    final rows = <Map<String, dynamic>>[];
    for (var i = 0; i < nombres.length; i++) {
      final nombre = nombres[i].trim();
      if (nombre.isEmpty) continue;
      final area = (areas != null && i < areas.length) ? areas[i] : null;
      rows.add({
        'lista_id': listaId,
        'nombre': nombre,
        'orden': rows.length,
        if (area != null && area.trim().isNotEmpty) 'area': area.trim(),
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

  /// Carga un tramo de hitos (por meses) en un grado. No asigna a niños.
  /// Si ya existe lista con mismo grado + meses, no duplica.
  Future<PortageLista?> cargarHitosTramo({
    required String gradoId,
    required int meses,
    required String createdBy,
    required List<({String area, List<String> items})> areas,
  }) async {
    final existentes = await listarListasPorGrado(gradoId);
    final ya = existentes.where((l) => l.mesesEdad == meses).toList();
    if (ya.isNotEmpty) return ya.first;

    final lista = await crearLista(
      gradoId: gradoId,
      nombre: 'Hitos $meses meses',
      createdBy: createdBy,
      tipo: 'habilidades',
      mesesEdad: meses,
    );

    final nombres = <String>[];
    final areasFlat = <String?>[];
    for (final a in areas) {
      for (final item in a.items) {
        nombres.add(item);
        areasFlat.add(a.area);
      }
    }
    await guardarIndicadores(lista.id, nombres, areas: areasFlat);
    return lista;
  }

  Future<List<String>> listarListaIdsAsignadasAlumno(String alumnoId) async {
    final rows = await _supabase
        .from('portage_alumno_listas')
        .select('lista_id')
        .eq('alumno_id', alumnoId);
    return (rows as List)
        .map((r) => r['lista_id'] as String?)
        .whereType<String>()
        .toList();
  }

  Future<List<PortageLista>> listarListasAsignadasAlumno(String alumnoId) async {
    final ids = await listarListaIdsAsignadasAlumno(alumnoId);
    if (ids.isEmpty) return [];
    final rows = await _supabase
        .from('portage_listas')
        .select()
        .inFilter('id', ids)
        .order('meses_edad');
    return (rows as List)
        .map((j) => PortageLista.fromJson(Map<String, dynamic>.from(j as Map)))
        .toList();
  }

  Future<void> asignarListaAlumno({
    required String alumnoId,
    required String listaId,
    String? assignedBy,
  }) async {
    await _supabase.from('portage_alumno_listas').upsert({
      'alumno_id': alumnoId,
      'lista_id': listaId,
      if (assignedBy != null) 'assigned_by': assignedBy,
    });
  }

  Future<void> quitarListaAlumno({
    required String alumnoId,
    required String listaId,
  }) async {
    await _supabase
        .from('portage_alumno_listas')
        .delete()
        .eq('alumno_id', alumnoId)
        .eq('lista_id', listaId);
  }

  Future<void> sincronizarAsignacionesAlumno({
    required String alumnoId,
    required Set<String> listaIds,
    String? assignedBy,
  }) async {
    final actuales = (await listarListaIdsAsignadasAlumno(alumnoId)).toSet();
    for (final id in actuales.difference(listaIds)) {
      await quitarListaAlumno(alumnoId: alumnoId, listaId: id);
    }
    for (final id in listaIds.difference(actuales)) {
      await asignarListaAlumno(
        alumnoId: alumnoId,
        listaId: id,
        assignedBy: assignedBy,
      );
    }
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

  /// Borra el seguimiento y, por CASCADE, todas sus calificaciones.
  Future<void> eliminarEvaluacion(String evaluacionId) async {
    await _supabase
        .from('portage_evaluaciones')
        .delete()
        .eq('id', evaluacionId);
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
    // Solo la directora debe cambiar esto (UI + refuerzo aquí).
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) {
      throw StateError('Sesión no válida');
    }
    final rol = await _supabase
        .from('usuarios')
        .select('rol')
        .eq('id', uid)
        .maybeSingle();
    if (rol?['rol']?.toString() != 'directora') {
      throw StateError(
        'Solo la directora puede mostrar u ocultar indicadores a los padres.',
      );
    }
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
    return ProfesorGruposService(client: _supabase).primerGradoId(usuarioId);
  }
}
