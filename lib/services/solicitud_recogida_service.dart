import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/solicitud_recogida.dart';

class SolicitudRecogidaService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Pendientes de entrega. Filtra en cliente para que al marcar «Listo»
  /// el stream quite el ítem (el `.eq` del server a veces deja basura).
  Stream<List<SolicitudRecogida>> streamPendientes() {
    return _supabase
        .from('solicitudes_recogida')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((rows) {
          final list = rows
              .map(SolicitudRecogida.fromJson)
              .where((s) => s.esPendiente)
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  Stream<SolicitudRecogida?> streamPendientePorAlumno(String alumnoId) {
    return _supabase
        .from('solicitudes_recogida')
        .stream(primaryKey: ['id'])
        .eq('alumno_id', alumnoId)
        .order('created_at', ascending: false)
        .map((rows) {
          SolicitudRecogida? recienteNoCoincide;
          for (final row in rows) {
            final s = SolicitudRecogida.fromJson(row);
            if (s.esPendiente) return s;
            if (s.esNoCoincide && recienteNoCoincide == null) {
              recienteNoCoincide = s;
            }
          }
          if (recienteNoCoincide != null &&
              DateTime.now().difference(recienteNoCoincide.createdAt).inHours < 18) {
            return recienteNoCoincide;
          }
          return null;
        });
  }

  Future<void> solicitarRecogida({
    required String alumnoId,
    required String padreId,
    String? mensaje,
    String? personaAutorizadaId,
    String? quienNombre,
    String? quienParentesco,
    bool requiereCodigo = false,
  }) async {
    await _supabase
        .from('solicitudes_recogida')
        .update({'estado': 'cancelada'})
        .eq('alumno_id', alumnoId)
        .eq('estado', 'pendiente');

    await _supabase.from('solicitudes_recogida').insert({
      'alumno_id': alumnoId,
      'padre_id': padreId,
      'mensaje': mensaje?.trim().isEmpty ?? true ? null : mensaje!.trim(),
      'estado': 'pendiente',
      'persona_autorizada_id': personaAutorizadaId,
      'quien_nombre': quienNombre?.trim().isEmpty ?? true ? null : quienNombre!.trim(),
      'quien_parentesco':
          quienParentesco?.trim().isEmpty ?? true ? null : quienParentesco!.trim(),
      'requiere_codigo': requiereCodigo,
    });
  }

  Future<void> marcarNoCoincide({
    required String solicitudId,
    required String atendidaPorId,
  }) async {
    await _supabase.from('solicitudes_recogida').update({
      'estado': 'no_coincide',
      'atendida_at': DateTime.now().toUtc().toIso8601String(),
      'atendida_por': atendidaPorId,
    }).eq('id', solicitudId);
  }

  Future<void> cancelar(String solicitudId) async {
    await _supabase
        .from('solicitudes_recogida')
        .update({'estado': 'cancelada'})
        .eq('id', solicitudId);
  }

  /// Borra la fila (equivocación: quita el histórico).
  Future<void> borrar(String solicitudId) async {
    await _supabase.from('solicitudes_recogida').delete().eq('id', solicitudId);
  }

  Future<void> marcarAtendida({
    required String solicitudId,
    required String atendidaPorId,
    required String modalidadEntrega,
    String? quienRecibio,
  }) async {
    await _supabase.from('solicitudes_recogida').update({
      'estado': 'atendida',
      'atendida_at': DateTime.now().toUtc().toIso8601String(),
      'atendida_por': atendidaPorId,
      'modalidad_entrega': modalidadEntrega,
      if (quienRecibio != null && quienRecibio.trim().isNotEmpty)
        'quien_recibio': quienRecibio.trim(),
    }).eq('id', solicitudId);
  }

  /// Cierra todas las pendientes del alumno (p. ej. tras validar QR en control).
  Future<void> cerrarPendientesDeAlumno({
    required String alumnoId,
    required String atendidaPorId,
    required String modalidadEntrega,
    String? quienRecibio,
  }) async {
    await _supabase.from('solicitudes_recogida').update({
      'estado': 'atendida',
      'atendida_at': DateTime.now().toUtc().toIso8601String(),
      'atendida_por': atendidaPorId,
      'modalidad_entrega': modalidadEntrega,
      if (quienRecibio != null && quienRecibio.trim().isNotEmpty)
        'quien_recibio': quienRecibio.trim(),
    }).eq('alumno_id', alumnoId).eq('estado', 'pendiente');
  }
}
