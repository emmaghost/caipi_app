import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../utils/codigo_qr.dart';
import '../utils/mexico_time.dart';
import 'notificacion_entrega_service.dart';
import 'solicitud_recogida_service.dart';

class ResultadoQrSalida {
  const ResultadoQrSalida({
    required this.salidaRegistrada,
    required this.avisoEnviado,
    required this.mensaje,
    this.alumnoId,
  });

  final bool salidaRegistrada;
  final bool avisoEnviado;
  final String mensaje;
  final String? alumnoId;
}

/// Valida el QR vigente y, si sirve, registra la salida sin abrir el formulario.
class QrSalidaService {
  QrSalidaService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<ResultadoQrSalida> procesar(
    String raw, {
    String? alumnoEsperadoId,
  }) async {
    final codigo = codigoDesdeEscaneo(raw);
    if (codigo == null) {
      return const ResultadoQrSalida(
        salidaRegistrada: false,
        avisoEnviado: false,
        mensaje:
            'Este QR no es de CAIPI. Pide que generen uno nuevo en la app.',
      );
    }

    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      return const ResultadoQrSalida(
        salidaRegistrada: false,
        avisoEnviado: false,
        mensaje: 'Inicia sesión de nuevo para escanear el QR.',
      );
    }

    late final Map<String, dynamic> data;
    try {
      final rawRpc = await _client.rpc(
        'validar_qr_temporal',
        params: {
          'p_codigo': codigo,
          'p_usuario_id': uid,
          'p_alumno_esperado': alumnoEsperadoId,
        },
      );
      data = _comoMapa(rawRpc);
    } catch (_) {
      return const ResultadoQrSalida(
        salidaRegistrada: false,
        avisoEnviado: false,
        mensaje: 'No se pudo validar el QR. Intenta de nuevo.',
      );
    }

    if (data['valido'] != true) {
      return _rechazo(data);
    }

    final alumnoId = data['alumno_id'] as String?;
    if (alumnoId == null || alumnoId.isEmpty) {
      return const ResultadoQrSalida(
        salidaRegistrada: false,
        avisoEnviado: false,
        mensaje:
            'Este QR no trae al niño. Pide que generen uno nuevo en la app.',
      );
    }

    final personaId = data['persona_autorizada_id'] as String?;
    final nombrePersona = await _nombrePersona(personaId);
    final nombreAlumno = await _nombreAlumno(alumnoId);

    try {
      await _registrarSalida(
        alumnoId: alumnoId,
        quienRecogio: nombrePersona,
        personaAutorizadaId: personaId,
        nota: 'Entregado por QR ($codigo)',
      );
    } catch (_) {
      final aviso = await _avisarGenerarNuevo(
        generadoPor: data['generado_por'] as String?,
        alumnoId: alumnoId,
      );
      return ResultadoQrSalida(
        salidaRegistrada: false,
        avisoEnviado: aviso,
        alumnoId: alumnoId,
        mensaje: aviso
            ? 'El QR era válido, pero la salida no se guardó. Ya avisamos para que generen uno nuevo.'
            : 'El QR era válido, pero la salida no se guardó. Pide que generen uno nuevo.',
      );
    }

    try {
      await SolicitudRecogidaService().cerrarPendientesDeAlumno(
        alumnoId: alumnoId,
        atendidaPorId: uid,
        modalidadEntrega: 'qr',
        quienRecibio: nombrePersona,
      );
    } catch (_) {}

    try {
      await NotificacionEntregaService(client: _client).avisarNinoRecogido(
        alumnoId: alumnoId,
        quienRecibio: nombrePersona,
        fechaSalida: DateTime.now(),
      );
    } catch (_) {}

