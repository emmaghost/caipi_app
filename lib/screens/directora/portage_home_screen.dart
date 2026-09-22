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
import '../../widgets/caipi_app_bar_leading.dart';

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
  String? _error;
  String? _gradoProfesor;
  String _filtro = '';

  bool get _puedeCrearSeguimiento {
    final u = context.read<AuthService>().currentUser;
    return u?.esDirectora == true ||
        u?.esProfesorAdmin == true ||
        u?.esProfesor == true;
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
        // Solo hitos por meses (sin listas de habilidades por áreas).
        _listas = listas.where((l) => l.mesesEdad != null).toList()
          ..sort((a, b) => (a.mesesEdad ?? 0).compareTo(b.mesesEdad ?? 0));
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


  Future<void> _crearEvaluacion() async {
    if (_gradoId == null) return;
    final listasActivas = _listas.where((l) => l.activa).toList();
    if (listasActivas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No hay hitos por meses en este grupo. '
            'Ve a «Hitos» para cargar el catálogo primero.',
          ),
        ),
      );
      return;
    }
    String listaId = listasActivas.first.id;
    final tituloCtrl = TextEditingController();
    void disposeTitulo() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        tituloCtrl.dispose();
      });
    }
    DateTime fecha = DateTime.now();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          title: const Text('Nuevo seguimiento'),
          content: SizedBox(
            width: MediaQuery.sizeOf(ctx).width,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Elige la lista a evaluar (ej. hitos 6 meses). '
                  'Esto no borra calificaciones anteriores: cada seguimiento '
                  'queda en el histórico del niño.',
                  style:
                      GoogleFonts.poppins(fontSize: 12, color: AppColors.gris),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: listaId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Lista a evaluar',
                    border: OutlineInputBorder(),
                  ),
                  items: listasActivas
                      .map(
                        (l) => DropdownMenuItem(
                          value: l.id,
                          child: Text(
                            '${l.nombre} (${l.tipoEtiqueta})',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                            softWrap: true,
                          ),
                        ),
                      )
                      .toList(),
                  selectedItemBuilder: (context) => listasActivas
                      .map(
                        (l) => Text(
                          '${l.nombre} (${l.tipoEtiqueta})',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          softWrap: false,
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
                    hintText: 'Ej. Seguimiento — marzo',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Fecha inicio: ${DateFormat('dd/MM/yyyy').format(fecha)}',
                    overflow: TextOverflow.ellipsis,
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
      disposeTitulo();
      return;
    }
    final user = context.read<AuthService>().currentUser!;
    if (!_puedeCrearSeguimiento) {
      disposeTitulo();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No tienes permiso para crear seguimientos'),
          backgroundColor: AppColors.rojo,
        ),
      );
      return;
    }
    final titulo =
        tituloCtrl.text.trim().isEmpty ? null : tituloCtrl.text.trim();
    disposeTitulo();
    try {
      await _portage.crearEvaluacion(
        listaId: listaId,
        gradoId: _gradoId!,
        titulo: titulo,
        fechaInicio: fecha,
        createdBy: user.id,
      );
      await _cargarGrado();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Seguimiento creado. Abre un niño para calificarlo. '
            'Cada seguimiento queda en el histórico (gráfica).',
          ),
          backgroundColor: AppColors.verde,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.rojo),
      );
    }
  }

  Future<void> _eliminarEvaluacion(PortageEvaluacion eval) async {
    if (!_esDirectora) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Borrar este seguimiento?'),
        content: Text(
          'Se eliminará «${eval.tituloDisplay}» '
          '(${DateFormat('dd/MM/yyyy').format(eval.fechaInicio)}).\n\n'
          'También se borrarán todas las calificaciones ya hechas en este '
          'seguimiento. Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.rojo),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await _portage.eliminarEvaluacion(eval.id);
      await _cargarGrado();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seguimiento eliminado'),
          backgroundColor: AppColors.verde,
        ),
      );
    } catch (e) {
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
        leading: const CaipiAppBarLeading(),
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
                          Text(
                            '3. Seguimientos del grupo',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Cada seguimiento es una foto en el tiempo '
                            '(hoy, en un mes, en 3…). Si algo que ya lograba '
                            'luego falla, lo verás en la gráfica del niño.',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppColors.gris,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              if (_puedeCrearSeguimiento)
                                FilledButton.icon(
                                  onPressed: _crearEvaluacion,
                                  icon: const Icon(Icons.add),
                                  label: const Text('Nuevo seguimiento'),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.morado,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (_evaluaciones.isEmpty)
                            Text(
                              'Sin seguimientos aún. Crea uno con la lista '
                              '(ej. hitos 6 meses) y luego califica niño por niño.',
                              style: GoogleFonts.poppins(
                                color: AppColors.gris,
                                fontSize: 12,
                              ),
                            ),
                          ..._evaluaciones.map(
                            (e) => Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                title: Text(e.tituloDisplay),
                                subtitle: Text(
                                  DateFormat('dd/MM/yyyy').format(e.fechaInicio),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (_esDirectora)
                                      IconButton(
                                        tooltip: 'Borrar seguimiento',
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          color: AppColors.rojo,
                                        ),
                                        onPressed: () =>
                                            _eliminarEvaluacion(e),
                                      ),
                                    const Icon(Icons.chevron_right),
                                  ],
                                ),
                                onTap: () => context.push(
                                  '/directora/portage/evaluacion/${e.id}',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: () async {
                              final gid = _gradoId;
                              await context.push(
                                gid == null
                                    ? '/directora/portage/listas'
                                    : '/directora/portage/listas?grado=$gid',
                              );
                              await _cargarGrado();
                            },
                            icon: const Icon(Icons.list_alt),
                            label: const Text(
                              'Ver hitos del grupo',
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: () => context.push('/directora/hitos'),
                            icon: const Icon(Icons.timeline, size: 18),
                            label: const Text(
                              'Hitos por meses (cargar catálogo)',
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
    );
  }
}
