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

  /// De `profesores.especialidad` (no está en la tabla usuarios).
  /// Valores: `titular` | `ingles`.
  final String? especialidadProfesor;
  final String? gradoIdProfesor;

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
    this.especialidadProfesor,
    this.gradoIdProfesor,
  });

  String get nombreCompleto => apellidos != null ? '$nombre $apellidos' : nombre;
  bool get esDirectora => rol == 'directora';
  /// Profesora de aula (rol base).
  bool get esProfesor => rol == 'profesor' || rol == 'profesor_admin';
  bool get esProfesorAdmin => rol == 'profesor_admin';
  bool get esSecretaria => rol == 'secretaria';
  bool get esCaja => rol == 'caja';
  bool get esPadre => rol == 'padre';
  /// Directora, profesoras, secretaria o caja: usan pantallas /directora.
  bool get esStaff => esDirectora || esProfesor || esSecretaria || esCaja;

  /// Maestra de inglés: mismo grupo que la titular, solo calificaciones de Inglés.
  bool get esMaestraIngles {
    final e = (especialidadProfesor ?? '')
        .toLowerCase()
        .replaceAll('é', 'e')
        .replaceAll('í', 'i');
    return e == 'ingles' || e.contains('ingles');
  }

  bool get esMaestraMusica {
    final e = (especialidadProfesor ?? '')
        .toLowerCase()
        .replaceAll('é', 'e')
        .replaceAll('í', 'i');
    return e == 'musica' || e.contains('musica');
  }

  /// Titular de grupo (no inglés ni música).
  bool get esMaestraTitular =>
      esMaestraAula && !esMaestraIngles && !esMaestraMusica;

  /// Indicadores de desarrollo: directora, supervisora o titular de aula.
  bool get puedeVerPortage =>
      esDirectora || esProfesorAdmin || esMaestraTitular;

  Usuario conPerfilProfesor({String? especialidad, String? gradoId}) {
    return Usuario(
      id: id,
      email: email,
      rol: rol,
      nombre: nombre,
      apellidos: apellidos,
      telefono: telefono,
      whatsapp: whatsapp,
      fotoUrl: fotoUrl,
      activo: activo,
      createdAt: createdAt,
      updatedAt: updatedAt,
      especialidadProfesor: especialidad,
      gradoIdProfesor: gradoId,
    );
  }

  /// Puede completar/editar fichas de alumnos (alta rápida).
  bool get puedeEditarAlumnos =>
      esDirectora || esProfesorAdmin || esSecretaria;

  /// Directora o caja: administrar cobros / acreditar pagos.
  bool get puedeGestionarPagos => esDirectora || esCaja;

  /// Profesora de aula (titular / inglés / música), no admin ni directora.
  bool get esMaestraAula => rol == 'profesor';

  bool get puedeEditarGrados => esDirectora;
  bool get puedeGestionarDocentes => esDirectora;
  bool get puedeGestionarAccesoPadres => esDirectora;
  bool get puedeAnunciarAGrupo =>
      esDirectora || esProfesorAdmin || esMaestraAula;

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
