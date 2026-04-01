class BitacoraGasto {
  final String id;
  final DateTime fecha;
  final String descripcion;
  final double monto;
  final String? gradoId;
  final DateTime createdAt;
  final DateTime updatedAt;

  BitacoraGasto({
    required this.id,
    required this.fecha,
    required this.descripcion,
    required this.monto,
    this.gradoId,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get esGeneralEscuela => gradoId == null || gradoId!.isEmpty;

  factory BitacoraGasto.fromJson(Map<String, dynamic> json) {
    final m = json['monto'];
    double monto;
    if (m is num) {
      monto = m.toDouble();
    } else if (m is String) {
      monto = double.tryParse(m) ?? 0;
    } else {
      monto = 0;
    }

    return BitacoraGasto(
      id: json['id']?.toString() ?? '',
      fecha: DateTime.tryParse(json['fecha']?.toString() ?? '') ??
          DateTime.now(),
      descripcion: json['descripcion'] as String? ?? '',
      monto: monto,
      gradoId: json['grado_id'] as String?,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJsonInsert() {
    return {
      'fecha': fecha.toIso8601String().split('T').first,
      'descripcion': descripcion,
      'monto': monto,
      'grado_id': gradoId,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}
