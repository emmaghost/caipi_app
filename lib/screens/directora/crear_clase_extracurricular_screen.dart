import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../models/clase_extracurricular.dart';
import '../../config/app_colors.dart';
import '../../widgets/app_drawer.dart';

class CrearClaseExtracurricularScreen extends StatefulWidget {
  final String? claseId;

  const CrearClaseExtracurricularScreen({super.key, this.claseId});

  @override
  State<CrearClaseExtracurricularScreen> createState() => _CrearClaseExtracurricularScreenState();
}

class _CrearClaseExtracurricularScreenState extends State<CrearClaseExtracurricularScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _costoController = TextEditingController();
  final _cupoController = TextEditingController(text: '15');

  TimeOfDay? _horaInicio;
  TimeOfDay? _horaFin;
  final List<String> _diasSeleccionados = [];
  bool _permiteExternos = false;
  bool _isLoading = false;

  final List<String> _diasSemana = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.claseId != null) {
      _cargarClase();
    }
  }

  Future<void> _cargarClase() async {
    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client
          .from('clases_extracurriculares')
          .select()
          .eq('id', widget.claseId!)
          .single();

      final clase = ClaseExtracurricular.fromJson(response);
      
      setState(() {
        _nombreController.text = clase.nombre;
        _descripcionController.text = clase.descripcion ?? '';
        _costoController.text = clase.costoMensual?.toStringAsFixed(0) ?? '';
        _cupoController.text = clase.cupoMaximo.toString();
        _diasSeleccionados.addAll(clase.diasSemana);
        _permiteExternos = clase.permiteExternos;
        
        if (clase.horaInicio != null) {
          _horaInicio = TimeOfDay(
            hour: clase.horaInicio!.hour,
            minute: clase.horaInicio!.minute,
          );
        }
        
        if (clase.horaFin != null) {
          _horaFin = TimeOfDay(
            hour: clase.horaFin!.hour,
            minute: clase.horaFin!.minute,
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar clase: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.claseId == null ? 'Nueva Clase Extracurricular' : 'Editar Clase'),
        backgroundColor: AppColors.azulOscuro,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => context.go('/directora'),
            tooltip: 'Ir al inicio',
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nombre
                    TextFormField(
                      controller: _nombreController,
                      decoration: InputDecoration(
                        labelText: 'Nombre de la clase *',
                        hintText: 'Ej: Fútbol, Danza, Arte',
                        prefixIcon: const Icon(Icons.school),
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

                    // Descripción
                    TextFormField(
                      controller: _descripcionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Descripción',
                        hintText: 'Descripción de la clase',
                        prefixIcon: const Icon(Icons.description),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Días de la semana
                    Text(
                      'Días de la semana *',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _diasSemana.map((dia) {
                        final isSelected = _diasSeleccionados.contains(dia);
                        return FilterChip(
                          label: Text(dia),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _diasSeleccionados.add(dia);
                              } else {
                                _diasSeleccionados.remove(dia);
                              }
                            });
                          },
                          selectedColor: AppColors.azulOscuro.withOpacity(0.3),
                          checkmarkColor: AppColors.azulOscuro,
                        );
                      }).toList(),
                    ),
                    if (_diasSeleccionados.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Selecciona al menos un día',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Horario
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: _horaInicio ?? const TimeOfDay(hour: 15, minute: 0),
                              );
                              if (time != null) {
                                setState(() => _horaInicio = time);
                              }
                            },
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Hora inicio',
                                prefixIcon: const Icon(Icons.access_time),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                _horaInicio != null
                                    ? _horaInicio!.format(context)
                                    : 'Seleccionar',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: _horaFin ?? const TimeOfDay(hour: 17, minute: 0),
                              );
                              if (time != null) {
                                setState(() => _horaFin = time);
                              }
                            },
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Hora fin',
                                prefixIcon: const Icon(Icons.access_time),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                _horaFin != null
                                    ? _horaFin!.format(context)
                                    : 'Seleccionar',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Cupo y Costo
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _cupoController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Cupo máximo *',
                              prefixIcon: const Icon(Icons.people),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'El cupo es obligatorio';
                              }
                              final cupo = int.tryParse(value);
                              if (cupo == null || cupo <= 0) {
                                return 'Cupo inválido';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _costoController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Costo mensual',
                              prefixIcon: const Icon(Icons.attach_money),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Permite externos
                    SwitchListTile(
                      title: Text(
                        'Permite externos (no alumnos)',
                        style: GoogleFonts.poppins(fontSize: 14),
                      ),
                      subtitle: Text(
                        'Permite inscribir personas externas (ej: madres)',
                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                      ),
                      value: _permiteExternos,
                      onChanged: (value) {
                        setState(() => _permiteExternos = value);
                      },
                      activeColor: AppColors.verdeClaro,
                    ),
                    const SizedBox(height: 24),

                    // Botón Guardar
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _guardar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.azulOscuro,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save),
                        label: Text(
                          _isLoading ? 'Guardando...' : 'Guardar Clase',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    if (_diasSeleccionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona al menos un día'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final data = {
        'nombre': _nombreController.text.trim(),
        'descripcion': _descripcionController.text.trim().isEmpty ? null : _descripcionController.text.trim(),
        'dias_semana': _diasSeleccionados,
        'hora_inicio': _horaInicio != null
            ? '${_horaInicio!.hour.toString().padLeft(2, '0')}:${_horaInicio!.minute.toString().padLeft(2, '0')}:00'
            : null,
        'hora_fin': _horaFin != null
            ? '${_horaFin!.hour.toString().padLeft(2, '0')}:${_horaFin!.minute.toString().padLeft(2, '0')}:00'
            : null,
        'cupo_maximo': int.parse(_cupoController.text.trim()),
        'costo_mensual': _costoController.text.trim().isEmpty
            ? null
            : double.parse(_costoController.text.trim()),
        'permite_externos': _permiteExternos,
        'activo': true,
      };

      if (widget.claseId == null) {
        // Crear nueva
        data['id'] = const Uuid().v4();
        await Supabase.instance.client
            .from('clases_extracurriculares')
            .insert(data);
      } else {
        // Actualizar existente
        await Supabase.instance.client
            .from('clases_extracurriculares')
            .update(data)
            .eq('id', widget.claseId!);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.claseId == null
                  ? 'Clase creada exitosamente'
                  : 'Clase actualizada exitosamente',
            ),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/directora/clases-extracurriculares');
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
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _costoController.dispose();
    _cupoController.dispose();
    super.dispose();
  }
}
