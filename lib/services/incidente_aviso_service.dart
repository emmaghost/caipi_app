import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Aviso push al papá cuando se registra un incidente.
class IncidenteAvisoService {
  IncidenteAvisoService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  /// Dispara FCM vía edge function `notify-chat` (tipo=incidente_nuevo).
  Future<void> avisarPadresNuevoIncidente({
    required String alumnoId,
    required String titulo,
    String? descripcion,
    int? nivel,
    String? incidenteId,
  }) async {
    try {
      await _client.functions.invoke(
        'notify-chat',
        body: {
          'tipo': 'incidente_nuevo',
          'alumno_id': alumnoId,
          'titulo': titulo,
          if (descripcion != null && descripcion.trim().isNotEmpty)
            'descripcion': descripcion.trim(),
          if (nivel != null) 'nivel': nivel,
          if (incidenteId != null && incidenteId.isNotEmpty)
            'incidente_id': incidenteId,
        },
      );
    } catch (e) {
      debugPrint('Push incidente: $e');
    }
  }
}
