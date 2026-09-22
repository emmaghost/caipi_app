import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../config/app_colors.dart';
import '../../models/alumno.dart';
import '../../models/portage.dart';
import '../../services/auth_service.dart';
import '../../services/portage_pdf.dart';
import '../../services/portage_service.dart';
import '../../services/supabase_service.dart';
import '../../utils/portage_stats.dart';
import '../../widgets/portage_line_chart.dart';
import '../../widgets/caipi_app_bar_leading.dart';

/// Ficha de un niño:
/// - Solo el **último** seguimiento para calificar / PDF.
/// - La gráfica usa seguimientos calificados (cada uno = un punto).
class PortageAlumnoHubScreen extends StatefulWidget {
  final String alumnoId;

  const PortageAlumnoHubScreen({super.key, required this.alumnoId});

  @override
  State<PortageAlumnoHubScreen> createState() => _PortageAlumnoHubScreenState();
}

class _PortageAlumnoHubScreenState extends State<PortageAlumnoHubScreen> {
  final _portage = PortageService();
  Alumno? _alumno;
  List<PortageEvaluacion> _evaluaciones = [];
  Map<String, List<PortageResultado>> _resultadosPorEval = {};
  Map<String, int> _totalesPorEval = {};
  PortageEvaluacion? _ultima;
  PortageConteoResumen? _resumenUltima;
  List<PortageIndicador> _indicadoresUltima = [];
  List<PortagePuntoSerie> _serie = [];
  /// null = todos; 3/6 = últimos N seguimientos calificados.
  int? _maxSeguimientos;
  bool _loading = true;
  bool _incluirGraficaPdf = true;

