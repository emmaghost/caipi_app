class Alumno {
  final String id;
  final String nombre;
  final String apellidos;
  final DateTime fechaNacimiento;
  final String? genero; // 'niño' o 'niña'
  final String? gradoId;
  final String padreId;
  final String? fotoUrl;
  final String? fotoDefaultGenero; // 'nino' o 'nina' para imagen por default
  final String? alergias;
  final String? condicionesMedicas;
  final String? contactoEmergenciaNombre;
  final String? contactoEmergenciaTelefono;
  // Dirección
  final String? calle;
  final String? colonia;
  final String? codigoPostal;
  final String? ciudad;
  final String? estado;
  // CURP y vacunas
  final String? curp;
  final bool cartillaCompleta;
  final String? vacunasFaltantes;
  // Pagos y beca
  final int planPagos; // 10 o 12 meses
  final DateTime fechaIngreso;
  final int becaPorcentaje; // 0-100 (porcentaje de descuento)
  final bool activo;
  final DateTime createdAt;
  final DateTime updatedAt;

  Alumno({
    required this.id,
    required this.nombre,
    required this.apellidos,
    required this.fechaNacimiento,
    this.genero,
    this.gradoId,
    required this.padreId,
    this.fotoUrl,
    this.fotoDefaultGenero,
    this.alergias,
    this.condicionesMedicas,
    this.contactoEmergenciaNombre,
    this.contactoEmergenciaTelefono,
    this.calle,
    this.colonia,
    this.codigoPostal,
    this.ciudad,
    this.estado,
    this.curp,
    this.cartillaCompleta = true,
    this.vacunasFaltantes,
    this.planPagos = 12, // Por defecto 12 meses
    required this.fechaIngreso,
    this.becaPorcentaje = 0, // Sin beca por defecto
    this.activo = true,
    required this.createdAt,
    required this.updatedAt,
  });

  String get nombreCompleto => '$nombre $apellidos';

  int get edad {
    final hoy = DateTime.now();
    int edad = hoy.year - fechaNacimiento.year;
    if (hoy.month < fechaNacimiento.month ||
        (hoy.month == fechaNacimiento.month && hoy.day < fechaNacimiento.day)) {
      edad--;
    }
    return edad;
  }

  String get fotoDisplay {
    if (fotoUrl != null && fotoUrl!.isNotEmpty) return fotoUrl!;
    // Retornar path de imagen por default según género
    if (fotoDefaultGenero == 'nina' || genero == 'niña') {
      return 'assets/images/default_nina.png';
    }
    return 'assets/images/default_nino.png';
  }

  bool get tieneAlergias => alergias != null && alergias!.isNotEmpty;
  bool get tieneCondicionesMedicas => condicionesMedicas != null && condicionesMedicas!.isNotEmpty;
  
  /// ¿Tiene beca?
  bool get tieneBeca => becaPorcentaje > 0;
  
  /// Texto descriptivo de la beca
  String get becaDescripcion {
    if (becaPorcentaje == 0) return 'Sin beca';
    if (becaPorcentaje == 100) return 'Beca completa (100%)';
    return 'Beca del $becaPorcentaje%';
  }

  factory Alumno.fromJson(Map<String, dynamic> json) {
    return Alumno(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      apellidos: json['apellidos'] as String,
      fechaNacimiento: DateTime.parse(json['fecha_nacimiento']),
      genero: json['genero'] as String?,
      gradoId: json['grado_id'] as String?,
      padreId: json['padre_id'] as String,
      fotoUrl: json['foto_url'] as String?,
      fotoDefaultGenero: json['foto_default_genero'] as String?,
      alergias: json['alergias'] as String?,
      condicionesMedicas: json['condiciones_medicas'] as String?,
      contactoEmergenciaNombre: json['contacto_emergencia_nombre'] as String?,
      contactoEmergenciaTelefono: json['contacto_emergencia_telefono'] as String?,
      calle: json['calle'] as String?,
      colonia: json['colonia'] as String?,
      codigoPostal: json['codigo_postal'] as String?,
      ciudad: json['ciudad'] as String?,
      estado: json['estado'] as String?,
      curp: json['curp'] as String?,
      cartillaCompleta: json['cartilla_completa'] as bool? ?? true,
      vacunasFaltantes: json['vacunas_faltantes'] as String?,
      planPagos: json['plan_pagos'] as int? ?? 12,
      fechaIngreso: json['fecha_ingreso'] != null 
          ? DateTime.parse(json['fecha_ingreso'])
          : DateTime.now(),
      becaPorcentaje: json['beca_porcentaje'] as int? ?? 0,
      activo: json['activo'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'apellidos': apellidos,
      'fecha_nacimiento': fechaNacimiento.toIso8601String().split('T')[0],
      'genero': genero,
      'grado_id': gradoId,
      'padre_id': padreId,
      'foto_url': fotoUrl,
      'foto_default_genero': fotoDefaultGenero,
      'alergias': alergias,
      'condiciones_medicas': condicionesMedicas,
      'contacto_emergencia_nombre': contactoEmergenciaNombre,
      'contacto_emergencia_telefono': contactoEmergenciaTelefono,
      'calle': calle,
      'colonia': colonia,
      'codigo_postal': codigoPostal,
      'ciudad': ciudad,
      'estado': estado,
      'curp': curp,
      'cartilla_completa': cartillaCompleta,
      'vacunas_faltantes': vacunasFaltantes,
      'plan_pagos': planPagos,
      'fecha_ingreso': fechaIngreso.toIso8601String().split('T')[0],
      'beca_porcentaje': becaPorcentaje,
      'activo': activo,
    };
  }

  Alumno copyWith({
    String? id,
    String? nombre,
    String? apellidos,
    DateTime? fechaNacimiento,
    String? genero,
    String? gradoId,
    String? padreId,
    String? fotoUrl,
    String? fotoDefaultGenero,
    String? alergias,
    String? condicionesMedicas,
    String? contactoEmergenciaNombre,
    String? contactoEmergenciaTelefono,
    String? calle,
    String? colonia,
    String? codigoPostal,
    String? ciudad,
    String? estado,
    String? curp,
    bool? cartillaCompleta,
    String? vacunasFaltantes,
    int? planPagos,
    DateTime? fechaIngreso,
    int? becaPorcentaje,
    bool? activo,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Alumno(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      apellidos: apellidos ?? this.apellidos,
      fechaNacimiento: fechaNacimiento ?? this.fechaNacimiento,
      genero: genero ?? this.genero,
      gradoId: gradoId ?? this.gradoId,
      padreId: padreId ?? this.padreId,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      fotoDefaultGenero: fotoDefaultGenero ?? this.fotoDefaultGenero,
      alergias: alergias ?? this.alergias,
      condicionesMedicas: condicionesMedicas ?? this.condicionesMedicas,
      contactoEmergenciaNombre: contactoEmergenciaNombre ?? this.contactoEmergenciaNombre,
      contactoEmergenciaTelefono: contactoEmergenciaTelefono ?? this.contactoEmergenciaTelefono,
      calle: calle ?? this.calle,
      colonia: colonia ?? this.colonia,
      codigoPostal: codigoPostal ?? this.codigoPostal,
      ciudad: ciudad ?? this.ciudad,
      estado: estado ?? this.estado,
      curp: curp ?? this.curp,
      cartillaCompleta: cartillaCompleta ?? this.cartillaCompleta,
      vacunasFaltantes: vacunasFaltantes ?? this.vacunasFaltantes,
      planPagos: planPagos ?? this.planPagos,
      fechaIngreso: fechaIngreso ?? this.fechaIngreso,
      becaPorcentaje: becaPorcentaje ?? this.becaPorcentaje,
      activo: activo ?? this.activo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
