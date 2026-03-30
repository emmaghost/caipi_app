class Bitacora {
  final String id;
  final String alumnoId;
  final String? profesorId;
  final DateTime fecha;
  final String? comio; // 'si', 'no', 'mas_o_menos' (legacy: 'medio')
  final bool tomoAgua;
  final bool pipi;
  final bool popo;
  final bool lavoDientes;
  final bool respetoDemas;
  final bool realizoActividades;
  final bool siesta;
  final String? estadoAnimo; // 'feliz', 'normal', 'triste', 'irritable'
  final String? observaciones;
  final DateTime createdAt;
  final DateTime updatedAt;

  Bitacora({
    required this.id,
    required this.alumnoId,
    this.profesorId,
    required this.fecha,
    this.comio,
    this.tomoAgua = false,
    this.pipi = false,
    this.popo = false,
    this.lavoDientes = false,
    this.respetoDemas = false,
    this.realizoActividades = false,
    this.siesta = false,
    this.estadoAnimo,
    this.observaciones,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Bitacora.fromJson(Map<String, dynamic> json) {
    return Bitacora(
      id: json['id'] as String,
      alumnoId: json['alumno_id'] as String,
      profesorId: json['profesor_id'] as String?,
      fecha: DateTime.parse(json['fecha']),
      comio: json['comio'] as String?,
      tomoAgua: json['tomo_agua'] as bool? ?? false,
      pipi: json['pipi'] as bool? ?? false,
      popo: json['popo'] as bool? ?? false,
      lavoDientes: json['lavo_dientes'] as bool? ?? false,
      respetoDemas: json['respeto_demas'] as bool? ?? false,
      realizoActividades: json['realizo_actividades'] as bool? ?? false,
      siesta: json['siesta'] as bool? ?? false,
      estadoAnimo: json['estado_animo'] as String?,
      observaciones: json['observaciones'] as String?,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  /// Texto para mostrar: Sí / No / Más o menos
  static String etiquetaComio(String? comio) {
    if (comio == 'si') return 'Sí';
    if (comio == 'mas_o_menos' || comio == 'medio') return 'Más o menos';
    return 'No';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'alumno_id': alumnoId,
      'profesor_id': profesorId,
      'fecha': fecha.toIso8601String().split('T')[0],
      'comio': comio,
      'tomo_agua': tomoAgua,
      'pipi': pipi,
      'popo': popo,
      'lavo_dientes': lavoDientes,
      'respeto_demas': respetoDemas,
      'realizo_actividades': realizoActividades,
      'siesta': siesta,
      'estado_animo': estadoAnimo,
      'observaciones': observaciones,
    };
  }
}
