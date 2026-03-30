import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../config/app_colors.dart';
import '../../models/alumno.dart';
import '../../models/control_salida.dart';
import '../../models/persona_autorizada.dart';
import '../../widgets/app_drawer.dart';

class RegistrarSalidaScreen extends StatefulWidget {
  final String? controlId;
  final DateTime? fechaInicial;

  const RegistrarSalidaScreen({
    super.key,
    this.controlId,
    this.fechaInicial,
  });

  @override
  State<RegistrarSalidaScreen> createState() => _RegistrarSalidaScreenState();
}

class _RegistrarSalidaScreenState extends State<RegistrarSalidaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quienTrajoController = TextEditingController();
  final _quienRecogioController = TextEditingController();

  String? _alumnoSeleccionadoId;
  DateTime _fecha = DateTime.now(); // Siempre es HOY
  TimeOfDay _horaEntrada = const TimeOfDay(hour: 9, minute: 0); // Por defecto 9:00 AM
  TimeOfDay _horaSalida = const TimeOfDay(hour: 14, minute: 0); // Por defecto 2:00 PM
  String? _personaAutorizadaId;

  bool _cargando = false;
  bool _esEdicion = false;

  @override
  void initState() {
    super.initState();
    // La fecha siempre es HOY, no necesita selector
    _fecha = DateTime.now();
    
    if (widget.controlId != null) {
      _esEdicion = true;
      _cargarDatosControl();
    }
  }

  Future<void> _cargarDatosControl() async {
    try {
      setState(() => _cargando = true);

      final response = await Supabase.instance.client
          .from('control_salidas')
          .select()
          .eq('id', widget.controlId!)
          .single();

      if (!mounted) return;

      final control = ControlSalida.fromJson(response);

      setState(() {
        _alumnoSeleccionadoId = control.alumnoId;
        _fecha = control.fecha;
        _horaEntrada = control.horaEntrada != null 
            ? TimeOfDay.fromDateTime(control.horaEntrada!) 
            : const TimeOfDay(hour: 9, minute: 0);
        _horaSalida = control.horaSalida != null 
            ? TimeOfDay.fromDateTime(control.horaSalida!) 
            : const TimeOfDay(hour: 14, minute: 0);
        _quienTrajoController.text = control.quienTrajo ?? '';
        _quienRecogioController.text = control.quienRecogio ?? '';
        _personaAutorizadaId = control.personaAutorizadaId;
        _cargando = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar registro: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _cargando = false);
      }
    }
  }

  @override
  void dispose() {
    _quienTrajoController.dispose();
    _quienRecogioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.amarillo, AppColors.naranja],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Row(
          children: [
            const Icon(Icons.access_time, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              _esEdicion ? 'Editar Registro' : 'Nuevo Registro',
              style: GoogleFonts.fredoka(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
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
                          colors: [AppColors.amarilloClaro, AppColors.naranjaClaro],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time, color: Colors.white, size: 40),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _esEdicion
                                      ? 'Modificar Registro'
                                      : 'Registrar Entrada/Salida',
                                  style: GoogleFonts.fredoka(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Control de asistencia del alumno',
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

                    // Alumno y Fecha
                    _buildSeccionTitulo('Información Básica'),
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
                            // Selector de alumno
                            StreamBuilder<List<Map<String, dynamic>>>(
                              stream: Supabase.instance.client
                                  .from('alumnos')
                                  .stream(primaryKey: ['id'])
                                  .order('nombre', ascending: true),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) {
                                  return const CircularProgressIndicator();
                                }

                                final alumnos = snapshot.data!
                                    .map((json) => Alumno.fromJson(json))
                                    .toList();

                                return DropdownButtonFormField<String>(
                                  value: _alumnoSeleccionadoId,
                                  decoration: InputDecoration(
                                    labelText: 'Alumno *',
                                    prefixIcon: const Icon(Icons.child_care),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  items: alumnos.map((alumno) {
                                    return DropdownMenuItem(
                                      value: alumno.id,
                                      child: Text('${alumno.nombre} ${alumno.apellidos}'),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _alumnoSeleccionadoId = value;
                                    });
                                  },
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Selecciona un alumno';
                                    }
                                    return null;
                                  },
                                );
                              },
                            ),
                            const SizedBox(height: 16),

                            // Fecha automática (HOY)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.amarilloClaro.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.amarillo.withOpacity(0.5)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_today, color: AppColors.naranja),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Hoy: ${DateFormat('EEEE, dd/MM/yyyy', 'es').format(_fecha)}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.negro,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ENTRADA
                    _buildSeccionTitulo('Registro de Entrada'),
                    const SizedBox(height: 12),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.green, width: 2),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            // Hora de entrada
                            InkWell(
                              onTap: () => _seleccionarHora(true),
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Hora de Entrada',
                                  prefixIcon: const Icon(Icons.login, color: Colors.green),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  _horaEntrada != null
                                      ? _horaEntrada!.format(context)
                                      : 'Seleccionar hora',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: _horaEntrada != null
                                        ? Colors.black
                                        : Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Quién trajo
                            TextFormField(
                              controller: _quienTrajoController,
                              decoration: InputDecoration(
                                labelText: 'Quién trajo al niño',
                                hintText: 'Ej: Mamá, Papá, Abuela',
                                prefixIcon: const Icon(Icons.person),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // SALIDA
                    _buildSeccionTitulo('Registro de Salida'),
                    const SizedBox(height: 12),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.orange, width: 2),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            // Hora de salida
                            InkWell(
                              onTap: () => _seleccionarHora(false),
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Hora de Salida',
                                  prefixIcon: const Icon(Icons.logout, color: Colors.orange),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  _horaSalida != null
                                      ? _horaSalida!.format(context)
                                      : 'Seleccionar hora',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: _horaSalida != null
                                        ? Colors.black
                                        : Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Quién recogió
                            TextFormField(
                              controller: _quienRecogioController,
                              decoration: InputDecoration(
                                labelText: 'Quién recogió al niño',
                                hintText: 'Ej: Mamá, Papá, Abuela',
                                prefixIcon: const Icon(Icons.person),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Persona autorizada
                            if (_alumnoSeleccionadoId != null)
                              StreamBuilder<List<Map<String, dynamic>>>(
                                stream: Supabase.instance.client
                                    .from('personas_autorizadas')
                                    .stream(primaryKey: ['id'])
                                    .eq('alumno_id', _alumnoSeleccionadoId!),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                    return const SizedBox.shrink();
                                  }

                                  final personasAutorizadas = snapshot.data!
                                      .map((json) => PersonaAutorizada.fromJson(json))
                                      .toList();

                                  return DropdownButtonFormField<String>(
                                    value: _personaAutorizadaId,
                                    decoration: InputDecoration(
                                      labelText: 'Persona Autorizada (opcional)',
                                      prefixIcon: const Icon(Icons.verified_user),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    items: [
                                      const DropdownMenuItem(
                                        value: null,
                                        child: Text('Ninguna'),
                                      ),
                                      ...personasAutorizadas.map((persona) {
                                        return DropdownMenuItem(
                                          value: persona.id,
                                          child: Text('${persona.nombre} (${persona.parentesco})'),
                                        );
                                      }),
                                    ],
                                    onChanged: (value) {
                                      setState(() {
                                        _personaAutorizadaId = value;
                                      });
                                    },
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Botón guardar
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _guardarControl,
                        icon: const Icon(Icons.save, color: Colors.white),
                        label: Text(
                          _esEdicion ? 'Actualizar Registro' : 'Guardar Registro',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.verde,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
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
                            'Eliminar Registro',
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

  Future<void> _seleccionarHora(bool esEntrada) async {
    final TimeOfDay? hora = await showTimePicker(
      context: context,
      initialTime: esEntrada
          ? (_horaEntrada ?? TimeOfDay.now())
          : (_horaSalida ?? TimeOfDay.now()),
    );

    if (hora != null) {
      setState(() {
        if (esEntrada) {
          _horaEntrada = hora;
        } else {
          _horaSalida = hora;
        }
      });
    }
  }

  Future<void> _guardarControl() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_alumnoSeleccionadoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona un alumno'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _cargando = true);

    try {
      final Map<String, dynamic> controlData = {
        'alumno_id': _alumnoSeleccionadoId,
        'fecha': DateFormat('yyyy-MM-dd').format(_fecha),
        'hora_entrada': _horaEntrada != null
            ? '${_horaEntrada!.hour.toString().padLeft(2, '0')}:${_horaEntrada!.minute.toString().padLeft(2, '0')}:00'
            : null,
        'quien_trajo': _quienTrajoController.text.trim().isEmpty
            ? null
            : _quienTrajoController.text.trim(),
        'hora_salida': _horaSalida != null
            ? '${_horaSalida!.hour.toString().padLeft(2, '0')}:${_horaSalida!.minute.toString().padLeft(2, '0')}:00'
            : null,
        'quien_recogio': _quienRecogioController.text.trim().isEmpty
            ? null
            : _quienRecogioController.text.trim(),
        'persona_autorizada_id': _personaAutorizadaId,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (_esEdicion) {
        // Actualizar control existente
        await Supabase.instance.client
            .from('control_salidas')
            .update(controlData)
            .eq('id', widget.controlId!);
      } else {
        // Crear nuevo control
        controlData['id'] = const Uuid().v4();
        controlData['created_at'] = DateTime.now().toIso8601String();

        await Supabase.instance.client
            .from('control_salidas')
            .insert(controlData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _esEdicion
                  ? '✓ Registro actualizado correctamente'
                  : '✓ Registro creado correctamente',
            ),
            backgroundColor: Colors.green,
          ),
        );
        GoRouter.of(context).go('/directora/control-salidas');
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
              '¿Eliminar Registro?',
              style: GoogleFonts.fredoka(),
            ),
          ],
        ),
        content: Text(
          'Esta acción no se puede deshacer. ¿Estás segura de eliminar este registro?',
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
      await _eliminarControl();
    }
  }

  Future<void> _eliminarControl() async {
    setState(() => _cargando = true);

    try {
      await Supabase.instance.client
          .from('control_salidas')
          .delete()
          .eq('id', widget.controlId!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Registro eliminado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        GoRouter.of(context).go('/directora/control-salidas');
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
