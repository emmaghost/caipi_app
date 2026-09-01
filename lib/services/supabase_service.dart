import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../models/alumno.dart';
import '../models/pago.dart';
import '../models/calificacion.dart';
import '../models/incidente.dart';
import '../models/anuncio.dart';
import '../models/grado.dart';
import '../models/usuario.dart';
import '../models/abono.dart';
import '../models/configuracion_costos.dart';
import '../utils/pago_helpers.dart';

class SupabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Incrementa al crear/editar/borrar alumnos para que la lista se refresque.
  final ValueNotifier<int> alumnosRevision = ValueNotifier<int>(0);

  void avisarAlumnosCambiaron() {
    alumnosRevision.value++;
  }

  // ==================== ALUMNOS ====================
  
  Stream<List<Alumno>> getAlumnos() {
    return _supabase
        .from('alumnos')
        .stream(primaryKey: ['id'])
        .map((data) => data
            .where((json) => json['activo'] == true)
            .map((json) => Alumno.fromJson(json))
            .toList()
          ..sort((a, b) => a.apellidos.compareTo(b.apellidos)));
  }

  Future<List<Alumno>> obtenerAlumnos() async {
    final response = await _supabase
        .from('alumnos')
        .select()
        .eq('activo', true)
        .order('apellidos');
    
    return response.map((json) => Alumno.fromJson(json)).toList();
  }

  Future<Alumno?> obtenerAlumnoPorId(String alumnoId) async {
    final response = await _supabase
        .from('alumnos')
        .select()
        .eq('id', alumnoId)
        .maybeSingle();
    
    return response != null ? Alumno.fromJson(response) : null;
  }

  /// Obtiene el usuario (ej. padre) por id. Para WhatsApp del padre.
  Future<Usuario?> obtenerUsuarioPorId(String usuarioId) async {
    final response = await _supabase
        .from('usuarios')
        .select()
        .eq('id', usuarioId)
        .maybeSingle();
    return response != null ? Usuario.fromJson(response) : null;
  }

  /// Teléfono o WhatsApp del padre del alumno (para notificar adeudos).
  Future<String?> obtenerTelefonoPadrePorAlumnoId(String alumnoId) async {
    final alumno = await obtenerAlumnoPorId(alumnoId);
    if (alumno == null || alumno.padreId == null || alumno.padreId!.isEmpty) {
      return null;
    }
    final response = await _supabase
        .from('usuarios')
        .select('whatsapp, telefono')
        .eq('id', alumno.padreId!)
        .maybeSingle();
    if (response == null) return null;
    return response['whatsapp'] as String? ?? response['telefono'] as String?;
  }

  Stream<List<Alumno>> getAlumnosPorPadre(String padreId) {
    return _supabase
        .from('alumnos')
        .stream(primaryKey: ['id'])
        .asyncMap((data) async {
          final idsTutor = await idsAlumnosDePadre(padreId);
          return data
              .where((json) =>
                  json['activo'] == true &&
                  (json['padre_id'] == padreId ||
                      idsTutor.contains(json['id'])))
              .map((json) => Alumno.fromJson(json))
              .toList();
        });
  }

  /// IDs de hijos vinculados a este papá (columna padre_id o tabla alumnos_padres).
  Future<Set<String>> idsAlumnosDePadre(String padreId) async {
    final ids = <String>{};
    try {
      final rows = await _supabase
          .from('alumnos_padres')
          .select('alumno_id')
          .eq('padre_id', padreId);
      for (final r in rows as List) {
        final id = r['alumno_id'] as String?;
        if (id != null) ids.add(id);
      }
    } catch (_) {
      // Tabla aún no creada: se usa solo alumnos.padre_id.
    }
    try {
      final rows = await _supabase
          .from('alumnos')
          .select('id')
          .eq('padre_id', padreId)
          .eq('activo', true);
      for (final r in rows as List) {
        ids.add(r['id'] as String);
      }
    } catch (_) {}
    return ids;
  }

  Future<List<String>> emailsPadresDeAlumno(String alumnoId) async {
    final emails = <String>[];
    try {
      final rows = await _supabase
          .from('alumnos_padres')
          .select('padre_id, es_principal')
          .eq('alumno_id', alumnoId)
          .order('es_principal', ascending: false);
      final padreIds = <String>[];
      for (final r in rows as List) {
        final id = r['padre_id'] as String?;
        if (id != null && !padreIds.contains(id)) padreIds.add(id);
      }
      for (final id in padreIds) {
        final padre = await _supabase
            .from('usuarios')
            .select('email')
            .eq('id', id)
            .maybeSingle();
        final email = padre?['email'] as String?;
        if (email != null && email.isNotEmpty && !emails.contains(email)) {
          emails.add(email);
        }
      }
      if (emails.isNotEmpty) return emails;
    } catch (_) {}

    try {
      final alumno = await _supabase
          .from('alumnos')
          .select('padre_id')
          .eq('id', alumnoId)
          .maybeSingle();
      final pid = alumno?['padre_id'] as String?;
      if (pid == null || pid.isEmpty) return [];
      final padre = await _supabase
          .from('usuarios')
          .select('email')
          .eq('id', pid)
          .maybeSingle();
      final email = padre?['email'] as String?;
      return email == null || email.isEmpty ? [] : [email];
    } catch (_) {
      return [];
    }
  }

  /// IDs de todos los papás vinculados al alumno (principal + alumnos_padres).
  Future<List<String>> idsPadresDeAlumno(String alumnoId) async {
    final ids = <String>[];
    try {
      final rows = await _supabase
          .from('alumnos_padres')
          .select('padre_id')
          .eq('alumno_id', alumnoId);
      for (final r in rows as List) {
        final id = r['padre_id'] as String?;
        if (id != null && id.isNotEmpty && !ids.contains(id)) ids.add(id);
      }
    } catch (_) {}

    if (ids.isEmpty) {
      try {
        final alumno = await _supabase
            .from('alumnos')
            .select('padre_id')
            .eq('id', alumnoId)
            .maybeSingle();
        final pid = alumno?['padre_id'] as String?;
        if (pid != null && pid.isNotEmpty) ids.add(pid);
      } catch (_) {}
    }
    return ids;
  }

  /// Reemplaza los tutores del alumno (máximo 2). El primero queda en padre_id.
  Future<void> guardarPadresAlumno(
    String alumnoId,
    List<String> padreIds,
  ) async {
    final unique = <String>[];
    for (final id in padreIds) {
      if (id.isNotEmpty && !unique.contains(id)) unique.add(id);
    }
    final ids = unique.take(2).toList();

    try {
      await _supabase.from('alumnos_padres').delete().eq('alumno_id', alumnoId);
    } catch (_) {}

    await _supabase.from('alumnos').update({
      'padre_id': ids.isEmpty ? null : ids.first,
    }).eq('id', alumnoId);

    if (ids.isEmpty) return;

    try {
      await _supabase.from('alumnos_padres').upsert(
        [
          for (var i = 0; i < ids.length; i++)
            {
              'alumno_id': alumnoId,
              'padre_id': ids[i],
              'es_principal': i == 0,
            },
        ],
      );
    } catch (e) {
      // ignore: avoid_print
      print('guardarPadresAlumno: $e');
    }
  }

  Stream<List<Alumno>> getAlumnosPorGrado(String grado) {
    return _supabase
        .from('alumnos')
        .stream(primaryKey: ['id'])
        .map((data) => data
            .where((json) => json['grado'] == grado && json['activo'] == true)
            .map((json) => Alumno.fromJson(json))
            .toList()
          ..sort((a, b) => a.apellidos.compareTo(b.apellidos)));
  }

  Future<void> crearAlumno(Alumno alumno, {bool verificarDuplicado = true}) async {
    final fechaNacimiento =
        alumno.fechaNacimiento.toIso8601String().split('T')[0];

    // Evita duplicados al reintentar el form. En alta rápida sin fecha de
    // nacimiento se usa placeholder 2018-01-01: no checar o bloquearía a todos.
    final esFechaPlaceholder = fechaNacimiento == '2018-01-01';
    if (verificarDuplicado && !esFechaPlaceholder) {
      var query = _supabase
          .from('alumnos')
          .select('id')
          .ilike('nombre', alumno.nombre.trim())
          .ilike('apellidos', alumno.apellidos.trim())
          .eq('fecha_nacimiento', fechaNacimiento)
          .eq('activo', true);
      if (alumno.padreId != null && alumno.padreId!.isNotEmpty) {
        query = query.eq('padre_id', alumno.padreId!);
      }
      final existente = await query.limit(1);
      if ((existente as List).isNotEmpty) {
        throw Exception(
          'Este alumno ya está registrado con los mismos datos básicos.',
        );
      }
    }

    await _supabase.from('alumnos').insert(alumno.toJson());
    avisarAlumnosCambiaron();

    // Los pagos no deben tumbar el alta del niño.
    try {
      await _generarPagosIniciales(alumno);
    } catch (e) {
      // ignore: avoid_print
      print('Alumno creado; pagos iniciales con aviso: $e');
    }
  }

  Future<void> _generarPagosIniciales(Alumno alumno) async {
    // Si el trigger de BD ya creó cargos, no duplicar.
    final existentes = await _supabase
        .from('pagos')
        .select('id')
        .eq('alumno_id', alumno.id)
        .limit(1);
    if ((existentes as List).isNotEmpty) return;

    // Estimulación = maternal: cobro por clase, sin colegiaturas ni paquetes auto.
    if (alumno.esPlanEstimulacion) return;

    // Sin grado o no kínder: no generar colegiaturas.
    if (alumno.gradoId == null || alumno.gradoId!.isEmpty) return;

    final gradoRow = await _supabase
        .from('grados')
        .select('nombre')
        .eq('id', alumno.gradoId!)
        .maybeSingle();
    if (gradoRow == null) return;
    final g = Grado.fromJson({
      ...gradoRow,
      'id': alumno.gradoId,
      'cupo_maximo': 20,
      'activo': true,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
    if (!g.esKinder) return;

    final inicio = alumno.fechaIngreso;
    final plan = PagoHelpers.normalizarPlan(alumno.planPagos);
    final descuentoFactor = (100 - alumno.becaPorcentaje.clamp(0, 100)) / 100.0;
    final anioCiclo = PagoHelpers.anioInicioCiclo(inicio);

    // Solo colegiaturas en el cuadro de pagos (no inscripción ni seguro).
    var costoMensualidad = plan == 10
        ? 2400.0
        : plan == 11
            ? 2200.0
            : 1500.0;

    try {
      final cfg = await _supabase
          .from('configuracion_costos')
          .select()
          .eq('vigente', true)
          .order('vigencia_desde', ascending: false)
          .limit(1)
          .maybeSingle();
      if (cfg != null) {
        final m12 = (cfg['costo_mensualidad_12'] as num).toDouble();
        final m10 = (cfg['costo_mensualidad_10'] as num).toDouble();
        final m11Raw = cfg['costo_mensualidad_11'];
        final m11 = m11Raw is num ? m11Raw.toDouble() : ((m12 + m10) / 2);
        costoMensualidad = plan == 10 ? m10 : plan == 11 ? m11 : m12;
      }
    } catch (_) {
      // Usar defaults si no hay configuración.
    }

    final List<Map<String, dynamic>> pagosIniciales = [];
    final fechas = PagoHelpers.fechasMensualidadesPlan(
      planPagos: plan,
      fechaIngreso: inicio,
    );
    final totalMeses = fechas.length;
    for (var i = 0; i < fechas.length; i++) {
      final fechaLimite = fechas[i];
      pagosIniciales.add({
        'alumno_id': alumno.id,
        'mes': PagoHelpers.etiquetaPeriodo(fechaLimite),
        'concepto': 'Colegiatura (${i + 1}/$totalMeses)',
        'monto': costoMensualidad * descuentoFactor,
        'monto_pagado': 0.0,
        'fecha_vencimiento':
            fechaLimite.toIso8601String().split('T')[0],
        'estatus': 'pendiente',
        'tipo_pago': 'mensualidad',
        'anio_escolar': anioCiclo,
      });
    }

    if (pagosIniciales.isNotEmpty) {
      await _supabase.from('pagos').insert(pagosIniciales);
    }
  }

  /// Tras editar grado/plan: genera pagos solo si aún no hay ninguno.
  /// Devuelve aviso si ya había pagos (no se tocan).
  Future<String?> sincronizarPagosTrasEditarAlumno(Alumno alumno) async {
    final existentes = await _supabase
        .from('pagos')
        .select('id')
        .eq('alumno_id', alumno.id)
        .limit(1);
    if ((existentes as List).isNotEmpty) {
      return 'Grado/plan actualizado. Los pagos ya existentes no se modifican; '
          'ajusta cargos en Pagos si hace falta.';
    }
    try {
      await _generarPagosIniciales(alumno);
    } catch (e) {
      // ignore: avoid_print
      print('sincronizarPagosTrasEditarAlumno: $e');
    }
    return null;
  }

  Future<void> _generarPagosEstimulacion(Alumno alumno) async {
    final inicio = alumno.fechaIngreso;
    final descuentoFactor = (100 - alumno.becaPorcentaje.clamp(0, 100)) / 100.0;
    final anioCiclo = PagoHelpers.anioInicioCiclo(inicio);
    final plan = alumno.planEstimulacion ?? 'sesion';

    var costoSesion = 350.0;
    var costoP4 = 950.0;
    var costoP6 = 1100.0;
    var costoP8 = 1150.0;
    var costoInsc = 1150.0;

    try {
      final cfg = await _supabase
          .from('configuracion_costos')
          .select()
          .eq('vigente', true)
          .order('vigencia_desde', ascending: false)
          .limit(1)
          .maybeSingle();
      if (cfg != null) {
        if (cfg['estim_sesion'] is num) {
          costoSesion = (cfg['estim_sesion'] as num).toDouble();
        }
        if (cfg['estim_paquete_4'] is num) {
          costoP4 = (cfg['estim_paquete_4'] as num).toDouble();
        }
        if (cfg['estim_paquete_6'] is num) {
          costoP6 = (cfg['estim_paquete_6'] as num).toDouble();
        }
        if (cfg['estim_paquete_8'] is num) {
          costoP8 = (cfg['estim_paquete_8'] as num).toDouble();
        }
        if (cfg['estim_inscripcion_anual'] is num) {
          costoInsc = (cfg['estim_inscripcion_anual'] as num).toDouble();
        }
      }
    } catch (_) {}

    final pagos = <Map<String, dynamic>>[];
    final vencInsc = inicio.add(const Duration(days: 15));

    // Inscripción anual de estimulación (sí va en pagos de estimulación).
    pagos.add({
      'alumno_id': alumno.id,
      'mes': 'Inscripción estimulación $anioCiclo',
      'concepto': 'Inscripción anual estimulación',
      'monto': costoInsc * descuentoFactor,
      'monto_pagado': 0.0,
      'fecha_vencimiento': vencInsc.toIso8601String().split('T')[0],
      'estatus': 'pendiente',
      'tipo_pago': 'inscripcion',
      'anio_escolar': anioCiclo,
    });

    if (plan == 'sesion') {
      // Por sesión: solo inscripción; las sesiones se cargan al asistir.
      await _supabase.from('pagos').insert(pagos);
      return;
    }

    final montoMensual = plan == 'paquete_4'
        ? costoP4
        : plan == 'paquete_6'
            ? costoP6
            : costoP8;
    final etiqueta = plan == 'paquete_4'
        ? 'Paquete 4 sesiones/mes'
        : plan == 'paquete_6'
            ? 'Paquete 6 sesiones/mes'
            : 'Paquete 8 sesiones/mes';

    // Paquetes mensuales Ago–Jul (ciclo escolar), desde mes de ingreso.
    final fechas = PagoHelpers.fechasMensualidadesPlan(
      planPagos: 12,
      fechaIngreso: inicio,
    );
    for (var i = 0; i < fechas.length; i++) {
      final f = fechas[i];
      pagos.add({
        'alumno_id': alumno.id,
        'mes': PagoHelpers.etiquetaPeriodo(f),
        'concepto': '$etiqueta (${i + 1}/${fechas.length})',
        'monto': montoMensual * descuentoFactor,
        'monto_pagado': 0.0,
        'fecha_vencimiento': f.toIso8601String().split('T')[0],
        'estatus': 'pendiente',
        'tipo_pago': 'mensualidad',
        'anio_escolar': anioCiclo,
      });
    }

    await _supabase.from('pagos').insert(pagos);
  }

  Future<ConfiguracionCostos?> obtenerConfiguracionCostosVigente() async {
    try {
      final response = await _supabase
          .from('configuracion_costos')
          .select()
          .eq('vigente', true)
          .order('vigencia_desde', ascending: false)
          .limit(1)
          .maybeSingle();
      if (response == null) return null;
      return ConfiguracionCostos.fromJson(response);
    } catch (_) {
      return null;
    }
  }

  /// Monto de una sesión de estimulación (para cargos manuales).
  Future<double> costoSesionEstimulacion() async {
    try {
      final cfg = await _supabase
          .from('configuracion_costos')
          .select('estim_sesion')
          .eq('vigente', true)
          .order('vigencia_desde', ascending: false)
          .limit(1)
          .maybeSingle();
      if (cfg != null && cfg['estim_sesion'] is num) {
        return (cfg['estim_sesion'] as num).toDouble();
      }
    } catch (_) {}
    return 350.0;
  }

  Future<void> agregarPagoLibros(String alumnoId, double monto) async {
    final now = DateTime.now();
    await _supabase.from('pagos').insert({
      'alumno_id': alumnoId,
      'mes': 'Libros ${now.year}',
      'concepto': 'Paquete de Libros',
      'monto': monto,
      'monto_pagado': 0.0,
      'fecha_vencimiento': DateTime(now.year, now.month, 15).toIso8601String().split('T')[0],
      'estatus': 'pendiente',
      'tipo_pago': 'extracurricular',
      'anio_escolar': now.year,
    });
  }

  Future<void> agregarPagoUniforme(String alumnoId, int cantidad, double precioUnitario) async {
    final now = DateTime.now();
    await _supabase.from('pagos').insert({
      'alumno_id': alumnoId,
      'mes': 'Uniforme ${DateFormat('dd/MM/yyyy').format(now)}',
      'concepto': 'Uniforme ($cantidad piezas)',
      'monto': cantidad * precioUnitario,
      'monto_pagado': 0.0,
      'fecha_vencimiento': DateTime(now.year, now.month, 15).toIso8601String().split('T')[0],
      'estatus': 'pendiente',
      'tipo_pago': 'extracurricular',
      'anio_escolar': now.year,
    });
  }

  /// Gasto personalizado (nombre libre + monto).
  Future<void> agregarPagoPersonalizado({
    required String alumnoId,
    required String nombreGasto,
    required double monto,
  }) async {
    final now = DateTime.now();
    final nombre = nombreGasto.trim();
    if (nombre.isEmpty) throw ArgumentError('El nombre del gasto es obligatorio');
    if (monto <= 0) throw ArgumentError('El monto debe ser mayor a cero');

    await _supabase.from('pagos').insert({
      'alumno_id': alumnoId,
      'mes': nombre,
      'concepto': nombre,
      'monto': monto,
      'monto_pagado': 0.0,
      'fecha_vencimiento': DateTime(now.year, now.month, 15).toIso8601String().split('T')[0],
      'estatus': 'pendiente',
      'tipo_pago': 'otro',
      'anio_escolar': now.year,
    });
  }

  /// Alta manual de cargo (colegiatura u otro) con periodo, descuento y notas.
  Future<void> crearPagoManual({
    required String alumnoId,
    required String tipoPago,
    required String concepto,
    required double montoBruto,
    required DateTime fechaPeriodo,
    double descuento = 0,
    String? notas,
    DateTime? fechaVencimiento,
  }) async {
    final neto = PagoHelpers.montoNeto(
      montoBruto: montoBruto,
      descuento: descuento,
    );
    if (neto <= 0) {
      throw ArgumentError('El monto a cobrar debe ser mayor a cero');
    }
    final conceptoLimpio = concepto.trim();
    if (conceptoLimpio.isEmpty) {
      throw ArgumentError('El concepto es obligatorio');
    }

    final periodo = PagoHelpers.etiquetaPeriodo(fechaPeriodo);
    final vencimiento = fechaVencimiento ??
        DateTime(fechaPeriodo.year, fechaPeriodo.month, 15);
    final notasFinal = PagoHelpers.notasConDescuento(
      montoBruto: montoBruto,
      descuento: descuento,
      notasUsuario: notas,
    );

    final row = <String, dynamic>{
      'alumno_id': alumnoId,
      'mes': periodo,
      'concepto': conceptoLimpio,
      'monto': neto,
      'monto_pagado': 0.0,
      'descuento': descuento,
      'fecha_vencimiento': vencimiento.toIso8601String().split('T')[0],
      'estatus': 'pendiente',
      'tipo_pago': tipoPago,
      'anio_escolar': fechaPeriodo.year,
      'notas': notasFinal,
    };

    try {
      await _supabase.from('pagos').insert(row);
    } catch (_) {
      // Si aún no existe la columna descuento en BD, insertar sin ella.
      row.remove('descuento');
      await _supabase.from('pagos').insert(row);
    }
  }

  Future<bool> pagoTieneAbonos(String pagoId) async {
    final rows = await _supabase
        .from('abonos')
        .select('id')
        .eq('pago_id', pagoId)
        .limit(1);
    return (rows as List).isNotEmpty;
  }

  /// Elimina un pago solo si no tiene abonos.
  Future<void> eliminarPagoSinAbonos(String pagoId) async {
    if (await pagoTieneAbonos(pagoId)) {
      throw Exception(
        'Este pago ya tiene abonos registrados y no se puede eliminar.',
      );
    }
    final pago = await obtenerPagoPorId(pagoId);
    if (pago != null && !pago.puedeEliminarse) {
      throw Exception(
        'Solo se pueden eliminar pagos pendientes sin abonos.',
      );
    }
    await eliminarPago(pagoId);
  }

  /// Borra varios pagos sin abonos. Devuelve cuántos se eliminaron y omitieron.
  Future<({int eliminados, int omitidos})> eliminarPagosSinAbonos(
    List<String> pagoIds,
  ) async {
    var eliminados = 0;
    var omitidos = 0;
    for (final id in pagoIds) {
      try {
        await eliminarPagoSinAbonos(id);
        eliminados++;
      } catch (_) {
        omitidos++;
      }
    }
    return (eliminados: eliminados, omitidos: omitidos);
  }

  Future<void> actualizarAlumno(Alumno alumno) async {
    await _supabase
        .from('alumnos')
        .update(alumno.toJson())
        .eq('id', alumno.id);
    avisarAlumnosCambiaron();
  }

  Future<void> eliminarAlumno(String alumnoId) async {
    await _supabase
        .from('alumnos')
        .update({'activo': false})
        .eq('id', alumnoId);
    avisarAlumnosCambiaron();
  }

  /// Elimina permanentemente al alumno y sus datos dependientes.
  /// Las relaciones de Supabase con ON DELETE CASCADE eliminan sus pagos,
  /// abonos, personas autorizadas y demás registros asociados.
  Future<void> eliminarAlumnoDefinitivamente(String alumnoId) async {
    // .select() devuelve las filas borradas: si RLS bloquea el DELETE,
    // Supabase no lanza error pero regresa lista vacía. Hay que avisarlo.
    final deleted = await _supabase
        .from('alumnos')
        .delete()
        .eq('id', alumnoId)
        .select('id');
    if ((deleted as List).isEmpty) {
      throw Exception(
        'Supabase no permitió borrar este alumno (permisos RLS). '
        'Ejecuta FIX_ALTA_ALUMNOS_PAGOS_Y_BORRADO.sql en Supabase.',
      );
    }
    avisarAlumnosCambiaron();
  }

  // ==================== PAGOS ====================

  Stream<List<Pago>> getPagosPorAlumno(String alumnoId) {
    return _supabase
        .from('pagos')
        .stream(primaryKey: ['id'])
        .map((data) => data
            .where((json) => json['alumno_id'] == alumnoId)
            .map((json) => Pago.fromJson(json))
            .toList()
          ..sort((a, b) {
            if (a.fechaVencimiento == null && b.fechaVencimiento == null) return 0;
            if (a.fechaVencimiento == null) return 1;
            if (b.fechaVencimiento == null) return -1;
            return b.fechaVencimiento!.compareTo(a.fechaVencimiento!);
          }));
  }

  Stream<List<Pago>> getPagosPendientes() {
    return _supabase
        .from('pagos')
        .stream(primaryKey: ['id'])
        .map((data) {
          final list = <Pago>[];
          for (final json in data) {
            if (json['estatus'] == 'pagado') continue;
            if (json['id'] == null || json['alumno_id'] == null) continue;
            try {
              list.add(Pago.fromJson(json));
            } catch (_) {
              // Ignorar filas con datos inválidos
            }
          }
          list.sort((a, b) {
            if (a.fechaVencimiento == null && b.fechaVencimiento == null) return 0;
            if (a.fechaVencimiento == null) return 1;
            if (b.fechaVencimiento == null) return -1;
            return a.fechaVencimiento!.compareTo(b.fechaVencimiento!);
          });
          return list;
        });
  }

  /// Misma lógica que [getPagosPendientes] pero por consulta directa.
  /// Úsala tras acreditar pagos o al deslizar para refrescar (el stream a veces no reemite).
  Future<List<Pago>> obtenerPagosPendientesList() async {
    final todos = await obtenerTodosPagosList();
    final list = todos.where((p) => !p.estaPagado).toList();
    list.sort((a, b) {
      if (a.fechaVencimiento == null && b.fechaVencimiento == null) return 0;
      if (a.fechaVencimiento == null) return 1;
      if (b.fechaVencimiento == null) return -1;
      return a.fechaVencimiento!.compareTo(b.fechaVencimiento!);
    });
    return list;
  }

  /// Todos los pagos (pendientes, parciales y pagados) para gestión y filtros.
  Future<List<Pago>> obtenerTodosPagosList() async {
    final response = await _supabase
        .from('pagos')
        .select()
        .order('created_at', ascending: false);
    final list = <Pago>[];
    for (final json in response as List) {
      if (json['id'] == null || json['alumno_id'] == null) continue;
      try {
        list.add(Pago.fromJson(Map<String, dynamic>.from(json as Map)));
      } catch (_) {}
    }
    return list;
  }

  Future<List<Pago>> obtenerPagos() async {
    final response = await _supabase
        .from('pagos')
        .select()
        .order('created_at', ascending: false); // Ordenar por fecha de creación
    
    return (response as List).map((json) => Pago.fromJson(json)).toList()
      ..sort((a, b) {
        // Ordenar manualmente para manejar nulls correctamente
        if (a.fechaVencimiento == null && b.fechaVencimiento == null) return 0;
        if (a.fechaVencimiento == null) return 1;
        if (b.fechaVencimiento == null) return -1;
        return a.fechaVencimiento!.compareTo(b.fechaVencimiento!);
      });
  }

  Future<Pago?> obtenerPagoPorId(String pagoId) async {
    final response = await _supabase
        .from('pagos')
        .select()
        .eq('id', pagoId)
        .maybeSingle();
    
    return response != null ? Pago.fromJson(response) : null;
  }

  Future<void> crearPago(Pago pago) async {
    await _supabase
        .from('pagos')
        .insert(pago.toJson());
  }

  Future<void> actualizarPago(Pago pago) async {
    await _supabase
        .from('pagos')
        .update(pago.toJson())
        .eq('id', pago.id);
  }

  Future<void> eliminarPago(String pagoId) async {
    final deleted = await _supabase
        .from('pagos')
        .delete()
        .eq('id', pagoId)
        .select('id');
    if ((deleted as List).isEmpty) {
      throw Exception(
        'Supabase no permitió borrar este pago (permisos RLS). '
        'Ejecuta FIX_ALTA_ALUMNOS_PAGOS_Y_BORRADO.sql en Supabase.',
      );
    }
  }

  Future<Abono?> obtenerUltimoAbono(String pagoId) async {
    final response = await _supabase
        .from('abonos')
        .select()
        .eq('pago_id', pagoId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    return response == null ? null : Abono.fromJson(response);
  }

  Future<void> marcarPagoComoPagado({
    required String pagoId,
    required String metodoPago,
    required String recibidoPor,
    String? referencia,
  }) async {
    final pago = await obtenerPagoPorId(pagoId);
    if (pago == null) throw Exception('Pago no encontrado');
    final nuevoPagado = pago.montoPagado + pago.saldoPendiente;
    final esCompleto = nuevoPagado >= pago.monto;
    await _supabase.from('pagos').update({
      'monto_pagado': nuevoPagado,
      'estatus': esCompleto ? 'pagado' : 'parcial',
      'fecha_pago': esCompleto ? DateTime.now().toIso8601String().split('T')[0] : null,
      'forma_pago': metodoPago,
      'referencia': referencia,
      'recibido_por_nombre': recibidoPor,
    }).eq('id', pagoId);
  }

  /// Acreditar un monto parcial (o total). Guarda quién recibió el dinero.
  Future<Abono> acreditarPagoParcial({
    required String pagoId,
    required double montoAbonar,
    required String metodoPago,
    required String recibidoPorNombre,
    String? referencia,
    String? notas,
  }) async {
    final pago = await obtenerPagoPorId(pagoId);
    if (pago == null) throw Exception('Pago no encontrado');
    if (montoAbonar <= 0 || montoAbonar > pago.saldoPendiente) {
      throw Exception('Monto inválido. Saldo pendiente: \$${pago.saldoPendiente.toStringAsFixed(2)}');
    }
    final response = await _supabase.from('abonos').insert({
      'pago_id': pagoId,
      'monto': montoAbonar,
      'fecha_abono': DateTime.now().toIso8601String().split('T')[0],
      'forma_pago': metodoPago,
      'referencia': referencia,
      'notas': (notas != null && notas.trim().isNotEmpty) ? notas.trim() : null,
      'recibido_por_nombre': recibidoPorNombre.trim().isEmpty ? null : recibidoPorNombre.trim(),
      'created_by': _supabase.auth.currentUser?.id,
    }).select().single();
    return Abono.fromJson(response);
  }

  // ==================== CALIFICACIONES ====================

  Stream<List<Calificacion>> getCalificacionesPorAlumno(String alumnoId) {
    return _supabase
        .from('calificaciones')
        .stream(primaryKey: ['id'])
        .map((data) => data
            .where((json) => json['alumno_id'] == alumnoId)
            .map((json) => Calificacion.fromJson(json))
            .toList()
          ..sort((a, b) => b.fecha.compareTo(a.fecha)));
  }

  Stream<List<Calificacion>> getCalificacionesPorPeriodo(String alumnoId, String periodo) {
    return _supabase
        .from('calificaciones')
        .stream(primaryKey: ['id'])
        .map((data) => data
            .where((json) => json['alumno_id'] == alumnoId && json['periodo'] == periodo)
            .map((json) => Calificacion.fromJson(json))
            .toList()
          ..sort((a, b) => a.materia.compareTo(b.materia)));
  }

  Future<void> crearCalificacion(Calificacion calificacion) async {
    await _supabase
        .from('calificaciones')
        .insert(calificacion.toJson());
  }

  Future<void> actualizarCalificacion(Calificacion calificacion) async {
    await _supabase
        .from('calificaciones')
        .update(calificacion.toJson())
        .eq('id', calificacion.id);
  }

  // ==================== INCIDENTES ====================

  Stream<List<Incidente>> getIncidentesPorAlumno(String alumnoId) {
    return _supabase
        .from('incidentes')
        .stream(primaryKey: ['id'])
        .map((data) => data
            .where((json) => json['alumno_id'] == alumnoId)
            .map((json) => Incidente.fromJson(json))
            .toList()
          ..sort((a, b) => b.fecha.compareTo(a.fecha)));
  }

  Stream<List<Incidente>> getIncidentesRecientes({int limite = 10}) {
    return _supabase
        .from('incidentes')
        .stream(primaryKey: ['id'])
        .map((data) {
          final list = data
              .map((json) => Incidente.fromJson(json))
              .toList()
            ..sort((a, b) => b.fecha.compareTo(a.fecha));
          return list.take(limite).toList();
        });
  }

  Future<void> crearIncidente(Incidente incidente) async {
    await _supabase
        .from('incidentes')
        .insert(incidente.toJson());
  }

  Future<void> marcarIncidenteAtendido(String incidenteId) async {
    await _supabase
        .from('incidentes')
        .update({'atendido': true})
        .eq('id', incidenteId);
  }

  // ==================== ANUNCIOS ====================

  Stream<List<Anuncio>> getAnuncios() {
    return _supabase
        .from('anuncios')
        .stream(primaryKey: ['id'])
        .map((data) => data
            .map((json) => Anuncio.fromJson(json))
            .toList()
          ..sort((a, b) => b.fechaPublicacion.compareTo(a.fechaPublicacion)));
  }

  Future<void> crearAnuncio(Anuncio anuncio) async {
    await _supabase
        .from('anuncios')
        .insert(anuncio.toJson());
  }

  Future<void> marcarAnuncioLeido(String anuncioId, String usuarioId) async {
    // Obtener anuncio actual
    final response = await _supabase
        .from('anuncios')
        .select('leido_por')
        .eq('id', anuncioId)
        .single();
    
    List<String> leidoPor = List<String>.from(response['leido_por'] ?? []);
    if (!leidoPor.contains(usuarioId)) {
      leidoPor.add(usuarioId);
      await _supabase
          .from('anuncios')
          .update({'leido_por': leidoPor})
          .eq('id', anuncioId);
    }
  }

  Future<void> eliminarAnuncio(String anuncioId) async {
    await _supabase
        .from('anuncios')
        .delete()
        .eq('id', anuncioId);
  }

  // ==================== GRADOS ====================

  Stream<List<Grado>> getGrados() {
    return _supabase
        .from('grados')
        .stream(primaryKey: ['id'])
        .map((data) => data
            .map((json) => Grado.fromJson(json))
            .toList()
          ..sort((a, b) => a.nombre.compareTo(b.nombre)));
  }

  Future<List<Grado>> obtenerGrados() async {
    final response = await _supabase
        .from('grados')
        .select()
        .eq('activo', true)
        .order('nombre');
    
    return response.map((json) => Grado.fromJson(json)).toList();
  }

  Future<void> crearGrado(Grado grado) async {
    await _supabase
        .from('grados')
        .insert(grado.toJson());
  }

  Future<void> actualizarGrado(Grado grado) async {
    await _supabase
        .from('grados')
        .update(grado.toJson())
        .eq('id', grado.id);
  }

  Future<void> actualizarTotalAlumnos(String gradoId) async {
    final response = await _supabase
        .from('alumnos')
        .select()
        .eq('grado', gradoId)
        .eq('activo', true);

    await _supabase
        .from('grados')
        .update({'total_alumnos': response.length})
        .eq('id', gradoId);
  }
}
