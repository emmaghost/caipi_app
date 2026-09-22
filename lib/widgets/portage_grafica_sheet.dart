import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../config/app_colors.dart';
import '../models/alumno.dart';
import '../models/portage.dart';
import '../services/auth_service.dart';
import '../services/portage_pdf.dart';
import '../services/portage_service.dart';
import '../utils/portage_stats.dart';
import 'portage_line_chart.dart';

/// Bottom sheet: evolución por seguimientos + PDF.
Future<void> mostrarPortageGraficaPdf({
  required BuildContext context,
  required Alumno alumno,
  required String gradoId,
  required PortageEvaluacion evaluacionPdf,
  required List<PortageIndicador> indicadoresPdf,
  int? maxSeguimientosInicial,
}) async {
  final portage = PortageService();
  int? maxSeg = maxSeguimientosInicial;

  Future<void> abrir() async {
    final evals = await portage.listarEvaluacionesPorGrado(gradoId);
    final resultadosPorEval = <String, List<PortageResultado>>{};
    final totales = <String, int>{};
    for (final e in evals) {
      final inds = await portage.listarIndicadores(e.listaId);
      totales[e.id] = inds.length;
      resultadosPorEval[e.id] =
          await portage.obtenerResultados(e.id, alumno.id);
    }

    final serie = PortageStats.seriePorSeguimientos(
      evaluaciones: evals,
      resultadosPorEvaluacion: resultadosPorEval,
      totalIndicadoresPorEvaluacion: totales,
      maxSeguimientos: maxSeg,
    );

    if (!context.mounted) return;
    var incluirGrafica = true;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                20 + MediaQuery.viewPaddingOf(ctx).bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Evolución · ${alumno.nombreCompleto}',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Cada punto es un seguimiento calificado.',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.gris,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<int?>(
                    segments: const [
                      ButtonSegment(value: null, label: Text('Todos')),
                      ButtonSegment(value: 3, label: Text('Últ. 3')),
                      ButtonSegment(value: 6, label: Text('Últ. 6')),
                    ],
                    selected: {maxSeg},
                    onSelectionChanged: (s) {
                      maxSeg = s.first;
                      Navigator.pop(ctx);
                      abrir();
                    },
                  ),
                  const SizedBox(height: 16),
                  if (serie.isEmpty)
                    Text(
                      'Aún no hay seguimientos calificados para graficar.',
                      style: GoogleFonts.poppins(color: AppColors.gris),
                    )
                  else ...[
                    SizedBox(
                      height: 220,
                      child: PortageLineChart(serie: serie),
                    ),
                    if (serie.length == 1)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Solo hay 1 seguimiento. Cuando califiques otro, '
                          'verás la línea de tendencia entre fechas.',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.gris,
                          ),
                        ),
                      ),
                  ],
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: incluirGrafica,
                    onChanged: (v) =>
                        setModal(() => incluirGrafica = v ?? true),
                    title: Text(
                      'Incluir gráfica al imprimir / compartir PDF',
                      style: GoogleFonts.poppins(fontSize: 13),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  Text(
                    'PDF del seguimiento: ${evaluacionPdf.tituloDisplay} · ${DateFormat('dd/MM/yyyy').format(evaluacionPdf.fechaInicio)}',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: AppColors.gris,
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: () async {
                      final resultados = await portage.obtenerResultados(
                        evaluacionPdf.id,
                        alumno.id,
                      );
                      await PortagePdf.compartir(
                        alumno: alumno,
                        evaluacion: evaluacionPdf,
                        indicadores: indicadoresPdf,
                        resultados: resultados,
                        serieEvolucion: incluirGrafica ? serie : null,
                        context: ctx,
                      );
                    },
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('Imprimir / compartir PDF'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  await abrir();
}

bool portageEsDirectora(BuildContext context) =>
    context.read<AuthService>().currentUser?.esDirectora == true;
