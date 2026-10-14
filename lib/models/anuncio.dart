import 'dart:convert';

import 'package:flutter/material.dart';

import 'mensaje_chat.dart';

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

  bool visibleParaPadre(Set<String> gradoIdsHijos) {
    if (paraTodos) return true;
    if (paraGrados.isEmpty) return false;
    return paraGrados.any(gradoIdsHijos.contains);
  }

  bool fueLeidoPor(String usuarioId) {
    final id = usuarioId.trim();
    if (id.isEmpty) return false;
    return leidoPor.any((e) => e.trim() == id);
  }

  /// Acepta list, JSON o texto `{uuid,uuid}` de Postgres.
  static List<String> parseLeidoPor(dynamic raw) {
    if (raw == null) return const [];
    if (raw is List) {
      return raw
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    final t = raw.toString().trim();
    if (t.isEmpty || t == '{}' || t == '[]') return const [];
    if (t.startsWith('{') && t.endsWith('}')) {
      return t
          .substring(1, t.length - 1)
          .split(',')
          .map((e) => e.trim().replaceAll('"', ''))
          .where((e) => e.isNotEmpty)
          .toList();
    }
    if (t.startsWith('[') && t.endsWith(']')) {
      try {
        final decoded = jsonDecode(t);
        if (decoded is List) return parseLeidoPor(decoded);
      } catch (_) {}
    }
    return const [];
  }

  String get mensajeVisible => MensajeChat.textoSinFoto(mensaje);

  String? get urlFoto => MensajeChat.urlFotoEn(mensaje);

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
    final grados = _parseGrados(json);
    final paraTodosRaw = json['para_todos'];
    final bool paraTodos;
    if (paraTodosRaw is bool) {
      paraTodos = paraTodosRaw;
    } else if (paraTodosRaw != null &&
        '$paraTodosRaw'.toLowerCase() == 'true') {
      paraTodos = true;
    } else if (paraTodosRaw != null &&
        '$paraTodosRaw'.toLowerCase() == 'false') {
      paraTodos = false;
    } else if (grados.isNotEmpty) {
      // Hay grados destino → no es para toda la escuela
      paraTodos = false;
    } else {
      // Sin flag y sin grados: no filtrar como “toda la escuela”
      // (antes default true filtraba mal y lo veían otros grupos).
      paraTodos = false;
    }
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
      leidoPor: parseLeidoPor(json['leido_por']),
      creadoPor: json['creado_por']?.toString() ?? '',
      paraTodos: paraTodos,
      paraGrados: grados,
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
