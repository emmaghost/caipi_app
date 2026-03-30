class Rol {
  final String id;
  final String codigo; // 'directora', 'profesor_admin', 'profesor', 'padre'
  final String nombre;
  final String? descripcion;
  final int nivelJerarquia; // 1=directora, 2=profesor_admin, 3=profesor, 4=padre
  final bool activo;
  final DateTime createdAt;

  Rol({
    required this.id,
    required this.codigo,
    required this.nombre,
    this.descripcion,
    required this.nivelJerarquia,
    this.activo = true,
    required this.createdAt,
  });

  factory Rol.fromJson(Map<String, dynamic> json) {
    return Rol(
      id: json['id'] as String,
      codigo: json['codigo'] as String,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String?,
      nivelJerarquia: json['nivel_jerarquia'] as int,
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
      'nivel_jerarquia': nivelJerarquia,
      'activo': activo,
    };
  }

  // Getter para icono según rol
  String get icono {
    switch (codigo) {
      case 'directora':
        return '👩‍💼';
      case 'profesor_admin':
        return '👩‍🏫⭐';
      case 'profesor':
        return '👩‍🏫';
      case 'padre':
        return '👨‍👩‍👧';
      default:
        return '👤';
    }
  }

  // Getter para verificar si es admin
  bool get esAdmin => codigo == 'directora' || codigo == 'profesor_admin';
}
