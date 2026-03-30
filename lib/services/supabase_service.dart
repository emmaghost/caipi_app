import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../models/alumno.dart';
import '../models/pago.dart';
import '../models/calificacion.dart';
import '../models/incidente.dart';
import '../models/anuncio.dart';
import '../models/grado.dart';
import '../models/usuario.dart';

class SupabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;

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
    if (alumno == null) return null;
    final response = await _supabase
        .from('usuarios')
        .select('whatsapp, telefono')
        .eq('id', alumno.padreId)
        .maybeSingle();
    if (response == null) return null;
    return response['whatsapp'] as String? ?? response['telefono'] as String?;
  }

  Stream<List<Alumno>> getAlumnosPorPadre(String padreId) {
    return _supabase
        .from('alumnos')
        .stream(primaryKey: ['id'])
        .map((data) => data
            .where((json) => json['padre_id'] == padreId && json['activo'] == true)
            .map((json) => Alumno.fromJson(json))
            .toList());
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

  Future<void> crearAlumno(Alumno alumno) async {
    // 1. Crear el alumno
    await _supabase
        .from('alumnos')
        .insert(alumno.toJson());

    // 2. Generar pagos automáticos
    await _generarPagosIniciales(alumno.id);
  }

  Future<void> _generarPagosIniciales(String alumnoId) async {
    final now = DateTime.now();
    final year = now.year;
    
    final List<Map<String, dynamic>> pagosIniciales = [];

    // 1. INSCRIPCIÓN ANUAL
    pagosIniciales.add({
      'alumno_id': alumnoId,
      'mes': 'Inscripción $year',
      'concepto': 'Inscripción Anual',
      'monto': 2000.00,
      'fecha_limite': DateTime(year, now.month, 15).toIso8601String().split('T')[0],
      'pagado': false,
    });

    // 2. SEGURO + CREDENCIAL
    pagosIniciales.add({
      'alumno_id': alumnoId,
      'mes': 'Seguro $year',
      'concepto': 'Seguro y Credencial',
      'monto': 500.00,
      'fecha_limite': DateTime(year, now.month, 15).toIso8601String().split('T')[0],
      'pagado': false,
    });

    // 3. COLEGIATURAS MENSUALES (12 meses)
    final meses = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];

    for (int i = 0; i < 12; i++) {
      final mes = i + 1;
      final mesNombre = meses[i];
      
      // Fecha límite: día 10 de cada mes
      final fechaLimite = DateTime(year, mes, 10);
      
      pagosIniciales.add({
        'alumno_id': alumnoId,
        'mes': '$mesNombre $year',
        'concepto': 'Colegiatura',
        'monto': 1500.00,
        'fecha_limite': fechaLimite.toIso8601String().split('T')[0],
        'pagado': false,
      });
    }

    // Insertar todos los pagos
    await _supabase.from('pagos').insert(pagosIniciales);
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

  Future<void> actualizarAlumno(Alumno alumno) async {
    await _supabase
        .from('alumnos')
        .update(alumno.toJson())
        .eq('id', alumno.id);
  }

  Future<void> eliminarAlumno(String alumnoId) async {
    // Soft delete
    await _supabase
        .from('alumnos')
        .update({'activo': false})
        .eq('id', alumnoId);
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
  Future<void> acreditarPagoParcial({
    required String pagoId,
    required double montoAbonar,
    required String metodoPago,
    required String recibidoPorNombre,
    String? referencia,
  }) async {
    final pago = await obtenerPagoPorId(pagoId);
    if (pago == null) throw Exception('Pago no encontrado');
    if (montoAbonar <= 0 || montoAbonar > pago.saldoPendiente) {
      throw Exception('Monto inválido. Saldo pendiente: \$${pago.saldoPendiente.toStringAsFixed(2)}');
    }
    final nuevoPagado = pago.montoPagado + montoAbonar;
    final esCompleto = nuevoPagado >= pago.monto;
    await _supabase.from('pagos').update({
      'monto_pagado': nuevoPagado,
      'estatus': esCompleto ? 'pagado' : 'parcial',
      'fecha_pago': esCompleto ? DateTime.now().toIso8601String().split('T')[0] : null,
      'forma_pago': metodoPago,
      'referencia': referencia,
      'recibido_por_nombre': recibidoPorNombre.trim().isEmpty ? null : recibidoPorNombre.trim(),
    }).eq('id', pagoId);
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
