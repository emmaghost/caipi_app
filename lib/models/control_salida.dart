class ControlSalida {
  final String id;
  final String alumnoId;
  final DateTime fecha;
  final DateTime? horaEntrada;
  final String? quienTrajo;
  final DateTime? horaSalida;
  final String? quienRecogio;
  final String? personaAutorizadaId;
  final String? observaciones;
  /// Si true, el niño no asistió ese día (sin horarios de entrada/salida).
  final bool ausente;
  final DateTime createdAt;

  ControlSalida({
    required this.id,
    required this.alumnoId,
    required this.fecha,
    this.horaEntrada,
    this.quienTrajo,
    this.horaSalida,
    this.quienRecogio,
    this.personaAutorizadaId,
    this.observaciones,
    this.ausente = false,
    required this.createdAt,
  });

  bool get tieneEntrada => !ausente && horaEntrada != null;
  bool get tieneSalida => !ausente && horaSalida != null;

  factory ControlSalida.fromJson(Map<String, dynamic> json) {
    return ControlSalida(
      id: json['id'] as String,
      alumnoId: json['alumno_id'] as String,
      fecha: DateTime.parse(json['fecha'].toString()),
      horaEntrada: json['hora_entrada'] != null
          ? DateTime.parse('${json['fecha']} ${json['hora_entrada']}')
          : null,
      quienTrajo: json['quien_trajo'] as String?,
      horaSalida: json['hora_salida'] != null
          ? DateTime.parse('${json['fecha']} ${json['hora_salida']}')
          : null,
      quienRecogio: json['quien_recogio'] as String?,
      personaAutorizadaId: json['persona_autorizada_id'] as String?,
      observaciones: json['observaciones'] as String?,
      ausente: json['ausente'] == true,
      createdAt: DateTime.parse(json['created_at'].toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'alumno_id': alumnoId,
      'fecha': fecha.toIso8601String().split('T')[0],
      'hora_entrada': horaEntrada?.toIso8601String().split('T')[1],
      'quien_trajo': quienTrajo,
      'hora_salida': horaSalida?.toIso8601String().split('T')[1],
      'quien_recogio': quienRecogio,
      'persona_autorizada_id': personaAutorizadaId,
      'observaciones': observaciones,
      'ausente': ausente,
    };
  }
}
