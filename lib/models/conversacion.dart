class Conversacion {
  final String id;
  final String padreId;
  final String canal;
  final String? staffId;
  final String? ultimoMensaje;
  final DateTime? ultimoMensajeAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Conversacion({
    required this.id,
    required this.padreId,
    this.canal = 'directora',
    this.staffId,
    this.ultimoMensaje,
    this.ultimoMensajeAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Conversacion.fromJson(Map<String, dynamic> json) {
    return Conversacion(
      id: json['id'] as String,
      padreId: json['padre_id'] as String,
      canal: (json['canal'] as String?) ?? 'directora',
      staffId: json['staff_id'] as String?,
      ultimoMensaje: json['ultimo_mensaje'] as String?,
      ultimoMensajeAt: json['ultimo_mensaje_at'] != null
          ? DateTime.parse(json['ultimo_mensaje_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'padre_id': padreId,
      'canal': canal,
      'staff_id': staffId,
      'ultimo_mensaje': ultimoMensaje,
      'ultimo_mensaje_at': ultimoMensajeAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
