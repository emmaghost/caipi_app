class FotoGaleria {
  final String id;
  final String? titulo;
  final String? descripcion;
  final String fotoUrl;
  final String? gradoId;
  final DateTime fechaEvento;
  final String? subidoPor;
  final bool activo;
  final DateTime createdAt;

  FotoGaleria({
    required this.id,
    this.titulo,
    this.descripcion,
    required this.fotoUrl,
    this.gradoId,
    required this.fechaEvento,
    this.subidoPor,
    this.activo = true,
    required this.createdAt,
  });

  // Getter para compatibilidad con código que usa 'fecha'
  DateTime get fecha => fechaEvento;

  factory FotoGaleria.fromJson(Map<String, dynamic> json) {
    return FotoGaleria(
      id: json['id'] as String,
      titulo: json['titulo'] as String?,
      descripcion: json['descripcion'] as String?,
      fotoUrl: json['foto_url'] as String,
      gradoId: json['grado_id'] as String?,
      fechaEvento: DateTime.parse(json['fecha_evento']),
      subidoPor: json['subido_por'] as String?,
      activo: json['activo'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'descripcion': descripcion,
      'foto_url': fotoUrl,
      'grado_id': gradoId,
      'fecha_evento': fechaEvento.toIso8601String().split('T')[0],
      'subido_por': subidoPor,
      'activo': activo,
    };
  }
}
