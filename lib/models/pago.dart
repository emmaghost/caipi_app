// Modelo de Pago para Supabase

enum EstadoPago {
  pendiente,
  parcial, // Nuevo: pago parcial
  pagado,
  vencido,
  cancelado,
}

class Pago {
  final String id;
  final String alumnoId;
  final String? concepto;
  final double monto;
  final double montoPagado; // Nuevo: monto acumulado de abonos
  final String estatus; // 'pendiente', 'parcial', 'pagado', 'vencido', 'cancelado'
  final DateTime? fechaVencimiento; // Nullable
  final DateTime? fechaPago;
  final String? formaPago; // 'Efectivo', 'Transferencia', 'Tarjeta'
  final String? referencia;
  final String? notas;
  final int? anioEscolar;
  final String? tipoPago; // 'inscripcion', 'mensualidad', 'seguro', 'otro'
  /// Quien recibió el dinero en caja (último abono registrado).
  final String? recibidoPorNombre;
  final DateTime createdAt;
  final DateTime updatedAt;

  Pago({
    required this.id,
    required this.alumnoId,
    this.concepto,
    required this.monto,
    this.montoPagado = 0.0,
    this.estatus = 'pendiente',
    this.fechaVencimiento, // Ahora nullable
    this.fechaPago,
    this.formaPago,
    this.referencia,
    this.notas,
    this.anioEscolar,
    this.tipoPago,
    this.recibidoPorNombre,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Saldo pendiente del pago
  double get saldoPendiente {
    return monto - montoPagado;
  }

  /// Porcentaje pagado (0-100)
  double get porcentajePagado {
    if (monto == 0) return 0;
    return (montoPagado / monto) * 100;
  }

  /// ¿Está completamente pagado?
  bool get estaPagado {
    return estatus == 'pagado' || montoPagado >= monto;
  }

  /// ¿Está parcialmente pagado?
  bool get estaParcial {
    return estatus == 'parcial' || (montoPagado > 0 && montoPagado < monto);
  }

  static DateTime get _hoy {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static DateTime _fechaSolo(DateTime d) {
    return DateTime(d.year, d.month, d.day);
  }

  /// ¿La fecha límite ya llegó o pasó? (hoy >= límite). Para filtro "Pendientes".
  /// Así "Pendientes" no muestra los de fecha futura ("los nuevos").
  bool get esFechaLimiteAlcanzada {
    if (fechaVencimiento == null || estaPagado) return false;
    final limite = _fechaSolo(fechaVencimiento!);
    return !_hoy.isBefore(limite); // hoy >= límite
  }

  /// ¿Está vencido? (solo por fecha). Vencido = la fecha límite ya pasó (hoy > límite).
  bool get estaVencido {
    if (fechaVencimiento == null) return false;
    if (estaPagado) return false;
    final limite = _fechaSolo(fechaVencimiento!);
    return _hoy.isAfter(limite);
  }

  /// Estado del pago como enum
  EstadoPago get estado {
    switch (estatus) {
      case 'pagado':
        return EstadoPago.pagado;
      case 'parcial':
        return EstadoPago.parcial;
      case 'vencido':
        return EstadoPago.vencido;
      case 'cancelado':
        return EstadoPago.cancelado;
      default:
        return EstadoPago.pendiente;
    }
  }

  /// Formatea el monto
  String get montoFormateado {
    return '\$${monto.toStringAsFixed(2)}';
  }

  /// Formatea el monto pagado
  String get montoPagadoFormateado {
    return '\$${montoPagado.toStringAsFixed(2)}';
  }

  /// Formatea el saldo pendiente
  String get saldoPendienteFormateado {
    return '\$${saldoPendiente.toStringAsFixed(2)}';
  }

  factory Pago.fromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString();
    final alumnoId = json['alumno_id']?.toString();
    if (id == null || id.isEmpty || alumnoId == null || alumnoId.isEmpty) {
      throw FormatException('Pago sin id o alumno_id', json.toString());
    }
    final createdAt = json['created_at'] != null
        ? DateTime.tryParse(json['created_at'].toString())
        : null;
    final updatedAt = json['updated_at'] != null
        ? DateTime.tryParse(json['updated_at'].toString())
        : null;
    return Pago(
      id: id,
      alumnoId: alumnoId,
      concepto: json['concepto'] as String?,
      monto: (json['monto'] as num?)?.toDouble() ?? 0.0,
      montoPagado: json['monto_pagado'] != null
          ? (json['monto_pagado'] as num).toDouble()
          : 0.0,
      estatus: json['estatus'] as String? ?? 'pendiente',
      fechaVencimiento: json['fecha_vencimiento'] != null
          ? DateTime.tryParse(json['fecha_vencimiento'].toString())
          : null,
      fechaPago: json['fecha_pago'] != null
          ? DateTime.tryParse(json['fecha_pago'].toString())
          : null,
      formaPago: json['forma_pago'] as String?,
      referencia: json['referencia'] as String?,
      notas: json['notas'] as String?,
      anioEscolar: json['anio_escolar'] as int?,
      tipoPago: json['tipo_pago'] as String?,
      recibidoPorNombre: json['recibido_por_nombre'] as String?,
      createdAt: createdAt ?? DateTime.now(),
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'alumno_id': alumnoId,
      'concepto': concepto,
      'monto': monto,
      'monto_pagado': montoPagado,
      'estatus': estatus,
      'fecha_vencimiento': fechaVencimiento?.toIso8601String().split('T')[0],
      'fecha_pago': fechaPago?.toIso8601String().split('T')[0],
      'forma_pago': formaPago,
      'referencia': referencia,
      'notas': notas,
      'anio_escolar': anioEscolar,
      'tipo_pago': tipoPago,
      'recibido_por_nombre': recibidoPorNombre,
    };
  }

  Pago copyWith({
    String? id,
    String? alumnoId,
    String? concepto,
    double? monto,
    double? montoPagado,
    String? estatus,
    DateTime? fechaVencimiento,
    DateTime? fechaPago,
    String? formaPago,
    String? referencia,
    String? notas,
    int? anioEscolar,
    String? tipoPago,
    String? recibidoPorNombre,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Pago(
      id: id ?? this.id,
      alumnoId: alumnoId ?? this.alumnoId,
      concepto: concepto ?? this.concepto,
      monto: monto ?? this.monto,
      montoPagado: montoPagado ?? this.montoPagado,
      estatus: estatus ?? this.estatus,
      fechaVencimiento: fechaVencimiento ?? this.fechaVencimiento,
      fechaPago: fechaPago ?? this.fechaPago,
      formaPago: formaPago ?? this.formaPago,
      referencia: referencia ?? this.referencia,
      notas: notas ?? this.notas,
      anioEscolar: anioEscolar ?? this.anioEscolar,
      tipoPago: tipoPago ?? this.tipoPago,
      recibidoPorNombre: recibidoPorNombre ?? this.recibidoPorNombre,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
