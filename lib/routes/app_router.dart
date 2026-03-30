import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../screens/login_screen.dart';
import '../screens/cambiar_contrasena_screen.dart';
import '../screens/directora/dashboard_directora.dart';
import '../screens/directora/alumnos_screen.dart';
import '../screens/directora/crear_alumno_screen.dart';
import '../screens/directora/pagos_screen.dart';
import '../screens/directora/acreditar_pago_screen.dart';
import '../screens/directora/configuracion_costos_screen.dart';
import '../screens/directora/test_whatsapp_screen.dart';
import '../screens/directora/profesores_screen.dart';
import '../screens/directora/crear_profesor_screen.dart';
import '../screens/directora/permisos_profesor_screen.dart';
import '../screens/directora/padres_screen.dart';
import '../screens/directora/crear_padre_screen.dart';
import '../screens/directora/ver_padre_screen.dart';
import '../screens/directora/personas_autorizadas_screen.dart';
import '../screens/directora/crear_anuncio_screen.dart';
import '../screens/directora/anuncios_screen.dart';
import '../screens/directora/eventos_screen.dart';
import '../screens/directora/crear_evento_screen.dart';
import '../screens/directora/incidentes_screen.dart';
import '../screens/directora/crear_incidente_screen.dart';
import '../screens/directora/tipos_incidentes_screen.dart';
import '../screens/directora/grados_screen.dart';
import '../screens/directora/crear_grado_screen.dart';
import '../screens/directora/bitacoras_screen.dart';
import '../screens/directora/crear_bitacora_screen.dart';
import '../screens/directora/control_salidas_screen.dart';
import '../screens/directora/registrar_salida_screen.dart';
import '../screens/directora/calificaciones_screen.dart';
import '../screens/directora/calificaciones_alumno_screen.dart';
import '../screens/directora/menu_maternal_screen.dart';
import '../screens/directora/crear_menu_screen.dart';
// Galería eliminada - no se necesita
// import '../screens/directora/galeria_screen.dart';
// import '../screens/directora/subir_foto_screen.dart';
import '../screens/directora/clases_extracurriculares_screen.dart';
import '../screens/directora/crear_clase_extracurricular_screen.dart';
import '../screens/directora/entrevista_padres_screen.dart';
import '../screens/padres/dashboard_padre.dart';
import '../screens/padres/detalle_hijo_screen.dart';
import '../screens/padres/bitacora_padre_screen.dart';
import '../screens/padres/pagos_padre_screen.dart';
import '../screens/padres/eventos_screen.dart';
import '../screens/padres/personas_autorizadas_screen.dart';
import '../screens/padres/qr_temporal_screen.dart';

