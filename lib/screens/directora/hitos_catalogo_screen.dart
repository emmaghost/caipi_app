import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../config/app_colors.dart';
import '../../models/grado.dart';
import '../../models/portage.dart';
import '../../services/auth_service.dart';
import '../../services/portage_service.dart';
import '../../services/supabase_service.dart';
import '../../utils/hitos_plantilla.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/caipi_app_bar_leading.dart';

/// Catálogo de hitos por meses: cargar al grado (no asigna a niños).
class HitosCatalogoScreen extends StatefulWidget {
  const HitosCatalogoScreen({super.key});

  @override
  State<HitosCatalogoScreen> createState() => _HitosCatalogoScreenState();
}

class _HitosCatalogoScreenState extends State<HitosCatalogoScreen> {
  final _portage = PortageService();
  List<Grado> _grados = [];
  String? _gradoId;
  List<PortageLista> _listas = [];
  bool _loading = true;
  bool _cargandoTramo = false;
  String? _error;

  bool get _puedeCargar {
    final u = context.read<AuthService>().currentUser;
    return u?.esDirectora == true ||
        u?.esProfesorAdmin == true ||
        u?.esProfesor == true;
  }

  Grado? get _gradoSel {
    final id = _gradoId;
    if (id == null) return null;
    for (final g in _grados) {
      if (g.id == id) return g;
    }
    return null;
  }

  Set<int> get _mesesSugeridos {
    final g = _gradoSel;
    if (g == null) return {};
    return HitosPlantilla.mesesSugeridosParaGrado(
      nombreGrado: g.nombre,
      edadMinima: g.edadMinima,
      edadMaxima: g.edadMaxima,
    ).toSet();
  }

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final grados = await context.read<SupabaseService>().obtenerGrados();
      // Todos los grupos activos: maternal, estimulación y kínder.
      final ordenados = grados.where((g) => g.activo).toList()
        ..sort((a, b) {
          int peso(Grado g) {
            if (g.esMaternalOBebes) return 0;
            if (g.esKinder) return 1;
            return 2;
          }

          final c = peso(a).compareTo(peso(b));
          return c != 0 ? c : a.nombre.compareTo(b.nombre);
        });
      if (!mounted) return;
      setState(() {
        _grados = ordenados;
        _gradoId = ordenados.isNotEmpty ? ordenados.first.id : null;
      });
      if (_gradoId != null) await _refrescarListas();
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refrescarListas() async {
    final gid = _gradoId;
    if (gid == null) return;
    final listas = await _portage.listarListasPorGrado(gid);
    if (!mounted) return;
    setState(() {
      _listas = listas.where((l) => l.mesesEdad != null).toList()
        ..sort((a, b) => (a.mesesEdad ?? 0).compareTo(b.mesesEdad ?? 0));
    });
  }

  Set<int> get _mesesCargados =>
      _listas.map((l) => l.mesesEdad).whereType<int>().toSet();

  String _etiquetaGrupo(Grado g) {
    if (g.esMaternalOBebes) return '${g.nombre} · maternal';
    if (g.esKinder) return '${g.nombre} · kínder';
    return g.nombre;
  }

