import 'package:intl/intl.dart';

/// Modelo para abonos (pagos parciales)
class Abono {
  final String id;
  final String pagoId;
  final double monto;
  final DateTime fechaAbono;
  final String? formaPago; // Efectivo, Transferencia, Tarjeta
  final String? referencia; // Número de referencia/transacción
  final String? notas;
  final String? reciboFolio; // REC-2026-0001
  final DateTime createdAt;
  final String? createdBy;

  Abono({
    required this.id,
    required this.pagoId,
    required this.monto,
    required this.fechaAbono,
    this.formaPago,
    this.referencia,
    this.notas,
    this.reciboFolio,
    required this.createdAt,
    this.createdBy,
  });

  /// Formatea el monto como moneda
  String get montoFormateado {
    return '\$${monto.toStringAsFixed(2)}';
  }

  /// Formatea la fecha de abono
  String get fechaFormateada {
    return DateFormat('dd/MM/yyyy').format(fechaAbono);
  }

  /// Formatea la fecha y hora de creación
  String get fechaHoraCreacion {
    return DateFormat('dd/MM/yyyy HH:mm').format(createdAt);
  }

  factory Abono.fromJson(Map<String, dynamic> json) {
    return Abono(
      id: json['id'] as String,
      pagoId: json['pago_id'] as String,
      monto: (json['monto'] as num).toDouble(),
      fechaAbono: DateTime.parse(json['fecha_abono'] as String),
      formaPago: json['forma_pago'] as String?,
      referencia: json['referencia'] as String?,
      notas: json['notas'] as String?,
      reciboFolio: json['recibo_folio'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      createdBy: json['created_by'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pago_id': pagoId,
      'monto': monto,
      'fecha_abono': fechaAbono.toIso8601String().split('T')[0],
      'forma_pago': formaPago,
      'referencia': referencia,
      'notas': notas,
      'recibo_folio': reciboFolio,
      'created_at': createdAt.toIso8601String(),
      'created_by': createdBy,
    };
  }

  Abono copyWith({
    String? id,
    String? pagoId,
    double? monto,
    DateTime? fechaAbono,
    String? formaPago,
    String? referencia,
    String? notas,
    String? reciboFolio,
    DateTime? createdAt,
    String? createdBy,
  }) {
    return Abono(
      id: id ?? this.id,
      pagoId: pagoId ?? this.pagoId,
      monto: monto ?? this.monto,
      fechaAbono: fechaAbono ?? this.fechaAbono,
      formaPago: formaPago ?? this.formaPago,
      referencia: referencia ?? this.referencia,
      notas: notas ?? this.notas,
      reciboFolio: reciboFolio ?? this.reciboFolio,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}
