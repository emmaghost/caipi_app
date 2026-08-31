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
  final bool paraTodos;
  final List<String> paraGrados;

  Anuncio({
    required this.id,
    required this.titulo,
    required this.mensaje,
    this.prioridad = PrioridadAnuncio.normal,
    required this.fechaPublicacion,
    this.fechaEvento,
    this.leidoPor = const [],
    this.creadoPor = '',
    this.paraTodos = true,
    this.paraGrados = const [],
  });

  bool fueLeidoPor(String usuarioId) {
    return leidoPor.contains(usuarioId);
  }

  Color get prioridadColor {
    return prioridad == PrioridadAnuncio.alta
        ? const Color(0xFFEF4444)
        : const Color(0xFF6366F1);
  }

  String get prioridadTexto {
    return prioridad == PrioridadAnuncio.alta ? 'Urgente' : 'Normal';
  }

  static DateTime _parseFecha(Map<String, dynamic> json) {
    final raw = json['fecha_publicacion'] ?? json['fecha'];
    if (raw == null) return DateTime.now();
    return DateTime.tryParse(raw.toString()) ?? DateTime.now();
  }

  static List<String> _parseGrados(Map<String, dynamic> json) {
    final raw = json['para_grados'] ?? json['grados'];
    if (raw is! List) return const [];
    return raw.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
  }

  factory Anuncio.fromJson(Map<String, dynamic> json) {
    return Anuncio(
      id: json['id']?.toString() ?? '',
      titulo: json['titulo']?.toString() ?? '',
      mensaje: json['mensaje']?.toString() ?? '',
      prioridad: json['prioridad'] == 'alta'
          ? PrioridadAnuncio.alta
          : PrioridadAnuncio.normal,
      fechaPublicacion: _parseFecha(json),
      fechaEvento: json['fecha_evento'] != null
          ? DateTime.tryParse(json['fecha_evento'].toString())
          : null,
      leidoPor: json['leido_por'] != null
          ? List<String>.from(json['leido_por'] as List)
          : const [],
      creadoPor: json['creado_por']?.toString() ?? '',
      paraTodos: json['para_todos'] as bool? ?? true,
      paraGrados: _parseGrados(json),
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
      'creado_por': creadoPor.isEmpty ? null : creadoPor,
      'para_todos': paraTodos,
      'para_grados': paraTodos ? <String>[] : paraGrados,
    };
  }
}
