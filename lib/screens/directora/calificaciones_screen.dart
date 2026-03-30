import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/app_colors.dart';
import '../../models/alumno.dart';
import '../../widgets/app_drawer.dart';

class CalificacionesScreen extends StatefulWidget {
  const CalificacionesScreen({super.key});

  @override
  State<CalificacionesScreen> createState() => _CalificacionesScreenState();
}

class _CalificacionesScreenState extends State<CalificacionesScreen> {
  String? _gradoSeleccionado;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.grade, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              'Calificaciones',
              style: GoogleFonts.fredoka(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.azulOscuro,
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
        child: Column(
          children: [
            // Selector de grado
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
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: Supabase.instance.client
                    .from('grados')
                    .stream(primaryKey: ['id'])
                    .eq('activo', true)
                    .order('nombre', ascending: true),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final grados = snapshot.data!;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Filtrar por Grado',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _gradoSeleccionado,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.school),
                        ),
                        hint: const Text('Todos los grados'),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('Todos los grados'),
                          ),
                          ...grados.map((grado) {
                            return DropdownMenuItem(
                              value: grado['id'] as String,
                              child: Text(grado['nombre'] as String),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _gradoSeleccionado = value;
                          });
                        },
                      ),
                    ],
                  );
                },
              ),
            ),

            // Lista de alumnos
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _gradoSeleccionado == null
                    ? Supabase.instance.client
                        .from('alumnos')
                        .stream(primaryKey: ['id'])
                        .order('nombre', ascending: true)
                    : Supabase.instance.client
                        .from('alumnos')
                        .stream(primaryKey: ['id'])
                        .eq('grado_id', _gradoSeleccionado!)
                        .order('nombre', ascending: true),
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
                            'Error al cargar alumnos',
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
                          Icon(Icons.people_outline,
                              size: 80,
                              color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No hay alumnos en este grado',
                            style: GoogleFonts.fredoka(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final alumnosData = snapshot.data!;
                  final alumnos = alumnosData
                      .map((json) => Alumno.fromJson(json))
                      .toList();

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: alumnos.length,
                    itemBuilder: (context, index) {
                      final alumno = alumnos[index];
                      return _AlumnoCalificacionCard(alumno: alumno);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlumnoCalificacionCard extends StatelessWidget {
  final Alumno alumno;

  const _AlumnoCalificacionCard({required this.alumno});

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
            '/directora/calificaciones/alumno/${alumno.id}',
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.moradoClaro,
                child: Text(
                  alumno.nombre[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Información
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${alumno.nombre} ${alumno.apellidos}',
                      style: GoogleFonts.fredoka(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.azulOscuro,
                      ),
                    ),
                    const SizedBox(height: 4),
                    FutureBuilder<Map<String, dynamic>>(
                      future: _cargarGrado(alumno.gradoId),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          snapshot.data!['nombre'],
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Indicador de calificaciones
              FutureBuilder<int>(
                future: _contarCalificaciones(alumno.id),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const SizedBox.shrink();
                  }
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: snapshot.data! > 0
                          ? Colors.green[50]
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: snapshot.data! > 0
                            ? Colors.green
                            : Colors.grey,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.grade,
                          size: 16,
                          color: snapshot.data! > 0
                              ? Colors.green[700]
                              : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${snapshot.data!}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: snapshot.data! > 0
                                ? Colors.green[700]
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
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

  Future<int> _contarCalificaciones(String alumnoId) async {
    final response = await Supabase.instance.client
        .from('calificaciones')
        .select()
        .eq('alumno_id', alumnoId);
    return response.length;
  }
}
