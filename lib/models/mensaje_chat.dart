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

  static final RegExp _lineaFoto = RegExp(r'\[\[foto\]\](https?://\S+)');

  static String textoSinFoto(String contenido) {
    return contenido
        .replaceAll(_lineaFoto, '')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }

  static List<String> urlsFotoEn(String? contenido) {
    if (contenido == null || contenido.isEmpty) return const [];
    return _lineaFoto
        .allMatches(contenido)
        .map((m) => m.group(1) ?? '')
        .where((url) => url.startsWith('http'))
        .toList();
  }

  static String? urlFotoEn(String? contenido) {
    final urls = urlsFotoEn(contenido);
    if (urls.isEmpty) return null;
    return urls.first;
  }

  static String conFotos(String texto, List<String> urls) {
    final limpio = textoSinFoto(texto);
    final validas =
        urls.map((u) => u.trim()).where((u) => u.isNotEmpty).toList();
    if (validas.isEmpty) return limpio;
    final marcas = validas.map((u) => '$marcadorFoto$u').join('\n');
    if (limpio.isEmpty) return marcas;
    return '$limpio\n$marcas';
  }

  static String conFoto(String texto, String? url) {
    final u = url?.trim() ?? '';
    if (u.isEmpty) return textoSinFoto(texto);
    return conFotos(texto, [u]);
  }

  static String vistaPreviaDe(String? contenido) {
    final t = (contenido ?? '').trim();
    if (t.startsWith(marcadorFoto) || urlFotoEn(t) != null && textoSinFoto(t).isEmpty) {
      return 'Imagen';
    }
    final limpio = textoSinFoto(t);
    return limpio.isEmpty ? t : limpio;
  }
}
