import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/acceso_padre_service.dart';
import '../services/permisos_service.dart';
import '../config/app_colors.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({Key? key}) : super(key: key);

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  Map<String, bool> _permisos = {};
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarPermisos();
  }

  static const _codigosPermisos = [
    'ver_alumnos',
    'ver_pagos',
    'ver_profesores',
    'ver_padres',
    'ver_eventos',
    'ver_incidentes',
    'ver_tipos_incidentes',
    'ver_personas_autorizadas',
    'ver_bitacora',
    'ver_anuncios',
    'ver_calificaciones',
  ];

  Map<String, bool> _permisosCompletosDirectora() => {
        for (final c in _codigosPermisos) c: true,
      };

  Future<void> _cargarPermisos() async {
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final user = auth.currentUser;

      // Padres / secretaria / inglés: menú fijo, sin RPC.
      if (user?.esPadre == true ||
          user?.esSecretaria == true ||
          user?.esMaestraIngles == true) {
        if (mounted) {
          setState(() {
            _permisos = {};
            _cargando = false;
          });
        }
        return;
      }

      // Directora: acceso total sin 11 round-trips (en iOS el drawer
      // se quedaba en spinner y parecía que no existía "Chat con Padres").
      if (user?.esDirectora == true) {
        if (mounted) {
          setState(() {
            _permisos = _permisosCompletosDirectora();
            _cargando = false;
          });
        }
        return;
      }

      final permisosService = PermisosService();
      final permisos = await permisosService.tienePermisos(_codigosPermisos);

      if (mounted) {
        setState(() {
          _permisos = permisos;
          if (auth.currentUser?.esDirectora != true) {
            _permisos['ver_pagos'] = false;
          }
          _cargando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        final auth = Provider.of<AuthService>(context, listen: false);
        final esDirectora = auth.currentUser?.esDirectora == true;
        setState(() {
          _permisos = esDirectora ? _permisosCompletosDirectora() : {};
          _cargando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final usuario = authService.currentUser;
    final accesoPadre = Provider.of<AccesoPadreService>(context);
    final padreRestringido =
        usuario?.esPadre == true && accesoPadre.restringido;

    return Drawer(
      child: Column(
        children: [
          // Header compacto: logo + nombre + rol en una sola franja
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF8B5CF6),
                  Color(0xFFFF69B4),
                  Color(0xFFFF8C42),
                ],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      padding: const EdgeInsets.all(4),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/icono_caipi.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            usuario?.nombre ?? 'Usuario',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _getRolLabel(usuario?.rol ?? ''),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Opciones del menú con fondo blanco
          Expanded(
            child: Container(
              color: Colors.white,
              child: ListView(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                        children: [
                          _buildMenuItem(
                            context: context,
                            icon: Icons.home,
                            title: 'Inicio',
                            ruta: _getRutaDashboard(usuario?.rol ?? ''),
                            tienePermiso: true,
                          ),

                          // Chat siempre visible para staff (no depende de RPC de permisos).
                          if (usuario?.esStaff == true &&
                              usuario?.esSecretaria != true &&
                              usuario?.esMaestraIngles != true &&
                              usuario?.esPadre != true) ...[
                            _buildMenuItem(
                              context: context,
                              icon: Icons.chat_bubble_rounded,
                              title: 'Chat con Padres',
                              ruta: '/directora/chat',
                              tienePermiso: true,
                            ),
                          ],

                          if (_cargando &&
                              usuario?.esStaff == true &&
                              usuario?.esPadre != true &&
                              usuario?.esSecretaria != true &&
                              usuario?.esMaestraIngles != true)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Center(
                                child: SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.morado,
                                  ),
                                ),
                              ),
                            ),

                          if (!_cargando) ...[
                          const SizedBox(height: 4),

                          // ===== MENÚ SOLO PADRE (nunca admin) =====
                          if (usuario?.esPadre == true) ...[
                            if (padreRestringido) ...[
                              _buildSectionHeader('ACCESO LIMITADO'),
                              _buildMenuItem(
                                context: context,
                                icon: Icons.lock_clock,
                                title: 'Pendiente de pago',
                                ruta: '/padre/adeudo',
                                tienePermiso: true,
                              ),
                              _buildMenuItem(
                                context: context,
                                icon: Icons.chat_bubble_rounded,
                                title: 'Chat con la Escuela',
                                ruta: '/padre/chat',
                                tienePermiso: true,
                              ),
                            ] else ...[
                              _buildSectionHeader('COMUNICACIÓN'),
                              _buildMenuItem(
                                context: context,
                                icon: Icons.chat_bubble_rounded,
                                title: 'Chat con la Escuela',
                                ruta: '/padre/chat',
                                tienePermiso: true,
                              ),
                              _buildSectionHeader('CUENTA'),
                              _buildMenuItem(
                                context: context,
                                icon: Icons.lock_outline,
                                title: 'Cambiar contraseña',
                                ruta: '/cambiar-contrasena',
                                tienePermiso: true,
                              ),
                            ],
                          ],

                          // ===== MAESTRA DE INGLÉS: grupo + calificaciones de Inglés =====
                          if (usuario?.esMaestraIngles == true) ...[
                            _buildSectionHeader('INGLÉS'),
                            _buildMenuItem(
                              context: context,
                              icon: Icons.child_care,
                              title: 'Alumnos del grupo',
                              ruta: '/directora/alumnos',
                              tienePermiso: true,
                            ),
                            _buildMenuItem(
                              context: context,
                              icon: Icons.grade,
                              title: 'Calificaciones de Inglés',
                              ruta: '/directora/calificaciones',
                              tienePermiso: true,
                            ),
                            _buildSectionHeader('CUENTA'),
                            _buildMenuItem(
                              context: context,
                              icon: Icons.lock_outline,
                              title: 'Cambiar contraseña',
                              ruta: '/cambiar-contrasena',
                              tienePermiso: true,
                            ),
                          ]

                          // ===== SECRETARIA: solo altas (alumnos / papás) =====
                          else if (usuario?.esSecretaria == true) ...[
                            _buildSectionHeader('ALTAS'),
                            _buildMenuItem(
                              context: context,
                              icon: Icons.person_add,
                              title: 'Alta de alumno',
                              ruta: '/directora/alumnos/crear',
                              tienePermiso: true,
                            ),
                            _buildSectionHeader('CUENTA'),
                            _buildMenuItem(
                              context: context,
                              icon: Icons.lock_outline,
                              title: 'Cambiar contraseña',
                              ruta: '/cambiar-contrasena',
                              tienePermiso: true,
                            ),
                          ]

                          // ===== MENÚ STAFF (directora / profesoras) =====
                          else if (usuario?.esStaff == true) ...[
                          const SizedBox(height: 4),
                          if (_permisos['ver_alumnos'] == true) ...[
                            _buildSectionHeader('ALUMNOS'),
                            _buildMenuItem(
                              context: context,
                              icon: Icons.child_care,
                              title: 'Alumnos',
                              ruta: '/directora/alumnos',
                              tienePermiso: true,
                            ),
                            _buildMenuItem(
                              context: context,
                              icon: Icons.grade,
                              title: 'Calificaciones',
                              ruta: '/directora/calificaciones',
                              tienePermiso: true,
                            ),
                            _buildMenuItem(
                              context: context,
                              icon: Icons.article,
                              title: 'Entrevista a Padres',
                              ruta: '/directora/entrevistas',
                              tienePermiso: true,
                            ),
                            _buildMenuItem(
                              context: context,
                              icon: Icons.psychology_outlined,
                              title: 'Indicadores de desarrollo',
                              ruta: '/directora/portage',
                              tienePermiso: true,
                            ),
                            if (usuario?.esDirectora == true ||
                                usuario?.esProfesorAdmin == true)
                              _buildMenuItem(
                                context: context,
                                icon: Icons.add_link,
                                title: 'Ligas Drive',
                                ruta: '/directora/ligas',
                                tienePermiso: true,
                              ),
                            _buildMenuItem(
                              context: context,
                              icon: Icons.school_outlined,
                              title: 'Grados',
                              ruta: '/directora/grados',
                              tienePermiso: true,
                            ),
                          ],

                          // SECCIÓN: PAGOS (solo directora)
                          if (_permisos['ver_pagos'] == true &&
                              usuario?.esDirectora == true) ...[
                            _buildSectionHeader('PAGOS'),
                            _buildMenuItem(
                              context: context,
                              icon: Icons.attach_money,
                              title: 'Pagos',
                              ruta: '/directora/pagos',
                              tienePermiso: true,
                            ),
                            _buildMenuItem(
                              context: context,
                              icon: Icons.settings,
                              title: 'Configuración de Costos',
                              ruta: '/directora/configuracion-costos',
                              tienePermiso: true,
                            ),
                          ],

                          // SECCIÓN: PERSONAL
                          if (_permisos['ver_profesores'] == true ||
                              _permisos['ver_padres'] == true) ...[
                            _buildSectionHeader('PERSONAL'),
                            if (_permisos['ver_profesores'] == true)
                              _buildMenuItem(
                                context: context,
                                icon: Icons.school,
                                title: 'Profesoras',
                                ruta: '/directora/profesores',
                                tienePermiso: true,
                              ),
                            if (_permisos['ver_padres'] == true)
                              _buildMenuItem(
                                context: context,
                                icon: Icons.family_restroom,
                                title: 'Padres de Familia',
                                ruta: '/directora/padres',
                                tienePermiso: true,
                              ),
                          ],

                          // SECCIÓN: EVENTOS E INCIDENTES
                          if (_permisos['ver_eventos'] == true ||
                              _permisos['ver_incidentes'] == true) ...[
                            _buildSectionHeader('EVENTOS & INCIDENTES'),
                            if (_permisos['ver_eventos'] == true)
                              _buildMenuItem(
                                context: context,
                                icon: Icons.event,
                                title: 'Eventos',
                                ruta: '/directora/eventos',
                                tienePermiso: true,
                              ),
                            if (_permisos['ver_incidentes'] == true)
                              _buildMenuItem(
                                context: context,
                                icon: Icons.warning_amber_rounded,
                                title: 'Incidentes',
                                ruta: '/directora/incidentes',
                                tienePermiso: true,
                              ),
                            if (_permisos['ver_tipos_incidentes'] == true)
                              _buildMenuItem(
                                context: context,
                                icon: Icons.category,
                                title: 'Tipos de Incidentes',
                                ruta: '/directora/tipos-incidentes',
                                tienePermiso: true,
                              ),
                          ],

                          // SECCIÓN: COMUNICACIÓN
                          if (_permisos['ver_anuncios'] == true) ...[
                            _buildSectionHeader('COMUNICACIÓN'),
                            _buildMenuItem(
                              context: context,
                              icon: Icons.campaign,
                              title: 'Anuncios',
                              ruta: '/directora/anuncios',
                              tienePermiso: true,
                            ),
                            _buildMenuItem(
                              context: context,
                              icon: Icons.sports_soccer,
                              title: 'Clases Extracurriculares',
                              ruta: '/directora/clases-extracurriculares',
                              tienePermiso: true,
                            ),
                          ],

                          // SECCIÓN: BITÁCORA
                          if (_permisos['ver_bitacora'] == true) ...[
                            _buildSectionHeader('BITÁCORA'),
                            _buildMenuItem(
                              context: context,
                              icon: Icons.assignment,
                              title: 'Bitácora Diaria',
                              ruta: '/directora/bitacoras',
                              tienePermiso: true,
                            ),
                            if (usuario?.esDirectora == true)
                              _buildMenuItem(
                                context: context,
                                icon: Icons.receipt_long,
                                title: 'Bitácora de gastos',
                                ruta: '/directora/bitacora-gastos',
                                tienePermiso: true,
                              ),
                            _buildMenuItem(
                              context: context,
                              icon: Icons.access_time,
                              title: 'Control Entrada/Salida',
                              ruta: '/directora/control-salidas',
                              tienePermiso: true,
                            ),
                          ],

                          if (usuario?.esDirectora == true) ...[
                            _buildSectionHeader('REPORTES'),
                            _buildMenuItem(
                              context: context,
                              icon: Icons.picture_as_pdf,
                              title: 'Reportes PDF',
                              ruta: '/directora/reportes-pdf',
                              tienePermiso: true,
                            ),
                            _buildSectionHeader('CONFIGURACIÓN'),
                            _buildMenuItem(
                              context: context,
                              icon: Icons.schedule,
                              title: 'Horario del chat',
                              ruta: '/directora/config-chat-horario',
                              tienePermiso: true,
                            ),
                          ],

                          _buildSectionHeader('CUENTA'),
                          _buildMenuItem(
                            context: context,
                            icon: Icons.lock_outline,
                            title: 'Cambiar contraseña',
                            ruta: '/cambiar-contrasena',
                            tienePermiso: true,
                          ),
                          ], // fin esStaff
                          ], // fin !_cargando
                        ],
                      ),
            ),
          ),

          // Footer: cerrar sesión
          Container(
            color: Colors.white,
            child: Column(
              children: [
                Divider(color: Colors.grey[300], height: 1, thickness: 1),
                Container(
                  margin: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.rojo, Color(0xFFFF6B6B)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.rojo.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.logout, color: Colors.white, size: 22),
                    title: const Text(
                      'Cerrar Sesión',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right, color: Colors.white70, size: 20),
                    onTap: () async {
                      await authService.logout();
                      if (context.mounted) {
                        try {
                          Provider.of<AccesoPadreService>(context, listen: false)
                              .limpiar();
                        } catch (_) {}
                        context.go('/login');
                      }
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // HELPERS
  // ============================================

  Widget _buildSectionHeader(String titulo) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        titulo,
        style: TextStyle(
          color: AppColors.morado,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String ruta,
    required bool tienePermiso,
    int? badge,
  }) {
    if (!tienePermiso) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [
            AppColors.morado.withOpacity(0.05),
            AppColors.rosa.withOpacity(0.05),
          ],
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.morado, AppColors.rosa],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: Colors.grey[800],
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        trailing: badge != null && badge > 0
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badge.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
        onTap: () {
          Navigator.of(context).pop(); // Cerrar drawer
          if (ruta == '/cambiar-contrasena') {
            context.push(ruta);
          } else {
            context.go(ruta);
          }
        },
      ),
    );
  }

  String _getRolLabel(String rol) {
    final u = Provider.of<AuthService>(context, listen: false).currentUser;
    if (u?.esMaestraIngles == true) return 'Maestra de inglés';
    switch (rol) {
      case 'directora':
        return '👩‍💼 Directora';
      case 'profesor':
        return '👩‍🏫 Profesora';
      case 'profesor_admin':
        return '👩‍🏫⭐ Profesora Admin';
      case 'secretaria':
        return '📋 Secretaria (altas)';
      case 'padre':
        return '👨‍👩‍👧 Padre/Madre';
      default:
        return '👤 Usuario';
    }
  }

  String _getRutaDashboard(String rol) {
    switch (rol) {
      case 'directora':
      case 'profesor':
      case 'profesor_admin':
      case 'secretaria':
        return '/directora';
      case 'padre':
        final restringido =
            Provider.of<AccesoPadreService>(context, listen: false).restringido;
        return restringido ? '/padre/adeudo' : '/padre';
      default:
        return '/';
    }
  }
}
