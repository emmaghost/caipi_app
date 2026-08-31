import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../../models/alumno.dart';
// Calificaciones (no implementado): ver historial en git si se reactiva
import '../../models/incidente.dart';
import '../../config/app_colors.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/solicitud_recogida_padre_card.dart';
import '../../widgets/ligas_padre_vista.dart';
import '../directora/portage_evaluacion_screen.dart';

class DetalleHijoScreen extends StatelessWidget {
  final String alumnoId;

  const DetalleHijoScreen({super.key, required this.alumnoId});

  /// Cargar nombre del grado desde BD
  Future<String> _cargarNombreGrado(String? gradoId) async {
    if (gradoId == null) return 'Sin asignar';
    
    try {
      final response = await Supabase.instance.client
          .from('grados')
          .select('nombre')
          .eq('id', gradoId)
          .maybeSingle();
      
      if (response == null) return 'Sin asignar';
      
      return response['nombre'] as String? ?? 'Sin asignar';
    } catch (e) {
      print('Error cargando grado: $e');
      return 'Sin asignar';
    }
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
            title: Text(alumno.nombreCompleto),
            backgroundColor: const Color(0xFFEC407A), // Rosa pastel (igual que vista padre)
            foregroundColor: Colors.white,
            actions: [
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

              // —— Bitácora (antes que pagos) ——
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: InkWell(
                  onTap: () => context.push(
                    '/padre/hijo/${alumno.id}/bitacora',
                    extra: {'alumnoNombre': alumno.nombreCompleto},
                  ),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.morado.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.morado.withOpacity(0.35),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.morado,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.assignment_outlined,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bitácora',
                                style: GoogleFonts.fredoka(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.morado,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Cómo le fue por día o por mes',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: AppColors.grisOscuro,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios,
                            color: AppColors.morado, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              LigasPadreVista(alumnoId: alumno.id),
              const SizedBox(height: 12),
              PortagePadreVista(alumno: alumno),
              const SizedBox(height: 12),

              // —— Pagos (solo consulta; se paga en escuela) ——
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: InkWell(
                  onTap: () => context.push(
                    '/padre/hijo/${alumno.id}/pagos',
                    extra: {'alumnoNombre': alumno.nombreCompleto},
                  ),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.orange.shade200, width: 1),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade700,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.payments_outlined,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pagos',
                                style: GoogleFonts.fredoka(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Pendientes o pagados · solo ver',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: AppColors.grisOscuro,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios,
                            color: Colors.orange.shade800, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Personas Autorizadas (mismo estilo que ¡Todo bien!)
              const SizedBox(height: 16),

              SolicitudRecogidaPadreCard(
                alumnoId: alumno.id,
                alumnoNombre: alumno.nombreCompleto,
              ),
              const SizedBox(height: 16),

              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: InkWell(
                  onTap: () => context.push(
                    '/padre/hijo/${alumno.id}/personas-autorizadas',
                    extra: {'alumnoNombre': alumno.nombreCompleto},
                  ),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.green[200]!, width: 1),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.green[600],
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withOpacity(0.4),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.verified_user,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Personas Autorizadas',
                                style: GoogleFonts.fredoka(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[800],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Gestiona quién puede recoger a tu hijo/a',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: AppColors.grisOscuro,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios, color: Colors.green[700], size: 18),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Calificaciones — oculto hasta implementar
              // _SeccionCalificaciones(alumnoId: alumnoId),
              // const SizedBox(height: 24),

              // Incidentes
              _SeccionIncidentes(alumnoId: alumnoId),
            ],
          ),
        );
      },
    );
  }
}

// ==================== SECCIÓN INCIDENTES ====================

class _SeccionIncidentes extends StatelessWidget {
  final String alumnoId;

  const _SeccionIncidentes({required this.alumnoId});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange),
            const SizedBox(width: 8),
            Text(
              'Incidentes y Reportes',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: Supabase.instance.client
              .from('incidentes')
              .stream(primaryKey: ['id'])
              .eq('alumno_id', alumnoId)
              .order('fecha', ascending: false),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    gradient: LinearGradient(
                      colors: [
                        Colors.green[400]!.withOpacity(0.2),
                        Colors.green[100]!.withOpacity(0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green[600],
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.4),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.check_circle,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '¡Todo bien! 🎉',
                              style: GoogleFonts.fredoka(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[800],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'No hay incidentes reportados',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: AppColors.grisOscuro,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final incidentesData = snapshot.data!;
            final incidentes = incidentesData
                .map((json) => Incidente.fromJson(json))
                .toList();

            // Contar por nivel
            final graves = incidentes.where((i) => i.nivel >= 4).length;

            return Column(
              children: [
                // Resumen si hay incidentes graves
                if (graves > 0)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red, width: 2),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.notifications_active, color: Colors.red),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '$graves incidente${graves > 1 ? 's' : ''} grave${graves > 1 ? 's' : ''}',
                            style: TextStyle(
                              color: Colors.red[900],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Lista de incidentes
                ...incidentes.map((incidente) {
                  final colorNivel = _getColorNivel(incidente.nivel);
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    elevation: incidente.nivel >= 4 ? 3 : 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: incidente.nivel >= 4
                          ? BorderSide(color: colorNivel, width: 2)
                          : BorderSide.none,
                    ),
                    child: ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: colorNivel,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            incidente.emoji,
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                      ),
                      title: Text(
                        incidente.titulo,
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            incidente.descripcion,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.calendar_today, size: 12, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(
                                DateFormat('dd/MM/yyyy HH:mm', 'es_MX').format(incidente.fecha),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: colorNivel.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'N${incidente.nivel}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: colorNivel,
                              ),
                            ),
                          ),
                          if (incidente.padreNotificado)
                            const Icon(Icons.notifications_active, 
                                color: Colors.orange, size: 16),
                        ],
                      ),
                      isThreeLine: true,
                      onTap: () => _mostrarDetalleIncidente(context, incidente),
                    ),
                  );
                }).toList(),
              ],
            );
          },
        ),
      ],
    );
  }

  Color _getColorNivel(int nivel) {
    switch (nivel) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.yellow[700]!;
      case 3:
        return Colors.orange;
      case 4:
        return Colors.deepOrange;
      case 5:
        return Colors.red[900]!;
      default:
        return Colors.grey;
    }
  }

  void _mostrarDetalleIncidente(BuildContext context, Incidente incidente) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text(incidente.emoji),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                incidente.titulo,
                style: GoogleFonts.fredoka(),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetalleItem(
                'Nivel',
                '${incidente.nivel} - ${incidente.nivelLabel}',
                _getColorNivel(incidente.nivel),
              ),
              const Divider(),
              _buildDetalleItem(
                'Descripción',
                incidente.descripcion,
                Colors.black87,
              ),
              const Divider(),
              _buildDetalleItem(
                'Fecha',
                DateFormat('dd/MM/yyyy HH:mm', 'es_MX').format(incidente.fecha),
                Colors.black87,
              ),
              if (incidente.observaciones != null) ...[
                const Divider(),
                _buildDetalleItem(
                  'Observaciones',
                  incidente.observaciones!,
                  Colors.black87,
                ),
              ],
              if (incidente.padreNotificado) ...[
                const Divider(),
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.notifications_active, color: Colors.orange, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Fue notificado',
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetalleItem(String label, String valor, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          valor,
          style: TextStyle(
            fontSize: 14,
            color: color,
          ),
        ),
      ],
    );
  }
}
