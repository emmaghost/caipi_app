class LigaDrive {
  final String id;
  final String nombre;
  final String url;
  /// 'general' | 'grados'
  final String alcance;
  final bool activa;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  /// Grados asignados cuando alcance == 'grados'.
  final List<String> gradoIds;

  LigaDrive({
    required this.id,
    required this.nombre,
    required this.url,
    this.alcance = 'general',
    this.activa = true,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.gradoIds = const [],
  });

  bool get esGeneral => alcance == 'general';
  bool get esPorGrados => alcance == 'grados';

  factory LigaDrive.fromJson(Map<String, dynamic> json) {
    final gradosRaw = json['ligas_drive_grados'];
    final ids = <String>[];
    if (gradosRaw is List) {
      for (final row in gradosRaw) {
        if (row is Map && row['grado_id'] != null) {
          ids.add(row['grado_id'].toString());
        }
      }
    }
    // Compat: si aún viene join viejo de alumnos, ignorar
    var alcance = json['alcance'] as String? ?? 'general';
    if (alcance == 'alumnos') alcance = 'grados';

    return LigaDrive(
      id: json['id'] as String,
      nombre: json['nombre'] as String? ?? 'Liga',
      url: json['url'] as String? ?? '',
      alcance: alcance,
      activa: json['activa'] as bool? ?? true,
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      gradoIds: ids,
    );
  }
}
