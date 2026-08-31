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

/// Ficha de un niño:
/// - Solo el **último** seguimiento para calificar / PDF.
/// - La gráfica usa los seguimientos del rango 1 / 3 / 6 meses (evolución).
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
  PortageEvaluacion? _ultima;
  PortageConteoResumen? _resumenUltima;
  List<PortageIndicador> _indicadoresUltima = [];
  List<PortagePuntoSerie> _serie = [];
  int _ventanaMeses = 3;
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

      final serie = PortageStats.seriePorVentanaMeses(
        evaluaciones: evals,
        resultadosPorEvaluacion: resultadosPorEval,
        totalIndicadoresPorEvaluacion: totales,
        meses: _ventanaMeses,
      );

      if (!mounted) return;
      setState(() {
        _alumno = alumno;
        _evaluaciones = evals;
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

  Future<void> _cambiarVentana(int meses) async {
    if (_ventanaMeses == meses) return;
    setState(() => _ventanaMeses = meses);
    final alumno = _alumno;
    if (alumno == null || alumno.gradoId == null) return;

    final resultadosPorEval = <String, List<PortageResultado>>{};
    final totales = <String, int>{};
    for (final e in _evaluaciones) {
      final inds = await _portage.listarIndicadores(e.listaId);
      totales[e.id] = inds.length;
      resultadosPorEval[e.id] =
          await _portage.obtenerResultados(e.id, alumno.id);
    }
    final serie = PortageStats.seriePorVentanaMeses(
      evaluaciones: _evaluaciones,
      resultadosPorEvaluacion: resultadosPorEval,
      totalIndicadoresPorEvaluacion: totales,
      meses: meses,
    );
    if (!mounted) return;
    setState(() => _serie = serie);
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

  Future<void> _calificarUltima() async {
    final alumno = _alumno;
    final ultima = _ultima;
    if (alumno == null || ultima == null) return;
    await context.push(
      '/directora/portage/evaluacion/${ultima.id}/alumno/${alumno.id}',
    );
    await _cargar();
  }

  Future<void> _compartirPdf() async {
    final alumno = _alumno;
    final ultima = _ultima;
    if (alumno == null || ultima == null) return;
    await PortagePdf.compartir(
      alumno: alumno,
      evaluacion: ultima,
      indicadores: _indicadoresUltima,
      resultados: await _portage.obtenerResultados(ultima.id, alumno.id),
      serieEvolucion: _incluirGraficaPdf ? _serie : null,
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
                                'Se califica solo el último seguimiento. '
                                'La gráfica muestra cómo ha ido evolucionando en el tiempo.',
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
                                        ? 'Ve la última evaluación'
                                        : 'No ve indicadores',
                                    style: GoogleFonts.poppins(fontSize: 12),
                                  ),
                                  value: alumno.portageVisiblePadre,
                                  onChanged: (_) => _toggleVisiblePadre(),
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
                          'Aún no hay seguimientos en este grupo. '
                          'La directora los crea con «Nueva» en Administrar.',
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
                        'Evolución en el tiempo',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Cada punto es un seguimiento de este niño en el rango elegido.',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.gris,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SegmentedButton<int>(
                        segments: const [
                          ButtonSegment(value: 1, label: Text('1 mes')),
                          ButtonSegment(value: 3, label: Text('3 meses')),
                          ButtonSegment(value: 6, label: Text('6 meses')),
                        ],
                        selected: {_ventanaMeses},
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
                                    'No hay seguimientos en este rango. '
                                    'Cuando existan varios meses, aquí verás la tendencia.',
                                    style: GoogleFonts.poppins(
                                      color: AppColors.gris,
                                      fontSize: 13,
                                    ),
                                  ),
                                )
                              : SizedBox(
                                  height: 220,
                                  child: PortageLineChart(serie: _serie),
                                ),
                        ),
                      ),
                      if (ultima != null) ...[
                        const SizedBox(height: 8),
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _incluirGraficaPdf,
                          onChanged: (v) => setState(
                            () => _incluirGraficaPdf = v ?? true,
                          ),
                          title: Text(
                            'Incluir esta gráfica al imprimir PDF',
                            style: GoogleFonts.poppins(fontSize: 13),
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                        OutlinedButton.icon(
                          onPressed: _compartirPdf,
                          icon: const Icon(Icons.picture_as_pdf),
                          label: const Text('Imprimir / compartir PDF (último)'),
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
