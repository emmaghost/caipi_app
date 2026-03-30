import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../config/app_colors.dart';
import '../../models/grado.dart';
import '../../widgets/app_drawer.dart';

class CrearGradoScreen extends StatefulWidget {
  final String? gradoId;

  const CrearGradoScreen({super.key, this.gradoId});

  @override
  State<CrearGradoScreen> createState() => _CrearGradoScreenState();
}

class _CrearGradoScreenState extends State<CrearGradoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  
  bool _activo = true;
  bool _cargando = false;
  bool _esEdicion = false;

  @override
  void initState() {
    super.initState();
    if (widget.gradoId != null) {
      _esEdicion = true;
      _cargarDatosGrado();
    }
  }

  Future<void> _cargarDatosGrado() async {
    try {
      setState(() => _cargando = true);

      final response = await Supabase.instance.client
          .from('grados')
          .select()
          .eq('id', widget.gradoId!)
          .single();

      if (!mounted) return;

      final grado = Grado.fromJson(response);
      
      setState(() {
        _nombreController.text = grado.nombre;
        _descripcionController.text = grado.descripcion ?? '';
        _activo = grado.activo;
        _cargando = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar grado: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _cargando = false);
      }
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    super.dispose();
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
              _esEdicion ? 'Editar Grado' : 'Nuevo Grado',
              style: GoogleFonts.fredoka(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.morado,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => GoRouter.of(context).pop(),
        ),
      ),
      drawer: const AppDrawer(),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Encabezado
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.rosa, AppColors.morado],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.school, color: Colors.white, size: 40),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _esEdicion ? 'Modificar Grado' : 'Crear Nuevo Grado',
                                  style: GoogleFonts.fredoka(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _esEdicion
                                      ? 'Actualiza la información del grado'
                                      : 'Completa los datos del grado',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Nombre del grado
                    _buildSeccionTitulo('Información del Grado'),
                    const SizedBox(height: 12),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _nombreController,
                              decoration: InputDecoration(
                                labelText: 'Nombre del Grado *',
                                hintText: 'Ej: Maternal, Kinder 1, Kinder 2',
                                prefixIcon: const Icon(Icons.label),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'El nombre es obligatorio';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _descripcionController,
                              decoration: InputDecoration(
                                labelText: 'Descripción (opcional)',
                                hintText: 'Ej: Niños de 2 a 3 años',
                                prefixIcon: const Icon(Icons.description),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              maxLines: 3,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Estado
                    _buildSeccionTitulo('Estado'),
                    const SizedBox(height: 12),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: SwitchListTile(
                        value: _activo,
                        onChanged: (value) {
                          setState(() => _activo = value);
                        },
                        title: Text(
                          'Grado Activo',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          _activo
                              ? 'Este grado está disponible para asignar a alumnos'
                              : 'Este grado no aparecerá en las opciones',
                          style: GoogleFonts.poppins(fontSize: 12),
                        ),
                        secondary: Icon(
                          _activo ? Icons.visibility : Icons.visibility_off,
                          color: _activo ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Botón guardar (verde oscuro para buen contraste con texto blanco)
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _guardarGrado,
                        icon: const Icon(Icons.save, color: Colors.white),
                        label: Text(
                          _esEdicion ? 'Actualizar Grado' : 'Crear Grado',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF166534),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),

                    // Botón eliminar (solo en edición)
                    if (_esEdicion) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton.icon(
                          onPressed: _confirmarEliminar,
                          icon: const Icon(Icons.delete, color: Colors.red),
                          label: Text(
                            'Eliminar Grado',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red, width: 2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSeccionTitulo(String titulo) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: AppColors.morado,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          titulo,
          style: GoogleFonts.fredoka(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF5C4D6B),
          ),
        ),
      ],
    );
  }

  Future<void> _guardarGrado() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _cargando = true);

    try {
      final Map<String, dynamic> gradoData = {
        'nombre': _nombreController.text.trim(),
        'descripcion': _descripcionController.text.trim().isEmpty
            ? null
            : _descripcionController.text.trim(),
        'activo': _activo,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (_esEdicion) {
        // Actualizar grado existente
        await Supabase.instance.client
            .from('grados')
            .update(gradoData)
            .eq('id', widget.gradoId!);
      } else {
        // Crear nuevo grado
        gradoData['id'] = const Uuid().v4();
        gradoData['created_at'] = DateTime.now().toIso8601String();

        await Supabase.instance.client
            .from('grados')
            .insert(gradoData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _esEdicion
                  ? '✓ Grado actualizado correctamente'
                  : '✓ Grado creado correctamente',
            ),
            backgroundColor: Colors.green,
          ),
        );
        GoRouter.of(context).go('/directora/grados');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _cargando = false);
      }
    }
  }

  Future<void> _confirmarEliminar() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning, color: Colors.red),
            const SizedBox(width: 8),
            Text(
              '¿Eliminar Grado?',
              style: GoogleFonts.fredoka(),
            ),
          ],
        ),
        content: Text(
          'Esta acción no se puede deshacer. ¿Estás segura de eliminar este grado?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await _eliminarGrado();
    }
  }

  Future<void> _eliminarGrado() async {
    setState(() => _cargando = true);

    try {
      // Verificar si hay alumnos con este grado
      final response = await Supabase.instance.client
          .from('alumnos')
          .select('id')
          .eq('grado_id', widget.gradoId!)
          .limit(1);

      if (response.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'No se puede eliminar: hay alumnos asignados a este grado',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Eliminar el grado
      await Supabase.instance.client
          .from('grados')
          .delete()
          .eq('id', widget.gradoId!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Grado eliminado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        GoRouter.of(context).go('/directora/grados');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _cargando = false);
      }
    }
  }
}
