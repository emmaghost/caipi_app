class MenuMaternal {
  final String id;
  final DateTime fecha;
  final String? desayuno;
  final String? colacionManana;
  final String? comida;
  final String? merienda; // alias para colacion_tarde
  final String? colacionTarde;
  final String? observaciones;
  final DateTime createdAt;

  MenuMaternal({
    required this.id,
    required this.fecha,
    this.desayuno,
    this.colacionManana,
    this.comida,
    this.merienda,
    this.colacionTarde,
    this.observaciones,
    required this.createdAt,
  });

  factory MenuMaternal.fromJson(Map<String, dynamic> json) {
    final meriendaValue = json['merienda'] as String? ?? json['colacion_tarde'] as String?;
    return MenuMaternal(
      id: json['id'] as String,
      fecha: DateTime.parse(json['fecha']),
      desayuno: json['desayuno'] as String?,
      colacionManana: json['colacion_manana'] as String?,
      comida: json['comida'] as String?,
      merienda: meriendaValue,
      colacionTarde: meriendaValue,
      observaciones: json['observaciones'] as String?,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fecha': fecha.toIso8601String().split('T')[0],
      'desayuno': desayuno,
      'colacion_manana': colacionManana,
      'comida': comida,
      'merienda': merienda ?? colacionTarde,
      'colacion_tarde': merienda ?? colacionTarde,
      'observaciones': observaciones,
    };
  }
}
