import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/supabase_service.dart';
import '../../models/profesor.dart';
import '../../models/grado.dart';
import '../../config/app_colors.dart';
import '../../widgets/app_drawer.dart';

class ProfesoresScreen extends StatelessWidget {
  const ProfesoresScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grisClaro,
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Text(
          'Profesoras',
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
            .from('profesores')
            .stream(primaryKey: ['id']),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final profesoresData = snapshot.data ?? [];
          final profesoresActivos = profesoresData
              .where((p) => p['activo'] == true)
              .toList();

          if (profesoresActivos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_add_outlined,
                    size: 80,
                    color: AppColors.gris.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay profesores registrados',
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
            itemCount: profesoresActivos.length,
            itemBuilder: (context, index) {
              final profesorData = profesoresActivos[index];
              return _buildProfesorCard(context, profesorData);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/directora/profesores/crear'),
        heroTag: 'crear_profesor',
        backgroundColor: AppColors.purpura,
        icon: const Icon(Icons.person_add),
        label: const Text('Agregar Profesora'),
      ),
    );
  }

  Widget _buildProfesorCard(BuildContext context, Map<String, dynamic> profesorData) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => context.push('/directora/profesores/editar/${profesorData['id']}'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: Supabase.instance.client
                .from('usuarios')
                .stream(primaryKey: ['id'])
                .map((data) => data
                    .where((u) => u['id'] == profesorData['usuario_id'])
                    .toList()),
            builder: (context, usuarioSnapshot) {
              final usuario = usuarioSnapshot.data?.firstOrNull;
              
              return StreamBuilder<List<Map<String, dynamic>>>(
                stream: Supabase.instance.client
                    .from('grados')
                    .stream(primaryKey: ['id'])
                    .map((data) => data
                        .where((g) => g['id'] == (profesorData['grado_id'] ?? ''))  // Corregido: era 'grupo_asignado'
                        .toList()),
                builder: (context, gradoSnapshot) {
                  final grado = gradoSnapshot.data?.firstOrNull;
                  
                  return Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.purpura, AppColors.rosa],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.person,
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
                              usuario?['nombre'] ?? 'Cargando...',
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
                                Text(
                                  usuario?['email'] ?? '',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: AppColors.gris,
                                  ),
                                ),
                              ],
                            ),
                            if (grado != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.school, size: 14, color: AppColors.azul),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Grupo: ${grado['nombre']}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: AppColors.azul,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ] else ...[
                              const SizedBox(height: 4),
                              Text(
                                'Sin grupo asignado',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: AppColors.naranja,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: AppColors.azulOscuro),
                            onPressed: () => context.push('/directora/profesores/editar/${profesorData['id']}'),
                            tooltip: 'Editar',
                          ),
                          IconButton(
                            icon: const Icon(Icons.key, color: AppColors.naranja),
                            onPressed: () => context.push(
                              '/directora/profesores/${profesorData['id']}/permisos?nombre=${Uri.encodeComponent(usuario?['nombre'] ?? '')}',
                            ),
                            tooltip: 'Permisos',
                          ),
                        ],
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
