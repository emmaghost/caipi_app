import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/app_colors.dart';
import '../../models/control_salida.dart';
import '../../widgets/app_drawer.dart';

class ControlSalidasScreen extends StatefulWidget {
  const ControlSalidasScreen({super.key});

  @override
  State<ControlSalidasScreen> createState() => _ControlSalidasScreenState();
}

class _ControlSalidasScreenState extends State<ControlSalidasScreen> {
  DateTime _fechaSeleccionada = DateTime.now();

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
              'Control de Entrada/Salida',
              style: GoogleFonts.fredoka(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today, color: Colors.white),
            onPressed: _seleccionarFecha,
          ),
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
        child: Column(
          children: [
            // Encabezado con fecha
            Container(
              margin: const EdgeInsets.all(16),
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
                  const Icon(Icons.calendar_today, color: Colors.white, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Fecha Seleccionada',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        Text(
                          DateFormat('EEEE, dd \'de\' MMMM yyyy', 'es_MX')
                              .format(_fechaSeleccionada),
                          style: GoogleFonts.fredoka(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_calendar, color: Colors.white),
                    onPressed: _seleccionarFecha,
                  ),
                ],
              ),
            ),

            // Lista de controles
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: Supabase.instance.client
                    .from('control_salidas')
                    .stream(primaryKey: ['id'])
                    .eq('fecha', DateFormat('yyyy-MM-dd').format(_fechaSeleccionada))
                    .order('created_at', ascending: false),
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
                            'Error al cargar registros',
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
                          Icon(Icons.access_time_outlined,
                              size: 80,
                              color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No hay registros para esta fecha',
                            style: GoogleFonts.fredoka(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () {
                              GoRouter.of(context).push(
                                '/directora/control-salidas/crear',
                                extra: {'fecha': _fechaSeleccionada},
                              );
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Registrar Entrada/Salida'),
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

                  final controlesData = snapshot.data!;
                  final controles = controlesData
                      .map((json) => ControlSalida.fromJson(json))
                      .toList();

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: controles.length,
                    itemBuilder: (context, index) {
                      final control = controles[index];
                      return _ControlSalidaCard(control: control);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          GoRouter.of(context).push(
            '/directora/control-salidas/crear',
            extra: {'fecha': _fechaSeleccionada},
          );
        },
        backgroundColor: AppColors.verdeClaro,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'Nuevo Registro',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('es', 'MX'),
    );

    if (fecha != null) {
      setState(() {
        _fechaSeleccionada = fecha;
      });
    }
  }
}

class _ControlSalidaCard extends StatelessWidget {
  final ControlSalida control;

  const _ControlSalidaCard({required this.control});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          GoRouter.of(context).push(
            '/directora/control-salidas/editar/${control.id}',
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado
              Row(
                children: [
                  // Avatar del alumno
                  FutureBuilder<Map<String, dynamic>>(
                    future: _cargarAlumno(control.alumnoId),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const CircularProgressIndicator();
                      }
                      final alumno = snapshot.data!;
                      return Row(
                        children: [
                          CircleAvatar(
                            radius: 25,
                            backgroundColor: AppColors.azulOscuro,
                            child: Text(
                              alumno['nombre'][0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${alumno['nombre']} ${alumno['apellidos']}',
                                style: GoogleFonts.fredoka(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.azulOscuro,
                                ),
                              ),
                              Text(
                                DateFormat('dd/MM/yyyy').format(control.fecha),
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () {
                      GoRouter.of(context).push(
                        '/directora/control-salidas/editar/${control.id}',
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Entrada
              _buildRegistroItem(
                context: context,
                icon: Icons.login,
                label: 'ENTRADA',
                hora: control.horaEntrada,
                persona: control.quienTrajo,
                color: Colors.green,
              ),
              const SizedBox(height: 12),

              // Salida
              _buildRegistroItem(
                context: context,
                icon: Icons.logout,
                label: 'SALIDA',
                hora: control.horaSalida,
                persona: control.quienRecogio,
                color: Colors.orange,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRegistroItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required DateTime? hora,
    required String? persona,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                if (hora != null) ...[
                  Text(
                    'Hora: ${_formatHora(hora)}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (persona != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      persona,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ] else ...[
                  Text(
                    'Sin registrar',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>> _cargarAlumno(String alumnoId) async {
    final response = await Supabase.instance.client
        .from('alumnos')
        .select('nombre, apellidos')
        .eq('id', alumnoId)
        .single();
    return response;
  }

  String _formatHora(DateTime dateTime) {
    final hora = TimeOfDay.fromDateTime(dateTime);
    final h = hora.hour.toString().padLeft(2, '0');
    final m = hora.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
