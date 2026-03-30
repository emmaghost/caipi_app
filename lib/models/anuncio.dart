import 'package:flutter/material.dart';

enum PrioridadAnuncio {
  alta,
  normal,
}

class Anuncio {
  final String id;
  final String titulo;
  final String mensaje;
  final PrioridadAnuncio prioridad;
  final DateTime fechaPublicacion;
  final DateTime? fechaEvento;
  final List<String> leidoPor;
  final String creadoPor;

  Anuncio({
    required this.id,
    required this.titulo,
    required this.mensaje,
    this.prioridad = PrioridadAnuncio.normal,
    required this.fechaPublicacion,
    this.fechaEvento,
    this.leidoPor = const [],
    required this.creadoPor,
  });

  bool fueLeidoPor(String usuarioId) {
    return leidoPor.contains(usuarioId);
  }

  Color get prioridadColor {
    return prioridad == PrioridadAnuncio.alta
        ? const Color(0xFFEF4444) // Rojo
        : const Color(0xFF6366F1); // Indigo
  }

  String get prioridadTexto {
    return prioridad == PrioridadAnuncio.alta ? 'Urgente' : 'Normal';
  }

  factory Anuncio.fromJson(Map<String, dynamic> json) {
    return Anuncio(
      id: json['id'] ?? '',
      titulo: json['titulo'] ?? '',
      mensaje: json['mensaje'] ?? '',
      prioridad: json['prioridad'] == 'alta' 
          ? PrioridadAnuncio.alta 
          : PrioridadAnuncio.normal,
      fechaPublicacion: DateTime.parse(json['fecha_publicacion'] ?? DateTime.now().toIso8601String()),
      fechaEvento: json['fecha_evento'] != null
          ? DateTime.parse(json['fecha_evento'])
          : null,
      leidoPor: json['leido_por'] != null ? List<String>.from(json['leido_por']) : [],
      creadoPor: json['creado_por'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'mensaje': mensaje,
      'prioridad': prioridad == PrioridadAnuncio.alta ? 'alta' : 'normal',
      'fecha_publicacion': fechaPublicacion.toIso8601String(),
      'fecha_evento': fechaEvento?.toIso8601String(),
      'leido_por': leidoPor,
      'creado_por': creadoPor,
    };
  }
}
