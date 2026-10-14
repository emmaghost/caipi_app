import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../../models/alumno.dart';
import '../../models/grado.dart';
import '../../models/incidente.dart';
import '../../config/app_colors.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/solicitud_recogida_padre_card.dart';
import '../../widgets/ligas_padre_vista.dart';
import '../../widgets/caipi_app_bar_leading.dart';
import '../../widgets/campana_anuncios_padre.dart';
import '../../widgets/menu_padre_tile.dart';

class DetalleHijoScreen extends StatelessWidget {
  final String alumnoId;

  const DetalleHijoScreen({super.key, required this.alumnoId});

  Future<Grado?> _cargarGrado(String? gradoId) async {
    if (gradoId == null) return null;
    try {
      final response = await Supabase.instance.client
          .from('grados')
          .select()
          .eq('id', gradoId)
          .maybeSingle();
      if (response == null) return null;
      return Grado.fromJson(Map<String, dynamic>.from(response));
    } catch (_) {
      return null;
    }
  }

  /// Cargar nombre del grado desde BD
  Future<String> _cargarNombreGrado(String? gradoId) async {
    final g = await _cargarGrado(gradoId);
    return g?.nombre ?? 'Sin asignar';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Supabase.instance.client
          .from('alumnos')
          .stream(primaryKey: ['id'])
          .eq('id', alumnoId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Scaffold(
            body: Center(child: Text('Alumno no encontrado')),
          );
        }

        final alumno = Alumno.fromJson(snapshot.data!.first);

        return Scaffold(
          drawer: const AppDrawer(),
          appBar: AppBar(
        leading: const CaipiAppBarLeading(),
            title: Text(alumno.nombreCompleto),
            backgroundColor: const Color(0xFFEC407A), // Rosa pastel (igual que vista padre)
            foregroundColor: Colors.white,
            actions: [
              const CampanaAnunciosPadre(),
              IconButton(
                icon: const Icon(Icons.home),
                onPressed: () => context.go('/padre'),
                tooltip: 'Ir al inicio',
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Info del alumno (mejorado)
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      colors: [
                        AppColors.morado.withOpacity(0.1),
                        Colors.white,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      // Avatar mejorado con icono de silueta
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [AppColors.morado, AppColors.azulOscuro],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.morado.withOpacity(0.4),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 38,
                          backgroundColor: Colors.transparent,
                          backgroundImage: alumno.fotoUrl != null
                              ? CachedNetworkImageProvider(alumno.fotoUrl!)
                              : null,
                          child: alumno.fotoUrl == null
                              ? const Icon(
                                  Icons.child_care,
                                  size: 45,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              alumno.nombreCompleto,
                              style: GoogleFonts.fredoka(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.azulOscuro,
                              ),
                            ),
                            const SizedBox(height: 8),
                            
                            // Grado (cargar nombre)
                            FutureBuilder<String>(
                              future: _cargarNombreGrado(alumno.gradoId),
                              builder: (context, snapshot) {
                                return Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: AppColors.morado.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.school,
                                        size: 16,
                                        color: AppColors.morado,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      snapshot.data ?? 'Sin asignar',
                                      style: GoogleFonts.poppins(
                                        fontSize: 15,
                                        color: AppColors.morado,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 6),
                            
                            // Edad (color oscuro para que se lea bien)
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppColors.morado.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.cake,
                                    size: 16,
                                    color: AppColors.morado,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${alumno.edad} años',
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    color: AppColors.negro,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              SolicitudRecogidaPadreCard(
                alumnoId: alumno.id,
                alumnoNombre: alumno.nombreCompleto,
              ),
              const SizedBox(height: 16),

              Text(
                'Menú',
                style: GoogleFonts.fredoka(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.azulOscuro,
                ),
              ),
              const SizedBox(height: 10),
              FutureBuilder<Grado?>(
                future: _cargarGrado(alumno.gradoId),
                builder: (context, gradoSnap) {
                  final muestraPagos =
                      gradoSnap.data?.muestraModuloPagos == true;
                  return StreamBuilder<List<Map<String, dynamic>>>(
                    stream: Supabase.instance.client
                        .from('incidentes')
                        .stream(primaryKey: ['id'])
                        .eq('alumno_id', alumno.id),
                    builder: (context, incSnap) {
                      final nuevas = (incSnap.data ?? const [])
                          .map((j) => Incidente.fromJson(j))
                          .where((i) => i.esNueva)
                          .length;
                      return GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.22,
                        children: [
                          if (muestraPagos)
                            MenuPadreTile(
                              titulo: 'Pagos',
                              subtitulo: 'Pendientes o pagados',
                              icono: Icons.payments_outlined,
                              color: Colors.orange.shade800,
                              onTap: () => context.push(
                                '/padre/hijo/${alumno.id}/pagos',
                                extra: {'alumnoNombre': alumno.nombreCompleto},
                              ),
                            ),
                          MenuPadreTile(
                            titulo: 'Incidentes',
                            subtitulo: nuevas > 0
                                ? '$nuevas sin leer'
                                : 'Avisos de tu hijo',
                            icono: Icons.favorite_outline,
                            color: Colors.amber.shade800,
                            badge: nuevas,
                            onTap: () => context.push(
                              '/padre/hijo/${alumno.id}/incidentes',
                              extra: {'alumnoNombre': alumno.nombreCompleto},
                            ),
                          ),
                          MenuPadreTile(
                            titulo: 'Personas',
                            subtitulo: 'Quién puede recogerlo',
                            icono: Icons.verified_user,
                            color: Colors.green.shade700,
                            onTap: () => context.push(
                              '/padre/hijo/${alumno.id}/personas-autorizadas',
                              extra: {'alumnoNombre': alumno.nombreCompleto},
                            ),
                          ),
                          MenuPadreTile(
                            titulo: 'Bitácora',
                            subtitulo: 'Cómo le fue en el día',
                            icono: Icons.assignment_outlined,
                            color: AppColors.morado,
                            onTap: () => context.push(
                              '/padre/hijo/${alumno.id}/bitacora',
                              extra: {'alumnoNombre': alumno.nombreCompleto},
                            ),
                          ),
                          MenuPadreTile(
                            titulo: 'Indicadores',
                            subtitulo: 'Seguimiento del grado',
                            icono: Icons.auto_graph,
                            color: AppColors.purpura,
                            onTap: () => context.push(
                              '/padre/hijo/${alumno.id}/indicadores',
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 12),

              LigasPadreVista(alumnoId: alumno.id),
            ],
          ),
        );
      },
    );
  }
}
