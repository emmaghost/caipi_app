import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'notification_service.dart';

/// Maneja FCM: token en Supabase + mostrar aviso en primer plano.
class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  FirebaseMessaging? _messaging;
  bool _ready = false;

  /// Navegación al tocar la notificación (lo asigna main.dart).
  void Function(String ruta)? onOpenRuta;

  bool get isReady => _ready;

  FirebaseMessaging get _fcm {
    return _messaging ??= FirebaseMessaging.instance;
  }

  Future<void> initialize({
    required NotificationService localNotifications,
  }) async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp().timeout(const Duration(seconds: 6));
      }
    } catch (e) {
      debugPrint('Firebase init: $e');
      _ready = false;
      return;
    }

    try {
      await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      await localNotifications.requestPermissions();

      localNotifications.onNotificationTap = (payload) {
        if (payload != null && payload.isNotEmpty) {
          onOpenRuta?.call(payload);
        }
      };

      FirebaseMessaging.onMessage.listen((message) async {
        final title = message.notification?.title ??
            message.data['title']?.toString() ??
            'CAIPI';
        final body = message.notification?.body ??
            message.data['body']?.toString() ??
            '';
        if (body.isEmpty && title == 'CAIPI') return;
        await localNotifications.showNotification(
          id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          title: title,
          body: body,
          payload: message.data['ruta']?.toString(),
        );
      });

      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        final ruta = message.data['ruta']?.toString();
        if (ruta != null && ruta.isNotEmpty) {
          onOpenRuta?.call(ruta);
        }
      });

      try {
        final initial = await _fcm
            .getInitialMessage()
            .timeout(const Duration(seconds: 3));
        if (initial != null) {
          final ruta = initial.data['ruta']?.toString();
          if (ruta != null && ruta.isNotEmpty) {
            Future<void>.delayed(const Duration(milliseconds: 800), () {
              onOpenRuta?.call(ruta);
            });
          }
        }
      } catch (_) {}

      _fcm.onTokenRefresh.listen((token) async {
        final uid = Supabase.instance.client.auth.currentUser?.id;
        if (uid != null) {
          await _guardarToken(usuarioId: uid, token: token);
        }
      });

      _ready = true;
      debugPrint('✅ Push FCM listo');
    } catch (e) {
      debugPrint('❌ Push FCM no disponible: $e');
      _ready = false;
    }
  }

 /// Registra el token FCM del usuario autenticado.
///
/// En iOS espera primero a que APNs entregue su token, ya que Firebase
/// necesita asociar el token APNs con el token FCM antes de poder obtenerlo.
///
/// @return Future<void>
Future<void> registrarTokenUsuarioActual() async {
  if (!_ready) {
    debugPrint('FCM: servicio aún no está listo');
    return;
  }

  final uid = Supabase.instance.client.auth.currentUser?.id;

  if (uid == null) {
    debugPrint('FCM: no hay usuario autenticado');
    return;
  }

  try {
    if (Platform.isIOS || Platform.isMacOS) {
      String? apnsToken;

      // APNs puede tardar un poco después de conceder permisos.
      for (var intento = 1; intento <= 10; intento++) {
        apnsToken = await _fcm.getAPNSToken();

        if (apnsToken != null && apnsToken.isNotEmpty) {
          debugPrint('✅ APNs token disponible');
          break;
        }

        debugPrint(
          'FCM: esperando APNs token... intento $intento/10',
        );

        await Future<void>.delayed(
          const Duration(milliseconds: 500),
        );
      }

      if (apnsToken == null || apnsToken.isEmpty) {
        debugPrint('❌ FCM: APNs token no disponible');
        return;
      }
    }

    final token = await _fcm.getToken();

    if (token == null || token.isEmpty) {
      debugPrint('FCM: sin token aún');
      return;
    }

    await _guardarToken(
      usuarioId: uid,
      token: token,
    );

    debugPrint('✅ Token FCM guardado para $uid');
  } catch (e) {
    debugPrint('❌ Error registrando token FCM: $e');
  }
}

  Future<void> _guardarToken({
    required String usuarioId,
    required String token,
  }) async {
    final plataforma = Platform.isIOS
        ? 'ios'
        : Platform.isAndroid
            ? 'android'
            : 'web';

    await Supabase.instance.client.from('device_tokens').upsert(
      {
        'usuario_id': usuarioId,
        'token': token,
        'plataforma': plataforma,
        'activo': true,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      onConflict: 'usuario_id,token',
    );
  }

  Future<void> desactivarTokensUsuario() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    try {
      await Supabase.instance.client
          .from('device_tokens')
          .update({'activo': false})
          .eq('usuario_id', uid);
    } catch (e) {
      debugPrint('Error desactivando tokens: $e');
    }
  }
}

/// Handler en segundo plano (debe ser top-level).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }
  debugPrint('Push en background: ${message.messageId}');
}
