import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../config/app_colors.dart';
import '../../models/alumno.dart';
import '../../models/grado.dart';
import '../../models/portage.dart';
import '../../services/auth_service.dart';
import '../../services/portage_service.dart';
import '../../services/supabase_service.dart';
import '../../widgets/app_drawer.dart';

/// Flujo: 1) grupo → 2) buscar/elegir niño → ficha del niño.
class PortageHomeScreen extends StatefulWidget {
  const PortageHomeScreen({super.key});

  @override
  State<PortageHomeScreen> createState() => _PortageHomeScreenState();
}

class _PortageHomeScreenState extends State<PortageHomeScreen> {
  final _portage = PortageService();
  final _busquedaCtrl = TextEditingController();
  List<Grado> _grados = [];
  String? _gradoId;
  List<PortageLista> _listas = [];
  List<PortageEvaluacion> _evaluaciones = [];
  List<Alumno> _alumnos = [];
  bool _loading = true;
  bool _adminAbierto = false;
  String? _error;
  String? _gradoProfesor;
  String _filtro = '';

  bool get _puedeEditarListas {
    final u = context.read<AuthService>().currentUser;
    return u?.esDirectora == true;
  }

  bool get _esDirectora =>
      context.read<AuthService>().currentUser?.esDirectora == true;

