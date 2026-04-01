import 'dart:convert';

class BitacoraGasto {
  final String id;
  final DateTime fecha;
  final String descripcion;
  final double monto;
  final String? gradoId;
  /// Varios grados (JSON en BD). Si hay un solo grado suele usarse solo [gradoId].
  final List<String>? gruposAlcanceIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  BitacoraGasto({
    required this.id,
    required this.fecha,
    required this.descripcion,
    required this.monto,
    this.gradoId,
    this.gruposAlcanceIds,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get esGeneralEscuela {
    final sinGrado = gradoId == null || gradoId!.isEmpty;
    final sinLista = gruposAlcanceIds == null || gruposAlcanceIds!.isEmpty;
    return sinGrado && sinLista;
  }

  /// Si el gasto aplica al grado [gradoFiltroId] (filtro de lista).
  bool aplicaAGrado(String gradoFiltroId) {
    if (gradoId != null && gradoId == gradoFiltroId) return true;
    return gruposAlcanceIds?.contains(gradoFiltroId) ?? false;
  }

  static List<String>? _parseGruposIds(dynamic v) {
    if (v == null) return null;
    if (v is String && v.trim().isEmpty) return null;
    if (v is String) {
      try {
        final d = jsonDecode(v);
        if (d is List) {
          return d.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
        }
      } catch (_) {
        return null;
      }
    }
    return null;
  }

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
      gruposAlcanceIds: _parseGruposIds(json['grupos_alcance_ids']),
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
      'grupos_alcance_ids': gruposAlcanceIds != null && gruposAlcanceIds!.isNotEmpty
          ? jsonEncode(gruposAlcanceIds)
          : null,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}
