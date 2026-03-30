import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/app_colors.dart';
import '../../widgets/app_drawer.dart';

class AnunciosScreen extends StatelessWidget {
  const AnunciosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.campaign, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              'Anuncios',
              style: GoogleFonts.fredoka(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.azulOscuro,
        actions: [
          IconButton(
            icon: const Icon(Icons.home, color: Colors.white),
            onPressed: () => GoRouter.of(context).go('/directora'),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.azulOscuro.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: Supabase.instance.client
              .from('anuncios')
              .stream(primaryKey: ['id'])
              .order('fecha', ascending: false),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      'Error al cargar anuncios',
                      style: GoogleFonts.poppins(fontSize: 18),
                    ),
                  ],
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.campaign_outlined,
                        size: 80,
                        color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No hay anuncios publicados',
                      style: GoogleFonts.fredoka(
                        fontSize: 18,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        GoRouter.of(context).push('/directora/anuncios/crear');
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Crear Primer Anuncio'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            final anuncios = snapshot.data!;

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: anuncios.length,
              itemBuilder: (context, index) {
                final anuncio = anuncios[index];
                return _AnuncioCard(anuncio: anuncio);
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          GoRouter.of(context).push('/directora/anuncios/crear');
        },
        backgroundColor: AppColors.verdeClaro,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'Nuevo Anuncio',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _AnuncioCard extends StatelessWidget {
  final Map<String, dynamic> anuncio;

  const _AnuncioCard({required this.anuncio});

  @override
  Widget build(BuildContext context) {
    final fecha = DateTime.parse(anuncio['fecha']);
    final paraTodos = anuncio['para_todos'] as bool? ?? false;
    final grados = (anuncio['grados'] as List<dynamic>?)?.cast<String>() ?? [];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          _mostrarDetalleAnuncio(context);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.rosaClaro, AppColors.moradoClaro],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.campaign, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          anuncio['titulo'] as String,
                          style: GoogleFonts.fredoka(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.azulOscuro,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.calendar_today,
                                size: 12, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('dd/MM/yyyy', 'es_MX').format(fecha),
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () {
                      GoRouter.of(context).push(
                        '/directora/anuncios/editar/${anuncio['id']}',
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Contenido
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  anuncio['mensaje'] as String,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[800],
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 12),

              // Destinatarios
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (paraTodos)
                    _buildChip(
                      icon: Icons.public,
                      label: 'Todos',
                      color: Colors.green,
                    )
                  else
                    ...grados.map((grado) {
                      return FutureBuilder<String>(
                        future: _obtenerNombreGrado(grado),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const SizedBox.shrink();
                          }
                          return _buildChip(
                            icon: Icons.school,
                            label: snapshot.data!,
                            color: AppColors.moradoClaro,
                          );
                        },
                      );
                    }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Future<String> _obtenerNombreGrado(String gradoId) async {
    try {
      final response = await Supabase.instance.client
          .from('grados')
          .select('nombre')
          .eq('id', gradoId)
          .single();
      return response['nombre'] as String;
    } catch (e) {
      return 'Grado';
    }
  }

  void _mostrarDetalleAnuncio(BuildContext context) {
    final fecha = DateTime.parse(anuncio['fecha']);
    final paraTodos = anuncio['para_todos'] as bool? ?? false;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.campaign),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                anuncio['titulo'] as String,
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
                'Fecha',
                DateFormat('dd/MM/yyyy HH:mm', 'es_MX').format(fecha),
              ),
              const Divider(),
              _buildDetalleItem('Mensaje', anuncio['mensaje'] as String),
              const Divider(),
              _buildDetalleItem(
                'Destinatarios',
                paraTodos ? 'Todos los padres' : 'Grados específicos',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              GoRouter.of(context).push(
                '/directora/anuncios/editar/${anuncio['id']}',
              );
            },
            child: const Text('Editar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetalleItem(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            valor,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
}
