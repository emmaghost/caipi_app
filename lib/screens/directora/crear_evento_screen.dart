import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../config/app_colors.dart';
import '../../widgets/app_drawer.dart';
import '../../models/evento.dart';
import '../../models/grado.dart';

class CrearEventoScreen extends StatefulWidget {
  final String? eventoId;

  const CrearEventoScreen({Key? key, this.eventoId}) : super(key: key);

  @override
  State<CrearEventoScreen> createState() => _CrearEventoScreenState();
}

class _CrearEventoScreenState extends State<CrearEventoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _horaInicioController = TextEditingController();
  final _horaFinController = TextEditingController();
  final _lugarController = TextEditingController();
  
  DateTime _fechaSeleccionada = DateTime.now();
  String _tipoSeleccionado = 'academico';
  bool _paraTodos = true;
  List<String> _gradosSeleccionados = [];
  List<Grado> _todosLosGrados = [];
  bool _cargando = true;
  Evento? _eventoActual;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    try {
      // Cargar grados
      final gradosResponse = await Supabase.instance.client
          .from('grados')
          .select()
          .eq('activo', true);
      
      final grados = (gradosResponse as List)
          .map((json) => Grado.fromJson(json))
          .toList();

      // Si es edición, cargar evento
      if (widget.eventoId != null) {
        final eventoResponse = await Supabase.instance.client
            .from('eventos')
            .select()
            .eq('id', widget.eventoId!)
            .single();
        
        final evento = Evento.fromJson(eventoResponse);
        
        _tituloController.text = evento.titulo;
        _descripcionController.text = evento.descripcion;
        _horaInicioController.text = evento.horaInicio ?? '';
        _horaFinController.text = evento.horaFin ?? '';
        _lugarController.text = evento.lugar ?? '';
        _fechaSeleccionada = evento.fechaEvento;
        _tipoSeleccionado = evento.tipo;
        _paraTodos = evento.paraTodos;
        _gradosSeleccionados = evento.gradosIds ?? [];
        _eventoActual = evento;
      }

      setState(() {
        _todosLosGrados = grados;
        _cargando = false;
      });
    } catch (e) {
      print('Error cargando datos: $e');
      setState(() => _cargando = false);
    }
  }

  Future<void> _guardarEvento() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_paraTodos && _gradosSeleccionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Selecciona al menos un grado'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final usuarioId = Supabase.instance.client.auth.currentUser?.id;

      final eventoData = {
        'titulo': _tituloController.text.trim(),
        'descripcion': _descripcionController.text.trim(),
        'fecha_evento': _fechaSeleccionada.toIso8601String().split('T')[0],
        'hora_inicio': _horaInicioController.text.trim().isEmpty
            ? null
            : _horaInicioController.text.trim(),
        'hora_fin': _horaFinController.text.trim().isEmpty
            ? null
            : _horaFinController.text.trim(),
        'lugar': _lugarController.text.trim().isEmpty
            ? null
            : _lugarController.text.trim(),
        'tipo': _tipoSeleccionado,
        'para_todos': _paraTodos,
        'grados_ids': _paraTodos ? null : _gradosSeleccionados,
        'creado_por': usuarioId,
        'activo': true,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (widget.eventoId != null) {
        // Actualizar evento existente
        await Supabase.instance.client
            .from('eventos')
            .update(eventoData)
            .eq('id', widget.eventoId!);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Evento actualizado correctamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Crear nuevo evento
        eventoData['id'] = const Uuid().v4();
        eventoData['created_at'] = DateTime.now().toIso8601String();

        await Supabase.instance.client
            .from('eventos')
            .insert(eventoData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Evento creado correctamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

      if (mounted) {
        context.pop(true);
      }
    } catch (e) {
      print('Error guardando evento: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grisClaro,
      drawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: AppColors.morado,
        foregroundColor: Colors.white,
        title: Text(
          widget.eventoId == null ? 'Crear Evento' : 'Editar Evento',
          style: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => context.go('/directora'),
            tooltip: 'Ir al inicio',
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título
                    _buildSectionTitle('📝 Información Básica'),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _tituloController,
                      decoration: InputDecoration(
                        labelText: 'Título del Evento',
                        hintText: 'Ej: Día del Niño',
                        prefixIcon: const Icon(Icons.title),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingresa el título';
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
                        hintText: 'Detalles del evento...',
                        prefixIcon: const Icon(Icons.description),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingresa la descripción';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Tipo de evento
                    _buildSectionTitle('🎯 Tipo de Evento'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildTipoChip('academico', '📚 Académico'),
                        _buildTipoChip('festivo', '🎉 Festivo'),
                        _buildTipoChip('reunion', '👥 Reunión'),
                        _buildTipoChip('clausura', '🎓 Clausura'),
                        _buildTipoChip('otro', '📅 Otro'),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Fecha y hora
                    _buildSectionTitle('📅 Fecha y Hora'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Card(
                            child: InkWell(
                              onTap: _seleccionarFecha,
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today, color: AppColors.morado),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Fecha',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        Text(
                                          DateFormat('dd/MM/yyyy', 'es_MX').format(_fechaSeleccionada),
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _horaInicioController,
                            decoration: InputDecoration(
                              labelText: 'Hora Inicio',
                              hintText: '09:00',
                              prefixIcon: const Icon(Icons.access_time),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _horaFinController,
                            decoration: InputDecoration(
                              labelText: 'Hora Fin',
                              hintText: '12:00',
                              prefixIcon: const Icon(Icons.access_time_filled),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Lugar
                    TextFormField(
                      controller: _lugarController,
                      decoration: InputDecoration(
                        labelText: 'Lugar (Opcional)',
                        hintText: 'Ej: Patio principal',
                        prefixIcon: const Icon(Icons.place),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Destinatarios
                    _buildSectionTitle('👨‍👩‍👧 Destinatarios'),
                    const SizedBox(height: 12),
                    Card(
                      elevation: 0,
                      color: AppColors.moradoClaro.withOpacity(0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: AppColors.morado.withOpacity(0.3)),
                      ),
                      child: SwitchListTile(
                        value: _paraTodos,
                        onChanged: (value) {
                          setState(() {
                            _paraTodos = value;
                            if (value) _gradosSeleccionados.clear();
                          });
                        },
                        title: Text(
                          'Para todos los grados',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF4A3F55),
                          ),
                        ),
                        subtitle: Text(
                          'Todos verán este evento',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                        activeColor: Colors.white,
                        activeTrackColor: AppColors.morado,
                        inactiveThumbColor: Colors.grey[600],
                        inactiveTrackColor: Colors.grey.shade300,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    if (!_paraTodos) ...[
                      const SizedBox(height: 12),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Selecciona los grados:',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _todosLosGrados.map((grado) {
                                  final seleccionado = _gradosSeleccionados.contains(grado.id);
                                  return FilterChip(
                                    label: Text(grado.nombre),
                                    selected: seleccionado,
                                    onSelected: (selected) {
                                      setState(() {
                                        if (selected) {
                                          _gradosSeleccionados.add(grado.id);
                                        } else {
                                          _gradosSeleccionados.remove(grado.id);
                                        }
                                      });
                                    },
                                    selectedColor: AppColors.morado,
                                    checkmarkColor: Colors.white,
                                    labelStyle: TextStyle(
                                      color: seleccionado ? Colors.white : Colors.black87,
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),

                    // Botón guardar
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _guardarEvento,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.morado,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          widget.eventoId == null ? 'Crear Evento' : 'Guardar Cambios',
                          style: GoogleFonts.fredoka(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
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

  Widget _buildSectionTitle(String titulo) {
    return Text(
      titulo,
      style: GoogleFonts.fredoka(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.morado,
      ),
    );
  }

  Widget _buildTipoChip(String tipo, String label) {
    final isSelected = _tipoSeleccionado == tipo;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _tipoSeleccionado = tipo;
          });
        }
      },
      selectedColor: AppColors.morado,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Future<void> _seleccionarFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('es', 'MX'),
    );

    if (picked != null && picked != _fechaSeleccionada) {
      setState(() {
        _fechaSeleccionada = picked;
      });
    }
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    _horaInicioController.dispose();
    _horaFinController.dispose();
    _lugarController.dispose();
    super.dispose();
  }
}
