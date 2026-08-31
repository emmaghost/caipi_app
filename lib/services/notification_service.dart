import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Callback al tocar notificación local (payload = ruta).
  void Function(String? payload)? onNotificationTap;

  /// Inicializar el servicio de notificaciones
  Future<void> initialize() async {
    if (_initialized) return;

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _initialized = true;
  }

  /// Solicitar permisos (Android 13+ e iOS)
  Future<bool?> requestPermissions() async {
    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      await android.requestNotificationsPermission();
    }

    return await _notifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  /// Manejar cuando el usuario toca una notificación
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notificación tocada: ${response.payload}');
    onNotificationTap?.call(response.payload);
  }

  /// Mostrar notificación simple
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'caipi_channel',
      'CAIPI Notificaciones',
      channelDescription: 'Notificaciones del Sistema Escolar CAIPI',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      id,
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Notificación de pago pendiente
  Future<void> notificarPagoPendiente({
    required String nombreAlumno,
    required String mes,
    required double monto,
  }) async {
    await showNotification(
      id: DateTime.now().millisecond,
      title: '💰 Pago Pendiente',
      body: '$nombreAlumno tiene pendiente el pago de $mes (\$${monto.toStringAsFixed(2)})',
      payload: 'pagos',
    );
  }

  /// Notificación de pago vencido
  Future<void> notificarPagoVencido({
    required String nombreAlumno,
    required String mes,
    required int diasVencidos,
  }) async {
    await showNotification(
      id: DateTime.now().millisecond,
      title: '🚨 Pago Vencido',
      body: '$nombreAlumno: Pago de $mes vencido hace $diasVencidos días',
      payload: 'pagos',
    );
  }

  /// Notificación de incidente grave
  Future<void> notificarIncidenteGrave({
    required String nombreAlumno,
    required String titulo,
    required int nivel,
  }) async {
    const emojis = {
      4: '⚠️',
      5: '🚨',
    };

    await showNotification(
      id: DateTime.now().millisecond,
      title: '${emojis[nivel] ?? '⚠️'} Incidente Nivel $nivel',
      body: '$nombreAlumno: $titulo',
      payload: 'incidentes',
    );
  }

  /// Notificación de nuevo anuncio
  Future<void> notificarNuevoAnuncio({
    required String titulo,
    required bool esUrgente,
  }) async {
    await showNotification(
      id: DateTime.now().millisecond,
      title: esUrgente ? '🔔 Anuncio Urgente' : '📢 Nuevo Anuncio',
      body: titulo,
      payload: 'anuncios',
    );
  }

  /// Notificación de nuevo evento
  Future<void> notificarNuevoEvento({
    required String titulo,
    required DateTime fecha,
  }) async {
    final fechaStr = '${fecha.day}/${fecha.month}/${fecha.year}';
    
    await showNotification(
      id: DateTime.now().millisecond,
      title: '📅 Nuevo Evento',
      body: '$titulo - $fechaStr',
      payload: 'eventos',
    );
  }

  /// Notificación de nuevo mensaje en chat
  Future<void> notificarNuevoMensajeChat({
    required bool remitenteEsPadre,
    required String preview,
  }) async {
    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title: remitenteEsPadre ? '💬 Mensaje de padre' : '💬 Mensaje de la escuela',
      body: preview,
      payload: 'chat',
    );
  }

  /// Padre en la entrada solicita al niño
  Future<void> notificarSolicitudRecogida({
    required String nombreAlumno,
  }) async {
    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000) + 1,
      title: '🚪 Padre en la entrada',
      body: 'Solicitan entregar a $nombreAlumno',
      payload: 'solicitud_recogida',
    );
  }

  /// Notificación de recordatorio
  Future<void> notificarRecordatorio({
    required String titulo,
    required String mensaje,
  }) async {
    await showNotification(
      id: DateTime.now().millisecond,
      title: '⏰ Recordatorio',
      body: '$titulo: $mensaje',
      payload: 'recordatorio',
    );
  }

  /// Cancelar notificación específica
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  /// Cancelar todas las notificaciones
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  /// Verificar si las notificaciones están habilitadas
  Future<bool> areNotificationsEnabled() async {
    final androidImplementation = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidImplementation != null) {
      return await androidImplementation.areNotificationsEnabled() ?? false;
    }
    
    return true; // iOS siempre retorna true si se concedieron permisos
  }
}
