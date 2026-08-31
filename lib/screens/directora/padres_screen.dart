import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/app_colors.dart';
import '../../services/chat_service.dart';
import '../../widgets/app_drawer.dart';

class PadresScreen extends StatefulWidget {
  const PadresScreen({super.key});

  @override
  State<PadresScreen> createState() => _PadresScreenState();
}

class _PadresScreenState extends State<PadresScreen> {
  late Future<List<Map<String, dynamic>>> _padresFuture;

  @override
  void initState() {
    super.initState();
    _padresFuture = _cargarPadres();
  }

  Future<List<Map<String, dynamic>>> _cargarPadres() async {
    final data = await Supabase.instance.client
        .from('usuarios')
        .select()
        .eq('rol', 'padre')
        .order('nombre');
    final padres = List<Map<String, dynamic>>.from(data as List);
    padres.sort((a, b) {
      final aActivo = a['activo'] == true ? 0 : 1;
      final bActivo = b['activo'] == true ? 0 : 1;
      if (aActivo != bActivo) return aActivo.compareTo(bActivo);
      return ((a['nombre'] as String?) ?? '')
          .compareTo((b['nombre'] as String?) ?? '');
    });
    return padres;
  }

  Future<List<Map<String, dynamic>>> _hijosDePadre(String padreId) async {
    final client = Supabase.instance.client;
    try {
      final vinculos = await client
          .from('alumnos_padres')
          .select('alumno_id')
          .eq('padre_id', padreId);
      final ids = (vinculos as List)
          .map((e) => e['alumno_id'] as String)
          .toSet();
      if (ids.isNotEmpty) {
        final data = await client
            .from('alumnos')
            .select('id')
            .inFilter('id', ids.toList())
            .eq('activo', true);
        return List<Map<String, dynamic>>.from(data as List);
      }
    } catch (_) {}
    final data = await client
        .from('alumnos')
        .select('id')
        .eq('padre_id', padreId)
        .eq('activo', true);
    return List<Map<String, dynamic>>.from(data as List);
  }

  Future<void> _refrescar() async {
    final future = _cargarPadres();
    setState(() => _padresFuture = future);
    await future.catchError((_) => <Map<String, dynamic>>[]);
  }

  Future<void> _abrirCrearPadre() async {
    await context.push('/directora/padres/crear');
    if (mounted) await _refrescar();
  }

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
            icon: const Icon(Icons.refresh),
            onPressed: _refrescar,
            tooltip: 'Actualizar lista',
          ),
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => context.go('/directora'),
            tooltip: 'Ir al inicio',
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _padresFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _refrescar,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
            );
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

          return RefreshIndicator(
            onRefresh: _refrescar,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              itemCount: padres.length,
              itemBuilder: (context, index) {
                final padre = padres[index];
                return _buildPadreCard(context, padre);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirCrearPadre,
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
        onTap: () async {
          await context.push('/directora/padres/ver/${padre['id']}');
          if (mounted) await _refrescar();
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _hijosDePadre(padre['id'] as String),
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
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                padre['nombre'] ?? 'Sin nombre',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (padre['activo'] != true)
                              Container(
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
                  IconButton(
                    icon: const Icon(Icons.chat_bubble_rounded, color: AppColors.morado),
                    tooltip: 'Chat',
                    onPressed: () async {
                      final chatService = ChatService();
                      final conversacion =
                          await chatService.obtenerOCrearConversacion(padre['id'] as String);
                      if (!context.mounted) return;
                      final nombre = padre['nombre'] as String? ?? 'Padre';
                      context.push(
                        '/directora/chat/${conversacion.id}',
                        extra: {'titulo': nombre},
                      );
                    },
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
