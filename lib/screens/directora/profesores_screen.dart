import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/app_colors.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_drawer.dart';

class ProfesoresScreen extends StatefulWidget {
  const ProfesoresScreen({super.key});

  @override
  State<ProfesoresScreen> createState() => _ProfesoresScreenState();
}

class _ProfesoresScreenState extends State<ProfesoresScreen> {
  /// Al volver de crear/editar, el stream a veces no emite al instante; forzamos nueva suscripción.
  int _streamEpoch = 0;

  Future<void> _abrirCrear() async {
    final ok = await context.push<bool>('/directora/profesores/crear');
    if (ok == true && mounted) setState(() => _streamEpoch++);
  }

  Future<void> _abrirEditar(String id) async {
    final ok = await context.push<bool>('/directora/profesores/editar/$id');
    if (ok == true && mounted) setState(() => _streamEpoch++);
  }

  Future<void> _eliminarProfesora(
    Map<String, dynamic> profesorData,
    String? nombre,
  ) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar profesora?'),
        content: Text(
          'Se desactivará el acceso de ${nombre ?? 'esta profesora'} '
          'y ya no aparecerá como activa.\n\n'
          'No se borra el historial; solo se quita el acceso.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.rojo),
            child: const Text('Eliminar acceso'),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;

    try {
      final client = Supabase.instance.client;
      final profesorId = profesorData['id'] as String;
      final usuarioId = profesorData['usuario_id'] as String?;

      await client
          .from('profesores')
          .update({
            'activo': false,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', profesorId);

      if (usuarioId != null && usuarioId.isNotEmpty) {
        await client
            .from('usuarios')
            .update({'activo': false})
            .eq('id', usuarioId);
      }

      if (!mounted) return;
      setState(() => _streamEpoch++);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profesora desactivada'),
          backgroundColor: AppColors.verde,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo eliminar: $e'),
          backgroundColor: AppColors.rojo,
        ),
      );
    }
  }

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
        key: ValueKey(_streamEpoch),
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

          final profesoresData = List<Map<String, dynamic>>.from(
            snapshot.data ?? [],
          );
          profesoresData.sort((a, b) {
            final aActivo = a['activo'] == true ? 0 : 1;
            final bActivo = b['activo'] == true ? 0 : 1;
            return aActivo.compareTo(bActivo);
          });

          if (profesoresData.isEmpty) {
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
            itemCount: profesoresData.length,
            itemBuilder: (context, index) {
              final profesorData = profesoresData[index];
              return _buildProfesorCard(
                context,
                profesorData,
                _abrirEditar,
                onEliminar: _eliminarProfesora,
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirCrear,
        heroTag: 'crear_profesor',
        backgroundColor: AppColors.purpura,
        icon: const Icon(Icons.person_add),
        label: const Text('Agregar Profesora'),
      ),
    );
  }

  Widget _buildProfesorCard(
    BuildContext context,
    Map<String, dynamic> profesorData,
    Future<void> Function(String id) abrirEditar, {
    required Future<void> Function(Map<String, dynamic> data, String? nombre)
        onEliminar,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => abrirEditar(profesorData['id'] as String),
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
                        .where((g) => g['id'] == (profesorData['grado_id'] ?? ''))
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
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    usuario?['nombre'] ?? 'Cargando...',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (usuario?['rol'] == 'profesor_admin')
                                  Container(
                                    margin: const EdgeInsets.only(left: 6),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.purpura.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Admin',
                                      style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.purpura,
                                      ),
                                    ),
                                  ),
                                if ((profesorData['especialidad'] as String? ?? '')
                                    .toLowerCase()
                                    .contains('ingles') ||
                                    (profesorData['especialidad'] as String? ?? '')
                                        .toLowerCase()
                                        .contains('inglés'))
                                  Container(
                                    margin: const EdgeInsets.only(left: 6),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.azul.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Inglés',
                                      style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.azul,
                                      ),
                                    ),
                                  ),
                                if (profesorData['activo'] != true ||
                                    usuario?['activo'] == false)
                                  Container(
                                    margin: const EdgeInsets.only(left: 6),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.rojo.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Sin acceso',
                                      style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.rojo,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.email, size: 14, color: AppColors.gris),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    usuario?['email'] ?? '',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: AppColors.gris,
                                    ),
                                    overflow: TextOverflow.ellipsis,
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
                            onPressed: () => abrirEditar(profesorData['id'] as String),
                            tooltip: 'Editar',
                          ),
                          IconButton(
                            icon: const Icon(Icons.key, color: AppColors.naranja),
                            onPressed: () => context.push(
                              '/directora/profesores/${profesorData['id']}/permisos?nombre=${Uri.encodeComponent(usuario?['nombre'] ?? '')}',
                            ),
                            tooltip: 'Permisos',
                          ),
                          if ((context.read<AuthService>().currentUser?.esDirectora ??
                                  false) &&
                              profesorData['activo'] == true &&
                              usuario?['activo'] != false)
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: AppColors.rojo),
                              onPressed: () => onEliminar(
                                profesorData,
                                usuario?['nombre'] as String?,
                              ),
                              tooltip: 'Eliminar (desactivar)',
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
