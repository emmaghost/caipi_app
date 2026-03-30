import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'config/supabase_config.dart';
import 'config/app_colors.dart';
import 'services/auth_service.dart';
import 'services/supabase_service.dart';
import 'services/storage_service.dart';
import 'services/notification_service.dart';
import 'routes/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Supabase
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );
  
  // Inicializar notificaciones
  final notificationService = NotificationService();
  await notificationService.initialize();
  await notificationService.requestPermissions();
  
  // Crear AuthService e inicializar router
  final authService = AuthService();
  appRouter = createRouter(authService);
  
  runApp(MyApp(authService: authService, notificationService: notificationService));
}

class MyApp extends StatelessWidget {
  final AuthService authService;
  final NotificationService notificationService;
  
  const MyApp({
    super.key,
    required this.authService,
    required this.notificationService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authService),
        Provider(create: (_) => SupabaseService()),
        Provider(create: (_) => StorageService()),
        Provider.value(value: notificationService),
      ],
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
          textTheme: GoogleFonts.poppinsTextTheme(),
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
    );
  }
}
