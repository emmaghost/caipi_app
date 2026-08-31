class Conversacion {
  final String id;
  final String padreId;
  final String? ultimoMensaje;
  final DateTime? ultimoMensajeAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Conversacion({
    required this.id,
    required this.padreId,
    this.ultimoMensaje,
    this.ultimoMensajeAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Conversacion.fromJson(Map<String, dynamic> json) {
    return Conversacion(
      id: json['id'] as String,
      padreId: json['padre_id'] as String,
      ultimoMensaje: json['ultimo_mensaje'] as String?,
      ultimoMensajeAt: json['ultimo_mensaje_at'] != null
          ? DateTime.parse(json['ultimo_mensaje_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}
