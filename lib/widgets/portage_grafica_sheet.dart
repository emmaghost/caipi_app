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

/// Bottom sheet: evolución + opción de incluir gráfica en PDF.
Future<void> mostrarPortageGraficaPdf({
  required BuildContext context,
  required Alumno alumno,
  required String gradoId,
  required PortageEvaluacion evaluacionPdf,
  required List<PortageIndicador> indicadoresPdf,
  int ventanaMesesInicial = 3,
}) async {
  final portage = PortageService();
  var ventanaMeses = ventanaMesesInicial;

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

    final serie = PortageStats.seriePorVentanaMeses(
      evaluaciones: evals,
      resultadosPorEvaluacion: resultadosPorEval,
      totalIndicadoresPorEvaluacion: totales,
      meses: ventanaMeses,
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
                  const SizedBox(height: 8),
                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 1, label: Text('1 mes')),
                      ButtonSegment(value: 3, label: Text('3 meses')),
                      ButtonSegment(value: 6, label: Text('6 meses')),
                    ],
                    selected: {ventanaMeses},
                    onSelectionChanged: (s) {
                      ventanaMeses = s.first;
                      Navigator.pop(ctx);
                      abrir();
                    },
                  ),
                  const SizedBox(height: 16),
                  if (serie.isEmpty)
                    Text(
                      'Sin registros en este rango de meses.',
                      style: GoogleFonts.poppins(color: AppColors.gris),
                    )
                  else
                    SizedBox(
                      height: 220,
                      child: PortageLineChart(serie: serie),
                    ),
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
