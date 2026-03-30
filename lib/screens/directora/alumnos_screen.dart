import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../services/supabase_service.dart';
import '../../models/alumno.dart';
import '../../models/grado.dart';
import '../../widgets/alumno_card.dart';
import '../../widgets/app_drawer.dart';

class AlumnosScreen extends StatefulWidget {
  const AlumnosScreen({super.key});

  @override
  State<AlumnosScreen> createState() => _AlumnosScreenState();
}

class _AlumnosScreenState extends State<AlumnosScreen> {
  String _filtroGrado = 'Todos';
  String _busqueda = '';
  List<Grado> _grados = [];
  bool _cargandoGrados = true;

  @override
  void initState() {
    super.initState();
    _cargarGrados();
  }

  Future<void> _cargarGrados() async {
    try {
      final supabaseService = context.read<SupabaseService>();
      final grados = await supabaseService.obtenerGrados();
      setState(() {
        _grados = grados;
        _cargandoGrados = false;
      });
    } catch (e) {
      print('Error cargando grados: $e');
      setState(() {
        _cargandoGrados = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = context.read<SupabaseService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alumnos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/directora/alumnos/crear'),
          ),
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => context.go('/directora'),
            tooltip: 'Ir al inicio',
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _busqueda = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Buscar alumno...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          // Filtro de grado
          SizedBox(
            height: 50,
            child: _cargandoGrados
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _FiltroChip(
                        label: 'Todos',
                        isSelected: _filtroGrado == 'Todos',
                        onTap: () => setState(() => _filtroGrado = 'Todos'),
                      ),
                      ..._grados.map((grado) => _FiltroChip(
                            label: grado.nombre,
                            isSelected: _filtroGrado == grado.id,
                            onTap: () => setState(() => _filtroGrado = grado.id),
                          )),
                    ],
                  ),
          ),

          const SizedBox(height: 8),

          // Lista de alumnos
          Expanded(
            child: StreamBuilder<List<Alumno>>(
              stream: firestoreService.getAlumnos(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.school_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No hay alumnos registrados',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () => context.push('/directora/alumnos/crear'),
                          icon: const Icon(Icons.add),
                          label: const Text('Agregar primer alumno'),
                        ),
                      ],
                    ),
                  );
                }

                // Filtrar alumnos
                var alumnos = snapshot.data!;
                
                if (_filtroGrado != 'Todos') {
                  alumnos = alumnos
                      .where((a) => a.gradoId == _filtroGrado)
                      .toList();
                }

                if (_busqueda.isNotEmpty) {
                  alumnos = alumnos
                      .where((a) =>
                          a.nombreCompleto.toLowerCase().contains(_busqueda))
                      .toList();
                }

                if (alumnos.isEmpty) {
                  return const Center(
                    child: Text('No se encontraron alumnos'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: alumnos.length,
                  itemBuilder: (context, index) {
                    return AlumnoCard(
                      alumno: alumnos[index],
                      showAutorizados: true,
                      onTap: () {
                        // Aquí puedes navegar al detalle o editar
                        context.push('/directora/alumnos/editar/${alumnos[index].id}');
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FiltroChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FiltroChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: Theme.of(context).colorScheme.primaryContainer,
      ),
    );
  }
}
