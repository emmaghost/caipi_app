import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../config/app_colors.dart';
import '../../models/menu_maternal.dart';
import '../../widgets/app_drawer.dart';

class CrearMenuScreen extends StatefulWidget {
  final String? menuId;
  final DateTime? fechaInicial;

  const CrearMenuScreen({
    super.key,
    this.menuId,
    this.fechaInicial,
  });

  @override
  State<CrearMenuScreen> createState() => _CrearMenuScreenState();
}

class _CrearMenuScreenState extends State<CrearMenuScreen> {
  final _formKey = GlobalKey<FormState>();
  final _desayunoController = TextEditingController();
  final _comidaController = TextEditingController();
  final _meriendaController = TextEditingController();
  final _observacionesController = TextEditingController();

  DateTime _fecha = DateTime.now();

  bool _cargando = false;
  bool _esEdicion = false;

  @override
  void initState() {
    super.initState();
    if (widget.fechaInicial != null) {
      _fecha = widget.fechaInicial!;
    }
    if (widget.menuId != null) {
      _esEdicion = true;
      _cargarDatosMenu();
    }
  }

  Future<void> _cargarDatosMenu() async {
    try {
      setState(() => _cargando = true);

      final response = await Supabase.instance.client
          .from('menu_maternal')
          .select()
          .eq('id', widget.menuId!)
          .single();

      if (!mounted) return;

      final menu = MenuMaternal.fromJson(response);

      setState(() {
        _fecha = menu.fecha;
        _desayunoController.text = menu.desayuno ?? '';
        _comidaController.text = menu.comida ?? '';
        _meriendaController.text = menu.merienda ?? '';
        _observacionesController.text = menu.observaciones ?? '';
        _cargando = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar menú: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _cargando = false);
      }
    }
  }

  @override
  void dispose() {
    _desayunoController.dispose();
    _comidaController.dispose();
    _meriendaController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.restaurant_menu, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              _esEdicion ? 'Editar Menú' : 'Nuevo Menú',
              style: GoogleFonts.fredoka(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.azulOscuro,
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
                        gradient: LinearGradient(
                          colors: [AppColors.naranjaClaro, AppColors.amarilloClaro],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.restaurant_menu, color: Colors.white, size: 40),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _esEdicion ? 'Modificar Menú' : 'Crear Menú del Día',
                                  style: GoogleFonts.fredoka(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Planifica la alimentación del día',
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

                    // Fecha
                    _buildSeccionTitulo('Fecha'),
                    const SizedBox(height: 12),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: InkWell(
                          onTap: _seleccionarFecha,
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Fecha del Menú *',
                              prefixIcon: const Icon(Icons.calendar_today),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              DateFormat('dd/MM/yyyy').format(_fecha),
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Desayuno
                    _buildSeccionTitulo('🌅 Desayuno'),
                    const SizedBox(height: 12),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.orange, width: 2),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: TextFormField(
                          controller: _desayunoController,
                          decoration: InputDecoration(
                            labelText: 'Desayuno *',
                            hintText: 'Ej: Leche con cereal, fruta',
                            prefixIcon: const Icon(Icons.wb_sunny, color: Colors.orange),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          maxLines: 2,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'El desayuno es obligatorio';
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Comida
                    _buildSeccionTitulo('🍽️ Comida'),
                    const SizedBox(height: 12),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.red, width: 2),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: TextFormField(
                          controller: _comidaController,
                          decoration: InputDecoration(
                            labelText: 'Comida *',
                            hintText: 'Ej: Sopa de verduras, pollo, arroz',
                            prefixIcon: const Icon(Icons.lunch_dining, color: Colors.red),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          maxLines: 2,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'La comida es obligatoria';
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Merienda
                    _buildSeccionTitulo('🍪 Merienda'),
                    const SizedBox(height: 12),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.purple, width: 2),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: TextFormField(
                          controller: _meriendaController,
                          decoration: InputDecoration(
                            labelText: 'Merienda *',
                            hintText: 'Ej: Galletas, jugo natural',
                            prefixIcon: const Icon(Icons.cookie, color: Colors.purple),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          maxLines: 2,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'La merienda es obligatoria';
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Observaciones
                    _buildSeccionTitulo('Observaciones'),
                    const SizedBox(height: 12),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: TextFormField(
                          controller: _observacionesController,
                          decoration: InputDecoration(
                            labelText: 'Observaciones (opcional)',
                            hintText: 'Notas adicionales sobre el menú...',
                            prefixIcon: const Icon(Icons.notes),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          maxLines: 3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Botón guardar
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _guardarMenu,
                        icon: const Icon(Icons.save, color: Colors.white),
                        label: Text(
                          _esEdicion ? 'Actualizar Menú' : 'Guardar Menú',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.verdeClaro,
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
                            'Eliminar Menú',
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
            color: AppColors.azulOscuro,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          titulo,
          style: GoogleFonts.fredoka(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.azulOscuro,
          ),
        ),
      ],
    );
  }

  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('es', 'MX'),
    );

    if (fecha != null) {
      setState(() {
        _fecha = fecha;
      });
    }
  }

  Future<void> _guardarMenu() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _cargando = true);

    try {
      // Verificar si ya existe un menú para esta fecha (si no es edición)
      if (!_esEdicion) {
        final existente = await Supabase.instance.client
            .from('menu_maternal')
            .select()
            .eq('fecha', DateFormat('yyyy-MM-dd').format(_fecha));

        if (existente.isNotEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Ya existe un menú para esta fecha'),
                backgroundColor: Colors.orange,
              ),
            );
            setState(() => _cargando = false);
          }
          return;
        }
      }

      // Obtener ID del profesor/usuario actual
      final userId = Supabase.instance.client.auth.currentUser?.id;

      final Map<String, dynamic> menuData = {
        'fecha': DateFormat('yyyy-MM-dd').format(_fecha),
        'desayuno': _desayunoController.text.trim(),
        'comida': _comidaController.text.trim(),
        'merienda': _meriendaController.text.trim(),
        'observaciones': _observacionesController.text.trim().isEmpty
            ? null
            : _observacionesController.text.trim(),
        'profesor_id': userId,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (_esEdicion) {
        // Actualizar menú existente
        await Supabase.instance.client
            .from('menu_maternal')
            .update(menuData)
            .eq('id', widget.menuId!);
      } else {
        // Crear nuevo menú
        menuData['id'] = const Uuid().v4();
        menuData['created_at'] = DateTime.now().toIso8601String();

        await Supabase.instance.client
            .from('menu_maternal')
            .insert(menuData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _esEdicion
                  ? '✓ Menú actualizado correctamente'
                  : '✓ Menú creado correctamente',
            ),
            backgroundColor: Colors.green,
          ),
        );
        GoRouter.of(context).go('/directora/menu-maternal');
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
              '¿Eliminar Menú?',
              style: GoogleFonts.fredoka(),
            ),
          ],
        ),
        content: Text(
          'Esta acción no se puede deshacer. ¿Estás segura de eliminar este menú?',
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
      await _eliminarMenu();
    }
  }

  Future<void> _eliminarMenu() async {
    setState(() => _cargando = true);

    try {
      await Supabase.instance.client
          .from('menu_maternal')
          .delete()
          .eq('id', widget.menuId!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Menú eliminado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        GoRouter.of(context).go('/directora/menu-maternal');
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
