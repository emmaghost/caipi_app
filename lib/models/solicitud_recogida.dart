import '../utils/mexico_time.dart';

class SolicitudRecogida {
  final String id;
  final String alumnoId;
  final String padreId;
  final String estado;
  final String? mensaje;
  final DateTime createdAt;
  final DateTime? atendidaAt;
  final String? atendidaPor;
  /// `padre` | `qr` | `autorizado` | null
  final String? modalidadEntrega;
  final String? quienRecibio;
  final String? personaAutorizadaId;
  final String? quienNombre;
  final String? quienParentesco;
  final bool requiereCodigo;

  SolicitudRecogida({
    required this.id,
    required this.alumnoId,
    required this.padreId,
    this.estado = 'pendiente',
    this.mensaje,
    required this.createdAt,
    this.atendidaAt,
    this.atendidaPor,
    this.modalidadEntrega,
    this.quienRecibio,
    this.personaAutorizadaId,
    this.quienNombre,
    this.quienParentesco,
    this.requiereCodigo = false,
  });

  bool get esPendiente => estado == 'pendiente';
  bool get esNoCoincide => estado == 'no_coincide';

  String get quienVaTexto {
    final nombre = (quienNombre ?? '').trim();
    final parentesco = (quienParentesco ?? '').trim();
    if (nombre.isEmpty) return '';
    if (parentesco.isEmpty) return nombre;
    return '$nombre · $parentesco';
  }

  factory SolicitudRecogida.fromJson(Map<String, dynamic> json) {
    return SolicitudRecogida(
      id: json['id'] as String,
      alumnoId: json['alumno_id'] as String,
      padreId: json['padre_id'] as String,
      estado: json['estado'] as String? ?? 'pendiente',
      mensaje: json['mensaje'] as String?,
      createdAt: MexicoTime.parse(json['created_at'] as String),
      atendidaAt: json['atendida_at'] != null
          ? MexicoTime.parse(json['atendida_at'] as String)
          : null,
      atendidaPor: json['atendida_por'] as String?,
      modalidadEntrega: json['modalidad_entrega'] as String?,
      quienRecibio: json['quien_recibio'] as String?,
      personaAutorizadaId: json['persona_autorizada_id'] as String?,
      quienNombre: json['quien_nombre'] as String?,
      quienParentesco: json['quien_parentesco'] as String?,
      requiereCodigo: json['requiere_codigo'] as bool? ?? false,
    );
  }
}
