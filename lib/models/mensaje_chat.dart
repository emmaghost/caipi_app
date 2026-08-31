class MensajeChat {
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
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
