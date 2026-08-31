import 'package:supabase_flutter/supabase_flutter.dart';

class ConfigChatHorario {
  final bool activo;
  final List<int> diasActivos;
  final String horaInicio; // HH:mm
  final String horaFin;
  final String zonaHoraria;
  final bool staffSiemprePuede;
  final String mensajeFueraHorario;

  ConfigChatHorario({
    required this.activo,
    required this.diasActivos,
    required this.horaInicio,
    required this.horaFin,
    required this.zonaHoraria,
    required this.staffSiemprePuede,
    required this.mensajeFueraHorario,
  });

  factory ConfigChatHorario.fromJson(Map<String, dynamic> json) {
    final dias = json['dias_activos'];
    return ConfigChatHorario(
      activo: json['activo'] as bool? ?? true,
      diasActivos: dias is List
          ? dias.map((e) => int.tryParse('$e') ?? 0).where((e) => e > 0).toList()
          : const [1, 2, 3, 4, 5],
      horaInicio: _soloHora(json['hora_inicio']),
      horaFin: _soloHora(json['hora_fin']),
      zonaHoraria: json['zona_horaria'] as String? ?? 'America/Mexico_City',
      staffSiemprePuede: json['staff_siempre_puede'] as bool? ?? true,
      mensajeFueraHorario: json['mensaje_fuera_horario'] as String? ??
          'El chat está disponible en horario escolar.',
    );
  }

  static String _soloHora(dynamic v) {
    if (v == null) return '08:00';
    final s = v.toString();
    if (s.length >= 5) return s.substring(0, 5);
    return s;
  }

  String get resumenDias {
    const nombres = {
      1: 'Lun',
      2: 'Mar',
      3: 'Mié',
      4: 'Jue',
      5: 'Vie',
      6: 'Sáb',
      7: 'Dom',
    };
    if (diasActivos.length == 5 &&
        diasActivos.contains(1) &&
        diasActivos.contains(5) &&
        !diasActivos.contains(6) &&
        !diasActivos.contains(7)) {
      return 'Lun–Vie';
    }
    return diasActivos.map((d) => nombres[d] ?? '$d').join(', ');
  }
}

class ChatHorarioService {
  final _client = Supabase.instance.client;

  Future<ConfigChatHorario> obtenerConfig() async {
    try {
      final row = await _client
          .from('config_chat_horario')
          .select()
          .eq('id', 1)
          .maybeSingle();
      if (row == null) {
        return ConfigChatHorario(
          activo: true,
          diasActivos: const [1, 2, 3, 4, 5],
          horaInicio: '08:00',
          horaFin: '16:00',
          zonaHoraria: 'America/Mexico_City',
          staffSiemprePuede: true,
          mensajeFueraHorario:
              'El chat está disponible de lunes a viernes de 8:00 a 16:00.',
        );
      }
      return ConfigChatHorario.fromJson(row);
    } catch (_) {
      return ConfigChatHorario(
        activo: false,
        diasActivos: const [1, 2, 3, 4, 5],
        horaInicio: '08:00',
        horaFin: '16:00',
        zonaHoraria: 'America/Mexico_City',
        staffSiemprePuede: true,
        mensajeFueraHorario: 'Chat disponible.',
      );
    }
  }

  Future<bool> usuarioPuedeEnviar(String usuarioId) async {
    try {
      final r = await _client.rpc(
        'usuario_puede_enviar_chat',
        params: {'p_usuario_id': usuarioId},
      );
      return r == true;
    } catch (_) {
      // Si aún no corrieron el SQL, no bloquear el chat
      return true;
    }
  }

  Future<void> guardarConfig({
    required bool activo,
    required List<int> diasActivos,
    required String horaInicio,
    required String horaFin,
    required bool staffSiemprePuede,
    required String mensajeFueraHorario,
    String? updatedBy,
  }) async {
    final payload = {
      'activo': activo,
      'dias_activos': diasActivos,
      'hora_inicio': horaInicio,
      'hora_fin': horaFin,
      'zona_horaria': 'America/Mexico_City',
      'staff_siempre_puede': staffSiemprePuede,
      'mensaje_fuera_horario': mensajeFueraHorario,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
      if (updatedBy != null) 'updated_by': updatedBy,
    };

    // Preferir UPDATE (fila id=1 ya insertada por SQL). UPSERT exige INSERT RLS.
    final updated = await _client
        .from('config_chat_horario')
        .update(payload)
        .eq('id', 1)
        .select('id');

    if (updated.isEmpty) {
      await _client.from('config_chat_horario').upsert({
        'id': 1,
        ...payload,
      });
    }
  }
}
