class Evento {
  final String id;
  final String titulo;
  final String descripcion;
  final DateTime fechaEvento;
  final String? horaInicio;
  final String? horaFin;
  final String? lugar;
  final String tipo; // 'academico', 'festivo', 'reunion', 'clausura', 'otro'
  final bool paraTodos;
  final List<String>? gradosIds;
  final String? fotoUrl;
  final String? creadoPor;
  final bool activo;
  final DateTime createdAt;
  final DateTime updatedAt;

  Evento({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.fechaEvento,
    this.horaInicio,
    this.horaFin,
    this.lugar,
    required this.tipo,
    this.paraTodos = true,
    this.gradosIds,
    this.fotoUrl,
    this.creadoPor,
    this.activo = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Evento.fromJson(Map<String, dynamic> json) {
    final ahora = DateTime.now();
    DateTime parseDt(dynamic raw, {DateTime? fallback}) {
      if (raw == null) return fallback ?? ahora;
      if (raw is DateTime) return raw;
      return DateTime.tryParse(raw.toString()) ?? fallback ?? ahora;
    }

    List<String>? grados;
    final rawGrados = json['grados_ids'] ?? json['para_grados'];
    if (rawGrados is List) {
      grados = rawGrados.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    }

    return Evento(
      id: json['id']?.toString() ?? '',
      titulo: json['titulo']?.toString() ?? '',
      descripcion: json['descripcion']?.toString() ?? '',
      fechaEvento: parseDt(json['fecha_evento']),
      horaInicio: json['hora_inicio'] as String?,
      horaFin: json['hora_fin'] as String?,
      lugar: json['lugar'] as String?,
      tipo: json['tipo']?.toString() ?? 'otro',
      paraTodos: json['para_todos'] as bool? ?? true,
      gradosIds: grados,
      fotoUrl: json['foto_url'] as String?,
      creadoPor: json['creado_por']?.toString(),
      activo: json['activo'] as bool? ?? true,
      createdAt: parseDt(json['created_at'], fallback: ahora),
      updatedAt: parseDt(json['updated_at'], fallback: ahora),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'descripcion': descripcion,
      'fecha_evento': fechaEvento.toIso8601String().split('T')[0],
      'hora_inicio': horaInicio,
      'hora_fin': horaFin,
      'lugar': lugar,
      'tipo': tipo,
      'para_todos': paraTodos,
      'grados_ids': gradosIds,
      'foto_url': fotoUrl,
      'creado_por': creadoPor,
      'activo': activo,
    };
  }

  // Getter para verificar si el evento ya pasó
  bool get yaOcurrio => fechaEvento.isBefore(DateTime.now());

  // Getter para verificar si es hoy
  bool get esHoy {
    final ahora = DateTime.now();
    return fechaEvento.year == ahora.year &&
        fechaEvento.month == ahora.month &&
        fechaEvento.day == ahora.day;
  }

  // Getter para verificar si es próximo (dentro de 7 días)
  bool get esProximo {
    final ahora = DateTime.now();
    final diferencia = fechaEvento.difference(ahora).inDays;
    return diferencia >= 0 && diferencia <= 7;
  }

  // Getter para emoji según tipo
  String get emoji {
    switch (tipo) {
      case 'academico':
        return '📚';
      case 'festivo':
        return '🎉';
      case 'reunion':
        return '👥';
      case 'clausura':
        return '🎓';
      default:
        return '📅';
    }
  }
}
