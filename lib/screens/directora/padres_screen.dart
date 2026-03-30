import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/app_colors.dart';
import '../../widgets/app_drawer.dart';

class PadresScreen extends StatelessWidget {
  const PadresScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grisClaro,
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Text(
          'Padres de Familia',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => context.go('/directora'),
            tooltip: 'Ir al inicio',
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: Supabase.instance.client
            .from('usuarios')
            .stream(primaryKey: ['id'])
            .map((data) => data
                .where((u) => u['rol'] == 'padre')
                .toList()),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final padres = snapshot.data ?? [];

          if (padres.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.family_restroom,
                    size: 80,
                    color: AppColors.gris.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay padres registrados',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      color: AppColors.gris,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Presiona + para agregar uno',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppColors.gris,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: padres.length,
            itemBuilder: (context, index) {
              final padre = padres[index];
              return _buildPadreCard(context, padre);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/directora/padres/crear'),
        heroTag: 'crear_padre',
        backgroundColor: AppColors.rosa,
        icon: const Icon(Icons.person_add),
        label: const Text('Agregar Padre'),
      ),
    );
  }

  Widget _buildPadreCard(BuildContext context, Map<String, dynamic> padre) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => context.push('/directora/padres/ver/${padre['id']}'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: Supabase.instance.client
                .from('alumnos')
                .stream(primaryKey: ['id'])
                .map((data) => data
                    .where((a) => a['padre_id'] == padre['id'] && a['activo'] == true)
                    .toList()),
            builder: (context, alumnosSnapshot) {
              final hijos = alumnosSnapshot.data ?? [];
              
              return Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.rosa, AppColors.naranja],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.family_restroom,
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
                          padre['nombre'] ?? 'Sin nombre',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.email, size: 14, color: AppColors.gris),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                padre['email'] ?? '',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: AppColors.gris,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.child_care, size: 14, color: AppColors.azul),
                            const SizedBox(width: 4),
                            Text(
                              '${hijos.length} hijo${hijos.length != 1 ? 's' : ''}',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: AppColors.azul,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: AppColors.gris,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