// Necesitamos crear el router como función para acceder al AuthService
GoRouter createRouter(AuthService authService) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: authService, // ← IMPORTANTE: Escucha cambios
    redirect: (context, state) {
      final isLoggedIn = authService.isLoggedIn;
      final isDirectora = authService.isDirectora;
      final isPadre = authService.isPadre;
      
      final isGoingToLogin = state.matchedLocation == '/login';
      final isGoingToRoot = state.matchedLocation == '/';

      // Si va a raíz, redirigir según estado
      if (isGoingToRoot) {
        if (!isLoggedIn) return '/login';
        if (isDirectora) return '/directora';
        if (isPadre) return '/padre';
        return '/login';
      }

      // Si no está logueado y no va al login, redirigir a login
      if (!isLoggedIn && !isGoingToLogin) {
        return '/login';
      }

      // Si está logueado y va al login, redirigir a su dashboard
      if (isLoggedIn && isGoingToLogin) {
        return isDirectora ? '/directora' : '/padre';
      }

      return null; // Sin redirección
    },
  routes: [
    GoRoute(
      path: '/',
      redirect: (context, state) => '/login',
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/cambiar-contrasena',
      builder: (context, state) => const CambiarContrasenaScreen(),
    ),

    // ==================== RUTAS DIRECTORA ====================
    GoRoute(
      path: '/directora',
      builder: (context, state) => const DashboardDirectora(),
    ),
    GoRoute(
      path: '/directora/alumnos',
      builder: (context, state) => const AlumnosScreen(),
    ),
    GoRoute(
      path: '/directora/alumnos/crear',
      builder: (context, state) => const CrearAlumnoScreen(),
    ),
    GoRoute(
      path: '/directora/alumnos/editar/:id',
      builder: (context, state) {
        final alumnoId = state.pathParameters['id']!;
        return CrearAlumnoScreen(alumnoId: alumnoId);
      },
    ),
    GoRoute(
      path: '/directora/entrevista/crear',
      builder: (context, state) {
        final alumnoId = state.uri.queryParameters['alumnoId'];
        return EntrevistaPadresScreen(alumnoId: alumnoId);
      },
    ),
    GoRoute(
      path: '/directora/entrevista/editar/:id',
      builder: (context, state) {
        final entrevistaId = state.pathParameters['id']!;
        final alumnoId = state.uri.queryParameters['alumnoId'];
        return EntrevistaPadresScreen(
          entrevistaId: entrevistaId,
          alumnoId: alumnoId,
        );
      },
    ),
    GoRoute(
      path: '/directora/pagos',
      builder: (context, state) => const PagosScreen(),
    ),
    GoRoute(
      path: '/acreditar-pago/:pagoId',
      builder: (context, state) {
        final pagoId = state.pathParameters['pagoId']!;
        return AcreditarPagoScreen(pagoId: pagoId);
      },
    ),
    GoRoute(
      path: '/directora/configuracion-costos',
      builder: (context, state) => const ConfiguracionCostosScreen(),
    ),
    GoRoute(
      path: '/directora/test-whatsapp',
      builder: (context, state) => const TestWhatsAppScreen(),
    ),
    GoRoute(
      path: '/directora/profesores',
      builder: (context, state) => const ProfesoresScreen(),
    ),
    GoRoute(
      path: '/directora/profesores/crear',
      builder: (context, state) => const CrearProfesorScreen(),
    ),
    GoRoute(
      path: '/directora/profesores/editar/:id',
      builder: (context, state) {
        final profesorId = state.pathParameters['id']!;
        return CrearProfesorScreen(profesorId: profesorId);
      },
    ),
    GoRoute(
      path: '/directora/profesores/:id/permisos',
      builder: (context, state) {
        final usuarioId = state.pathParameters['id']!;
        final nombre = state.uri.queryParameters['nombre'] ?? 'Profesora';
        return PermisosProfesorScreen(
          usuarioId: usuarioId,
          nombreProfesor: nombre,
        );
      },
    ),
    GoRoute(
      path: '/directora/padres',
      builder: (context, state) => const PadresScreen(),
    ),
    GoRoute(
      path: '/directora/padres/crear',
      builder: (context, state) => const CrearPadreScreen(),
    ),
    GoRoute(
      path: '/directora/padres/ver/:id',
      builder: (context, state) {
        final padreId = state.pathParameters['id']!;
        return VerPadreScreen(padreId: padreId);
      },
    ),
    GoRoute(
      path: '/directora/personas-autorizadas/:alumnoId',
      builder: (context, state) {
        final alumnoId = state.pathParameters['alumnoId']!;
        final alumnoNombre = state.uri.queryParameters['nombre'] ?? 'Alumno';
        return PersonasAutorizadasScreen(
          alumnoId: alumnoId,
          alumnoNombre: alumnoNombre,
        );
      },
    ),
    GoRoute(
      path: '/directora/anuncios',
      builder: (context, state) => const AnunciosScreen(),
    ),
    GoRoute(
      path: '/directora/anuncios/crear',
      builder: (context, state) => const CrearAnuncioScreen(),
    ),
    GoRoute(
      path: '/directora/anuncios/editar/:id',
      builder: (context, state) {
        final anuncioId = state.pathParameters['id']!;
        return CrearAnuncioScreen(anuncioId: anuncioId);
      },
    ),
    GoRoute(
      path: '/directora/eventos',
      builder: (context, state) => const EventosScreen(),
    ),
    GoRoute(
      path: '/directora/eventos/crear',
      builder: (context, state) => const CrearEventoScreen(),
    ),
    GoRoute(
      path: '/directora/eventos/editar/:id',
      builder: (context, state) {
        final eventoId = state.pathParameters['id']!;
        return CrearEventoScreen(eventoId: eventoId);
      },
    ),
    GoRoute(
      path: '/directora/incidentes',
      builder: (context, state) => const IncidentesScreen(),
    ),
    GoRoute(
      path: '/directora/incidentes/crear',
      builder: (context, state) => const CrearIncidenteScreen(),
    ),
    GoRoute(
      path: '/directora/tipos-incidentes',
      builder: (context, state) => const TiposIncidentesScreen(),
    ),
    GoRoute(
      path: '/directora/grados',
      builder: (context, state) => const GradosScreen(),
    ),
    GoRoute(
      path: '/directora/grados/crear',
      builder: (context, state) => const CrearGradoScreen(),
    ),
    GoRoute(
      path: '/directora/grados/editar/:id',
      builder: (context, state) {
        final gradoId = state.pathParameters['id']!;
        return CrearGradoScreen(gradoId: gradoId);
      },
    ),
    GoRoute(
      path: '/directora/bitacoras',
      builder: (context, state) => const BitacorasScreen(),
    ),
    GoRoute(
      path: '/directora/bitacoras/crear',
      builder: (context, state) {
        DateTime? fecha;
        final ex = state.extra;
        if (ex is Map<String, dynamic>) {
          fecha = ex['fecha'] as DateTime?;
        }
        return CrearBitacoraScreen(fechaInicial: fecha);
      },
    ),
    GoRoute(
      path: '/directora/bitacoras/editar/:id',
      builder: (context, state) {
        final bitacoraId = state.pathParameters['id']!;
        return CrearBitacoraScreen(bitacoraId: bitacoraId);
      },
    ),
    GoRoute(
      path: '/directora/control-salidas',
      builder: (context, state) => const ControlSalidasScreen(),
    ),
    GoRoute(
      path: '/directora/control-salidas/crear',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        final fecha = extra?['fecha'] as DateTime?;
        return RegistrarSalidaScreen(fechaInicial: fecha);
      },
    ),
    GoRoute(
      path: '/directora/control-salidas/editar/:id',
      builder: (context, state) {
        final controlId = state.pathParameters['id']!;
        return RegistrarSalidaScreen(controlId: controlId);
      },
    ),
    GoRoute(
      path: '/directora/calificaciones',
      builder: (context, state) => const CalificacionesScreen(),
    ),
    GoRoute(
      path: '/directora/calificaciones/alumno/:alumnoId',
      builder: (context, state) {
        final alumnoId = state.pathParameters['alumnoId']!;
        return CalificacionesAlumnoScreen(alumnoId: alumnoId);
      },
    ),
    GoRoute(
      path: '/directora/menu-maternal',
      builder: (context, state) => const MenuMaternalScreen(),
    ),
    GoRoute(
      path: '/directora/menu-maternal/crear',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        final fecha = extra?['fecha'] as DateTime?;
        return CrearMenuScreen(fechaInicial: fecha);
      },
    ),
    GoRoute(
      path: '/directora/menu-maternal/editar/:id',
      builder: (context, state) {
        final menuId = state.pathParameters['id']!;
        return CrearMenuScreen(menuId: menuId);
      },
    ),
    // Rutas de galería eliminadas - no se necesitan
    // GoRoute(
    //   path: '/directora/galeria',
    //   builder: (context, state) => const GaleriaScreen(),
    // ),
    // GoRoute(
    //   path: '/directora/galeria/subir',
    //   builder: (context, state) => const SubirFotoScreen(),
    // ),
    GoRoute(
      path: '/directora/clases-extracurriculares',
      builder: (context, state) => const ClasesExtracurricularesScreen(),
    ),
    GoRoute(
      path: '/directora/clases-extracurriculares/crear',
      builder: (context, state) => const CrearClaseExtracurricularScreen(),
    ),
    GoRoute(
      path: '/directora/clases-extracurriculares/editar/:id',
      builder: (context, state) {
        final claseId = state.pathParameters['id']!;
        return CrearClaseExtracurricularScreen(claseId: claseId);
      },
    ),
    
    // ==================== RUTAS PADRES ====================
    GoRoute(
      path: '/padre',
      builder: (context, state) => const DashboardPadre(),
    ),
    GoRoute(
      path: '/padre/hijo/:id/pagos',
      builder: (context, state) {
        final hijoId = state.pathParameters['id']!;
        final extra = state.extra as Map<String, dynamic>?;
        final nombre = extra?['alumnoNombre'] as String? ?? 'Mi hijo/a';
        return PagosPadreScreen(alumnoId: hijoId, alumnoNombre: nombre);
      },
    ),
    GoRoute(
      path: '/padre/hijo/:id/bitacora',
      builder: (context, state) {
        final hijoId = state.pathParameters['id']!;
        final extra = state.extra as Map<String, dynamic>?;
        final nombre = extra?['alumnoNombre'] as String? ?? 'Mi hijo/a';
        return BitacoraPadreScreen(alumnoId: hijoId, alumnoNombre: nombre);
      },
    ),
    GoRoute(
      path: '/padre/hijo/:id',
      builder: (context, state) {
        final hijoId = state.pathParameters['id']!;
        return DetalleHijoScreen(alumnoId: hijoId);
      },
    ),
    GoRoute(
      path: '/padre/eventos',
      builder: (context, state) => const EventosPadreScreen(),
    ),
    GoRoute(
      path: '/padre/hijo/:id/personas-autorizadas',
      builder: (context, state) {
        final hijoId = state.pathParameters['id']!;
        final extra = state.extra as Map<String, dynamic>?;
        final alumnoNombre = extra?['alumnoNombre'] ?? 'Alumno';
        return PersonasAutorizadasPadreScreen(
          alumnoId: hijoId,
          alumnoNombre: alumnoNombre,
        );
      },
    ),
    GoRoute(
      path: '/padre/qr-temporal',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return QrTemporalScreen(
          codigo: extra['codigo'] as String,
          nombrePersona: extra['nombrePersona'] as String,
          alumnoNombre: extra['alumnoNombre'] as String,
        );
      },
    ),
  ],
  );
}

// Variable global para el router (se inicializa en main.dart)
late final GoRouter appRouter;