  List<Alumno> get _alumnosFiltrados {
    final q = _filtro.trim().toLowerCase();
    if (q.isEmpty) return _alumnos;
    return _alumnos.where((a) {
      final n = a.nombreCompleto.toLowerCase();
      return n.contains(q);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _iniciar();
  }

  @override
  void dispose() {
    _busquedaCtrl.dispose();
    super.dispose();
  }

  Future<void> _iniciar() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final auth = context.read<AuthService>();
      final user = auth.currentUser;
      final grados = await context.read<SupabaseService>().obtenerGrados();

      String? gradoFijo;
      if (user != null &&
          user.esProfesor &&
          !user.esProfesorAdmin &&
          !user.esDirectora) {
        gradoFijo = await _portage.obtenerGradoIdProfesor(user.id);
        _gradoProfesor = gradoFijo;
      }

      final filtrados = gradoFijo == null
          ? grados.where((g) => g.activo).toList()
          : grados.where((g) => g.id == gradoFijo).toList();

      if (!mounted) return;
      setState(() {
        _grados = filtrados;
        _gradoId = filtrados.isNotEmpty
            ? (gradoFijo ?? filtrados.first.id)
            : null;
      });
      if (_gradoId != null) await _cargarGrado();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _cargarGrado() async {
    final gid = _gradoId;
    if (gid == null) return;
    setState(() => _loading = true);
    try {
      final listas = await _portage.listarListasPorGrado(gid);
      final evals = await _portage.listarEvaluacionesPorGrado(gid);
      var alumnos = await context.read<SupabaseService>().obtenerAlumnos();
      alumnos = alumnos
          .where((a) => a.activo && a.gradoId == gid)
          .toList()
        ..sort((a, b) {
          final c = a.apellidos.compareTo(b.apellidos);
          return c != 0 ? c : a.nombre.compareTo(b.nombre);
        });

      if (!mounted) return;
      setState(() {
        _listas = listas;
        _evaluaciones = evals;
        _alumnos = alumnos;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.rojo),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _crearLista() async {
    if (!_puedeEditarListas || _gradoId == null) return;
    final nombreCtrl = TextEditingController(text: 'Indicadores de desarrollo');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nueva lista'),
        content: TextField(
          controller: nombreCtrl,
          decoration: const InputDecoration(labelText: 'Nombre de la lista'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Crear'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) {
      nombreCtrl.dispose();
      return;
    }
    final user = context.read<AuthService>().currentUser!;
    try {
      final lista = await _portage.crearLista(
        gradoId: _gradoId!,
        nombre: nombreCtrl.text.trim().isEmpty
            ? 'Indicadores de desarrollo'
            : nombreCtrl.text.trim(),
        createdBy: user.id,
      );
      nombreCtrl.dispose();
      if (!mounted) return;
      await context.push('/directora/portage/lista/${lista.id}');
      await _cargarGrado();
    } catch (e) {
      nombreCtrl.dispose();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.rojo),
      );
    }
  }

  Future<void> _crearEvaluacion() async {
    if (_gradoId == null) return;
    final listasActivas = _listas.where((l) => l.activa).toList();
    if (listasActivas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Primero crea una lista de indicadores para este grado'),
        ),
      );
      return;
    }
    String listaId = listasActivas.first.id;
    final tituloCtrl = TextEditingController();
    DateTime fecha = DateTime.now();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Nuevo seguimiento'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: listaId,
                decoration: const InputDecoration(
                  labelText: 'Lista de indicadores',
                ),
                items: listasActivas
                    .map(
                      (l) => DropdownMenuItem(
                        value: l.id,
                        child: Text(l.nombre, overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) setLocal(() => listaId = v);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: tituloCtrl,
                decoration: const InputDecoration(
                  labelText: 'Título (opcional)',
                  hintText: 'Ej. Signos de alerta — marzo',
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Fecha inicio: ${DateFormat('dd/MM/yyyy').format(fecha)}',
                ),
                trailing: const Icon(Icons.calendar_month),
                onTap: () async {
                  final p = await showDatePicker(
                    context: ctx,
                    initialDate: fecha,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (p != null) setLocal(() => fecha = p);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Crear'),
            ),
          ],
        ),
      ),
    );
    if (ok != true || !mounted) {
      tituloCtrl.dispose();
      return;
    }
    final user = context.read<AuthService>().currentUser!;
    if (!user.esDirectora) {
      tituloCtrl.dispose();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Solo la directora crea nuevos seguimientos'),
          backgroundColor: AppColors.rojo,
        ),
      );
      return;
    }
    try {
      await _portage.crearEvaluacion(
        listaId: listaId,
        gradoId: _gradoId!,
        titulo: tituloCtrl.text.trim().isEmpty ? null : tituloCtrl.text.trim(),
        fechaInicio: fecha,
        createdBy: user.id,
      );
      tituloCtrl.dispose();
      await _cargarGrado();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seguimiento creado. Elige un niño para calificar.'),
          backgroundColor: AppColors.verde,
        ),
      );
    } catch (e) {
      tituloCtrl.dispose();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.rojo),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtrados = _alumnosFiltrados;
    return Scaffold(
      backgroundColor: AppColors.grisClaro,
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Text(
          'Indicadores de desarrollo',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.morado,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => context.go('/directora'),
          ),
        ],
      ),
      body: _loading && _grados.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _grados.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          _gradoProfesor == null
                              ? 'No hay grados'
                              : 'No tienes grupo asignado. Pide a la directora que te asigne un grado.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(),
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _cargarGrado,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          Text(
                            '1. Elige el grupo',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (_grados.length > 1)
                            DropdownButtonFormField<String>(
                              value: _gradoId,
                              decoration: InputDecoration(
                                labelText: 'Grupo / grado',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              items: _grados
                                  .map(
                                    (g) => DropdownMenuItem(
                                      value: g.id,
                                      child: Text(g.nombre),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) async {
                                setState(() {
                                  _gradoId = v;
                                  _filtro = '';
                                  _busquedaCtrl.clear();
                                });
                                await _cargarGrado();
                              },
                            )
                          else
                            Text(
                              _grados.first.nombre,
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          const SizedBox(height: 20),
                          Text(
                            '2. Elige al niño',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_alumnos.length} niño${_alumnos.length == 1 ? '' : 's'} en este grupo'
                            '${_filtro.isEmpty ? '' : ' · ${filtrados.length} coincidencia(s)'}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppColors.gris,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _busquedaCtrl,
                            onChanged: (v) => setState(() => _filtro = v),
                            decoration: InputDecoration(
                              hintText: 'Buscar por nombre…',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: _filtro.isEmpty
                                  ? null
                                  : IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        _busquedaCtrl.clear();
                                        setState(() => _filtro = '');
                                      },
                                    ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (_loading)
                            const Padding(
                              padding: EdgeInsets.all(24),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          else if (_alumnos.isEmpty)
                            Text(
                              'No hay alumnos activos en este grupo.',
                              style: GoogleFonts.poppins(color: AppColors.gris),
                            )
                          else if (filtrados.isEmpty)
                            Text(
                              'Ningún niño coincide con la búsqueda.',
                              style: GoogleFonts.poppins(color: AppColors.gris),
                            )
                          else
                            ...filtrados.map(
                              (a) => Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor:
                                        AppColors.morado.withOpacity(0.15),
                                    child: Text(
                                      a.nombre.isNotEmpty
                                          ? a.nombre[0].toUpperCase()
                                          : '?',
                                      style: const TextStyle(
                                        color: AppColors.morado,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Text(a.nombreCompleto),
                                  subtitle: Text(
                                    a.portageVisiblePadre
                                        ? 'Padre puede ver indicadores'
                                        : 'Toca para calificar / ver seguimiento',
                                    style: GoogleFonts.poppins(fontSize: 11),
                                  ),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () async {
                                    await context.push(
                                      '/directora/portage/alumno/${a.id}',
                                    );
                                    await _cargarGrado();
                                  },
                                ),
                              ),
                            ),
                          const SizedBox(height: 20),
                          Card(
                            child: ExpansionTile(
                              initiallyExpanded: _adminAbierto,
                              onExpansionChanged: (v) =>
                                  setState(() => _adminAbierto = v),
                              title: Text(
                                'Administrar listas y seguimientos',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Text(
                                _esDirectora
                                    ? 'Listas de indicadores y altas de mes'
                                    : 'Ver listas (solo lectura) y seguimientos del grupo',
                                style: GoogleFonts.poppins(fontSize: 11),
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    0,
                                    16,
                                    12,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              'Indicadores de desarrollo',
                                              style: GoogleFonts.poppins(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          if (_puedeEditarListas)
                                            TextButton.icon(
                                              onPressed: _crearLista,
                                              icon: const Icon(Icons.add),
                                              label: const Text('Lista'),
                                            ),
                                        ],
                                      ),
                                      if (_listas.isEmpty)
                                        Text(
                                          'Sin listas aún.',
                                          style: GoogleFonts.poppins(
                                            color: AppColors.gris,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ..._listas.map(
                                        (l) => ListTile(
                                          dense: true,
                                          contentPadding: EdgeInsets.zero,
                                          title: Text(l.nombre),
                                          subtitle: Text(
                                            l.activa ? 'Activa' : 'Inactiva',
                                          ),
                                          trailing:
                                              const Icon(Icons.chevron_right),
                                          onTap: () async {
                                            await context.push(
                                              '/directora/portage/lista/${l.id}',
                                            );
                                            await _cargarGrado();
                                          },
                                        ),
                                      ),
                                      const Divider(),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              'Signos de alerta…',
                                              style: GoogleFonts.poppins(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          if (_esDirectora)
                                            TextButton.icon(
                                              onPressed: _crearEvaluacion,
                                              icon: const Icon(Icons.add),
                                              label: const Text('Nueva'),
                                            ),
                                        ],
                                      ),
                                      if (_evaluaciones.isEmpty)
                                        Text(
                                          'Sin seguimientos. La directora crea uno con «Nueva».',
                                          style: GoogleFonts.poppins(
                                            color: AppColors.gris,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ..._evaluaciones.map(
                                        (e) => ListTile(
                                          dense: true,
                                          contentPadding: EdgeInsets.zero,
                                          title: Text(
                                            e.titulo?.trim().isNotEmpty == true
                                                ? e.titulo!
                                                : 'Seguimiento ${DateFormat('dd/MM/yyyy').format(e.fechaInicio)}',
                                          ),
                                          subtitle: Text(
                                            DateFormat('dd/MM/yyyy')
                                                .format(e.fechaInicio),
                                          ),
                                          trailing: const Icon(
                                            Icons.chevron_right,
                                          ),
                                          onTap: () => context.push(
                                            '/directora/portage/evaluacion/${e.id}',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
    );
  }
}
