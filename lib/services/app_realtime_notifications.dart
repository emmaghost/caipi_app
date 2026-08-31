import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_service.dart';
import 'notification_service.dart';

/// Escucha mensajes de chat y solicitudes de recogida; muestra notificación local.
class AppRealtimeNotifications extends StatefulWidget {
  final AuthService authService;
  final NotificationService notificationService;
  final Widget child;

  const AppRealtimeNotifications({
    super.key,
    required this.authService,
    required this.notificationService,
    required this.child,
  });

  @override
  State<AppRealtimeNotifications> createState() => _AppRealtimeNotificationsState();
}

class _AppRealtimeNotificationsState extends State<AppRealtimeNotifications> {
  StreamSubscription<List<Map<String, dynamic>>>? _chatSub;
  StreamSubscription<List<Map<String, dynamic>>>? _solicitudSub;
  final Set<String> _mensajesConocidos = {};
  final Set<String> _solicitudesConocidas = {};
  bool _chatPrimeraCarga = true;
  bool _solicitudPrimeraCarga = true;
  String? _usuarioId;
  bool _esEscuela = false;
  // Para profesores: solo notificar solicitudes del grado asignado
  String? _gradoIdProfesor;

  @override
  void initState() {
    super.initState();
    widget.authService.addListener(_reconfigurar);
    _reconfigurar();
  }

  @override
  void dispose() {
    widget.authService.removeListener(_reconfigurar);
    _chatSub?.cancel();
    _solicitudSub?.cancel();
    super.dispose();
  }

  void _reconfigurar() {
    _chatSub?.cancel();
    _solicitudSub?.cancel();
    _mensajesConocidos.clear();
    _solicitudesConocidas.clear();
    _chatPrimeraCarga = true;
    _solicitudPrimeraCarga = true;
    _gradoIdProfesor = null;

    final user = widget.authService.currentUser;
    if (user == null) {
      _usuarioId = null;
      return;
    }

    _usuarioId = user.id;
    _esEscuela = user.esDirectora ||
        user.esProfesorAdmin ||
        (user.esProfesor && !user.esMaestraIngles);

    if (!user.esMaestraIngles && !user.esSecretaria) {
      _chatSub = Supabase.instance.client
          .from('mensajes_chat')
          .stream(primaryKey: ['id'])
          .order('created_at')
          .listen(_onMensajesChat);
    }

    if (_esEscuela) {
      if (user.esProfesor) {
        // Cargar grado PRIMERO, luego suscribir al stream
        // para evitar race condition (notificar de grados ajenos)
        _cargarGradoYSuscribir(user.id);
      } else {
        // Directora: suscribir de inmediato sin filtro
        _suscribirSolicitudes();
      }
    }
  }

  Future<void> _cargarGradoYSuscribir(String usuarioId) async {
    try {
      final rows = await Supabase.instance.client
          .from('profesores')
          .select('grado_id')
          .eq('usuario_id', usuarioId)
          .eq('activo', true)
          .limit(1);
      final list = List<Map<String, dynamic>>.from(rows as List);
      _gradoIdProfesor =
          list.isEmpty ? null : list.first['grado_id'] as String?;
    } catch (_) {}
    // Suscribir después de tener el grado
    _suscribirSolicitudes();
  }

  void _suscribirSolicitudes() {
    _solicitudSub = Supabase.instance.client
        .from('solicitudes_recogida')
        .stream(primaryKey: ['id'])
        .eq('estado', 'pendiente')
        .order('created_at', ascending: false)
        .listen(_onSolicitudes);
  }

  Future<void> _onMensajesChat(List<Map<String, dynamic>> rows) async {
    final userId = _usuarioId;
    if (userId == null) return;

    for (final row in rows) {
      final id = row['id']?.toString();
      if (id == null || _mensajesConocidos.contains(id)) continue;
      _mensajesConocidos.add(id);

      if (_chatPrimeraCarga) continue;

      final remitenteId = row['remitente_id']?.toString();
      if (remitenteId == null || remitenteId == userId) continue;

      final contenido = (row['contenido'] as String?) ?? 'Nuevo mensaje';
      final preview = contenido.length > 80 ? '${contenido.substring(0, 80)}…' : contenido;

      await widget.notificationService.notificarNuevoMensajeChat(
        remitenteEsPadre: _esEscuela,
        preview: preview,
      );
    }
    _chatPrimeraCarga = false;
  }

  Future<void> _onSolicitudes(List<Map<String, dynamic>> rows) async {
    if (!_esEscuela) return;

    for (final row in rows) {
      final id = row['id']?.toString();
      if (id == null || _solicitudesConocidas.contains(id)) continue;
      _solicitudesConocidas.add(id);

      if (_solicitudPrimeraCarga) continue;

      final alumnoId = row['alumno_id']?.toString();
      if (alumnoId == null) continue;

      // Si es profesor, solo notificar si el alumno es de su grado
      if (_gradoIdProfesor != null) {
        try {
          final alumnoRow = await Supabase.instance.client
              .from('alumnos')
              .select('grado_id')
              .eq('id', alumnoId)
              .maybeSingle();
          final gradoAlumno = alumnoRow?['grado_id'] as String?;
          if (gradoAlumno != _gradoIdProfesor) continue;
        } catch (_) {
          continue;
        }
      }

      String nombreAlumno = 'un alumno';
      try {
        final alumno = await Supabase.instance.client
            .from('alumnos')
            .select('nombre, apellidos')
            .eq('id', alumnoId)
            .maybeSingle();
        if (alumno != null) {
          final n = alumno['nombre'] as String? ?? '';
          final a = alumno['apellidos'] as String?;
          nombreAlumno = a != null && a.isNotEmpty ? '$n $a' : n;
        }
      } catch (_) {}

      await widget.notificationService.notificarSolicitudRecogida(
        nombreAlumno: nombreAlumno,
      );
    }
    _solicitudPrimeraCarga = false;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
