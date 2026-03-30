class Usuario {
  final String id;
  final String email;
  final String rol; // 'directora', 'profesor', 'padre'
  final String nombre;
  final String? apellidos;
  final String? telefono;
  final String? whatsapp;
  final String? fotoUrl;
  final bool activo;
  final DateTime createdAt;
  final DateTime updatedAt;

  Usuario({
    required this.id,
    required this.email,
    required this.rol,
    required this.nombre,
    this.apellidos,
    this.telefono,
    this.whatsapp,
    this.fotoUrl,
    this.activo = true,
    required this.createdAt,
    required this.updatedAt,
  });

  String get nombreCompleto => apellidos != null ? '$nombre $apellidos' : nombre;
  bool get esDirectora => rol == 'directora';
  bool get esProfesor => rol == 'profesor';
  bool get esPadre => rol == 'padre';

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'] as String,
      email: json['email'] as String,
      rol: json['rol'] as String,
      nombre: json['nombre'] as String,
      apellidos: json['apellidos'] as String?,
      telefono: json['telefono'] as String?,
      whatsapp: json['whatsapp'] as String?,
      fotoUrl: json['foto_url'] as String?,
      activo: json['activo'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'rol': rol,
      'nombre': nombre,
      'apellidos': apellidos,
      'telefono': telefono,
      'whatsapp': whatsapp,
      'foto_url': fotoUrl,
      'activo': activo,
    };
  }
}
