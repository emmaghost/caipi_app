// Modelo de Grado para Supabase

class Grado {
  final String id;
  final String nombre;
  final String? descripcion;
  final int? edadMinima;
  final int? edadMaxima;
  final int cupoMaximo;
  final bool activo;
  final String? guiaDriveUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  Grado({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.edadMinima,
    this.edadMaxima,
    required this.cupoMaximo,
    this.activo = true,
    this.guiaDriveUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Grado.fromJson(Map<String, dynamic> json) {
    return Grado(
      id: json['id'] as String? ?? '',
      nombre: json['nombre'] as String? ?? 'Sin nombre',
      descripcion: json['descripcion'] as String?,
      edadMinima: json['edad_minima'] as int?,
      edadMaxima: json['edad_maxima'] as int?,
      cupoMaximo: json['cupo_maximo'] as int? ?? 20,
      activo: json['activo'] as bool? ?? true,
      guiaDriveUrl: json['guia_drive_url'] as String?,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : DateTime.now(),
    );
  }

  bool get esEstimulacion {
    final n = nombre.toLowerCase();
    return n.contains('estimul');
  }

  bool get esMaternal {
    final n = nombre.toLowerCase();
    return n.contains('maternal');
  }

  /// En CAIPI, estimulación temprana es el mismo grupo que maternal.
  bool get esMaternalOBebes => esMaternal || esEstimulacion;

  bool get esKinder {
    final n = nombre.toLowerCase().replaceAll('í', 'i');
    return n.contains('kinder');
  }

  /// Solo Kínder 1, 2 y 3 entran al módulo de pagos / colegiaturas.
  /// Estimulación, maternal y otros no aparecen en Pagos.
  bool get muestraModuloPagos {
    final n = nombre
        .toLowerCase()
        .replaceAll('í', 'i')
        .replaceAll('á', 'a')
        .replaceAll('é', 'e');
    if (!n.contains('kinder')) return false;
    final m = RegExp(r'kinder\s*([0-9]+)').firstMatch(n);
    if (m != null) {
      final num = int.tryParse(m.group(1)!);
      return num == 1 || num == 2 || num == 3;
    }
    // Nombre tipo "Kinder" sin número: se trata como colegiado.
    return true;
  }

  /// Colegiatura automática 10/11/12 solo para kínder 1–3.
  bool get generaColegiaturaAutomatica => muestraModuloPagos;

  /// Por clase / sin plan fijo: maternal (incluye estimulación) o sin clasificar.
  bool get cobroPorClase => !muestraModuloPagos;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'edad_minima': edadMinima,
      'edad_maxima': edadMaxima,
      'cupo_maximo': cupoMaximo,
      'activo': activo,
      'guia_drive_url': guiaDriveUrl,
    };
  }
}
