import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/conversacion.dart';
import '../models/mensaje_chat.dart';

class ChatService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Stream<List<Conversacion>> streamConversaciones() {
    return _supabase
        .from('conversaciones')
        .stream(primaryKey: ['id'])
        .order('ultimo_mensaje_at', ascending: false)
        .map((rows) {
          final list = rows.map(Conversacion.fromJson).toList();
          // Más reciente arriba (como bandeja de chats).
          list.sort((a, b) {
            final fa = a.ultimoMensajeAt ?? a.updatedAt;
            final fb = b.ultimoMensajeAt ?? b.updatedAt;
            return fb.compareTo(fa);
          });
          return list;
        });
  }

  Stream<List<MensajeChat>> streamMensajes(String conversacionId) {
    return _supabase
        .from('mensajes_chat')
        .stream(primaryKey: ['id'])
        .eq('conversacion_id', conversacionId)
        .order('created_at', ascending: true)
        .map((rows) {
          final list = rows.map(MensajeChat.fromJson).toList();
          // El stream a veces no respeta el order; forzar cronológico (viejo → nuevo).
          list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          return list;
        });
  }

  Future<Conversacion?> obtenerConversacionPorPadre(String padreId) async {
    final response = await _supabase
        .from('conversaciones')
        .select()
        .eq('padre_id', padreId)
        .maybeSingle();

    return response != null ? Conversacion.fromJson(response) : null;
  }

  Future<Conversacion> obtenerOCrearConversacion(String padreId) async {
    final existente = await obtenerConversacionPorPadre(padreId);
    if (existente != null) return existente;

    final response = await _supabase
        .from('conversaciones')
        .insert({'padre_id': padreId})
        .select()
        .single();

    return Conversacion.fromJson(response);
  }

  Future<MensajeChat> enviarMensaje({
    required String conversacionId,
    required String remitenteId,
    required String contenido,
    bool omitirHorario = false,
  }) async {
    final texto = contenido.trim();
    if (texto.isEmpty) {
      throw ArgumentError('El mensaje no puede estar vacío');
    }

    if (!omitirHorario) {
      try {
        final puede = await _supabase.rpc(
          'usuario_puede_enviar_chat',
          params: {'p_usuario_id': remitenteId},
        );
        if (puede == false) {
          throw StateError(
            'FUERA_HORARIO',
          );
        }
      } catch (e) {
        if (e is StateError && e.message == 'FUERA_HORARIO') rethrow;
        // Si la función no existe aún, permitir envío
      }
    }

    final response = await _supabase
        .from('mensajes_chat')
        .insert({
          'conversacion_id': conversacionId,
          'remitente_id': remitenteId,
          'contenido': texto,
        })
        .select()
        .single();

    return MensajeChat.fromJson(response);
  }

  /// IDs de padres activos: todos o solo los de los grados indicados (incluye 2º papá).
  Future<List<String>> idsPadresDestino({
    required bool paraTodos,
    List<String> gradoIds = const [],
  }) async {
    if (paraTodos) {
      final rows = await _supabase
          .from('usuarios')
          .select('id')
          .eq('rol', 'padre')
          .eq('activo', true);
      return (rows as List)
          .map((r) => r['id'] as String)
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();
    }

    if (gradoIds.isEmpty) return const [];

    final alumnos = await _supabase
        .from('alumnos')
        .select('id, padre_id')
        .inFilter('grado_id', gradoIds)
        .eq('activo', true);

    final ids = <String>{};
    final alumnoIds = <String>[];
    for (final row in alumnos as List) {
      final pid = row['padre_id'] as String?;
      if (pid != null && pid.isNotEmpty) ids.add(pid);
      final aid = row['id'] as String?;
      if (aid != null) alumnoIds.add(aid);
    }

    if (alumnoIds.isNotEmpty) {
      try {
        final vinculos = await _supabase
            .from('alumnos_padres')
            .select('padre_id')
            .inFilter('alumno_id', alumnoIds);
        for (final row in vinculos as List) {
          final pid = row['padre_id'] as String?;
          if (pid != null && pid.isNotEmpty) ids.add(pid);
        }
      } catch (_) {
        // Tabla alumnos_padres aún no existe.
      }
    }

    return ids.toList();
  }

  /// Envía el mismo texto a muchos padres (crea conversación si falta).
  /// Devuelve cuántos envíos tuvieron éxito.
  Future<int> enviarMensajeMasivoAPadres({
    required String remitenteId,
    required String contenido,
    required bool paraTodos,
    List<String> gradoIds = const [],
    List<String>? soloPadreIds,
    bool omitirHorario = true,
  }) async {
    final texto = contenido.trim();
    if (texto.isEmpty) return 0;

    var padreIds = soloPadreIds ??
        await idsPadresDestino(paraTodos: paraTodos, gradoIds: gradoIds);

    // Si vienen IDs sueltos, dejar solo papás activos.
    if (soloPadreIds != null && soloPadreIds.isNotEmpty) {
      final activos = await _supabase
          .from('usuarios')
          .select('id')
          .eq('rol', 'padre')
          .eq('activo', true)
          .inFilter('id', soloPadreIds);
      padreIds = (activos as List)
          .map((r) => r['id'] as String)
          .where((id) => id.isNotEmpty)
          .toList();
    }

    if (padreIds.isEmpty) return 0;

    var enviados = 0;
    Object? ultimoError;
    for (final padreId in padreIds) {
      try {
        final conv = await obtenerOCrearConversacion(padreId);
        await enviarMensaje(
          conversacionId: conv.id,
          remitenteId: remitenteId,
          contenido: texto,
          omitirHorario: omitirHorario,
        );
        enviados++;
      } catch (e) {
        ultimoError = e;
      }
    }

    if (enviados == 0 && ultimoError != null) {
      throw StateError(
        'No se pudo enviar el mensaje masivo. $ultimoError',
      );
    }
    return enviados;
  }

  Future<void> marcarMensajesLeidos({
    required String conversacionId,
    required String lectorId,
  }) async {
    await _supabase
        .from('mensajes_chat')
        .update({'leido': true})
        .eq('conversacion_id', conversacionId)
        .neq('remitente_id', lectorId)
        .eq('leido', false);
  }

  Future<int> contarNoLeidosEscuela() async {
    final idsPadres = await _supabase
        .from('usuarios')
        .select('id')
        .eq('rol', 'padre');

    final padreIds = (idsPadres as List).map((u) => u['id'] as String).toSet();
    if (padreIds.isEmpty) return 0;

    final response = await _supabase
        .from('mensajes_chat')
        .select('id, remitente_id')
        .eq('leido', false);

    var count = 0;
    for (final m in response as List) {
      final remitenteId = m['remitente_id'] as String?;
      if (remitenteId != null && padreIds.contains(remitenteId)) {
        count++;
      }
    }
    return count;
  }

  /// Conversaciones con mensajes de papás aún no leídos por la escuela.
  Future<Set<String>> idsConversacionesNoLeidasEscuela() async {
    final idsPadres = await _supabase
        .from('usuarios')
        .select('id')
        .eq('rol', 'padre');

    final padreIds = (idsPadres as List).map((u) => u['id'] as String).toSet();
    if (padreIds.isEmpty) return {};

    final response = await _supabase
        .from('mensajes_chat')
        .select('conversacion_id, remitente_id')
        .eq('leido', false);

    final convIds = <String>{};
    for (final m in response as List) {
      final remitenteId = m['remitente_id'] as String?;
      final convId = m['conversacion_id'] as String?;
      if (convId != null &&
          remitenteId != null &&
          padreIds.contains(remitenteId)) {
        convIds.add(convId);
      }
    }
    return convIds;
  }

  /// Stream de IDs de conversación con mensajes no leídos de papás.
  Stream<Set<String>> streamConversacionesNoLeidasEscuela() {
    return _supabase
        .from('mensajes_chat')
        .stream(primaryKey: ['id'])
        .asyncMap((rows) async {
      final idsPadres = await _supabase
          .from('usuarios')
          .select('id')
          .eq('rol', 'padre');
      final padreIds =
          (idsPadres as List).map((u) => u['id'] as String).toSet();
      final convIds = <String>{};
      for (final m in rows) {
        if (m['leido'] == true) continue;
        final remitenteId = m['remitente_id'] as String?;
        final convId = m['conversacion_id'] as String?;
        if (convId != null &&
            remitenteId != null &&
            padreIds.contains(remitenteId)) {
          convIds.add(convId);
        }
      }
      return convIds;
    });
  }

  Future<int> contarNoLeidosPadre(String padreId) async {
    final conv = await obtenerConversacionPorPadre(padreId);
    if (conv == null) return 0;

    final response = await _supabase
        .from('mensajes_chat')
        .select('id')
        .eq('conversacion_id', conv.id)
        .eq('leido', false)
        .neq('remitente_id', padreId);

    return (response as List).length;
  }
}
