import '../utils/mexico_time.dart';

class MensajeChat {
  /// Marca un mensaje que es solo imagen (la URL va después). Sin columna extra.
  static const marcadorFoto = '[[foto]]';

  final String id;
  final String conversacionId;
  final String remitenteId;
  final String contenido;
  final bool leido;
  final DateTime createdAt;

  MensajeChat({
    required this.id,
    required this.conversacionId,
    required this.remitenteId,
    required this.contenido,
    this.leido = false,
    required this.createdAt,
  });

  factory MensajeChat.fromJson(Map<String, dynamic> json) {
    return MensajeChat(
      id: json['id'] as String,
      conversacionId: json['conversacion_id'] as String,
      remitenteId: json['remitente_id'] as String,
      contenido: json['contenido'] as String,
      leido: json['leido'] as bool? ?? false,
      createdAt: MexicoTime.parse(json['created_at'] as String),
    );
  }

  bool get esFoto {
    final t = contenido.trim();
    return t.startsWith(marcadorFoto);
  }

  /// URL pública de la imagen, si el mensaje es una foto.
  String? get urlFoto {
    if (!esFoto) return null;
    final url = contenido.trim().substring(marcadorFoto.length).trim();
    if (!url.startsWith('http')) return null;
    return url;
  }

  static String vistaPreviaDe(String? contenido) {
    final t = (contenido ?? '').trim();
    if (t.startsWith(marcadorFoto)) return 'Imagen';
    return t;
  }
}
