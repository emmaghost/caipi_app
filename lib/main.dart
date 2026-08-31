import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'config/supabase_config.dart';
import 'config/app_colors.dart';
import 'services/auth_service.dart';
import 'services/supabase_service.dart';
import 'services/storage_service.dart';
import 'services/notification_service.dart';
import 'services/push_notification_service.dart';
import 'services/app_realtime_notifications.dart';
import 'services/acceso_padre_service.dart';
import 'routes/app_router.dart';

/// Arranque a prueba de pantalla blanca:
/// 1) Muestra UI de inmediato
/// 2) Inicializa Supabase / notificaciones / FCM después
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Fuentes: se permiten en red; si falla, el ErrorWidget / fallback del
  // paquete evita pantalla blanca. En release físico suele haber caché.
  // (Antes allowRuntimeFetching=false rompía Poppins/Fredoka sin assets.)
  GoogleFonts.config.allowRuntimeFetching = true;

  // Errores de Flutter: no pantalla negra/blanca muda
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exceptionAsString()}');
  };

  ErrorWidget.builder = (details) {
    return Material(
      color: Colors.white,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Error de interfaz:\n${details.exception}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red, fontSize: 14),
            ),
          ),
        ),
      ),
    );
  };

  runApp(const _BootstrapApp());
}

class _BootstrapApp extends StatefulWidget {
  const _BootstrapApp();

  @override
  State<_BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<_BootstrapApp> {
  String? _error;
  Widget? _app;

  @override
  void initState() {
    super.initState();
    // Tras el primer frame, inicializar (nunca antes de pintar)
    WidgetsBinding.instance.addPostFrameCallback((_) => _iniciar());
  }

  Future<void> _iniciar() async {
    try {
      await Supabase.initialize(
        url: SupabaseConfig.supabaseUrl,
        anonKey: SupabaseConfig.supabaseAnonKey,
      ).timeout(const Duration(seconds: 20));

      final notificationService = NotificationService();
      try {
        await notificationService.initialize();
      } catch (e) {
        debugPrint('Notificaciones locales: $e');
      }

      final authService = AuthService();
      final accesoPadreService = AccesoPadreService();
      appRouter = createRouter(
        authService: authService,
        accesoPadreService: accesoPadreService,
      );

      PushNotificationService.instance.onOpenRuta = (ruta) {
        try {
          appRouter.go(ruta);
        } catch (e) {
          debugPrint('Navegación push: $e');
        }
      };

      if (!mounted) return;
      setState(() {
        _app = MyApp(
          authService: authService,
          accesoPadreService: accesoPadreService,
          notificationService: notificationService,
        );
      });

      // FCM en segundo plano (si falla, la app ya está visible)
      unawaited(_iniciarPush(notificationService, authService));
    } catch (e, st) {
      debugPrint('Bootstrap falló: $e\n$st');
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  Future<void> _iniciarPush(
    NotificationService notificationService,
    AuthService authService,
  ) async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp().timeout(const Duration(seconds: 8));
      }
      try {
        FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      } catch (e) {
        debugPrint('Background handler: $e');
      }
      await notificationService.requestPermissions();
      await PushNotificationService.instance
          .initialize(localNotifications: notificationService)
          .timeout(const Duration(seconds: 10));
      // Esperar un poco a que AuthService cargue sesión
      await Future<void>.delayed(const Duration(milliseconds: 1200));
      if (authService.isLoggedIn) {
        await PushNotificationService.instance.registrarTokenUsuarioActual();
      }
    } catch (e) {
      debugPrint('Push opcional falló (app sigue): $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.cloud_off, size: 56, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text(
                      'No se pudo iniciar CAIPI',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () {
                        setState(() {
                          _error = null;
                          _app = null;
                        });
                        _iniciar();
                      },
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (_app != null) return _app!;

    // Splash visible (ya no blanco mudo)
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: AppColors.purpura,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.school,
                size: 80,
                color: Colors.white,
              ),
              const SizedBox(height: 24),
              const Text(
                'CAIPI',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              const CircularProgressIndicator(color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  final AuthService authService;
  final AccesoPadreService accesoPadreService;
  final NotificationService notificationService;

  const MyApp({
    super.key,
    required this.authService,
    required this.accesoPadreService,
    required this.notificationService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authService),
        ChangeNotifierProvider.value(value: accesoPadreService),
        Provider(create: (_) => SupabaseService()),
        Provider(create: (_) => StorageService()),
        Provider.value(value: notificationService),
      ],
      child: AppRealtimeNotifications(
        authService: authService,
        notificationService: notificationService,
        child: MaterialApp.router(
          title: 'CAIPI',
          debugShowCheckedModeBanner: false,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('es', 'MX'),
            Locale('es', ''),
          ],
          locale: const Locale('es', 'MX'),
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.purpura,
              primary: AppColors.purpura,
              secondary: AppColors.rosa,
              tertiary: AppColors.turquesa,
              brightness: Brightness.light,
            ),
            // Sin GoogleFonts aquí: en release sin red / sin Play Services
            // a veces deja la UI en blanco. Las pantallas pueden seguir usándolos.
            useMaterial3: true,
            cardTheme: CardThemeData(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: AppColors.grisClaro,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          routerConfig: appRouter,
        ),
      ),
    );
  }
}
