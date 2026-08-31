import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../config/app_colors.dart';
import '../../models/alumno.dart';
import '../../models/portage.dart';
import '../../services/auth_service.dart';
import '../../services/portage_service.dart';
import '../../services/supabase_service.dart';
import '../../widgets/portage_grafica_sheet.dart';

/// Alumnos de un seguimiento (con búsqueda) — atajo desde administración.
class PortageEvaluacionScreen extends StatefulWidget {
  final String evaluacionId;

  const PortageEvaluacionScreen({super.key, required this.evaluacionId});

  @override
  State<PortageEvaluacionScreen> createState() =>
      _PortageEvaluacionScreenState();
}

class _PortageEvaluacionScreenState extends State<PortageEvaluacionScreen> {
  final _portage = PortageService();
  final _busquedaCtrl = TextEditingController();
  PortageEvaluacion? _eval;
  List<Alumno> _alumnos = [];
  List<PortageIndicador> _indicadores = [];
  bool _loading = true;
  String _filtro = '';

  List<Alumno> get _filtrados {
    final q = _filtro.trim().toLowerCase();
    if (q.isEmpty) return _alumnos;
    return _alumnos
        .where((a) => a.nombreCompleto.toLowerCase().contains(q))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _busquedaCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() => _loading = true);
    try {
      final eval = await _portage.obtenerEvaluacion(widget.evaluacionId);
      if (eval == null) throw Exception('Seguimiento no encontrado');
      final inds = await _portage.listarIndicadores(eval.listaId);
      var alumnos =
          await context.read<SupabaseService>().obtenerAlumnos();
      alumnos = alumnos
          .where((a) => a.activo && a.gradoId == eval.gradoId)
          .toList()
        ..sort((a, b) => a.apellidos.compareTo(b.apellidos));

      final user = context.read<AuthService>().currentUser;
      if (user != null &&
          user.esProfesor &&
          !user.esDirectora &&
          !user.esProfesorAdmin) {
        final gid = await _portage.obtenerGradoIdProfesor(user.id);
        if (gid != null) {
          alumnos = alumnos.where((a) => a.gradoId == gid).toList();
        }
      }

      if (!mounted) return;
      setState(() {
        _eval = eval;
        _indicadores = inds;
        _alumnos = alumnos;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.rojo),
      );
    }
  }

  Future<void> _toggleVisiblePadre(Alumno a) async {
    if (context.read<AuthService>().currentUser?.esDirectora != true) return;
    final nuevo = !a.portageVisiblePadre;
    try {
      await _portage.setPortageVisiblePadre(a.id, nuevo);
      setState(() {
        final i = _alumnos.indexWhere((x) => x.id == a.id);
        if (i >= 0) {
          _alumnos[i] = a.copyWith(portageVisiblePadre: nuevo);
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.rojo),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final eval = _eval;
    final lista = _filtrados;
    return Scaffold(
      backgroundColor: AppColors.grisClaro,
      appBar: AppBar(
        title: Text(
          eval == null
              ? 'Seguimiento'
              : (eval.titulo?.trim().isNotEmpty == true
                  ? eval.titulo!
                  : 'Seguimiento ${DateFormat('dd/MM/yyyy').format(eval.fechaInicio)}'),
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.morado,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: TextField(
                    controller: _busquedaCtrl,
                    onChanged: (v) => setState(() => _filtro = v),
                    decoration: InputDecoration(
                      hintText: 'Buscar niño en este grupo…',
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
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: lista.isEmpty
                      ? Center(
                          child: Text(
                            _alumnos.isEmpty
                                ? 'Sin alumnos en el grupo'
                                : 'Ninguna coincidencia',
                            style: GoogleFonts.poppins(color: AppColors.gris),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: lista.length,
                          itemBuilder: (context, index) {
                            final a = lista[index];
                            final esDir = context
                                    .read<AuthService>()
                                    .currentUser
                                    ?.esDirectora ==
                                true;
                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: ListTile(
                                title: Text(a.nombreCompleto),
                                subtitle: esDir
                                    ? Text(
                                        a.portageVisiblePadre
                                            ? 'Padre puede ver (última eval.)'
                                            : 'Padre no ve indicadores',
                                        style: TextStyle(
                                          color: a.portageVisiblePadre
                                              ? AppColors.verde
                                              : AppColors.gris,
                                          fontSize: 12,
                                        ),
                                      )
                                    : Text(
                                        '${_indicadores.length} indicadores',
                                      ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (esDir)
                                      IconButton(
                                        tooltip: 'Visible al padre',
                                        icon: Icon(
                                          a.portageVisiblePadre
                                              ? Icons.visibility
                                              : Icons.visibility_off,
                                          color: a.portageVisiblePadre
                                              ? AppColors.verde
                                              : AppColors.gris,
                                        ),
                                        onPressed: () =>
                                            _toggleVisiblePadre(a),
                                      ),
                                    IconButton(
                                      tooltip: 'Gráfica / PDF',
                                      icon: const Icon(Icons.show_chart),
                                      onPressed: () async {
                                        if (eval == null) return;
                                        await mostrarPortageGraficaPdf(
                                          context: context,
                                          alumno: a,
                                          gradoId: eval.gradoId,
                                          evaluacionPdf: eval,
                                          indicadoresPdf: _indicadores,
                                        );
                                      },
                                    ),
                                    const Icon(Icons.edit_note),
                                  ],
                                ),
                                onTap: () async {
                                  await context.push(
                                    '/directora/portage/evaluacion/${widget.evaluacionId}/alumno/${a.id}',
                                  );
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

/// Calificar indicadores de un niño en una evaluación.
class PortageCalificarAlumnoScreen extends StatefulWidget {
  final String evaluacionId;
  final String alumnoId;

  const PortageCalificarAlumnoScreen({
    super.key,
    required this.evaluacionId,
    required this.alumnoId,
  });

  @override
  State<PortageCalificarAlumnoScreen> createState() =>
      _PortageCalificarAlumnoScreenState();
}

class _PortageCalificarAlumnoScreenState
    extends State<PortageCalificarAlumnoScreen> {
  final _portage = PortageService();
  PortageEvaluacion? _eval;
  Alumno? _alumno;
  List<PortageIndicador> _indicadores = [];
  final Map<String, String?> _estados = {};
  final Map<String, TextEditingController> _obs = {};
  bool _loading = true;
  bool _saving = false;
  bool _soloLectura = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    for (final c in _obs.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _cargar() async {
    try {
      final eval = await _portage.obtenerEvaluacion(widget.evaluacionId);
      final alumno =
          await context.read<SupabaseService>().obtenerAlumnoPorId(widget.alumnoId);
      if (eval == null || alumno == null) {
        throw Exception('Datos no encontrados');
      }
      final inds = await _portage.listarIndicadores(eval.listaId);
      final resultados =
          await _portage.obtenerResultados(eval.id, alumno.id);
      final porInd = {for (final r in resultados) r.indicadorId: r};

      for (final i in inds) {
        _estados[i.id] = porInd[i.id]?.estado;
        _obs[i.id] = TextEditingController(
          text: porInd[i.id]?.observaciones ?? '',
        );
      }

      final user = context.read<AuthService>().currentUser;
      // Padre nunca llega aquí por ruta staff; staff siempre puede editar
      // excepto si en el futuro abrimos vista padre en esta misma screen.
      _soloLectura = user?.esPadre == true;

      if (!mounted) return;
      setState(() {
        _eval = eval;
        _alumno = alumno;
        _indicadores = inds;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.rojo),
      );
    }
  }

  Future<void> _guardar() async {
    if (_soloLectura || _eval == null) return;
    final user = context.read<AuthService>().currentUser;
    if (user == null) return;
    setState(() => _saving = true);
    try {
      for (final i in _indicadores) {
        await _portage.upsertResultado(
          evaluacionId: _eval!.id,
          alumnoId: widget.alumnoId,
          indicadorId: i.id,
          estado: _estados[i.id],
          observaciones: _obs[i.id]?.text.trim(),
          actualizadoPor: user.id,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Evaluación guardada'),
          backgroundColor: AppColors.verde,
        ),
      );
      context.pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.rojo),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grisClaro,
      appBar: AppBar(
        title: Text(
          _alumno?.nombreCompleto ?? 'Calificar',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.morado,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final ind in _indicadores) ...[
                  Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ind.nombre,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            children: [
                              ChoiceChip(
                                label: const Text('Logrado'),
                                selected: _estados[ind.id] == PortageEstado.logrado,
                                selectedColor: AppColors.verde.withOpacity(0.3),
                                onSelected: _soloLectura
                                    ? null
                                    : (_) => setState(() {
                                          _estados[ind.id] =
                                              PortageEstado.logrado;
                                        }),
                              ),
                              ChoiceChip(
                                label: const Text('En proceso'),
                                selected:
                                    _estados[ind.id] == PortageEstado.enProceso,
                                selectedColor: Colors.orange.withOpacity(0.3),
                                onSelected: _soloLectura
                                    ? null
                                    : (_) => setState(() {
                                          _estados[ind.id] =
                                              PortageEstado.enProceso;
                                        }),
                              ),
                              ChoiceChip(
                                label: const Text('Sin calificar'),
                                selected: _estados[ind.id] == null,
                                onSelected: _soloLectura
                                    ? null
                                    : (_) => setState(() {
                                          _estados[ind.id] = null;
                                        }),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _obs[ind.id],
                            enabled: !_soloLectura,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              labelText: 'Observaciones / notas',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                if (!_soloLectura)
                  FilledButton(
                    onPressed: _saving ? null : _guardar,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.morado,
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: _saving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Guardar calificación'),
                  ),
                const SizedBox(height: 24),
              ],
            ),
    );
  }
}

/// Vista padre: última evaluación de indicadores (ligas Drive van aparte).
class PortagePadreVista extends StatelessWidget {
  final Alumno alumno;

  const PortagePadreVista({super.key, required this.alumno});

  @override
  Widget build(BuildContext context) {
    if (!alumno.portageVisiblePadre) {
      return const SizedBox.shrink();
    }
    return FutureBuilder(
      future: _cargar(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const SizedBox.shrink();
        }
        final data = snap.data!;
        if (data.eval == null) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Indicadores de desarrollo (última evaluación)',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            ...data.indicadores.map((ind) {
              final r = data.resultados[ind.id];
              return Card(
                child: ListTile(
                  title: Text(ind.nombre, style: const TextStyle(fontSize: 13)),
                  subtitle: Text(
                    [
                      PortageEstado.etiqueta(r?.estado),
                      if (r?.observaciones?.trim().isNotEmpty == true)
                        r!.observaciones!.trim(),
                    ].join(' · '),
                  ),
                  trailing: Text(
                    PortageEstado.simbolo(r?.estado),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: PortageEstado.isLogrado(r?.estado)
                          ? AppColors.verde
                          : Colors.orange,
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Future<_PadrePortageData> _cargar() async {
    final svc = PortageService();
    final eval = await svc.ultimaEvaluacionParaAlumno(alumno.id);
    if (eval == null) {
      return _PadrePortageData();
    }
    final inds = await svc.listarIndicadores(eval.listaId);
    final res = await svc.obtenerResultados(eval.id, alumno.id);
    return _PadrePortageData(
      eval: eval,
      indicadores: inds,
      resultados: {for (final r in res) r.indicadorId: r},
    );
  }
}

class _PadrePortageData {
  final PortageEvaluacion? eval;
  final List<PortageIndicador> indicadores;
  final Map<String, PortageResultado> resultados;

  _PadrePortageData({
    this.eval,
    this.indicadores = const [],
    this.resultados = const {},
  });
}
