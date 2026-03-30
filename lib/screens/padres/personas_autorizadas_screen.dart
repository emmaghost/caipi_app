import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../config/app_colors.dart';
import '../../widgets/app_drawer.dart';

class PersonasAutorizadasPadreScreen extends StatelessWidget {
  final String alumnoId;
  final String alumnoNombre;

  const PersonasAutorizadasPadreScreen({
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
                color: Colors.white70,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFEC407A), // Rosa pastel (igual que Mis Hijos)
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => context.go('/padre'),
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
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: const LinearGradient(
            colors: [Color(0xFFEC407A), Color(0xFFE91E63)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.pink.shade400.withOpacity(0.5),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () => _mostrarDialogoAgregar(context),
          heroTag: 'agregar_persona',
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          icon: const Icon(Icons.person_add, size: 28),
          label: Text(
            'Agregar Persona',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 17,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPersonaCard(BuildContext context, Map<String, dynamic> persona) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 4,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              AppColors.verdeClaro.withOpacity(0.2),
              AppColors.rosaClaro.withOpacity(0.3),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.verdeClaro, AppColors.rosa],
                      ),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.rosa.withOpacity(0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.verified_user,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          persona['nombre'] ?? '',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1A237E),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.morado.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.family_restroom, size: 16, color: Colors.white),
                              const SizedBox(width: 6),
                              Text(
                                persona['parentesco'] ?? '',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.rosa.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.phone, size: 16, color: Colors.white),
                              const SizedBox(width: 6),
                              Text(
                                persona['telefono'] ?? '',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (persona['identificacion'] != null && persona['identificacion'].toString().isNotEmpty) ...[
                          const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.naranja.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                            child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.badge, size: 16, color: Colors.white),
                                const SizedBox(width: 6),
                                Text(
                                  'ID: ${persona['identificacion']}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: Colors.white,
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
                  Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.morado.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.edit, color: Color(0xFF7B1FA2), size: 24),
                          onPressed: () => _mostrarDialogoEditar(context, persona),
                          tooltip: 'Editar',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red, size: 24),
                          onPressed: () => _eliminarPersona(context, persona['id']),
                          tooltip: 'Eliminar',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          
          // Botón para generar QR temporal (MEJORADO)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(12),
            child: ElevatedButton.icon(
              onPressed: () => _generarQrTemporal(context, persona),
              icon: const Icon(
                Icons.qr_code_2,
                size: 28,
              ),
              label: Text(
                'Generar QR Temporal',
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32), // Verde oscuro para que se vea el texto
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
              ),
            ),
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
        title: Text(
          'Agregar Persona Autorizada',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nombreController,
                decoration: InputDecoration(
                  labelText: 'Nombre completo *',
                  prefixIcon: const Icon(Icons.person),
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
                  prefixIcon: const Icon(Icons.family_restroom),
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
                  prefixIcon: const Icon(Icons.phone),
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
                  prefixIcon: const Icon(Icons.badge),
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
            child: Text('Cancelar', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () {
              if (nombreController.text.trim().isEmpty ||
                  parentescoController.text.trim().isEmpty ||
                  telefonoController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Por favor completa todos los campos obligatorios'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32), // Verde oscuro para que se vea el botón
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              elevation: 2,
            ),
            child: Text('Agregar', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16)),
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
            SnackBar(
              content: Text(
                'Persona agregada exitosamente',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: AppColors.verdeClaro,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
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

  Future<void> _mostrarDialogoEditar(BuildContext context, Map<String, dynamic> persona) async {
    final nombreController = TextEditingController(text: persona['nombre']);
    final parentescoController = TextEditingController(text: persona['parentesco']);
    final telefonoController = TextEditingController(text: persona['telefono']);
    final identificacionController = TextEditingController(text: persona['identificacion'] ?? '');

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Editar Persona Autorizada',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nombreController,
                decoration: InputDecoration(
                  labelText: 'Nombre completo *',
                  prefixIcon: const Icon(Icons.person),
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
                  prefixIcon: const Icon(Icons.family_restroom),
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
                  prefixIcon: const Icon(Icons.phone),
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
                  prefixIcon: const Icon(Icons.badge),
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
            child: Text('Cancelar', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.azulOscuro,
              foregroundColor: Colors.white,
            ),
            child: Text('Guardar', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await Supabase.instance.client
            .from('personas_autorizadas')
            .update({
          'nombre': nombreController.text.trim(),
          'parentesco': parentescoController.text.trim(),
          'telefono': telefonoController.text.trim(),
          'identificacion': identificacionController.text.trim().isEmpty
              ? null
              : identificacionController.text.trim(),
        }).eq('id', persona['id']);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Persona actualizada exitosamente',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: AppColors.verdeClaro,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
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

  Future<void> _eliminarPersona(BuildContext context, String personaId) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Eliminar Persona',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          '¿Estás seguro de eliminar esta persona autorizada?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Eliminar', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
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
            SnackBar(
              content: Text(
                'Persona eliminada',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: AppColors.verdeClaro,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
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

  Future<void> _generarQrTemporal(BuildContext context, Map<String, dynamic> persona) async {
    try {
      // Generar código único (RPC retorna TEXT; no usar .select())
      final codigoResponse = await Supabase.instance.client.rpc('generar_codigo_qr');
      final codigo = (codigoResponse is String
          ? codigoResponse
          : (codigoResponse is List && (codigoResponse as List).isNotEmpty
              ? (codigoResponse as List).first
              : null)) as String?;
      if (codigo == null || codigo.isEmpty) throw Exception('No se obtuvo código QR');
      
      // Crear QR temporal (válido por 24 horas)
      await Supabase.instance.client.from('qr_temporales').insert({
        'codigo': codigo,
        'persona_autorizada_id': persona['id'],
        'alumno_id': alumnoId,
        'fecha_expiracion': DateTime.now().add(const Duration(hours: 24)).toIso8601String(),
        'generado_por': Supabase.instance.client.auth.currentUser?.id,
        'notas': 'QR generado desde app móvil',
      });
      
      if (context.mounted) {
        // Navegar a pantalla de QR
        context.push(
          '/padre/qr-temporal',
          extra: {
            'codigo': codigo,
            'nombrePersona': persona['nombre'],
            'alumnoNombre': alumnoNombre,
          },
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generando QR: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
