class PersonaAutorizada {
  final String id;
  final String alumnoId;
  final String nombre;
  final String apellidos;
  final String parentesco;
  final String telefono;
  final String? identificacion;
  final String? fotoUrl;
  final String? fotoIneUrl;
  final bool esListaFija;
  final bool activo;
  final DateTime createdAt;

  PersonaAutorizada({
    required this.id,
    required this.alumnoId,
    required this.nombre,
    required this.apellidos,
    required this.parentesco,
    required this.telefono,
    this.identificacion,
    this.fotoUrl,
    this.fotoIneUrl,
    this.esListaFija = false,
    this.activo = true,
    required this.createdAt,
  });

  String get nombreCompleto => '$nombre $apellidos';

  factory PersonaAutorizada.fromJson(Map<String, dynamic> json) {
    return PersonaAutorizada(
      id: json['id']?.toString() ?? '',
      alumnoId: json['alumno_id']?.toString() ?? '',
      nombre: json['nombre'] as String? ?? '',
      apellidos: json['apellidos'] as String? ?? '',
      parentesco: json['parentesco'] as String? ?? '',
      telefono: json['telefono'] as String? ?? '',
      identificacion: json['identificacion'] as String?,
      fotoUrl: json['foto_url'] as String?,
      fotoIneUrl: json['foto_ine_url'] as String?,
      esListaFija: json['es_lista_fija'] as bool? ?? false,
      activo: json['activo'] as bool? ?? true,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'alumno_id': alumnoId,
      'nombre': nombre,
      'apellidos': apellidos,
      'parentesco': parentesco,
      'telefono': telefono,
      'identificacion': identificacion,
      'foto_url': fotoUrl,
      'activo': activo,
    };
  }
}
