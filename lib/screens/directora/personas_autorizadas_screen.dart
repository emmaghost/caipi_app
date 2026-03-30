import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/app_colors.dart';
import '../../widgets/app_drawer.dart';

class PersonasAutorizadasScreen extends StatelessWidget {
  final String alumnoId;
  final String alumnoNombre;

  const PersonasAutorizadasScreen({
    super.key,
    required this.alumnoId,
    required this.alumnoNombre,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grisClaro,
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personas Autorizadas',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              alumnoNombre,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.gris,
              ),
            ),
          ],
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
            .from('personas_autorizadas')
            .stream(primaryKey: ['id'])
            .map((data) => data
                .where((p) => p['alumno_id'] == alumnoId)
                .toList()),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final personas = snapshot.data ?? [];

          if (personas.isEmpty) {
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
                    'No hay personas autorizadas',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      color: AppColors.gris,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Presiona + para agregar una',
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
            itemCount: personas.length,
            itemBuilder: (context, index) {
              final persona = personas[index];
              return _buildPersonaCard(context, persona);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarDialogoAgregar(context),
        heroTag: 'agregar_persona',
        backgroundColor: AppColors.verde,
        icon: const Icon(Icons.person_add),
        label: const Text('Agregar Persona'),
      ),
    );
  }

  Widget _buildPersonaCard(BuildContext context, Map<String, dynamic> persona) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.verde, AppColors.turquesa],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.verified_user,
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
                    persona['nombre'] ?? '',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.family_restroom, size: 14, color: AppColors.gris),
                      const SizedBox(width: 4),
                      Text(
                        persona['parentesco'] ?? '',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.gris,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.phone, size: 14, color: AppColors.azul),
                      const SizedBox(width: 4),
                      Text(
                        persona['telefono'] ?? '',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.azul,
                        ),
                      ),
                    ],
                  ),
                  if (persona['identificacion'] != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.badge, size: 14, color: AppColors.naranja),
                        const SizedBox(width: 4),
                        Text(
                          'ID: ${persona['identificacion']}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.naranja,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: AppColors.rojo),
              onPressed: () => _eliminarPersona(context, persona['id']),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _mostrarDialogoAgregar(BuildContext context) async {
    final nombreController = TextEditingController();
    final parentescoController = TextEditingController();
    final telefonoController = TextEditingController();
    final identificacionController = TextEditingController();

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar Persona Autorizada'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nombreController,
                decoration: InputDecoration(
                  labelText: 'Nombre completo *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: parentescoController,
                decoration: InputDecoration(
                  labelText: 'Parentesco *',
                  hintText: 'Ej: Tío, Abuela, Niñera',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: telefonoController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Teléfono *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: identificacionController,
                decoration: InputDecoration(
                  labelText: 'Identificación (opcional)',
                  hintText: 'INE, Pasaporte, etc.',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.verde,
            ),
            child: const Text('Agregar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await Supabase.instance.client.from('personas_autorizadas').insert({
          'alumno_id': alumnoId,
          'nombre': nombreController.text.trim(),
          'parentesco': parentescoController.text.trim(),
          'telefono': telefonoController.text.trim(),
          'identificacion': identificacionController.text.trim().isEmpty
              ? null
              : identificacionController.text.trim(),
        });

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Persona agregada exitosamente'),
              backgroundColor: AppColors.verde,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppColors.rojo,
            ),
          );
        }
      }
    }
  }

  Future<void> _eliminarPersona(BuildContext context, String personaId) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Persona'),
        content: const Text('¿Estás seguro de eliminar esta persona autorizada?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.rojo,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await Supabase.instance.client
            .from('personas_autorizadas')
            .delete()
            .eq('id', personaId);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Persona eliminada'),
              backgroundColor: AppColors.verde,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppColors.rojo,
            ),
          );
        }
      }
    }
  }
}
