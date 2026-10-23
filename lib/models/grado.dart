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

  static String claveNombre(String nombre) {
    return nombre
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ü', 'u');
  }

  String get _clave => claveNombre(nombre);

  bool get esEstimulacion => _clave.contains('estimul');

  bool get esMaternal => _clave.contains('maternal');

  /// Lactante, bebé o sala cuna: mismo trato de pagos que maternal.
  bool get esLactanteOBebes {
    final n = _clave;
    return n.contains('lactante') || n.contains('bebe') || n.contains('cuna');
  }

  /// Maternal, lactante/bebé o estimulación.
  bool get esMaternalOBebes => esMaternal || esLactanteOBebes || esEstimulacion;

  bool get esKinder => _clave.contains('kinder');

  /// Kínder 1, 2 y 3. Caja solo ve estos. La directora ve todos los grupos.
  bool get muestraModuloPagos {
    final n = _clave;
    if (!n.contains('kinder')) return false;
    final m = RegExp(r'kinder\s*([0-9]+)').firstMatch(n);
    if (m != null) {
      final num = int.tryParse(m.group(1)!);
      return num == 1 || num == 2 || num == 3;
    }
    // Nombre tipo "Kinder" sin número: se trata como colegiado.
    return true;
  }

  /// Colegiatura 10/11/12 solo de kínder. Maternal y lactante usan sesión o paquete.
  bool get generaColegiaturaAutomatica => muestraModuloPagos;

  /// Sesión o paquete (1, 4, 6 u 8), con los precios de maternal y lactante.
  bool get usaCostosMaternal =>
      esMaternal || esLactanteOBebes || esEstimulacion;

  /// El papá ve pagos de kínder y también de maternal, lactante o estimulación.
  bool get muestraPagosAlPadre => muestraModuloPagos || usaCostosMaternal;

  /// Por clase, sin colegiatura de kínder.
  bool get cobroPorClase => !generaColegiaturaAutomatica;

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
