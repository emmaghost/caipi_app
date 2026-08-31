import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../config/app_colors.dart';
import '../../models/alumno.dart';
import '../../services/auth_service.dart';
import '../../utils/constantes.dart';
import '../../widgets/app_drawer.dart';

class CalificacionesAlumnoScreen extends StatefulWidget {
  final String alumnoId;

  const CalificacionesAlumnoScreen({super.key, required this.alumnoId});

  @override
  State<CalificacionesAlumnoScreen> createState() =>
      _CalificacionesAlumnoScreenState();
}

class _CalificacionesAlumnoScreenState
    extends State<CalificacionesAlumnoScreen> {
  Alumno? _alumno;
  bool _cargando = true;

  bool get _soloIngles =>
      context.read<AuthService>().currentUser?.esMaestraIngles == true;

  bool _esMateriaIngles(String? materia) {
    final n = (materia ?? '')
        .toLowerCase()
        .replaceAll('é', 'e')
        .replaceAll('í', 'i');
    return n.contains('ingles');
  }

  @override
  void initState() {
    super.initState();
    _cargarAlumno();
  }

  Future<void> _cargarAlumno() async {
    try {
      final response = await Supabase.instance.client
          .from('alumnos')
          .select()
          .eq('id', widget.alumnoId)
          .single();

      if (mounted) {
        setState(() {
          _alumno = Alumno.fromJson(response);
          _cargando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar alumno: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _cargando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.grade, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              _soloIngles ? 'Inglés' : 'Calificaciones',
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
          : _alumno == null
              ? Center(
                  child: Text(
                    'No se pudo cargar la información del alumno',
                    style: GoogleFonts.poppins(fontSize: 16),
                  ),
                )
              : Container(
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
                  child: Column(
                    children: [
                      // Encabezado con info del alumno
                      Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.moradoClaro, AppColors.azulOscuro],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 35,
                              backgroundColor: Colors.white,
                              child: Text(
                                _alumno!.nombre[0].toUpperCase(),
                                style: TextStyle(
                                  color: AppColors.azulOscuro,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${_alumno!.nombre} ${_alumno!.apellidos}',
                                    style: GoogleFonts.fredoka(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  FutureBuilder<Map<String, dynamic>>(
                                    future: _cargarGrado(_alumno!.gradoId),
                                    builder: (context, snapshot) {
                                      if (!snapshot.hasData) {
                                        return const SizedBox.shrink();
                                      }
                                      return Text(
                                        snapshot.data!['nombre'],
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          color: Colors.white.withOpacity(0.9),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Lista de calificaciones
                      Expanded(
                        child: StreamBuilder<List<Map<String, dynamic>>>(
                          stream: Supabase.instance.client
                              .from('calificaciones')
                              .stream(primaryKey: ['id'])
                              .eq('alumno_id', widget.alumnoId)
                              .order('periodo', ascending: true)
                              .order('materia', ascending: true),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }

                            if (snapshot.hasError) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.error_outline,
                                        size: 64, color: Colors.red),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Error al cargar calificaciones',
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
                                    Icon(Icons.grade_outlined,
                                        size: 80, color: Colors.grey[400]),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No hay calificaciones ${_soloIngles ? 'de Inglés ' : ''}registradas',
                                      style: GoogleFonts.fredoka(
                                        fontSize: 18,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    ElevatedButton.icon(
                                      onPressed: () => _mostrarDialogoNuevaCalificacion(),
                                      icon: const Icon(Icons.add),
                                      label: const Text('Agregar Calificación'),
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

                            var calificacionesData = snapshot.data!;
                            if (_soloIngles) {
                              calificacionesData = calificacionesData
                                  .where((c) => _esMateriaIngles(
                                      c['materia'] as String?))
                                  .toList();
                            }

                            if (calificacionesData.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.grade_outlined,
                                        size: 80, color: Colors.grey[400]),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No hay calificaciones ${_soloIngles ? 'de Inglés ' : ''}registradas',
                                      style: GoogleFonts.fredoka(
                                        fontSize: 18,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    ElevatedButton.icon(
                                      onPressed: () =>
                                          _mostrarDialogoNuevaCalificacion(),
                                      icon: const Icon(Icons.add),
                                      label: Text(_soloIngles
                                          ? 'Agregar Inglés'
                                          : 'Agregar Calificación'),
                                    ),
                                  ],
                                ),
                              );
                            }

                            // Agrupar por periodo
                            final Map<String, List<Map<String, dynamic>>>
                                calificacionesPorPeriodo = {};
                            for (final cal in calificacionesData) {
                              final periodo = cal['periodo'] as String;
                              if (!calificacionesPorPeriodo.containsKey(periodo)) {
                                calificacionesPorPeriodo[periodo] = [];
                              }
                              calificacionesPorPeriodo[periodo]!.add(cal);
                            }

                            return ListView(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              children: calificacionesPorPeriodo.entries
                                  .map((entry) {
                                return _PeriodoCard(
                                  periodo: entry.key,
                                  calificaciones: entry.value,
                                  onEdit: _mostrarDialogoEditarCalificacion,
                                  onDelete: _eliminarCalificacion,
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _mostrarDialogoNuevaCalificacion,
        backgroundColor: AppColors.verdeClaro,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          _soloIngles ? 'Inglés' : 'Agregar',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> _cargarGrado(String? gradoId) async {
    if (gradoId == null) {
      return {'nombre': 'Sin grado'};
    }
    final response = await Supabase.instance.client
        .from('grados')
        .select('nombre')
        .eq('id', gradoId)
        .single();
    return response;
  }

  Future<void> _mostrarDialogoNuevaCalificacion() async {
    final soloIngles = _soloIngles;
    final _materiaController = TextEditingController(
      text: soloIngles ? Constantes.materiaIngles : '',
    );
    final _calificacionController = TextEditingController();
    String periodo = 'Bimestre 1';

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Nueva Calificación',
          style: GoogleFonts.fredoka(),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: periodo,
                decoration: InputDecoration(
                  labelText: 'Periodo',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: [
                  'Bimestre 1',
                  'Bimestre 2',
                  'Bimestre 3',
                  'Bimestre 4',
                  'Bimestre 5',
                  'Bimestre 6',
                ].map((p) {
                  return DropdownMenuItem(
                    value: p,
                    child: Text(p),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    periodo = value;
                  }
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _materiaController,
                enabled: !soloIngles,
                decoration: InputDecoration(
                  labelText: 'Materia',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _calificacionController,
                decoration: InputDecoration(
                  labelText: 'Calificación (0-10)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if ((!soloIngles && _materiaController.text.trim().isEmpty) ||
                  _calificacionController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Completa todos los campos'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              final calificacion = double.tryParse(_calificacionController.text);
              if (calificacion == null || calificacion < 0 || calificacion > 10) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('La calificación debe ser entre 0 y 10'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              try {
                await Supabase.instance.client.from('calificaciones').insert({
                  'id': const Uuid().v4(),
                  'alumno_id': widget.alumnoId,
                  'periodo': periodo,
                  'materia': soloIngles
                      ? Constantes.materiaIngles
                      : _materiaController.text.trim(),
                  'calificacion': calificacion,
                  'created_at': DateTime.now().toIso8601String(),
                  'updated_at': DateTime.now().toIso8601String(),
                });

                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✓ Calificación agregada'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _mostrarDialogoEditarCalificacion(Map<String, dynamic> calificacion) async {
    final soloIngles = _soloIngles;
    final _materiaController = TextEditingController(
      text: soloIngles
          ? Constantes.materiaIngles
          : calificacion['materia'] as String,
    );
    final _calificacionController =
        TextEditingController(text: calificacion['calificacion'].toString());
    String periodo = calificacion['periodo'] as String;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Editar Calificación',
          style: GoogleFonts.fredoka(),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: periodo,
                decoration: InputDecoration(
                  labelText: 'Periodo',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: [
                  'Bimestre 1',
                  'Bimestre 2',
                  'Bimestre 3',
                  'Bimestre 4',
                  'Bimestre 5',
                  'Bimestre 6',
                ].map((p) {
                  return DropdownMenuItem(
                    value: p,
                    child: Text(p),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    periodo = value;
                  }
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _materiaController,
                enabled: !soloIngles,
                decoration: InputDecoration(
                  labelText: 'Materia',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _calificacionController,
                decoration: InputDecoration(
                  labelText: 'Calificación (0-10)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if ((!soloIngles && _materiaController.text.trim().isEmpty) ||
                  _calificacionController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Completa todos los campos'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              final calificacionValor =
                  double.tryParse(_calificacionController.text);
              if (calificacionValor == null ||
                  calificacionValor < 0 ||
                  calificacionValor > 10) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('La calificación debe ser entre 0 y 10'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              try {
                await Supabase.instance.client
                    .from('calificaciones')
                    .update({
                  'periodo': periodo,
                  'materia': soloIngles
                      ? Constantes.materiaIngles
                      : _materiaController.text.trim(),
                  'calificacion': calificacionValor,
                  'updated_at': DateTime.now().toIso8601String(),
                }).eq('id', calificacion['id'] as String);

                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✓ Calificación actualizada'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Actualizar'),
          ),
        ],
      ),
    );
  }

  Future<void> _eliminarCalificacion(String calificacionId) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '¿Eliminar Calificación?',
          style: GoogleFonts.fredoka(),
        ),
        content: Text(
          'Esta acción no se puede deshacer.',
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
      try {
        await Supabase.instance.client
            .from('calificaciones')
            .delete()
            .eq('id', calificacionId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ Calificación eliminada'),
              backgroundColor: Colors.green,
            ),
          );
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
}

class _PeriodoCard extends StatelessWidget {
  final String periodo;
  final List<Map<String, dynamic>> calificaciones;
  final Function(Map<String, dynamic>) onEdit;
  final Function(String) onDelete;

  const _PeriodoCard({
    required this.periodo,
    required this.calificaciones,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // Calcular promedio
    final promedio = calificaciones.isEmpty
        ? 0.0
        : calificaciones
                .map((c) => c['calificacion'] as num)
                .reduce((a, b) => a + b) /
            calificaciones.length;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado del periodo
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.moradoClaro.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.calendar_today, color: AppColors.moradoClaro),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        periodo,
                        style: GoogleFonts.fredoka(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.azulOscuro,
                        ),
                      ),
                      Text(
                        '${calificaciones.length} ${calificaciones.length == 1 ? 'materia' : 'materias'}',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _getColorPromedio(promedio).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _getColorPromedio(promedio),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Promedio',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: _getColorPromedio(promedio),
                        ),
                      ),
                      Text(
                        promedio.toStringAsFixed(1),
                        style: GoogleFonts.fredoka(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _getColorPromedio(promedio),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),

            // Lista de materias
            ...calificaciones.map((cal) {
              final calificacion = cal['calificacion'] as num;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        cal['materia'] as String,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getColorCalificacion(calificacion.toDouble())
                            .withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        calificacion.toStringAsFixed(1),
                        style: GoogleFonts.fredoka(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _getColorCalificacion(calificacion.toDouble()),
                        ),
                      ),
                    ),
                    PopupMenuButton(
                      icon: const Icon(Icons.more_vert, size: 20),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          child: const Row(
                            children: [
                              Icon(Icons.edit, size: 18),
                              SizedBox(width: 8),
                              Text('Editar'),
                            ],
                          ),
                          onTap: () => Future.delayed(
                            Duration.zero,
                            () => onEdit(cal),
                          ),
                        ),
                        PopupMenuItem(
                          child: const Row(
                            children: [
                              Icon(Icons.delete, size: 18, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Eliminar', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                          onTap: () => Future.delayed(
                            Duration.zero,
                            () => onDelete(cal['id'] as String),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Color _getColorCalificacion(double cal) {
    if (cal >= 8.0) return Colors.green;
    if (cal >= 6.0) return Colors.orange;
    return Colors.red;
  }

  Color _getColorPromedio(double prom) {
    if (prom >= 8.0) return Colors.green;
    if (prom >= 6.0) return Colors.orange;
    return Colors.red;
  }
}
