import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/app_colors.dart';
import '../../models/grado.dart';
import '../../widgets/app_drawer.dart';

class GradosScreen extends StatefulWidget {
  const GradosScreen({super.key});

  @override
  State<GradosScreen> createState() => _GradosScreenState();
}

class _GradosScreenState extends State<GradosScreen> {
  late Future<List<Grado>> _gradosFuture;

  @override
  void initState() {
    super.initState();
    _recargar();
  }

  void _recargar() {
    _gradosFuture = Supabase.instance.client
        .from('grados')
        .select()
        .order('nombre', ascending: true)
        .then((data) => data.map(Grado.fromJson).toList());
  }

  Future<void> _abrirFormulario([String? gradoId]) async {
    final ruta = gradoId == null
        ? '/directora/grados/crear'
        : '/directora/grados/editar/$gradoId';
    await GoRouter.of(context).push(ruta);
    if (!mounted) return;
    setState(_recargar);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.school, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              'Grados',
              style: GoogleFonts.fredoka(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.morado,
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
        child: FutureBuilder<List<Grado>>(
          future: _gradosFuture,
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
                      'Error al cargar grados',
                      style: GoogleFonts.poppins(fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        snapshot.error.toString(),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () => setState(_recargar),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
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
                    Icon(Icons.school_outlined, size: 80, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No hay grados registrados',
                      style: GoogleFonts.fredoka(
                        fontSize: 18,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        _abrirFormulario();
                      },
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text('Agregar Primer Grado'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF166534),
                        foregroundColor: Colors.white,
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

            final grados = snapshot.data!;

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: grados.length,
              itemBuilder: (context, index) {
                final grado = grados[index];
                return _GradoCard(
                  grado: grado,
                  onEdit: () => _abrirFormulario(grado.id),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirFormulario,
        backgroundColor: const Color(0xFF166534),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'Nuevo Grado',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _GradoCard extends StatelessWidget {
  final Grado grado;
  final VoidCallback onEdit;

  const _GradoCard({required this.grado, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icono
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.rosa, AppColors.morado],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.school,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),

              // Información
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      grado.nombre,
                      style: GoogleFonts.fredoka(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.morado,
                      ),
                    ),
                    if (grado.descripcion != null && grado.descripcion!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        grado.descripcion!,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    _buildEstadoChip(),
                  ],
                ),
              ),

              // Botones de acción
              Column(
                children: [
                  IconButton(
                    icon: Icon(Icons.edit, color: AppColors.morado),
                    onPressed: onEdit,
                  ),
                  IconButton(
                    icon: Icon(
                      grado.activo ? Icons.visibility : Icons.visibility_off,
                      color: grado.activo ? Colors.green : Colors.red,
                    ),
                    onPressed: () => _toggleEstado(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEstadoChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: grado.activo ? Colors.green[50] : Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: grado.activo ? Colors.green : Colors.red,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            grado.activo ? Icons.check_circle : Icons.cancel,
            size: 14,
            color: grado.activo ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 4),
          Text(
            grado.activo ? 'Activo' : 'Inactivo',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: grado.activo ? Colors.green[700] : Colors.red[700],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleEstado(BuildContext context) async {
    try {
      final nuevoEstado = !grado.activo;
      
      await Supabase.instance.client
          .from('grados')
          .update({
            'activo': nuevoEstado,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', grado.id);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              nuevoEstado
                  ? '✓ Grado activado correctamente'
                  : '✓ Grado desactivado correctamente',
            ),
            backgroundColor: nuevoEstado ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cambiar estado: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
