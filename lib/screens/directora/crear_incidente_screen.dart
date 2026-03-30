import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../config/app_colors.dart';
import '../../widgets/app_drawer.dart';
import '../../models/alumno.dart';
import '../../models/tipo_incidente.dart';

class CrearIncidenteScreen extends StatefulWidget {
  const CrearIncidenteScreen({Key? key}) : super(key: key);

  @override
  State<CrearIncidenteScreen> createState() => _CrearIncidenteScreenState();
}

class _CrearIncidenteScreenState extends State<CrearIncidenteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descripcionController = TextEditingController();
  final _observacionesController = TextEditingController();

  List<Alumno> _alumnos = [];
  List<TipoIncidente> _tiposIncidentes = [];
  Alumno? _alumnoSeleccionado;
  TipoIncidente? _tipoSeleccionado;
  DateTime _fechaSeleccionada = DateTime.now();
  TimeOfDay _horaSeleccionada = TimeOfDay.now();
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    try {
      // Cargar alumnos
      final alumnosResponse = await Supabase.instance.client
          .from('alumnos')
          .select()
          .eq('activo', true)
          .order('nombre');

      // Cargar tipos de incidentes activos
      final tiposResponse = await Supabase.instance.client
          .from('tipos_incidentes')
          .select()
          .eq('activo', true)
          .order('nivel')
          .order('nombre');

      setState(() {
        _alumnos = (alumnosResponse as List)
            .map((json) => Alumno.fromJson(json))
            .toList();
        _tiposIncidentes = (tiposResponse as List)
            .map((json) => TipoIncidente.fromJson(json))
            .toList();
        _cargando = false;
      });
    } catch (e) {
      print('Error cargando datos: $e');
      setState(() => _cargando = false);
    }
  }

  Future<void> _guardarIncidente() async {
    if (!_formKey.currentState!.validate()) return;

    if (_alumnoSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Selecciona un alumno'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_tipoSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Selecciona un tipo de incidente'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final usuarioId = Supabase.instance.client.auth.currentUser?.id;
      final fechaHora = DateTime(
        _fechaSeleccionada.year,
        _fechaSeleccionada.month,
        _fechaSeleccionada.day,
        _horaSeleccionada.hour,
        _horaSeleccionada.minute,
      );

      final incidenteData = {
        'id': const Uuid().v4(),
        'alumno_id': _alumnoSeleccionado!.id,
        'tipo_incidente_id': _tipoSeleccionado!.id,
        'nivel': _tipoSeleccionado!.nivel,
        'titulo': _tipoSeleccionado!.nombre,
        'descripcion': _descripcionController.text.trim(),
        'fecha': fechaHora.toIso8601String(),
        'reportado_por': usuarioId,
        'atendido': false,
        'padre_notificado': false, // El trigger lo manejará si nivel >= 4
        'observaciones': _observacionesController.text.trim().isEmpty
            ? null
            : _observacionesController.text.trim(),
        'created_at': DateTime.now().toIso8601String(),
      };

      await Supabase.instance.client
          .from('incidentes')
          .insert(incidenteData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _tipoSeleccionado!.nivel >= 4
                  ? '✅ Incidente creado. Padre será notificado.'
                  : '✅ Incidente creado correctamente',
            ),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      print('Error guardando incidente: $e');
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
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.naranja, AppColors.rojo],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
        title: Text(
          'Registrar Incidente',
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
                    // Seleccionar alumno
                    _buildSectionTitle('👶 Alumno'),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<Alumno>(
                      value: _alumnoSeleccionado,
                      decoration: InputDecoration(
                        labelText: 'Selecciona el alumno',
                        prefixIcon: const Icon(Icons.child_care),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: _alumnos.map((alumno) {
                        return DropdownMenuItem(
                          value: alumno,
                          child: Text(alumno.nombreCompleto),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _alumnoSeleccionado = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Selecciona un alumno';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Seleccionar tipo de incidente
                    _buildSectionTitle('📋 Tipo de Incidente'),
                    const SizedBox(height: 12),
                    Card(
                      child: Column(
                        children: _tiposIncidentes.map((tipo) {
                          final isSelected = _tipoSeleccionado?.id == tipo.id;
                          return ListTile(
                            selected: isSelected,
                            selectedTileColor: _getColorNivel(tipo.nivel).withOpacity(0.1),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _getColorNivel(tipo.nivel),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                tipo.emoji,
                                style: const TextStyle(fontSize: 20),
                              ),
                            ),
                            title: Text(
                              tipo.nombre,
                              style: GoogleFonts.poppins(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${tipo.categoriaEmoji} ${tipo.categoria}'),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getColorNivel(tipo.nivel).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'NIVEL ${tipo.nivel} - ${tipo.nivelLabel.toUpperCase()}',
                                    style: TextStyle(
                                      color: _getColorNivel(tipo.nivel),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (tipo.nivel >= 4)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      '🔔 Notificará al padre',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.orange[700],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            trailing: isSelected
                                ? const Icon(Icons.check_circle, color: Colors.green)
                                : null,
                            onTap: () {
                              setState(() {
                                _tipoSeleccionado = tipo;
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Descripción detallada
                    _buildSectionTitle('📝 Detalles'),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descripcionController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'Descripción detallada',
                        hintText: '¿Qué sucedió? ¿Cuándo? ¿Cómo?',
                        prefixIcon: const Icon(Icons.description),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingresa una descripción';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Observaciones adicionales
                    TextFormField(
                      controller: _observacionesController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Observaciones (Opcional)',
                        hintText: 'Información adicional...',
                        prefixIcon: const Icon(Icons.note),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
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
                                    const Icon(Icons.calendar_today, color: AppColors.azulOscuro),
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
                        const SizedBox(width: 12),
                        Expanded(
                          child: Card(
                            child: InkWell(
                              onTap: _seleccionarHora,
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    const Icon(Icons.access_time, color: AppColors.azulOscuro),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Hora',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        Text(
                                          _horaSeleccionada.format(context),
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

                    const SizedBox(height: 32),

                    // Botón guardar
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _guardarIncidente,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _tipoSeleccionado != null && _tipoSeleccionado!.nivel >= 4
                              ? Colors.red[700]
                              : AppColors.azulOscuro,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_tipoSeleccionado != null && _tipoSeleccionado!.nivel >= 4)
                              const Icon(Icons.notifications_active),
                            if (_tipoSeleccionado != null && _tipoSeleccionado!.nivel >= 4)
                              const SizedBox(width: 8),
                            Text(
                              _tipoSeleccionado != null && _tipoSeleccionado!.nivel >= 4
                                  ? 'Registrar y Notificar Padre'
                                  : 'Registrar Incidente',
                              style: GoogleFonts.fredoka(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (_tipoSeleccionado != null && _tipoSeleccionado!.nivel >= 4) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange, width: 2),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: Colors.orange),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Este incidente notificará automáticamente al padre del alumno.',
                                style: TextStyle(
                                  color: Colors.orange[900],
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
        color: AppColors.azulOscuro,
      ),
    );
  }

  Color _getColorNivel(int nivel) {
    switch (nivel) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.yellow[700]!;
      case 3:
        return Colors.orange;
      case 4:
        return Colors.deepOrange;
      case 5:
        return Colors.red[900]!;
      default:
        return Colors.grey;
    }
  }

  Future<void> _seleccionarFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'MX'),
    );

    if (picked != null && picked != _fechaSeleccionada) {
      setState(() {
        _fechaSeleccionada = picked;
      });
    }
  }

  Future<void> _seleccionarHora() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _horaSeleccionada,
    );

    if (picked != null && picked != _horaSeleccionada) {
      setState(() {
        _horaSeleccionada = picked;
      });
    }
  }

  @override
  void dispose() {
    _descripcionController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }
}
