import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_service.dart';
import 'notification_service.dart';
import 'profesor_grupos_service.dart';
import '../models/mensaje_chat.dart';

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
  bool _esDirectora = false;
  /// Grados de la profesora. Vacío = no avisar solicitudes de otros grupos.
  Set<String>? _gradoIdsProfesor;

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
    _gradoIdsProfesor = null;
    _esDirectora = false;

    final user = widget.authService.currentUser;
    if (user == null) {
      _usuarioId = null;
      return;
    }

    _usuarioId = user.id;
    _esDirectora = user.esDirectora;
    _esEscuela = user.esDirectora ||
        user.esProfesorAdmin ||
        (user.esProfesor && !user.esMaestraIngles);

    // Chat: directora, maestras (incl. inglés/música) y padres. No secretaria/caja.
    if (!user.esSecretaria && !user.esCaja) {
      _chatSub = Supabase.instance.client
          .from('mensajes_chat')
          .stream(primaryKey: ['id'])
          .order('created_at')
          .listen(_onMensajesChat);
    }

    if (_esEscuela) {
      if (user.esDirectora) {
        _suscribirSolicitudes();
      } else if (user.esProfesor) {
        _cargarGradosYSuscribir(user.id);
      }
    }
  }

  Future<void> _cargarGradosYSuscribir(String usuarioId) async {
    try {
      final ids = await ProfesorGruposService().gradoIdsDeUsuario(usuarioId);
      _gradoIdsProfesor = ids.toSet();
    } catch (_) {
      _gradoIdsProfesor = {};
    }
    _suscribirSolicitudes();
  }

  void _suscribirSolicitudes() {
    _solicitudSub = Supabase.instance.client
        .from('solicitudes_recogida')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .listen(_onSolicitudes);
  }

  Future<void> _onMensajesChat(List<Map<String, dynamic>> rows) async {
    final userId = _usuarioId;
    if (userId == null) return;
    final user = widget.authService.currentUser;

    for (final row in rows) {
      final id = row['id']?.toString();
      if (id == null || _mensajesConocidos.contains(id)) continue;
      _mensajesConocidos.add(id);

      if (_chatPrimeraCarga) continue;

      final remitenteId = row['remitente_id']?.toString();
      if (remitenteId == null || remitenteId == userId) continue;

      final conversacionId = row['conversacion_id']?.toString();
      if (conversacionId == null) continue;

      // Solo notificar si este usuario es el destinatario del hilo.
      try {
        final conv = await Supabase.instance.client
            .from('conversaciones')
            .select('padre_id, canal, staff_id')
            .eq('id', conversacionId)
            .maybeSingle();
        if (conv == null) continue;

        final padreId = conv['padre_id']?.toString();
        final staffId = conv['staff_id']?.toString();
        final canal = (conv['canal'] as String?) ?? 'directora';

        if (_esEscuela || user?.esProfesor == true) {
          if (staffId != null && staffId.isNotEmpty) {
            // Hilo con la miss: solo esa miss (no la directora).
            if (staffId != userId) continue;
          } else if (canal == 'profesor') {
            continue;
          } else {
            // Canal directora: solo rol directora.
            if (user?.esDirectora != true) continue;
          }
        } else {
          // Padre: solo su conversación.
          if (padreId != userId) continue;
        }
      } catch (_) {
        continue;
      }

      final raw = (row['contenido'] as String?) ?? 'Nuevo mensaje';
      final previewTexto = MensajeChat.vistaPreviaDe(raw);
      final preview = previewTexto.length > 80
          ? '${previewTexto.substring(0, 80)}…'
          : previewTexto;

      final soyEscuela =
          user?.esDirectora == true || user?.esProfesor == true;
      await widget.notificationService.notificarNuevoMensajeChat(
        remitenteEsPadre: soyEscuela,
        preview: preview,
        ruta: soyEscuela ? '/directora/chat' : '/padre/chat',
      );
    }
    _chatPrimeraCarga = false;
  }

  Future<void> _onSolicitudes(List<Map<String, dynamic>> rows) async {
    if (!_esEscuela) return;
    final user = widget.authService.currentUser;

    for (final row in rows) {
      final id = row['id']?.toString();
      if (id == null || _solicitudesConocidas.contains(id)) continue;
      _solicitudesConocidas.add(id);

      if (_solicitudPrimeraCarga) continue;

      // Solo avisar de solicitudes nuevas pendientes
      if (row['estado']?.toString() != 'pendiente') continue;

      final alumnoId = row['alumno_id']?.toString();
      if (alumnoId == null) continue;

      // Si es profesora, solo su(s) grupo(s). Sin grupos asignados: no avisar a todos.
      if (!_esDirectora) {
        final grupos = _gradoIdsProfesor;
        final adminSinGrupo = user?.esProfesorAdmin == true &&
            (grupos == null || grupos.isEmpty);
        if (!adminSinGrupo) {
          if (grupos == null || grupos.isEmpty) continue;
          try {
            final alumnoRow = await Supabase.instance.client
                .from('alumnos')
                .select('grado_id')
                .eq('id', alumnoId)
                .maybeSingle();
            final gradoAlumno = alumnoRow?['grado_id'] as String?;
            if (gradoAlumno == null || !grupos.contains(gradoAlumno)) {
              continue;
            }
          } catch (_) {
            continue;
          }
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