    return ResultadoQrSalida(
      salidaRegistrada: true,
      avisoEnviado: false,
      alumnoId: alumnoId,
      mensaje: '$nombrePersona recogió a $nombreAlumno.',
    );
  }

  Future<ResultadoQrSalida> _rechazo(Map<String, dynamic> data) async {
    final motivo = data['motivo'] as String? ?? '';
    if (motivo == 'sin_permiso') {
      return const ResultadoQrSalida(
        salidaRegistrada: false,
        avisoEnviado: false,
        mensaje: 'Solo la profesora o la directora pueden escanear este QR.',
      );
    }
    if (motivo == 'otro_nino') {
      return const ResultadoQrSalida(
        salidaRegistrada: false,
        avisoEnviado: false,
        mensaje:
            'Ese QR es de otro niño. No se usó. Escanea el QR de este niño.',
      );
    }
    if (motivo == 'no_existe') {
      return const ResultadoQrSalida(
        salidaRegistrada: false,
        avisoEnviado: false,
        mensaje:
            'Este QR no es válido. Pide que generen uno nuevo en la app.',
      );
    }

    final aviso = await _avisarGenerarNuevo(
      generadoPor: data['generado_por'] as String?,
      alumnoId: data['alumno_id'] as String?,
    );
    return ResultadoQrSalida(
      salidaRegistrada: false,
      avisoEnviado: aviso,
      mensaje: aviso
          ? 'Este QR ya no está vigente. Avisamos para que generen uno nuevo.'
          : 'Este QR ya no está vigente. Pide que generen uno nuevo en la app.',
    );
  }

  Future<bool> _avisarGenerarNuevo({
    String? generadoPor,
    String? alumnoId,
  }) async {
    final ids = <String>{};
    if (generadoPor != null && generadoPor.isNotEmpty) ids.add(generadoPor);
    if (alumnoId != null && alumnoId.isNotEmpty) {
      try {
        final alumno = await _client
            .from('alumnos')
            .select('padre_id')
            .eq('id', alumnoId)
            .maybeSingle();
        final padreId = alumno?['padre_id'] as String?;
        if (padreId != null && padreId.isNotEmpty) ids.add(padreId);
      } catch (_) {}
      try {
        final rows = await _client
            .from('alumnos_padres')
            .select('padre_id')
            .eq('alumno_id', alumnoId);
        for (final row in rows as List) {
          final padreId = row['padre_id'] as String?;
          if (padreId != null && padreId.isNotEmpty) ids.add(padreId);
        }
      } catch (_) {}
    }
    if (ids.isEmpty) return false;
    try {
      await _client.functions.invoke(
        'notify-chat',
        body: {
          'title': 'El QR no es válido',
          'body':
              'Ese código no sirve para la salida. Genera uno nuevo en la app.',
          'usuario_ids': ids.toList(),
        },
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _registrarSalida({
    required String alumnoId,
    required String quienRecogio,
    String? personaAutorizadaId,
    required String nota,
  }) async {
    final hoy = MexicoTime.ymd(MexicoTime.now());
    final ahora = MexicoTime.hms(MexicoTime.now());
    final existente = await _client
        .from('control_salidas')
        .select('id')
        .eq('alumno_id', alumnoId)
        .eq('fecha', hoy)
        .maybeSingle();

    final payload = <String, dynamic>{
      'alumno_id': alumnoId,
      'fecha': hoy,
      'ausente': false,
      'hora_salida': ahora,
      'quien_recogio': quienRecogio,
      'persona_autorizada_id': personaAutorizadaId,
      'observaciones': nota,
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (existente != null) {
      await _client
          .from('control_salidas')
          .update(payload)
          .eq('id', existente['id'] as String);
      return;
    }

    payload['id'] = const Uuid().v4();
    payload['created_at'] = DateTime.now().toIso8601String();
    payload['hora_entrada'] = ahora;
    payload['quien_trajo'] = null;
    await _client.from('control_salidas').insert(payload);
  }

  Future<String> _nombrePersona(String? personaId) async {
    if (personaId == null || personaId.isEmpty) return 'Persona autorizada';
    try {
      final persona = await _client
          .from('personas_autorizadas')
          .select('nombre')
          .eq('id', personaId)
          .maybeSingle();
      final nombre = (persona?['nombre'] as String?)?.trim();
      if (nombre != null && nombre.isNotEmpty) return nombre;
    } catch (_) {}
    return 'Persona autorizada';
  }

  Future<String> _nombreAlumno(String alumnoId) async {
    try {
      final alumno = await _client
          .from('alumnos')
          .select('nombre, apellidos')
          .eq('id', alumnoId)
          .maybeSingle();
      if (alumno != null) {
        final nombre =
            '${alumno['nombre'] ?? ''} ${alumno['apellidos'] ?? ''}'.trim();
        if (nombre.isNotEmpty) return nombre;
      }
    } catch (_) {}
    return 'el niño';
  }

  Map<String, dynamic> _comoMapa(dynamic raw) {
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is String && raw.isNotEmpty) {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    }
    throw StateError('Respuesta inesperada');
  }
}
