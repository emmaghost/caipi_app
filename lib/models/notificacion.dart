class Notificacion {
  final String id;
  final String titulo;
  final String mensaje;
  final String? tipo; // 'pago', 'incidente', 'anuncio', 'evento', 'general'
  final String? enviadoPor;
  final String? paraUsuarioId; // UUID del usuario específico
  final String? paraGrupo; // UUID del grupo/grado
  final bool paraTodos;
  final DateTime fecha;
  final bool leido;
  final DateTime createdAt;

  Notificacion({
    required this.id,
    required this.titulo,
    required this.mensaje,
    this.tipo,
    this.enviadoPor,
    this.paraUsuarioId,
    this.paraGrupo,
    this.paraTodos = false,
    required this.fecha,
    this.leido = false,
    required this.createdAt,
  });

  factory Notificacion.fromJson(Map<String, dynamic> json) {
    return Notificacion(
      id: json['id'] as String,
      titulo: json['titulo'] as String,
      mensaje: json['mensaje'] as String,
      tipo: json['tipo'] as String?,
      enviadoPor: json['enviado_por'] as String?,
      paraUsuarioId: json['para_usuario_id'] as String?,
      paraGrupo: json['para_grupo'] as String?,
      paraTodos: json['para_todos'] ?? false,
      fecha: DateTime.parse(json['fecha']),
      leido: json['leido'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'mensaje': mensaje,
      'tipo': tipo,
      'enviado_por': enviadoPor,
      'para_usuario_id': paraUsuarioId,
      'para_grupo': paraGrupo,
      'para_todos': paraTodos,
      'fecha': fecha.toIso8601String(),
      'leido': leido,
    };
  }
}