  bool get _esDirectora =>
      context.read<AuthService>().currentUser?.esDirectora == true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _loading = true);
    try {
      final alumnos = await context.read<SupabaseService>().obtenerAlumnos();
      Alumno? alumno;
      for (final a in alumnos) {
        if (a.id == widget.alumnoId) {
          alumno = a;
          break;
        }
      }
      if (alumno == null || alumno.gradoId == null) {
        throw Exception('Alumno no encontrado o sin grupo');
      }

      // Ya vienen ordenadas por fecha_inicio desc
      final evals =
          await _portage.listarEvaluacionesPorGrado(alumno.gradoId!);
      final ultima = evals.isEmpty ? null : evals.first;

      PortageConteoResumen? resumenUltima;
      var indicadoresUltima = <PortageIndicador>[];
      if (ultima != null) {
        indicadoresUltima = await _portage.listarIndicadores(ultima.listaId);
        final res =
            await _portage.obtenerResultados(ultima.id, alumno.id);
        var logrados = 0;
        var ep = 0;
        for (final r in res) {
          if (r.esLogrado) logrados++;
          if (r.esEnProceso) ep++;
        }
        resumenUltima = PortageConteoResumen(
          total: indicadoresUltima.length,
          logrados: logrados,
          enProceso: ep,
          calificados: logrados + ep,
        );
      }

      final resultadosPorEval = <String, List<PortageResultado>>{};
      final totales = <String, int>{};
      for (final e in evals) {
        final inds = await _portage.listarIndicadores(e.listaId);
        totales[e.id] = inds.length;
        resultadosPorEval[e.id] =
            await _portage.obtenerResultados(e.id, alumno.id);
      }

      final serie = PortageStats.seriePorSeguimientos(
        evaluaciones: evals,
        resultadosPorEvaluacion: resultadosPorEval,
        totalIndicadoresPorEvaluacion: totales,
        maxSeguimientos: _maxSeguimientos,
      );

      if (!mounted) return;
      setState(() {
        _alumno = alumno;
        _evaluaciones = evals;
        _resultadosPorEval = resultadosPorEval;
        _totalesPorEval = totales;
        _ultima = ultima;
        _resumenUltima = resumenUltima;
        _indicadoresUltima = indicadoresUltima;
        _serie = serie;
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

  void _cambiarVentana(int? maxSeg) {
    if (_maxSeguimientos == maxSeg) return;
    final serie = PortageStats.seriePorSeguimientos(
      evaluaciones: _evaluaciones,
      resultadosPorEvaluacion: _resultadosPorEval,
      totalIndicadoresPorEvaluacion: _totalesPorEval,
      maxSeguimientos: maxSeg,
    );
    setState(() {
      _maxSeguimientos = maxSeg;
      _serie = serie;
    });
  }

  Future<void> _toggleVisiblePadre() async {
    final a = _alumno;
    if (a == null || !_esDirectora) return;
    final nuevo = !a.portageVisiblePadre;
    try {
      await _portage.setPortageVisiblePadre(a.id, nuevo);
      setState(() => _alumno = a.copyWith(portageVisiblePadre: nuevo));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.rojo),
      );
    }
  }

  Future<void> _asignarHitos() async {
    final alumno = _alumno;
    if (alumno == null || alumno.gradoId == null) return;
    if (!_esDirectora) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Solo la directora asigna hitos / listas y la visibilidad a padres.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    final user = context.read<AuthService>().currentUser;
    final disponibles =
        await _portage.listarListasPorGrado(alumno.gradoId!);
    final hitos = disponibles.where((l) => l.mesesEdad != null).toList()
      ..sort((a, b) => (a.mesesEdad ?? 0).compareTo(b.mesesEdad ?? 0));
    if (hitos.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No hay hitos cargados en este grupo. Ve a «Hitos (cargar catálogo)».',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    final actuales =
        (await _portage.listarListaIdsAsignadasAlumno(alumno.id)).toSet();
    if (!mounted) return;

    final seleccion = Set<String>.from(actuales);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Asignar hitos'),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: hitos
                    .map(
                      (l) => CheckboxListTile(
                        value: seleccion.contains(l.id),
                        title: Text(l.nombre),
                        subtitle: Text('${l.mesesEdad} meses'),
                        onChanged: (v) => setLocal(() {
                          if (v == true) {
                            seleccion.add(l.id);
                          } else {
                            seleccion.remove(l.id);
                          }
                        }),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    try {
      await _portage.sincronizarAsignacionesAlumno(
        alumnoId: alumno.id,
        listaIds: seleccion,
        assignedBy: user?.id,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${seleccion.length} lista(s) asignada(s)'),
          backgroundColor: Colors.green.shade700,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error al asignar. ¿Ejecutaste HITOS_DESARROLLO_CARGAR.sql?\n$e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _calificarUltima() async {
    final alumno = _alumno;
    final ultima = _ultima;
    if (alumno == null || ultima == null) return;
    await context.push(
      '/directora/portage/evaluacion/${ultima.id}/alumno/${alumno.id}',
    );
    await _cargar();
  }

  Future<void> _compartirPdf([PortageEvaluacion? eval]) async {
    final alumno = _alumno;
    final target = eval ?? _ultima;
    if (alumno == null || target == null) return;

    final inds = target.id == _ultima?.id
        ? _indicadoresUltima
        : await _portage.listarIndicadores(target.listaId);
    final res = _resultadosPorEval[target.id] ??
        await _portage.obtenerResultados(target.id, alumno.id);

    if (!mounted) return;
    await PortagePdf.compartir(
      alumno: alumno,
      evaluacion: target,
      indicadores: inds,
      resultados: res,
      serieEvolucion: _incluirGraficaPdf ? _serie : null,
      context: context,
    );
  }

  bool _evalTieneCalif(PortageEvaluacion e) {
    final res = _resultadosPorEval[e.id] ?? const [];
    return res.any((r) => !r.sinCalificar);
  }

  String _subtituloEval(PortageEvaluacion e) {
    final res = _resultadosPorEval[e.id] ?? const [];
    final total = _totalesPorEval[e.id] ?? 0;
    var logrados = 0;
    var ep = 0;
    for (final r in res) {
      if (r.esLogrado) logrados++;
      if (r.esEnProceso) ep++;
    }
    final cal = logrados + ep;
    final fecha = DateFormat('dd/MM/yyyy').format(e.fechaInicio);
    if (cal == 0) return '$fecha · sin calificar';
    return '$fecha · $cal/$total · $logrados L · $ep EP';
  }

  Widget _tablaComparativa() {
    if (_serie.length < 2) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Comparativo de evolución',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Logrados por seguimiento (más reciente arriba).',
              style: GoogleFonts.poppins(fontSize: 12, color: AppColors.gris),
            ),
            const SizedBox(height: 10),
            ..._serie.reversed.map((p) {
              final pct = p.total <= 0
                  ? 0
                  : ((p.logrados / p.total) * 100).round();
              final etiqueta =
                  DateFormat('dd/MM/yyyy').format(p.fecha);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        etiqueta,
                        style: GoogleFonts.poppins(fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '${p.logrados}/${p.total} ($pct%)',
                        textAlign: TextAlign.right,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.morado,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final alumno = _alumno;
    final ultima = _ultima;
    final resumen = _resumenUltima;

    return Scaffold(
      backgroundColor: AppColors.grisClaro,
      appBar: AppBar(
        leading: const CaipiAppBarLeading(),
        title: Text(
          alumno?.nombreCompleto ?? 'Niño',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.morado,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : alumno == null
              ? const Center(child: Text('No encontrado'))
              : RefreshIndicator(
                  onRefresh: _cargar,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                alumno.nombreCompleto,
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '1) Asigna hitos a este niño. '
                                '2) Crea seguimientos en el grupo (cada uno = una fecha). '
                                '3) Califica. Si algo que ya lograba luego falla, '
                                'baja en la gráfica = retroceso.',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: AppColors.gris,
                                ),
                              ),
                              if (_esDirectora) ...[
                                const SizedBox(height: 8),
                                SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text('Visible al padre'),
                                  subtitle: Text(
                                    alumno.portageVisiblePadre
                                        ? 'Ve hitos asignados y calificados'
                                        : 'No ve indicadores',
                                    style: GoogleFonts.poppins(fontSize: 12),
                                  ),
                                  value: alumno.portageVisiblePadre,
                                  onChanged: (_) => _toggleVisiblePadre(),
                                ),
                                const SizedBox(height: 8),
                                OutlinedButton.icon(
                                  onPressed: _asignarHitos,
                                  icon: const Icon(Icons.playlist_add_check),
                                  label: const Text('Asignar hitos a este niño'),
                                ),
                              ] else ...[
                                const SizedBox(height: 8),
                                Text(
                                  'La directora decide qué hitos se asignan y si '
                                  'el padre los ve. Tú solo calificas el seguimiento.',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: AppColors.gris,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Seguimiento actual (último)',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (ultima == null)
                        Text(
                          'Aún no hay seguimientos. Carga hitos en el menú '
                          '«Hitos (cargar catálogo)», asígnalos aquí y crea un seguimiento.',
                          style: GoogleFonts.poppins(color: AppColors.gris),
                        )
                      else
                        Card(
                          child: ListTile(
                            title: Text(
                              ultima.titulo?.trim().isNotEmpty == true
                                  ? ultima.titulo!
                                  : 'Seguimiento ${DateFormat('dd/MM/yyyy').format(ultima.fechaInicio)}',
                            ),
                            subtitle: Text(
                              'Inicio ${DateFormat('dd/MM/yyyy').format(ultima.fechaInicio)}\n'
                              '${resumen == null || resumen.total == 0 ? 'Sin indicadores' : '${resumen.calificados}/${resumen.total} calificados · ${resumen.logrados} L · ${resumen.enProceso} EP'}',
                            ),
                            isThreeLine: true,
                            trailing: const Icon(Icons.edit_note),
                            onTap: _calificarUltima,
                          ),
                        ),
                      if (ultima != null) ...[
                        const SizedBox(height: 8),
                        FilledButton.icon(
                          onPressed: _calificarUltima,
                          icon: const Icon(Icons.checklist),
                          label: const Text('Calificar último seguimiento'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.morado,
                            minimumSize: const Size.fromHeight(46),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      Text(
                        'Evolución (por seguimientos)',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Cada punto es un seguimiento calificado. '
                        'Si baja el número de logrados, hubo retroceso.',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.gris,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SegmentedButton<int?>(
                        segments: const [
                          ButtonSegment(value: null, label: Text('Todos')),
                          ButtonSegment(value: 3, label: Text('Últ. 3')),
                          ButtonSegment(value: 6, label: Text('Últ. 6')),
                        ],
                        selected: {_maxSeguimientos},
                        onSelectionChanged: (s) => _cambiarVentana(s.first),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
                          child: _serie.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Text(
                                    'Aún no hay seguimientos calificados. '
                                    'Cuando califiques, aquí verás la tendencia.',
                                    style: GoogleFonts.poppins(
                                      color: AppColors.gris,
                                      fontSize: 13,
                                    ),
                                  ),
                                )
                              : Column(
                                  children: [
                                    SizedBox(
                                      height: 220,
                                      child: PortageLineChart(serie: _serie),
                                    ),
                                    if (_serie.length == 1)
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                          12,
                                          0,
                                          12,
                                          8,
                                        ),
                                        child: Text(
                                          'Solo 1 seguimiento. Con el siguiente '
                                          'aparecerá la línea entre fechas.',
                                          style: GoogleFonts.poppins(
                                            color: AppColors.gris,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                        ),
                      ),
                      if (_serie.length >= 2) ...[
                        const SizedBox(height: 16),
                        _tablaComparativa(),
                      ],
                      if (_evaluaciones.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Text(
                          'Histórico de seguimientos',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Toca para calificar o ver. El PDF está disponible '
                          'en cada seguimiento ya calificado.',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.gris,
                          ),
                        ),
                        const SizedBox(height: 8),
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _incluirGraficaPdf,
                          onChanged: (v) => setState(
                            () => _incluirGraficaPdf = v ?? true,
                          ),
                          title: Text(
                            'Incluir gráfica de evolución al PDF',
                            style: GoogleFonts.poppins(fontSize: 13),
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                        ..._evaluaciones.map(
                          (e) {
                            final esUltima =
                                ultima != null && e.id == ultima.id;
                            final calificado = _evalTieneCalif(e);
                            return Card(
                              margin: const EdgeInsets.only(bottom: 6),
                              child: ListTile(
                                dense: true,
                                title: Text(
                                  e.tituloDisplay,
                                  style: GoogleFonts.poppins(
                                    fontWeight: esUltima
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                ),
                                subtitle: Text(_subtituloEval(e)),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (calificado)
                                      IconButton(
                                        tooltip: 'PDF / compartir',
                                        icon: const Icon(
                                          Icons.picture_as_pdf_outlined,
                                        ),
                                        onPressed: () => _compartirPdf(e),
                                      ),
                                    const Icon(Icons.chevron_right),
                                  ],
                                ),
                                onTap: () async {
                                  await context.push(
                                    '/directora/portage/evaluacion/${e.id}/alumno/${alumno.id}',
                                  );
                                  await _cargar();
                                },
                              ),
                            );
                          },
                        ),
                      ],
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
    );
  }
}

class PortageConteoResumen {
  final int total;
  final int logrados;
  final int enProceso;
  final int calificados;

  const PortageConteoResumen({
    required this.total,
    required this.logrados,
    required this.enProceso,
    required this.calificados,
  });
}
