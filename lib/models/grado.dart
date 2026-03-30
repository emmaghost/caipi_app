// Modelo de Grado para Supabase

class Grado {
  final String id;
  final String nombre;
  final String? descripcion;
  final int? edadMinima;
  final int? edadMaxima;
  final int cupoMaximo;
  final bool activo;
  final DateTime createdAt;
  final DateTime updatedAt;

  Grado({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.edadMinima,
    this.edadMaxima,
    required this.cupoMaximo,
    this.activo = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Grado.fromJson(Map<String, dynamic> json) {
    return Grado(
      id: json['id'] as String? ?? '',
      nombre: json['nombre'] as String? ?? 'Sin nombre',
      descripcion: json['descripcion'] as String?,
      edadMinima: json['edad_minima'] as int?,
      edadMaxima: json['edad_maxima'] as int?,
      cupoMaximo: json['cupo_maximo'] as int? ?? 20,
      activo: json['activo'] as bool? ?? true,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'edad_minima': edadMinima,
      'edad_maxima': edadMaxima,
      'cupo_maximo': cupoMaximo,
      'activo': activo,
    };
  }
}
