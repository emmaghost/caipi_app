// Modelos del módulo Portage (listas, indicadores, evaluaciones, resultados).

/// Valores de estado en `portage_resultados.estado`.
class PortageEstado {
  PortageEstado._();

  static const logrado = 'logrado';
  static const enProceso = 'en_proceso';

  static bool isLogrado(String? estado) => estado == logrado;
  static bool isEnProceso(String? estado) => estado == enProceso;
  static bool isSinCalificar(String? estado) =>
      estado == null || estado.isEmpty;

  static String etiqueta(String? estado) {
    if (isLogrado(estado)) return 'Logrado';
    if (isEnProceso(estado)) return 'En proceso';
    return 'Sin calificar';
  }

  /// Símbolo compacto para tablas/PDF: L, EP o vacío.
  static String simbolo(String? estado) {
    if (isLogrado(estado)) return 'L';
    if (isEnProceso(estado)) return 'EP';
    return '';
  }

  static String? parse(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    if (raw == logrado || raw == enProceso) return raw;
    return null;
  }
}

class PortageLista {
  final String id;
  final String gradoId;
  final String nombre;
  final bool activa;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  PortageLista({
    required this.id,
    required this.gradoId,
    required this.nombre,
    this.activa = true,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PortageLista.fromJson(Map<String, dynamic> json) {
    return PortageLista(
      id: json['id'] as String,
      gradoId: json['grado_id'] as String,
      nombre: json['nombre'] as String? ?? 'Indicadores de desarrollo',
      activa: json['activa'] as bool? ?? true,
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'grado_id': gradoId,
      'nombre': nombre,
      'activa': activa,
      if (createdBy != null) 'created_by': createdBy,
    };
  }
}

class PortageIndicador {
  final String id;
  final String listaId;
  final String nombre;
  final int orden;
  final DateTime createdAt;

  PortageIndicador({
    required this.id,
    required this.listaId,
    required this.nombre,
    required this.orden,
    required this.createdAt,
  });

  factory PortageIndicador.fromJson(Map<String, dynamic> json) {
    return PortageIndicador(
      id: json['id'] as String,
      listaId: json['lista_id'] as String,
      nombre: json['nombre'] as String,
      orden: json['orden'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lista_id': listaId,
      'nombre': nombre,
      'orden': orden,
    };
  }
}

class PortageEvaluacion {
  final String id;
  final String listaId;
  final String gradoId;
  final String? titulo;
  final DateTime fechaInicio;
  final String? createdBy;
  final DateTime createdAt;

  PortageEvaluacion({
    required this.id,
    required this.listaId,
    required this.gradoId,
    this.titulo,
    required this.fechaInicio,
    this.createdBy,
    required this.createdAt,
  });

  String get tituloDisplay =>
      (titulo != null && titulo!.trim().isNotEmpty)
          ? titulo!.trim()
          : 'Signos de alerta';

  factory PortageEvaluacion.fromJson(Map<String, dynamic> json) {
    return PortageEvaluacion(
      id: json['id'] as String,
      listaId: json['lista_id'] as String,
      gradoId: json['grado_id'] as String,
      titulo: json['titulo'] as String?,
      fechaInicio: DateTime.parse(json['fecha_inicio'] as String),
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lista_id': listaId,
      'grado_id': gradoId,
      'titulo': titulo,
      'fecha_inicio': fechaInicio.toIso8601String().split('T')[0],
      if (createdBy != null) 'created_by': createdBy,
    };
  }
}

class PortageResultado {
  final String id;
  final String evaluacionId;
  final String alumnoId;
  final String indicadorId;
  final String? estado;
  final String? observaciones;
  final String? actualizadoPor;
  final DateTime updatedAt;

  PortageResultado({
    required this.id,
    required this.evaluacionId,
    required this.alumnoId,
    required this.indicadorId,
    this.estado,
    this.observaciones,
    this.actualizadoPor,
    required this.updatedAt,
  });

  bool get esLogrado => PortageEstado.isLogrado(estado);
  bool get esEnProceso => PortageEstado.isEnProceso(estado);
  bool get sinCalificar => PortageEstado.isSinCalificar(estado);

  factory PortageResultado.fromJson(Map<String, dynamic> json) {
    return PortageResultado(
      id: json['id'] as String,
      evaluacionId: json['evaluacion_id'] as String,
      alumnoId: json['alumno_id'] as String,
      indicadorId: json['indicador_id'] as String,
      estado: PortageEstado.parse(json['estado'] as String?),
      observaciones: json['observaciones'] as String?,
      actualizadoPor: json['actualizado_por'] as String?,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'evaluacion_id': evaluacionId,
      'alumno_id': alumnoId,
      'indicador_id': indicadorId,
      'estado': estado,
      'observaciones': observaciones,
      if (actualizadoPor != null) 'actualizado_por': actualizadoPor,
    };
  }
}
