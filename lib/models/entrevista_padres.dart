class EntrevistaPadres {
  final String id;
  final String? alumnoId;
  final String? padreUsuarioId;
  
  // SECCIÓN 1: DATOS DE LA MADRE
  final String? madreNombre;
  final int? madreEdad;
  final String? madreOcupacion;
  final String? madreDireccion;
  final String? madreGradoEstudios;
  final String? madreTelefono;
  
  // SECCIÓN 2: DATOS DEL PADRE
  final String? padreNombre;
  final int? padreEdad;
  final String? padreOcupacion;
  final String? padreDireccion;
  final String? padreGradoEstudios;
  final String? padreTelefono;
  
  // SECCIÓN 3: DIRECCIÓN DONDE VIVE EL ALUMNO
  final String? viveCalle;
  final String? viveColonia;
  final String? viveNumero;
  final String? viveReferencia;
  final String? viveTipo; // 'Casa', 'Departamento', 'Otro'
  final String? viveCondicion; // 'Propia', 'Rentada', 'De un familiar'
  
  // SECCIÓN 4: INFORMACIÓN DEL HOGAR
  final String? personasVivenCon;
  final String? quienCuidaCuandoNoEscuela;
  final String? enfermedadesPadecimientos;
  final String? alergiasCuidados;
  final bool? controlEsfinteres;
  final String? controlEsfinteresEdad;
  final String? necesidadesEducativasEspeciales;
  final String? dificultadesRealizar;
  final String? motivoInasistencias;
  
  // SECCIÓN 5: ANTECEDENTES
  final String? embarazoPlaneado;
  final String? tiempoEmbarazo;
  final String? dificultadesEmbarazo;
  final String? edadCamino;
  final String? edadHablo;
  
  // SECCIÓN 6: PADRES SEPARADOS
  final bool padresSeparados;
  final String? quienPatriaPotestad;
  final String? conviveOtraParte;
  final String? tienePadrastroMadrastra;
  final String? relacionPadrastroMadrastra;
  final String? comoSeRefiereAEl;
  final String? tieneHermanastros;
  final String? relacionHermanastros;
  
  // SECCIÓN 7: ASPECTO SOCIAL DEL HIJO
  final String? caracterHijo;
  final String? queLaHaceEnojar;
  final String? queLaPoneTriste;
  final String? comoActuaCuandoAsi;
  final String? queMasLeGustaHacer;
  final bool? seVisteSola;
  final String? seAtaCordonesSola; // Cambié a String para flexibilidad
  final String? habitosHigiene;
  final String? rutinaDespuesEscuela;
  final String? horaDuerme;
  final String? horaDespierta;
  
  // SECCIÓN 8: ASPECTO SOCIAL (FAMILIA)
  final bool? saleFineSemana;
  final String? saleADonde;
  final String? actividadesFamilia;
  final bool? haceAmigosFacilidad;
  final String? nombresAmigos;
  final bool? tieneMascotas;
  final String? mascotasCuales;
  final bool? ayudaQuehaceres;
  final String? cuandoPortaMalActua;
  final String? hayCastigosCuales;
  final String? cuandoPortaBienActua;
  final String? dicenGroceriasQuien;
  final String? juguetesUsaFrecuencia;
  
  // SECCIÓN 9: SOBRE NOSOTROS (EXPECTATIVAS)
  final String? queEsperaMaestra;
  final String? queEsperaEscuela;
  final bool? dispuestoApoyarEscuela;
  
  // Metadatos
  final bool completado;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;

  EntrevistaPadres({
    required this.id,
    this.alumnoId,
    this.padreUsuarioId,
    // Madre
    this.madreNombre,
    this.madreEdad,
    this.madreOcupacion,
    this.madreDireccion,
    this.madreGradoEstudios,
    this.madreTelefono,
    // Padre
    this.padreNombre,
    this.padreEdad,
    this.padreOcupacion,
    this.padreDireccion,
    this.padreGradoEstudios,
    this.padreTelefono,
    // Dirección
    this.viveCalle,
    this.viveColonia,
    this.viveNumero,
    this.viveReferencia,
    this.viveTipo,
    this.viveCondicion,
    // Hogar
    this.personasVivenCon,
    this.quienCuidaCuandoNoEscuela,
    this.enfermedadesPadecimientos,
    this.alergiasCuidados,
    this.controlEsfinteres,
    this.controlEsfinteresEdad,
    this.necesidadesEducativasEspeciales,
    this.dificultadesRealizar,
    this.motivoInasistencias,
    // Antecedentes
    this.embarazoPlaneado,
    this.tiempoEmbarazo,
    this.dificultadesEmbarazo,
    this.edadCamino,
    this.edadHablo,
    // Padres separados
    this.padresSeparados = false,
    this.quienPatriaPotestad,
    this.conviveOtraParte,
    this.tienePadrastroMadrastra,
    this.relacionPadrastroMadrastra,
    this.comoSeRefiereAEl,
    this.tieneHermanastros,
    this.relacionHermanastros,
    // Aspecto social hijo
    this.caracterHijo,
    this.queLaHaceEnojar,
    this.queLaPoneTriste,
    this.comoActuaCuandoAsi,
    this.queMasLeGustaHacer,
    this.seVisteSola,
    this.seAtaCordonesSola,
    this.habitosHigiene,
    this.rutinaDespuesEscuela,
    this.horaDuerme,
    this.horaDespierta,
    // Aspecto social familia
    this.saleFineSemana,
    this.saleADonde,
    this.actividadesFamilia,
    this.haceAmigosFacilidad,
    this.nombresAmigos,
    this.tieneMascotas,
    this.mascotasCuales,
    this.ayudaQuehaceres,
    this.cuandoPortaMalActua,
    this.hayCastigosCuales,
    this.cuandoPortaBienActua,
    this.dicenGroceriasQuien,
    this.juguetesUsaFrecuencia,
    // Expectativas
    this.queEsperaMaestra,
    this.queEsperaEscuela,
    this.dispuestoApoyarEscuela,
    // Metadatos
    this.completado = false,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
  });

  factory EntrevistaPadres.fromJson(Map<String, dynamic> json) {
    return EntrevistaPadres(
      id: json['id'] as String,
      alumnoId: json['alumno_id'] as String?,
      padreUsuarioId: json['padre_usuario_id'] as String?,
      // Madre
      madreNombre: json['madre_nombre'] as String?,
      madreEdad: json['madre_edad'] as int?,
      madreOcupacion: json['madre_ocupacion'] as String?,
      madreDireccion: json['madre_direccion'] as String?,
      madreGradoEstudios: json['madre_grado_estudios'] as String?,
      madreTelefono: json['madre_telefono'] as String?,
      // Padre
      padreNombre: json['padre_nombre'] as String?,
      padreEdad: json['padre_edad'] as int?,
      padreOcupacion: json['padre_ocupacion'] as String?,
      padreDireccion: json['padre_direccion'] as String?,
      padreGradoEstudios: json['padre_grado_estudios'] as String?,
      padreTelefono: json['padre_telefono'] as String?,
      // Dirección
      viveCalle: json['vive_calle'] as String?,
      viveColonia: json['vive_colonia'] as String?,
      viveNumero: json['vive_numero'] as String?,
      viveReferencia: json['vive_referencia'] as String?,
      viveTipo: json['vive_tipo'] as String?,
      viveCondicion: json['vive_condicion'] as String?,
      // Hogar
      personasVivenCon: json['personas_viven_con'] as String?,
      quienCuidaCuandoNoEscuela: json['quien_cuida_cuando_no_escuela'] as String?,
      enfermedadesPadecimientos: json['enfermedades_padecimientos'] as String?,
      alergiasCuidados: json['alergias_cuidados'] as String?,
      controlEsfinteres: json['control_esfinteres'] as bool?,
      controlEsfinteresEdad: json['control_esfinteres_edad'] as String?,
      necesidadesEducativasEspeciales: json['necesidades_educativas_especiales'] as String?,
      dificultadesRealizar: json['dificultades_realizar'] as String?,
      motivoInasistencias: json['motivo_inasistencias'] as String?,
      // Antecedentes
      embarazoPlaneado: json['embarazo_planeado'] as String?,
      tiempoEmbarazo: json['tiempo_embarazo'] as String?,
      dificultadesEmbarazo: json['dificultades_embarazo'] as String?,
      edadCamino: json['edad_camino'] as String?,
      edadHablo: json['edad_hablo'] as String?,
      // Padres separados
      padresSeparados: json['padres_separados'] as bool? ?? false,
      quienPatriaPotestad: json['quien_patria_potestad'] as String?,
      conviveOtraParte: json['convive_otra_parte'] as String?,
      tienePadrastroMadrastra: json['tiene_padrastro_madrastra'] as String?,
      relacionPadrastroMadrastra: json['relacion_padrastro_madrastra'] as String?,
      comoSeRefiereAEl: json['como_se_refiere_a_el'] as String?,
      tieneHermanastros: json['tiene_hermanastros'] as String?,
      relacionHermanastros: json['relacion_hermanastros'] as String?,
      // Aspecto social hijo
      caracterHijo: json['caracter_hijo'] as String?,
      queLaHaceEnojar: json['que_la_hace_enojar'] as String?,
      queLaPoneTriste: json['que_la_pone_triste'] as String?,
      comoActuaCuandoAsi: json['como_actua_cuando_asi'] as String?,
      queMasLeGustaHacer: json['que_mas_le_gusta_hacer'] as String?,
      seVisteSola: json['se_viste_sola'] as bool?,
      seAtaCordonesSola: json['se_ata_cordones_sola'] as String?,
      habitosHigiene: json['habitos_higiene'] as String?,
      rutinaDespuesEscuela: json['rutina_despues_escuela'] as String?,
      horaDuerme: json['hora_duerme'] as String?,
      horaDespierta: json['hora_despierta'] as String?,
      // Aspecto social familia
      saleFineSemana: json['sale_fines_semana'] as bool?,
      saleADonde: json['sale_a_donde'] as String?,
      actividadesFamilia: json['actividades_familia'] as String?,
      haceAmigosFacilidad: json['hace_amigos_facilidad'] as bool?,
      nombresAmigos: json['nombres_amigos'] as String?,
      tieneMascotas: json['tiene_mascotas'] as bool?,
      mascotasCuales: json['mascotas_cuales'] as String?,
      ayudaQuehaceres: json['ayuda_quehaceres'] as bool?,
      cuandoPortaMalActua: json['cuando_porta_mal_actua'] as String?,
      hayCastigosCuales: json['hay_castigos_cuales'] as String?,
      cuandoPortaBienActua: json['cuando_porta_bien_actua'] as String?,
      dicenGroceriasQuien: json['dicen_grocerias_quien'] as String?,
      juguetesUsaFrecuencia: json['juguetes_usa_frecuencia'] as String?,
      // Expectativas
      queEsperaMaestra: json['que_espera_maestra'] as String?,
      queEsperaEscuela: json['que_espera_escuela'] as String?,
      dispuestoApoyarEscuela: json['dispuesto_apoyar_escuela'] as bool?,
      // Metadatos
      completado: json['completado'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      createdBy: json['created_by'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'alumno_id': alumnoId,
      'padre_usuario_id': padreUsuarioId,
      // Madre
      'madre_nombre': madreNombre,
      'madre_edad': madreEdad,
      'madre_ocupacion': madreOcupacion,
      'madre_direccion': madreDireccion,
      'madre_grado_estudios': madreGradoEstudios,
      'madre_telefono': madreTelefono,
      // Padre
      'padre_nombre': padreNombre,
      'padre_edad': padreEdad,
      'padre_ocupacion': padreOcupacion,
      'padre_direccion': padreDireccion,
      'padre_grado_estudios': padreGradoEstudios,
      'padre_telefono': padreTelefono,
      // Dirección
      'vive_calle': viveCalle,
      'vive_colonia': viveColonia,
      'vive_numero': viveNumero,
      'vive_referencia': viveReferencia,
      'vive_tipo': viveTipo,
      'vive_condicion': viveCondicion,
      // Hogar
      'personas_viven_con': personasVivenCon,
      'quien_cuida_cuando_no_escuela': quienCuidaCuandoNoEscuela,
      'enfermedades_padecimientos': enfermedadesPadecimientos,
      'alergias_cuidados': alergiasCuidados,
      'control_esfinteres': controlEsfinteres,
      'control_esfinteres_edad': controlEsfinteresEdad,
      'necesidades_educativas_especiales': necesidadesEducativasEspeciales,
      'dificultades_realizar': dificultadesRealizar,
      'motivo_inasistencias': motivoInasistencias,
      // Antecedentes
      'embarazo_planeado': embarazoPlaneado,
      'tiempo_embarazo': tiempoEmbarazo,
      'dificultades_embarazo': dificultadesEmbarazo,
      'edad_camino': edadCamino,
      'edad_hablo': edadHablo,
      // Padres separados
      'padres_separados': padresSeparados,
      'quien_patria_potestad': quienPatriaPotestad,
      'convive_otra_parte': conviveOtraParte,
      'tiene_padrastro_madrastra': tienePadrastroMadrastra,
      'relacion_padrastro_madrastra': relacionPadrastroMadrastra,
      'como_se_refiere_a_el': comoSeRefiereAEl,
      'tiene_hermanastros': tieneHermanastros,
      'relacion_hermanastros': relacionHermanastros,
      // Aspecto social hijo
      'caracter_hijo': caracterHijo,
      'que_la_hace_enojar': queLaHaceEnojar,
      'que_la_pone_triste': queLaPoneTriste,
      'como_actua_cuando_asi': comoActuaCuandoAsi,
      'que_mas_le_gusta_hacer': queMasLeGustaHacer,
      'se_viste_sola': seVisteSola,
      'se_ata_cordones_sola': seAtaCordonesSola,
      'habitos_higiene': habitosHigiene,
      'rutina_despues_escuela': rutinaDespuesEscuela,
      'hora_duerme': horaDuerme,
      'hora_despierta': horaDespierta,
      // Aspecto social familia
      'sale_fines_semana': saleFineSemana,
      'sale_a_donde': saleADonde,
      'actividades_familia': actividadesFamilia,
      'hace_amigos_facilidad': haceAmigosFacilidad,
      'nombres_amigos': nombresAmigos,
      'tiene_mascotas': tieneMascotas,
      'mascotas_cuales': mascotasCuales,
      'ayuda_quehaceres': ayudaQuehaceres,
      'cuando_porta_mal_actua': cuandoPortaMalActua,
      'hay_castigos_cuales': hayCastigosCuales,
      'cuando_porta_bien_actua': cuandoPortaBienActua,
      'dicen_grocerias_quien': dicenGroceriasQuien,
      'juguetes_usa_frecuencia': juguetesUsaFrecuencia,
      // Expectativas
      'que_espera_maestra': queEsperaMaestra,
      'que_espera_escuela': queEsperaEscuela,
      'dispuesto_apoyar_escuela': dispuestoApoyarEscuela,
      // Metadatos
      'completado': completado,
    };
  }
}
