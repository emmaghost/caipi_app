import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/solicitud_recogida.dart';

class SolicitudRecogidaService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Stream<List<SolicitudRecogida>> streamPendientes() {
    return _supabase
        .from('solicitudes_recogida')
        .stream(primaryKey: ['id'])
        .eq('estado', 'pendiente')
        .order('created_at', ascending: false)
        .map((rows) => rows.map(SolicitudRecogida.fromJson).toList());
  }

  Stream<SolicitudRecogida?> streamPendientePorAlumno(String alumnoId) {
    return _supabase
        .from('solicitudes_recogida')
        .stream(primaryKey: ['id'])
        .eq('alumno_id', alumnoId)
        .order('created_at', ascending: false)
        .map((rows) {
          for (final row in rows) {
            if (row['estado'] == 'pendiente') {
              return SolicitudRecogida.fromJson(row);
            }
          }
          return null;
        });
  }

  Future<void> solicitarRecogida({
    required String alumnoId,
    required String padreId,
    String? mensaje,
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
    });
  }

  Future<void> cancelar(String solicitudId) async {
    await _supabase
        .from('solicitudes_recogida')
        .update({'estado': 'cancelada'})
        .eq('id', solicitudId);
  }

  Future<void> marcarAtendida({
    required String solicitudId,
    required String atendidaPorId,
  }) async {
    await _supabase.from('solicitudes_recogida').update({
      'estado': 'atendida',
      'atendida_at': DateTime.now().toUtc().toIso8601String(),
      'atendida_por': atendidaPorId,
    }).eq('id', solicitudId);
  }
}
