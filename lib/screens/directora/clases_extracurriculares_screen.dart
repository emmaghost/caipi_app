import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/clase_extracurricular.dart';
import '../../config/app_colors.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/caipi_app_bar_leading.dart';

class ClasesExtracurricularesScreen extends StatefulWidget {
  const ClasesExtracurricularesScreen({super.key});

  @override
  State<ClasesExtracurricularesScreen> createState() =>
      _ClasesExtracurricularesScreenState();
}

class _ClasesExtracurricularesScreenState
    extends State<ClasesExtracurricularesScreen> {
  List<ClaseExtracurricular> _clases = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await Supabase.instance.client
          .from('clases_extracurriculares')
          .select()
          .order('nombre');
      final clases = (data as List)
          .map((json) =>
              ClaseExtracurricular.fromJson(Map<String, dynamic>.from(json)))
          .toList();
      if (!mounted) return;
      setState(() {
        _clases = clases;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const CaipiAppBarLeading(),
        title: const Text('Clases Extracurriculares'),
        backgroundColor: AppColors.azulOscuro,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargar,
            tooltip: 'Actualizar',
          ),
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => context.go('/directora'),
            tooltip: 'Ir al inicio',
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Error: $_error', textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _cargar,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _cargar,
                  child: _clases.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(
                              height: MediaQuery.sizeOf(context).height * 0.55,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.sports_soccer,
                                      size: 80, color: Colors.grey[400]),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No hay clases todavía',
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 32),
                                    child: Text(
                                      'Crea la clase con su costo (sin niños). '
                                      'Después ábrela e inscribe alumnos para generar el pago.',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _clases.length,
                          itemBuilder: (context, index) {
                            final clase = _clases[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: clase.activo
                                      ? AppColors.verdeClaro
                                      : Colors.grey,
                                  width: 2,
                                ),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                leading: CircleAvatar(
                                  backgroundColor: clase.activo
                                      ? AppColors.verdeClaro
                                      : Colors.grey,
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
                                    color: clase.activo
                                        ? Colors.black87
                                        : Colors.grey,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    if (clase.descripcion != null)
                                      Text(
                                        clase.descripcion!,
                                        style:
                                            GoogleFonts.poppins(fontSize: 13),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${clase.horario}'
                                      '${clase.costoMensual != null ? ' · \$${clase.costoMensual!.toStringAsFixed(0)}/mes' : ''}'
                                      ' · Cupo ${clase.cupoMaximo}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Toca para ver inscritos / asignar niños',
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: AppColors.azulOscuro,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit,
                                          color: AppColors.azulOscuro),
                                      onPressed: () async {
                                        await context.push(
                                          '/directora/clases-extracurriculares/editar/${clase.id}',
                                        );
                                        if (mounted) _cargar();
                                      },
                                      tooltip: 'Editar',
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        clase.activo
                                            ? Icons.check_circle
                                            : Icons.cancel,
                                        color: clase.activo
                                            ? Colors.green
                                            : Colors.grey,
                                      ),
                                      onPressed: () => _toggleActivo(clase),
                                      tooltip: clase.activo
                                          ? 'Desactivar'
                                          : 'Activar',
                                    ),
                                  ],
                                ),
                                onTap: () async {
                                  await context.push(
                                    '/directora/clases-extracurriculares/detalle/${clase.id}',
                                  );
                                  if (mounted) _cargar();
                                },
                              ),
                            );
                          },
                        ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push('/directora/clases-extracurriculares/crear');
          if (mounted) _cargar();
        },
        backgroundColor: AppColors.azulOscuro,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'Nueva Clase',
          style: GoogleFonts.poppins(
              color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  IconData _getIconForClass(String nombre) {
    final nombreLower = nombre.toLowerCase();
    if (nombreLower.contains('fútbol') || nombreLower.contains('futbol')) {
      return Icons.sports_soccer;
    } else if (nombreLower.contains('danza') ||
        nombreLower.contains('baile')) {
      return Icons.music_note;
    } else if (nombreLower.contains('arte') ||
        nombreLower.contains('pintura')) {
      return Icons.palette;
    } else if (nombreLower.contains('música') ||
        nombreLower.contains('musica')) {
      return Icons.piano;
    } else if (nombreLower.contains('inglés') ||
        nombreLower.contains('ingles')) {
      return Icons.language;
    } else if (nombreLower.contains('natación') ||
        nombreLower.contains('natacion')) {
      return Icons.pool;
    } else if (nombreLower.contains('teatro')) {
      return Icons.theater_comedy;
    } else if (nombreLower.contains('yoga') ||
        nombreLower.contains('taekwondo')) {
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
        await _cargar();
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
