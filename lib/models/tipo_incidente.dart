class TipoIncidente {
  final String id;
  final String nombre;
  final String? descripcion;
  final String categoria; // 'accidente', 'comportamiento', 'logro', 'otro'
  final int nivel; // 1-5
  final String color;
  final bool activo;
  final DateTime createdAt;
  final DateTime updatedAt;

  TipoIncidente({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.categoria,
    required this.nivel,
    this.color = '#808080',
    this.activo = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TipoIncidente.fromJson(Map<String, dynamic> json) {
    return TipoIncidente(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String?,
      categoria: json['categoria'] as String,
      nivel: json['nivel'] as int,
      color: json['color'] as String? ?? '#808080',
      activo: json['activo'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'categoria': categoria,
      'nivel': nivel,
      'color': color,
      'activo': activo,
    };
  }

  // Getter para saber si requiere notificar al padre
  bool get requiereNotificarPadre => nivel >= 4;

  // Getter para emoji según nivel
  String get emoji {
    switch (nivel) {
      case 1:
        return 'ℹ️'; // Info
      case 2:
        return '⚠️'; // Advertencia leve
      case 3:
        return '⚠️'; // Advertencia
      case 4:
        return '🚨'; // Alerta
      case 5:
        return '🆘'; // Urgente
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

  // Getter para emoji según categoría
  String get categoriaEmoji {
    switch (categoria) {
      case 'accidente':
        return '🩹';
      case 'comportamiento':
        return '👤';
      case 'logro':
        return '🌟';
      case 'otro':
        return '📝';
      default:
        return '📋';
    }
  }
}
