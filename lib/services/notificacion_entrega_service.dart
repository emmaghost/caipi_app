import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Avisos push al entregar / recoger un niño (papá + maestra del grupo).
class NotificacionEntregaService {
  NotificacionEntregaService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  /// Dispara FCM vía edge function `notify-chat`.
  /// No lanza: si falla el push, la entrega ya quedó registrada.
  Future<void> avisarNinoRecogido({
    required String alumnoId,
    String? quienRecibio,
  }) async {
    try {
      await _client.functions.invoke(
        'notify-chat',
        body: {
          'tipo': 'entrega_completada',
          'alumno_id': alumnoId,
          if (quienRecibio != null && quienRecibio.trim().isNotEmpty)
            'quien_recibio': quienRecibio.trim(),
        },
      );
    } catch (e) {
      debugPrint('Push entrega: $e');
    }
  }
}
