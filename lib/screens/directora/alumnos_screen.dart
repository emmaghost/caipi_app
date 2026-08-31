import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../services/auth_service.dart';
import '../../services/portage_service.dart';
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
  List<Alumno> _alumnos = [];
  bool _cargandoAlumnos = true;
  String? _errorAlumnos;
  int _listaEpoch = 0;

  /// Si la profesora de aula tiene grado fijo, no puede cambiar el filtro.
  bool _gradoBloqueado = false;

  SupabaseService? _supabaseService;

  @override
  void initState() {
    super.initState();
    _cargarGrados();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _supabaseService = context.read<SupabaseService>();
      _supabaseService!.alumnosRevision.addListener(_onAlumnosRevision);
      _refrescarAlumnos();
    });
  }

  @override
  void dispose() {
    _supabaseService?.alumnosRevision.removeListener(_onAlumnosRevision);
    super.dispose();
  }

  void _onAlumnosRevision() {
    if (mounted) _refrescarAlumnos();
  }

  Future<void> _refrescarAlumnos() async {
    final epoch = ++_listaEpoch;
    setState(() {
      _cargandoAlumnos = true;
      _errorAlumnos = null;
    });
    try {
      final lista =
          await context.read<SupabaseService>().obtenerAlumnos();
      if (!mounted || epoch != _listaEpoch) return;
      setState(() {
        _alumnos = lista;
        _cargandoAlumnos = false;
      });
    } catch (e) {
      if (!mounted || epoch != _listaEpoch) return;
      setState(() {
        _errorAlumnos = e.toString();
        _cargandoAlumnos = false;
      });
    }
  }

  /// Abre crear/editar y refresca la lista al volver.
  Future<void> _abrirFormularioAlumno([String? alumnoId]) async {
    final ruta = alumnoId == null
        ? '/directora/alumnos/crear'
        : '/directora/alumnos/editar/$alumnoId';
    await context.push(ruta);
    if (mounted) await _refrescarAlumnos();
  }

  Future<void> _cargarGrados() async {
    try {
      final supabaseService = context.read<SupabaseService>();
      final grados = await supabaseService.obtenerGrados();
      final user = context.read<AuthService>().currentUser;
      String filtro = 'Todos';
      var bloqueado = false;
      if (user != null &&
          user.esProfesor &&
          !user.esDirectora &&
          !user.esProfesorAdmin) {
        final gid = await PortageService().obtenerGradoIdProfesor(user.id);
        if (gid != null) {
          filtro = gid;
          bloqueado = true;
        }
      }
      if (!mounted) return;
      setState(() {
        _grados = grados;
        _filtroGrado = filtro;
        _gradoBloqueado = bloqueado;
        _cargandoGrados = false;
      });
    } catch (e) {
      // ignore: avoid_print
      print('Error cargando grados: $e');
      setState(() {
        _cargandoGrados = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final puedeEditar =
        context.watch<AuthService>().currentUser?.puedeEditarAlumnos ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alumnos'),
        actions: [
          if (puedeEditar)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _abrirFormularioAlumno(),
              tooltip: 'Nuevo alumno',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refrescarAlumnos,
            tooltip: 'Actualizar lista',
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
          SizedBox(
            height: 50,
            child: _cargandoGrados
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      if (!_gradoBloqueado)
                        _FiltroChip(
                          label: 'Todos',
                          isSelected: _filtroGrado == 'Todos',
                          onTap: () => setState(() => _filtroGrado = 'Todos'),
                        ),
                      ..._grados
                          .where((g) => !g.esEstimulacion)
                          .where((g) => !_gradoBloqueado || g.id == _filtroGrado)
                          .map((grado) => _FiltroChip(
                                label: grado.nombre,
                                isSelected: _filtroGrado == grado.id,
                                onTap: _gradoBloqueado
                                    ? () {}
                                    : () =>
                                        setState(() => _filtroGrado = grado.id),
                              )),
                    ],
                  ),
          ),
          const SizedBox(height: 8),
          Expanded(child: _buildLista(puedeEditar)),
        ],
      ),
    );
  }

  Widget _buildLista(bool puedeEditar) {
    final esIngles =
        context.watch<AuthService>().currentUser?.esMaestraIngles == true;
    final esSecretaria =
        context.watch<AuthService>().currentUser?.esSecretaria == true;

    if (_cargandoAlumnos && _alumnos.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorAlumnos != null && _alumnos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $_errorAlumnos'),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _refrescarAlumnos,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_alumnos.isEmpty) {
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
            if (esSecretaria) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Si deberían aparecer alumnos, ejecuta FIX_SECRETARIA_VER_ALUMNOS.sql en Supabase.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ),
            ],
            if (puedeEditar) ...[
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () => _abrirFormularioAlumno(),
                icon: const Icon(Icons.add),
                label: const Text('Agregar primer alumno'),
              ),
            ],
          ],
        ),
      );
    }

    var alumnos = List<Alumno>.from(_alumnos);

    if (_filtroGrado != 'Todos') {
      final ids = <String>{_filtroGrado};
      final seleccionado = _grados.where((g) => g.id == _filtroGrado);
      if (seleccionado.isNotEmpty && seleccionado.first.esMaternal) {
        ids.addAll(_grados.where((g) => g.esEstimulacion).map((g) => g.id));
      }
      alumnos = alumnos.where((a) => ids.contains(a.gradoId)).toList();
    }

    if (_busqueda.isNotEmpty) {
      alumnos = alumnos
          .where((a) => a.nombreCompleto.toLowerCase().contains(_busqueda))
          .toList();
    }

    if (alumnos.isEmpty) {
      return const Center(
        child: Text('No se encontraron alumnos'),
      );
    }

    return RefreshIndicator(
      onRefresh: _refrescarAlumnos,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: alumnos.length,
        itemBuilder: (context, index) {
          return AlumnoCard(
            alumno: alumnos[index],
            showAutorizados: true,
            onTap: esIngles
                ? () => context.push(
                      '/directora/calificaciones/alumno/${alumnos[index].id}',
                    )
                : puedeEditar
                    ? () => _abrirFormularioAlumno(alumnos[index].id)
                    : null,
          );
        },
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
