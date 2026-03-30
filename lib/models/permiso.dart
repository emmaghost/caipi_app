class Permiso {
  final String id;
  final String codigo; // 'ver_alumnos', 'crear_alumno', etc.
  final String nombre;
  final String? descripcion;
  final String modulo; // 'alumnos', 'pagos', etc.
  final String tipo; // 'lectura', 'escritura', 'eliminacion', 'especial'
  final bool activo;
  final DateTime createdAt;

  Permiso({
    required this.id,
    required this.codigo,
    required this.nombre,
    this.descripcion,
    required this.modulo,
    required this.tipo,
    this.activo = true,
    required this.createdAt,
  });

  factory Permiso.fromJson(Map<String, dynamic> json) {
    return Permiso(
      id: json['id'] as String,
      codigo: json['codigo'] as String,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String?,
      modulo: json['modulo'] as String,
      tipo: json['tipo'] as String,
      activo: json['activo'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'codigo': codigo,
      'nombre': nombre,
      'descripcion': descripcion,
      'modulo': modulo,
      'tipo': tipo,
      'activo': activo,
    };
  }

  // Getter para icono según módulo
  String get icono {
    switch (modulo) {
      case 'alumnos':
        return '👶';
      case 'pagos':
        return '💰';
      case 'profesores':
        return '👩‍🏫';
      case 'padres':
        return '👨‍👩‍👧';
      case 'eventos':
        return '📅';
      case 'incidentes':
        return '🚨';
      case 'autorizados':
        return '🔐';
      case 'bitacora':
        return '📝';
      case 'anuncios':
        return '📢';
      default:
        return '📋';
    }
  }

  // Getter para color según tipo
  String get colorTipo {
    switch (tipo) {
      case 'lectura':
        return '#4CAF50'; // Verde
      case 'escritura':
        return '#2196F3'; // Azul
      case 'eliminacion':
        return '#F44336'; // Rojo
      case 'especial':
        return '#FF9800'; // Naranja
      default:
        return '#9E9E9E'; // Gris
    }
  }
}
