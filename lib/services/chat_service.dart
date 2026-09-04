import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/conversacion.dart';
import '../models/mensaje_chat.dart';
import '../utils/constantes.dart';

class ChatConfig {
  final bool padrePuedeDirectora;
  final bool padrePuedeMaestraGrupo;
  final bool padrePuedeMaestraIngles;

  const ChatConfig({
    this.padrePuedeDirectora = true,
    this.padrePuedeMaestraGrupo = true,
    this.padrePuedeMaestraIngles = true,
  });

  factory ChatConfig.fromJson(Map<String, dynamic> json) {
    return ChatConfig(
      padrePuedeDirectora: json['padre_puede_directora'] as bool? ?? true,
      padrePuedeMaestraGrupo:
          json['padre_puede_maestra_grupo'] as bool? ?? true,
      padrePuedeMaestraIngles:
          json['padre_puede_maestra_ingles'] as bool? ?? true,
    );
  }
}

class ChatService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Stream<List<Conversacion>> streamConversaciones({
    String? canal,
    String? staffId,
  }) {
    return _supabase
        .from('conversaciones')
        .stream(primaryKey: ['id'])
        .order('ultimo_mensaje_at', ascending: false)
        .map((rows) {
          var list = rows.map(Conversacion.fromJson).toList();
          if (canal != null) {
            list = list.where((c) => c.canal == canal).toList();
          }
          if (staffId != null) {
            list = list.where((c) => c.staffId == staffId).toList();
          }
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
          list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          return list;
        });
  }

  Future<Conversacion?> obtenerConversacionPorPadre(
    String padreId, {
    String canal = 'directora',
    String? staffId,
  }) async {
    var query = _supabase
        .from('conversaciones')
        .select()
        .eq('padre_id', padreId)
        .eq('canal', canal);

    if (canal == 'profesor' && staffId != null) {
      query = query.eq('staff_id', staffId);
    } else if (canal == 'directora') {
      query = query.isFilter('staff_id', null);
    }

    final response = await query.maybeSingle();
    return response != null ? Conversacion.fromJson(response) : null;
  }

  Future<Conversacion> obtenerOCrearConversacion(
    String padreId, {
    String canal = 'directora',
    String? staffId,
  }) async {
    final existente = await obtenerConversacionPorPadre(
      padreId,
      canal: canal,
      staffId: staffId,
    );
    if (existente != null) return existente;

    final payload = <String, dynamic>{
      'padre_id': padreId,
      'canal': canal,
      'staff_id': canal == 'profesor' ? staffId : null,
    };

    final response = await _supabase
        .from('conversaciones')
        .insert(payload)
        .select()
        .single();

    return Conversacion.fromJson(response);
  }

  Future<ChatConfig> obtenerChatConfig() async {
    try {
      final row = await _supabase
          .from('chat_config')
          .select()
          .eq('id', 1)
          .maybeSingle();
      if (row == null) return const ChatConfig();
      return ChatConfig.fromJson(Map<String, dynamic>.from(row));
    } catch (_) {
      return const ChatConfig();
    }
  }

  Future<void> guardarChatConfig({
    required bool padrePuedeDirectora,
    required bool padrePuedeMaestraGrupo,
    required bool padrePuedeMaestraIngles,
  }) async {
    await _supabase.from('chat_config').upsert({
      'id': 1,
      'padre_puede_directora': padrePuedeDirectora,
      'padre_puede_maestra_grupo': padrePuedeMaestraGrupo,
      'padre_puede_maestra_ingles': padrePuedeMaestraIngles,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  /// Contactos disponibles para el padre según [chat_config] y maestras de sus hijos.
  Future<List<Map<String, dynamic>>> contactosParaPadre(String padreId) async {
    final config = await obtenerChatConfig();
    final contactos = <Map<String, dynamic>>[];

    if (config.padrePuedeDirectora) {
      contactos.add({
        'canal': 'directora',
        'staffId': null,
        'titulo': 'Directora',
      });
    }

    if (!config.padrePuedeMaestraGrupo && !config.padrePuedeMaestraIngles) {
      return contactos;
    }

    // Hijos del padre (columna padre_id + alumnos_padres).
    final gradoIds = <String>{};
    try {
      final alumnos = await _supabase
          .from('alumnos')
          .select('id, grado_id')
          .eq('padre_id', padreId)
          .eq('activo', true);
      final alumnoIds = <String>[];
      for (final row in alumnos as List) {
        final gid = row['grado_id'] as String?;
        if (gid != null) gradoIds.add(gid);
        final aid = row['id'] as String?;
        if (aid != null) alumnoIds.add(aid);
      }
      if (alumnoIds.isNotEmpty) {
        try {
          final vinculos = await _supabase
              .from('alumnos_padres')
              .select('alumno_id')
              .eq('padre_id', padreId);
          final extraIds = (vinculos as List)
              .map((r) => r['alumno_id'] as String?)
              .whereType<String>()
              .where((id) => !alumnoIds.contains(id))
              .toList();
          if (extraIds.isNotEmpty) {
            final extras = await _supabase
                .from('alumnos')
                .select('grado_id')
                .inFilter('id', extraIds)
                .eq('activo', true);
            for (final row in extras as List) {
              final gid = row['grado_id'] as String?;
              if (gid != null) gradoIds.add(gid);
            }
          }
        } catch (_) {}
      }
    } catch (_) {
      return contactos;
    }

    if (gradoIds.isEmpty) return contactos;

    try {
      final profesores = await _supabase
          .from('profesores')
          .select('usuario_id, grado_id, especialidad, usuarios!inner(nombre, apellidos, activo)')
          .inFilter('grado_id', gradoIds.toList())
          .eq('activo', true);

      final vistosGrupo = <String>{};
      final vistosIngles = <String>{};

      for (final row in profesores as List) {
        final map = Map<String, dynamic>.from(row as Map);
        final usuarioId = map['usuario_id'] as String?;
        if (usuarioId == null) continue;
        final usuario = map['usuarios'];
        if (usuario is Map && usuario['activo'] == false) continue;

        final esp = ((map['especialidad'] as String?) ?? '')
            .toLowerCase()
            .replaceAll('é', 'e')
            .replaceAll('í', 'i');
        final esIngles =
            esp == Constantes.especialidadIngles || esp.contains('ingles');

        String nombreStaff = 'Maestra';
        if (usuario is Map) {
          final n = usuario['nombre'] as String? ?? '';
          final a = usuario['apellidos'] as String? ?? '';
          final full = '$n $a'.trim();
          if (full.isNotEmpty) nombreStaff = full;
        }

        if (esIngles) {
          if (!config.padrePuedeMaestraIngles) continue;
          if (vistosIngles.contains(usuarioId)) continue;
          vistosIngles.add(usuarioId);
          contactos.add({
            'canal': 'profesor',
            'staffId': usuarioId,
            'titulo': 'Maestra de inglés · $nombreStaff',
          });
        } else {
          if (!config.padrePuedeMaestraGrupo) continue;
          if (vistosGrupo.contains(usuarioId)) continue;
          vistosGrupo.add(usuarioId);
          contactos.add({
            'canal': 'profesor',
            'staffId': usuarioId,
            'titulo': 'Maestra de grupo · $nombreStaff',
          });
        }
      }
    } catch (_) {
      // Sin tabla profesores o RLS: solo directora.
    }

    return contactos;
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

  /// Envía el mismo texto a muchos padres (crea conversación canal directora).
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
        final conv = await obtenerOCrearConversacion(
          padreId,
          canal: 'directora',
        );
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
    final convs = await _supabase
        .from('conversaciones')
        .select('id')
        .eq('padre_id', padreId);

    final ids = (convs as List)
        .map((c) => c['id'] as String?)
        .whereType<String>()
        .toList();
    if (ids.isEmpty) return 0;

    final response = await _supabase
        .from('mensajes_chat')
        .select('id')
        .inFilter('conversacion_id', ids)
        .eq('leido', false)
        .neq('remitente_id', padreId);

    return (response as List).length;
  }
}
