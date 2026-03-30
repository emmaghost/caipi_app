import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/clase_extracurricular.dart';
import '../../config/app_colors.dart';
import '../../widgets/app_drawer.dart';

class ClasesExtracurricularesScreen extends StatefulWidget {
  const ClasesExtracurricularesScreen({super.key});

  @override
  State<ClasesExtracurricularesScreen> createState() => _ClasesExtracurricularesScreenState();
}

class _ClasesExtracurricularesScreenState extends State<ClasesExtracurricularesScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clases Extracurriculares'),
        backgroundColor: AppColors.azulOscuro,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => context.go('/directora'),
            tooltip: 'Ir al inicio',
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: Supabase.instance.client
            .from('clases_extracurriculares')
            .stream(primaryKey: ['id'])
            .order('nombre'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final clasesData = snapshot.data ?? [];
          final clases = clasesData.map((json) => ClaseExtracurricular.fromJson(json)).toList();

          if (clases.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.sports_soccer, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No hay clases extracurriculares',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Agrega la primera clase',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: clases.length,
            itemBuilder: (context, index) {
              final clase = clases[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: clase.activo ? AppColors.verdeClaro : Colors.grey,
                    width: 2,
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: clase.activo ? AppColors.verdeClaro : Colors.grey,
                    radius: 28,
                    child: Icon(
                      _getIconForClass(clase.nombre),
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  title: Text(
                    clase.nombre,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: clase.activo ? Colors.black87 : Colors.grey,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      if (clase.descripcion != null)
                        Text(
                          clase.descripcion!,
                          style: GoogleFonts.poppins(fontSize: 13),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.schedule, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            clase.horario,
                            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.people, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            'Cupo: ${clase.cupoMaximo}',
                            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                          ),
                          if (clase.costoMensual != null) ...[
                            const SizedBox(width: 16),
                            Icon(Icons.attach_money, size: 14, color: Colors.grey[600]),
                            Text(
                              '\$${clase.costoMensual!.toStringAsFixed(0)}/mes',
                              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ],
                      ),
                      if (clase.permiteExternos) ...[
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.naranjaClaro.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Permite externos',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: AppColors.naranjaClaro,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: AppColors.azulOscuro),
                        onPressed: () => context.push('/directora/clases-extracurriculares/editar/${clase.id}'),
                        tooltip: 'Editar',
                      ),
                      IconButton(
                        icon: Icon(
                          clase.activo ? Icons.check_circle : Icons.cancel,
                          color: clase.activo ? Colors.green : Colors.grey,
                        ),
                        onPressed: () => _toggleActivo(clase),
                        tooltip: clase.activo ? 'Desactivar' : 'Activar',
                      ),
                    ],
                  ),
                  onTap: () => context.push('/directora/clases-extracurriculares/editar/${clase.id}'),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/directora/clases-extracurriculares/crear'),
        backgroundColor: AppColors.azulOscuro,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'Nueva Clase',
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  IconData _getIconForClass(String nombre) {
    final nombreLower = nombre.toLowerCase();
    if (nombreLower.contains('fútbol') || nombreLower.contains('futbol')) {
      return Icons.sports_soccer;
    } else if (nombreLower.contains('danza') || nombreLower.contains('baile')) {
      return Icons.music_note;
    } else if (nombreLower.contains('arte') || nombreLower.contains('pintura')) {
      return Icons.palette;
    } else if (nombreLower.contains('música') || nombreLower.contains('musica')) {
      return Icons.piano;
    } else if (nombreLower.contains('inglés') || nombreLower.contains('ingles')) {
      return Icons.language;
    } else if (nombreLower.contains('natación') || nombreLower.contains('natacion')) {
      return Icons.pool;
    } else if (nombreLower.contains('teatro')) {
      return Icons.theater_comedy;
    } else if (nombreLower.contains('yoga') || nombreLower.contains('taekwondo')) {
      return Icons.self_improvement;
    }
    return Icons.school;
  }

  Future<void> _toggleActivo(ClaseExtracurricular clase) async {
    try {
      await Supabase.instance.client
          .from('clases_extracurriculares')
          .update({'activo': !clase.activo})
          .eq('id', clase.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              clase.activo ? 'Clase desactivada' : 'Clase activada',
            ),
            backgroundColor: clase.activo ? Colors.orange : Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