  Future<void> _cargarTramo(int meses) async {
    final gid = _gradoId;
    final user = context.read<AuthService>().currentUser;
    if (gid == null || user == null || _cargandoTramo) return;

    final tramo = HitosPlantilla.porMeses(meses);
    if (tramo == null) return;

    setState(() => _cargandoTramo = true);
    try {
      final areas = tramo.areas
          .map((a) => (area: a.nombre, items: a.items))
          .toList();
      final lista = await _portage.cargarHitosTramo(
        gradoId: gid,
        meses: meses,
        createdBy: user.id,
        areas: areas,
      );
      await _refrescarListas();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            lista == null
                ? 'No se pudo cargar'
                : (_mesesCargados.contains(meses)
                    ? 'Listo: ${lista.nombre} (${tramo.areas.fold<int>(0, (s, a) => s + a.items.length)} ítems)'
                    : 'Cargado: ${lista.nombre}'),
          ),
          backgroundColor: Colors.green.shade700,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error al cargar. ¿Ejecutaste HITOS_DESARROLLO_CARGAR.sql?\n$e',
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 6),
        ),
      );
    } finally {
      if (mounted) setState(() => _cargandoTramo = false);
    }
  }

  Future<void> _cargarSugeridos() async {
    final pendientes = _mesesSugeridos
        .where((m) => !_mesesCargados.contains(m))
        .toList()
      ..sort();
    if (pendientes.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este grupo ya tiene todos los tramos sugeridos.'),
        ),
      );
      return;
    }
    for (final m in pendientes) {
      await _cargarTramo(m);
      if (!mounted) return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sugeridos = _mesesSugeridos;
    final pendientes = sugeridos.where((m) => !_mesesCargados.contains(m)).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FA),
      drawer: const AppDrawer(),
      appBar: AppBar(
        leading: const CaipiAppBarLeading(),
        backgroundColor: AppColors.morado,
        foregroundColor: Colors.white,
        title: Text(
          'Hitos de desarrollo',
          style: GoogleFonts.fredoka(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.child_care),
            tooltip: 'Ir a niños / asignar',
            onPressed: () => context.go('/directora/portage'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Text(
                          '1) Elige el grupo (maternal, estimulación o kínder).\n'
                          '2) Carga los tramos por meses (los sugeridos del grupo '
                          'aparecen marcados).\n'
                          '3) En cada niño, asigna qué hitos le corresponden.\n\n'
                          'Cargar no asigna a nadie: solo deja el catálogo listo.',
                          style: GoogleFonts.poppins(fontSize: 13, height: 1.35),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_grados.isEmpty)
                      const Text('No hay grados activos.')
                    else
                      DropdownButtonFormField<String>(
                        value: _gradoId,
                        decoration: InputDecoration(
                          labelText: 'Grupo',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: _grados
                            .map(
                              (g) => DropdownMenuItem(
                                value: g.id,
                                child: Text(_etiquetaGrupo(g)),
                              ),
                            )
                            .toList(),
                        onChanged: (v) async {
                          setState(() => _gradoId = v);
                          await _refrescarListas();
                        },
                      ),
                    if (_puedeCargar && sugeridos.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: _cargandoTramo || pendientes == 0
                            ? null
                            : _cargarSugeridos,
                        icon: const Icon(Icons.library_add_check),
                        label: Text(
                          pendientes == 0
                              ? 'Tramos sugeridos ya cargados'
                              : 'Cargar $pendientes tramos sugeridos del grupo',
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.morado,
                          minimumSize: const Size.fromHeight(46),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Text(
                      'Tramos por edad',
                      style: GoogleFonts.fredoka(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Los marcados como «sugerido» encajan con la edad típica '
                      'del grupo seleccionado.',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.gris,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...HitosPlantilla.tramos.map((t) {
                      final cargado = _mesesCargados.contains(t.meses);
                      final sugerido = sugeridos.contains(t.meses);
                      final nItems = t.areas.fold<int>(
                        0,
                        (s, a) => s + a.items.length,
                      );
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        color: sugerido && !cargado
                            ? AppColors.rosaClaro.withValues(alpha: 0.35)
                            : null,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: cargado
                                ? Colors.green.shade100
                                : AppColors.rosaClaro,
                            child: Text(
                              '${t.meses}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: cargado
                                    ? Colors.green.shade800
                                    : AppColors.morado,
                              ),
                            ),
                          ),
                          title: Text(
                            t.titulo,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            [
                              if (sugerido) 'Sugerido',
                              if (cargado) 'Ya cargado',
                              if (!cargado) 'Pendiente',
                              '$nItems ítems',
                            ].join(' · '),
                            style: GoogleFonts.poppins(fontSize: 12),
                          ),
                          trailing: _puedeCargar
                              ? (cargado
                                  ? Icon(Icons.check_circle,
                                      color: Colors.green.shade700)
                                  : FilledButton(
                                      onPressed: _cargandoTramo
                                          ? null
                                          : () => _cargarTramo(t.meses),
                                      child: const Text('Cargar'),
                                    ))
                              : null,
                        ),
                      );
                    }),
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      onPressed: () => context.go('/directora/portage'),
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Ir a niños para asignar hitos'),
                    ),
                  ],
                ),
    );
  }
}
