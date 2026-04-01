import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
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

  Future<void> _cargarPermisos() async {
    try {
      final permisosService = PermisosService();
      
      // Lista de permisos a verificar
      final codigosPermisos = [
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

      final permisos = await permisosService.tienePermisos(codigosPermisos);
      
      print('🔑 Permisos cargados: $permisos');
      
      if (mounted) {
        setState(() {
          _permisos = permisos;
          _cargando = false;
        });
      }
    } catch (e) {
      print('❌ Error cargando permisos: $e');
      if (mounted) {
        setState(() {
          // En caso de error, dar acceso básico si es directora
          _permisos = {
            'ver_alumnos': true,
            'ver_pagos': true,
            'ver_profesores': true,
            'ver_padres': true,
            'ver_eventos': true,
            'ver_incidentes': true,
            'ver_tipos_incidentes': true,
            'ver_personas_autorizadas': true,
            'ver_bitacora': true,
            'ver_anuncios': true,
            'ver_calificaciones': true,
          };
          _cargando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final usuario = authService.currentUser;

    return Drawer(
      child: Column(
        children: [
          // 🌈 Header con degradado arcoíris espectacular
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF8B5CF6), // Morado
                  Color(0xFFFF69B4), // Rosa
                  Color(0xFFFF8C42), // Naranja
                  Color(0xFFFFD700), // Amarillo
                  Color(0xFF90EE90), // Verde
                  Color(0xFF87CEEB), // Azul cielo
                ],
                stops: [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
                child: Column(
                  children: [
                    // Logo circular con efecto de brillo
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.5),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                          const BoxShadow(
                            color: Colors.black26,
                            blurRadius: 15,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(8),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/logo_caipi.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Nombre del usuario con sombra
                    Text(
                      usuario?.nombre ?? 'Usuario',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    // Rol con badge bonito
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        _getRolLabel(usuario?.rol ?? ''),
                        style: TextStyle(
                          color: AppColors.morado,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Decoración divisora con ondas
          Container(
            height: 20,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
          ),

          // Opciones del menú con fondo blanco
          Expanded(
            child: Container(
              color: Colors.white,
              child: _cargando
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.morado),
                    )
                  : ListView(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                        children: [
                          // Home/Dashboard
                          _buildMenuItem(
                            context: context,
                            icon: Icons.home,
                            title: 'Inicio',
                            ruta: _getRutaDashboard(usuario?.rol ?? ''),
                            tienePermiso: true,
                          ),

                          const SizedBox(height: 8),
                          
                          // SECCIÓN: ALUMNOS
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
                              icon: Icons.article,
                              title: 'Entrevista a Padres',
                              ruta: '/directora/entrevista/crear',
                              tienePermiso: true,
                            ),
                            // Personas autorizadas: oculto por solicitud (no se muestra en ningún lado)
                            // if (_permisos['ver_personas_autorizadas'] == true)
                            //   _buildMenuItem(...),
                            _buildMenuItem(
                              context: context,
                              icon: Icons.school_outlined,
                              title: 'Grados',
                              ruta: '/directora/grados',
                              tienePermiso: true,
                            ),
                            // Calificaciones: deshabilitado temporalmente (no sirve ahorita)
                            // if (_permisos['ver_calificaciones'] == true)
                            //   _buildMenuItem(
                            //     context: context,
                            //     icon: Icons.grade,
                            //     title: 'Calificaciones',
                            //     ruta: '/directora/calificaciones',
                            //     tienePermiso: true,
                            //   ),
                          ],

                          // SECCIÓN: PAGOS
                          if (_permisos['ver_pagos'] == true) ...[
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
                            _buildMenuItem(
                              context: context,
                              icon: Icons.message,
                              title: '🧪 Prueba WhatsApp',
                              ruta: '/directora/test-whatsapp',
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
                            // Galería eliminada - no se necesita
                            // _buildMenuItem(
                            //   context: context,
                            //   icon: Icons.photo_library,
                            //   title: 'Galería de Fotos',
                            //   ruta: '/directora/galeria',
                            //   tienePermiso: true,
                            // ),
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
                        ],
                      ),
            ),
          ),

          // Footer: cambiar contraseña + cerrar sesión
          Container(
            color: Colors.white,
            child: Column(
              children: [
                Divider(color: Colors.grey[300], height: 1, thickness: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: AppColors.morado.withOpacity(0.3)),
                    ),
                    leading: Icon(Icons.password_rounded, color: AppColors.morado),
                    title: Text(
                      'Cambiar contraseña',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    subtitle: Text(
                      'Si usas Caipi2026, cámbiala aquí',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push('/cambiar-contrasena');
                    },
                  ),
                ),
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
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.morado, AppColors.rosa],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.morado.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        titulo,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
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
          context.go(ruta);
        },
      ),
    );
  }

  String _getRolLabel(String rol) {
    switch (rol) {
      case 'directora':
        return '👩‍💼 Directora';
      case 'profesor':
        return '👩‍🏫 Profesora';
      case 'profesor_admin':
        return '👩‍🏫⭐ Profesora Admin';
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
        return '/directora';
      case 'padre':
        return '/padre';
      default:
        return '/';
    }
  }
}
