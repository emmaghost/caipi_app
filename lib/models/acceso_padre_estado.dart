class AdeudoAccesoPadre {
  final String alumnoId;
  final String alumnoNombre;
  final String? mes;
  final double monto;
  final double saldo;
  final DateTime? fechaVencimiento;

  AdeudoAccesoPadre({
    required this.alumnoId,
    required this.alumnoNombre,
    this.mes,
    required this.monto,
    required this.saldo,
    this.fechaVencimiento,
  });

  factory AdeudoAccesoPadre.fromJson(Map<String, dynamic> json) {
    return AdeudoAccesoPadre(
      alumnoId: json['alumno_id']?.toString() ?? '',
      alumnoNombre: json['alumno_nombre']?.toString() ?? 'Alumno',
      mes: json['mes']?.toString(),
      monto: (json['monto'] as num?)?.toDouble() ?? 0,
      saldo: (json['saldo'] as num?)?.toDouble() ?? 0,
      fechaVencimiento: json['fecha_vencimiento'] != null
          ? DateTime.tryParse(json['fecha_vencimiento'].toString())
          : null,
    );
  }
}

class AccesoPadreEstado {
  final bool restringido;
  final String modo;
  final String? motivo;
  final String? notaDirectora;
  final int diasGracia;
  final List<AdeudoAccesoPadre> adeudos;

  AccesoPadreEstado({
    required this.restringido,
    this.modo = 'automatico',
    this.motivo,
    this.notaDirectora,
    this.diasGracia = 5,
    this.adeudos = const [],
  });

  double get totalSaldo =>
      adeudos.fold<double>(0, (sum, a) => sum + a.saldo);

  factory AccesoPadreEstado.libre() => AccesoPadreEstado(restringido: false);

  factory AccesoPadreEstado.fromJson(dynamic raw) {
    if (raw is! Map) return AccesoPadreEstado.libre();
    final json = Map<String, dynamic>.from(raw);
    final adeudosRaw = json['adeudos'];
    final adeudos = adeudosRaw is List
        ? adeudosRaw
            .whereType<Map>()
            .map((e) => AdeudoAccesoPadre.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <AdeudoAccesoPadre>[];

    return AccesoPadreEstado(
      restringido: json['restringido'] == true,
      modo: json['modo']?.toString() ?? 'automatico',
      motivo: json['motivo']?.toString(),
      notaDirectora: json['nota_directora']?.toString(),
      diasGracia: (json['dias_gracia'] as num?)?.toInt() ?? 5,
      adeudos: adeudos,
    );
  }
}
