import 'package:flutter/material.dart';

class Calificacion {
  final String id;
  final String alumnoId;
  final String materia;
  final double calificacion;
  final String periodo;
  final String? comentarios;
  final DateTime fecha;

  Calificacion({
    required this.id,
    required this.alumnoId,
    required this.materia,
    required this.calificacion,
    required this.periodo,
    this.comentarios,
    required this.fecha,
  });

  String get desempenio {
    if (calificacion >= 9.0) return 'Excelente';
    if (calificacion >= 8.0) return 'Muy bien';
    if (calificacion >= 7.0) return 'Bien';
    if (calificacion >= 6.0) return 'Suficiente';
    return 'Necesita mejorar';
  }

  Color get color {
    if (calificacion >= 9.0) return const Color(0xFF10B981); // Verde
    if (calificacion >= 8.0) return const Color(0xFF3B82F6); // Azul
    if (calificacion >= 7.0) return const Color(0xFFF59E0B); // Amarillo
    if (calificacion >= 6.0) return const Color(0xFFEF4444); // Rojo
    return const Color(0xFF991B1B); // Rojo oscuro
  }

  factory Calificacion.fromJson(Map<String, dynamic> json) {
    return Calificacion(
      id: json['id'] ?? '',
      alumnoId: json['alumno_id'] ?? '',
      materia: json['materia'] ?? '',
      calificacion: (json['calificacion'] ?? 0).toDouble(),
      periodo: json['periodo'] ?? '',
      comentarios: json['comentarios'],
      fecha: DateTime.parse(json['fecha'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'alumno_id': alumnoId,
      'materia': materia,
      'calificacion': calificacion,
      'periodo': periodo,
      'comentarios': comentarios,
      'fecha': fecha.toIso8601String(),
    };
  }
}
