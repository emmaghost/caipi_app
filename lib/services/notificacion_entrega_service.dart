import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Avisos push al entregar / recoger un niño (papás del niño + maestra del grupo).
class NotificacionEntregaService {
  NotificacionEntregaService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  /// Cuántos papás/tutores tiene el alumno (máx. 2).
  Future<int> contarPadresDeAlumno(String alumnoId) async {
    final ids = <String>{};
    try {
      final a = await _client
          .from('alumnos')
          .select('padre_id')
          .eq('id', alumnoId)
          .maybeSingle();
      final pid = a?['padre_id'] as String?;
      if (pid != null && pid.isNotEmpty) ids.add(pid);
    } catch (_) {}
    try {
      final rows = await _client
          .from('alumnos_padres')
          .select('padre_id')
          .eq('alumno_id', alumnoId);
      for (final r in rows as List) {
        final pid = r['padre_id'] as String?;
        if (pid != null && pid.isNotEmpty) ids.add(pid);
      }
    } catch (_) {}
    return ids.length;
  }

  /// Dispara FCM vía edge function `notify-chat`.
  /// [fechaSalida] = día del registro (no la hora en que se tocó el botón).
  /// [notificarPadres] = si false, no avisa a papás (sí puede avisar a maestra).
  Future<void> avisarNinoRecogido({
    required String alumnoId,
    String? quienRecibio,
    String? padreSolicitanteId,
    DateTime? fechaSalida,
    bool notificarPadres = true,
  }) async {
    final f = fechaSalida ?? DateTime.now();
    final ymd =
        '${f.year.toString().padLeft(4, '0')}-${f.month.toString().padLeft(2, '0')}-${f.day.toString().padLeft(2, '0')}';
    try {
      await _client.functions.invoke(
        'notify-chat',
        body: {
          'tipo': 'entrega_completada',
          'alumno_id': alumnoId,
          'fecha': ymd,
          'notificar_padres': notificarPadres,
          if (padreSolicitanteId != null && padreSolicitanteId.isNotEmpty)
            'padre_solicitante_id': padreSolicitanteId,
          if (quienRecibio != null && quienRecibio.trim().isNotEmpty)
            'quien_recibio': quienRecibio.trim(),
        },
      );
    } catch (e) {
      debugPrint('Push entrega: $e');
    }
  }
}
