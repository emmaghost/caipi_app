import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../models/solicitud_recogida.dart';
import '../../models/pago.dart';
import '../../services/auth_service.dart';
import '../../services/solicitud_recogida_service.dart';
import '../../config/app_colors.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/panel_solicitudes_recogida_escuela.dart';

class DashboardDirectora extends StatefulWidget {
  const DashboardDirectora({super.key});

  @override
  State<DashboardDirectora> createState() => _DashboardDirectoraState();
}

class _DashboardDirectoraState extends State<DashboardDirectora> {
  String? _gradoIdProfesor; // null = directora (ve todo)
  final _solicitudService = SolicitudRecogidaService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargarGrado());
  }

  Future<void> _cargarGrado() async {
    final auth = context.read<AuthService>();
    final user = auth.currentUser;
    if (user == null || user.esDirectora) return;
    try {
      final rows = await Supabase.instance.client
          .from('profesores')
          .select('grado_id')
          .eq('usuario_id', user.id)
          .eq('activo', true)
          .limit(1);
      final list = List<Map<String, dynamic>>.from(rows as List);
      if (mounted) {
        setState(() => _gradoIdProfesor =
            list.isEmpty ? null : list.first['grado_id'] as String?);
      }
    } catch (_) {}
  }

  void _mostrarSolicitudes(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Icon(Icons.door_front_door, color: Colors.orange.shade800),
                    const SizedBox(width: 8),
                    Text(
                      'Padres en la entrada',
                      style: GoogleFonts.fredoka(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: controller,
                  child: PanelSolicitudesRecogidaEscuela(
                    gradoIdFiltro: _gradoIdProfesor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final usuario = authService.currentUser;
    final menuCompleto = usuario != null &&
        !usuario.esSecretaria &&
        !usuario.esMaestraIngles;

    // Si no hay usuario, mostrar loading
    if (usuario == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.grisClaro,
      drawer: const AppDrawer(),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              width: 45,
              height: 45,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(3),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/icono_caipi.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      decoration: BoxDecoration(
                        gradient: AppColors.gradienteArcoiris,
                      ),
                      child: const Icon(Icons.school, color: Colors.white, size: 24),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'CAIPI',
              style: GoogleFonts.fredoka(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.rosa,
              ),
            ),
          ],
        ),
        actions: [
          if (menuCompleto)
            StreamBuilder<List<SolicitudRecogida>>(
            stream: _solicitudService.streamPendientes(),
            builder: (context, snapshot) {
              final pendientes = (snapshot.data ?? []).where((s) {
                if (_gradoIdProfesor == null) return true;
                // El filtro real lo hace el panel; aquí solo el badge aproximado
                return true;
              }).length;

              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined, color: AppColors.rosa),
                    onPressed: () => _mostrarSolicitudes(context),
                  ),
                  if (pendientes > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          '$pendientes',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.gris),
            onPressed: () async {
              await authService.logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final ancho = constraints.maxWidth;
          final esTablet = ancho >= 600;
          final maxContent = esTablet ? 720.0 : double.infinity;
          final accionesCols = esTablet ? (ancho >= 900 ? 4 : 3) : 2;
          // En tableta: tarjetas más bajas (menos “alargadas”).
          final accionesAspect = esTablet ? 1.55 : 1.2;
          final accionesIcon = esTablet ? 28.0 : 36.0;
          final accionesPad = esTablet ? 10.0 : 16.0;
          final accionesGap = esTablet ? 8.0 : 12.0;
          final accionesFont = esTablet ? 12.5 : 14.0;

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: esTablet ? 28 : 20,
              vertical: 20,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxContent),
                child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Saludo
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppColors.gradientePrincipal,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.rosa.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.person, color: AppColors.rosa, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '¡Hola, ${usuario.nombre}!',
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          usuario.esSecretaria
                              ? 'Alta de alumnos (junta)'
                              : usuario.esMaestraIngles
                                  ? 'Inglés — tu grupo'
                                  : 'Panel de Directora',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),

            if (menuCompleto) ...[
            // Título de estadísticas
            Text(
              'Resumen General',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.negro,
              ),
            ),
            const SizedBox(height: 16),

            // Estadísticas con streams
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: Supabase.instance.client
                  .from('alumnos')
                  .stream(primaryKey: ['id']),
              builder: (context, alumnosSnapshot) {
                final totalAlumnos = alumnosSnapshot.data?.where((a) => a['activo'] == true).length ?? 0;
                
                return StreamBuilder<List<Map<String, dynamic>>>(
                  stream: Supabase.instance.client
                      .from('pagos')
                      .stream(primaryKey: ['id']),
                  builder: (context, pagosSnapshot) {
                    final pagosVencidos = (pagosSnapshot.data ?? []).where((raw) {
                      try {
                        return Pago.fromJson(
                          Map<String, dynamic>.from(raw),
                        ).estaVencido;
                      } catch (_) {
                        return false;
                      }
                    }).length;
                    
                    return StreamBuilder<List<Map<String, dynamic>>>(
                      stream: Supabase.instance.client
                          .from('incidentes')
                          .stream(primaryKey: ['id']),
                      builder: (context, incidentesSnapshot) {
                        final incidentesPendientes = incidentesSnapshot.data?.where((i) => i['atendido'] == false).length ?? 0;
                        
                        return StreamBuilder<List<Map<String, dynamic>>>(
                          stream: Supabase.instance.client
                              .from('grados')
                              .stream(primaryKey: ['id']),
                          builder: (context, gradosSnapshot) {
                            final totalGrados = gradosSnapshot.data?.where((g) => g['activo'] == true).length ?? 0;
                            
                            return Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildStatCard(
                                        context: context,
                                        title: 'Alumnos',
                                        value: totalAlumnos,
                                        icon: Icons.school,
                                        color: AppColors.azulCielo,
                                        gradient: const LinearGradient(
                                          colors: [AppColors.azulCielo, AppColors.azul],
                                        ),
                                        onTap: () => context.go('/directora/alumnos'),
                                      ),
                                    ),
                                    if (menuCompleto) ...[
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildStatCard(
                                        context: context,
                                        title: 'Pagos vencidos',
                                        value: pagosVencidos,
                                        icon: Icons.payment,
                                        color: AppColors.naranja,
                                        gradient: const LinearGradient(
                                          colors: [AppColors.amarillo, AppColors.naranja],
                                        ),
                                        onTap: () => context.go('/directora/pagos'),
                                      ),
                                    ),
                                    ],
                                  ],
                                ),
                                if (menuCompleto) ...[
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildStatCard(
                                        context: context,
                                        title: 'Incidentes',
                                        value: incidentesPendientes,
                                        icon: Icons.warning_amber_rounded,
                                        color: AppColors.rojo,
                                        gradient: const LinearGradient(
                                          colors: [AppColors.rosa, AppColors.rojo],
                                        ),
                                        onTap: () => context.go('/directora/incidentes'),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildStatCard(
                                        context: context,
                                        title: 'Grados',
                                        value: totalGrados,
                                        icon: Icons.class_,
                                        color: AppColors.verde,
                                        gradient: const LinearGradient(
                                          colors: [AppColors.verde, AppColors.turquesa],
                                        ),
                                        onTap: () => context.go('/directora/grados'),
                                      ),
                                    ),
                                  ],
                                ),
                                ],
                              ],
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 32),

            // Próximos Eventos
            _buildProximosEventos(context),
            const SizedBox(height: 24),
            ],

            if (usuario.esSecretaria) ...[
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Registro en junta',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Captura aquí los datos del alumno y del papá. '
                        'No verás beca ni pagos: eso lo revisa la directora después.',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppColors.gris,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () =>
                              context.push('/directora/alumnos/crear'),
                          icon: const Icon(Icons.person_add),
                          label: const Text('Alta de alumno'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.rosa,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Acciones rápidas
            Text(
              usuario.esSecretaria ? 'Más opciones' : 'Acciones Rápidas',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.negro,
              ),
            ),
            const SizedBox(height: 16),

            GridView.count(
              crossAxisCount: accionesCols,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: accionesGap,
              crossAxisSpacing: accionesGap,
              childAspectRatio: accionesAspect,
              children: [
                if (!usuario.esSecretaria)
                  _buildActionCard(
                  context: context,
                  title: 'Ver Alumnos',
                  icon: Icons.groups,
                  color: AppColors.azulCielo,
                  iconSize: accionesIcon,
                  iconPadding: accionesPad,
                  titleSize: accionesFont,
                  onTap: () => context.go('/directora/alumnos'),
                ),
                if (usuario.esMaestraIngles)
                  _buildActionCard(
                    context: context,
                    title: 'Calificaciones de Inglés',
                    icon: Icons.grade,
                    color: AppColors.azulOscuro,
                    iconSize: accionesIcon,
                    iconPadding: accionesPad,
                    titleSize: accionesFont,
                    onTap: () => context.go('/directora/calificaciones'),
                  ),
                if (usuario.esDirectora)
                  _buildActionCard(
                    context: context,
                    title: 'Gestionar Pagos',
                    icon: Icons.attach_money,
                    color: AppColors.verde,
                    iconSize: accionesIcon,
                    iconPadding: accionesPad,
                    titleSize: accionesFont,
                    onTap: () => context.go('/directora/pagos'),
                  ),
                if (menuCompleto)
                  _buildActionCard(
                  context: context,
                  title: 'Profesoras',
                  icon: Icons.person,
                  color: AppColors.purpura,
                  iconSize: accionesIcon,
                  iconPadding: accionesPad,
                  titleSize: accionesFont,
                  onTap: () => context.go('/directora/profesores'),
                ),
                if (menuCompleto)
                  _buildActionCard(
                  context: context,
                  title: 'Padres de Familia',
                  icon: Icons.family_restroom,
                  color: AppColors.rosa,
                  iconSize: accionesIcon,
                  iconPadding: accionesPad,
                  titleSize: accionesFont,
                  onTap: () => context.go('/directora/padres'),
                ),
                if (menuCompleto)
                  _buildActionCard(
                  context: context,
                  title: 'Nuevo Anuncio',
                  icon: Icons.campaign,
                  color: AppColors.morado,
                  iconSize: accionesIcon,
                  iconPadding: accionesPad,
                  titleSize: accionesFont,
                  onTap: () => context.go('/directora/anuncios'),
                ),
                if (menuCompleto)
                  _buildActionCard(
                  context: context,
                  title: 'Indicadores de desarrollo',
                  icon: Icons.psychology_outlined,
                  color: AppColors.azulOscuro,
                  iconSize: accionesIcon,
                  iconPadding: accionesPad,
                  titleSize: accionesFont,
                  onTap: () => context.go('/directora/portage'),
                ),
                if (usuario.puedeEditarAlumnos)
                _buildActionCard(
                  context: context,
                  title: 'Agregar Alumno',
                  icon: Icons.person_add,
                  color: AppColors.rosa,
                  iconSize: accionesIcon,
                  iconPadding: accionesPad,
                  titleSize: accionesFont,
                  onTap: () {
                    final puede = context
                            .read<AuthService>()
                            .currentUser
                            ?.puedeEditarAlumnos ??
                        false;
                    if (!puede) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Solo directora, secretaria o supervisora pueden agregar alumnos.',
                          ),
                        ),
                      );
                      return;
                    }
                    context.push('/directora/alumnos/crear');
                  },
                ),
                if (usuario.esSecretaria || usuario.esMaestraIngles)
                  _buildActionCard(
                    context: context,
                    title: 'Cambiar contraseña',
                    icon: Icons.lock_outline,
                    color: AppColors.morado,
                    iconSize: accionesIcon,
                    iconPadding: accionesPad,
                    titleSize: accionesFont,
                    onTap: () => context.push('/cambiar-contrasena'),
                  ),
              ],
            ),
          ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required String title,
    required int value,
    required IconData icon,
    required Color color,
    required Gradient gradient,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 32, color: Colors.white),
              ),
              const SizedBox(height: 12),
              Text(
                value.toString(),
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.95),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    double iconSize = 36,
    double iconPadding = 16,
    double titleSize = 14,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(iconPadding),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: iconSize, color: color),
            ),
            SizedBox(height: iconPadding > 12 ? 12 : 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: titleSize,
                  fontWeight: FontWeight.w600,
                  color: AppColors.negro,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProximosEventos(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Supabase.instance.client
          .from('eventos')
          .stream(primaryKey: ['id'])
          .order('fecha_evento'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final ahora = DateTime.now();
        final eventosProximos = (snapshot.data ?? [])
            .where((e) {
              final fechaEvento = DateTime.parse(e['fecha_evento']);
              final diferencia = fechaEvento.difference(ahora).inDays;
              return diferencia >= 0 && diferencia <= 7;
            })
            .take(3)
            .toList();

        if (eventosProximos.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.event, color: AppColors.azulOscuro, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Próximos Eventos',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.negro,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => context.go('/directora/eventos'),
                  child: const Text('Ver todos'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...eventosProximos.map((eventoData) {
              final fechaEvento = DateTime.parse(eventoData['fecha_evento']);
              final diasRestantes = fechaEvento.difference(ahora).inDays;
              final emoji = _getEmojiTipoEvento(eventoData['tipo']);

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.azulOscuro.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          fechaEvento.day.toString(),
                          style: GoogleFonts.fredoka(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.azulOscuro,
                          ),
                        ),
                        Text(
                          DateFormat('MMM', 'es_MX').format(fechaEvento).toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.gris,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  title: Text(
                    '$emoji ${eventoData['titulo']}',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    diasRestantes == 0
                        ? '¡Hoy!'
                        : diasRestantes == 1
                            ? 'Mañana'
                            : 'En $diasRestantes días',
                    style: TextStyle(
                      color: diasRestantes == 0 ? Colors.red : AppColors.gris,
                      fontWeight: diasRestantes == 0 ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => context.go('/directora/eventos'),
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }

  String _getEmojiTipoEvento(String? tipo) {
    switch (tipo) {
      case 'academico':
        return '📚';
      case 'festivo':
        return '🎉';
      case 'reunion':
        return '👥';
      case 'clausura':
        return '🎓';
      default:
        return '📅';
    }
  }
}
