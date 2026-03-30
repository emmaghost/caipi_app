class Incidente {
  final String id;
  final String alumnoId;
  final String? tipoIncidenteId;
  final int nivel; // 1-5
  final String titulo;
  final String descripcion;
  final DateTime fecha;
  final String? reportadoPor;
  final bool atendido;
  final bool padreNotificado;
  final DateTime? fechaNotificacion;
  final String? fotoUrl;
  final String? observaciones;
  final DateTime createdAt;

  Incidente({
    required this.id,
    required this.alumnoId,
    this.tipoIncidenteId,
    required this.nivel,
    required this.titulo,
    required this.descripcion,
    required this.fecha,
    this.reportadoPor,
    this.atendido = false,
    this.padreNotificado = false,
    this.fechaNotificacion,
    this.fotoUrl,
    this.observaciones,
    required this.createdAt,
  });

  factory Incidente.fromJson(Map<String, dynamic> json) {
    return Incidente(
      id: json['id'] as String,
      alumnoId: json['alumno_id'] as String,
      tipoIncidenteId: json['tipo_incidente_id'] as String?,
      nivel: json['nivel'] as int,
      titulo: json['titulo'] as String,
      descripcion: json['descripcion'] as String,
      fecha: DateTime.parse(json['fecha']),
      reportadoPor: json['reportado_por'] as String?,
      atendido: json['atendido'] as bool? ?? false,
      padreNotificado: json['padre_notificado'] as bool? ?? false,
      fechaNotificacion: json['fecha_notificacion'] != null
          ? DateTime.parse(json['fecha_notificacion'])
          : null,
      fotoUrl: json['foto_url'] as String?,
      observaciones: json['observaciones'] as String?,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'alumno_id': alumnoId,
      'tipo_incidente_id': tipoIncidenteId,
      'nivel': nivel,
      'titulo': titulo,
      'descripcion': descripcion,
      'fecha': fecha.toIso8601String(),
      'reportado_por': reportadoPor,
      'atendido': atendido,
      'padre_notificado': padreNotificado,
      'fecha_notificacion': fechaNotificacion?.toIso8601String(),
      'foto_url': fotoUrl,
      'observaciones': observaciones,
    };
  }

  // Getter para saber si requiere notificar al padre
  bool get requiereNotificarPadre => nivel >= 4;

  // Getter para color según nivel
  String get colorNivel {
    switch (nivel) {
      case 1:
        return '#90EE90'; // Verde claro
      case 2:
        return '#FFD700'; // Dorado
      case 3:
        return '#FF8C00'; // Naranja
      case 4:
        return '#FF4500'; // Rojo naranja
      case 5:
        return '#8B0000'; // Rojo oscuro
      default:
        return '#808080'; // Gris
    }
  }

  // Getter para emoji según nivel
  String get emoji {
    switch (nivel) {
      case 1:
        return 'ℹ️';
      case 2:
        return '⚠️';
      case 3:
        return '⚠️';
      case 4:
        return '🚨';
      case 5:
        return '🆘';
      default:
        return '📝';
    }
  }

  // Getter para etiqueta de nivel
  String get nivelLabel {
    switch (nivel) {
      case 1:
        return 'Info';
      case 2:
        return 'Leve';
      case 3:
        return 'Moderado';
      case 4:
        return 'Grave';
      case 5:
        return 'Urgente';
      default:
        return 'Desconocido';
    }
  }

  // Getter para verificar si es reciente (últimas 24 horas)
  bool get esReciente {
    final ahora = DateTime.now();
    return ahora.difference(fecha).inHours < 24;
  }
}
