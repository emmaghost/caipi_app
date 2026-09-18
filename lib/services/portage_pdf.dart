import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../models/alumno.dart';
import '../models/portage.dart';
import '../utils/portage_stats.dart';
import 'pdf_branding.dart';

class PortagePdf {
  static Future<Uint8List> generar({
    required Alumno alumno,
    required PortageEvaluacion evaluacion,
    required List<PortageIndicador> indicadores,
    required List<PortageResultado> resultados,
    List<PortagePuntoSerie>? serieEvolucion,
  }) async {
    final brand = await PdfBranding.cargar();
    final pdf = pw.Document(
      title: 'Indicadores ${evaluacion.tituloDisplay}',
      author: 'CAIPI',
    );

    final porIndicador = {
      for (final r in resultados) r.indicadorId: r,
    };
    final conteo = PortageStats.contarPorEstado(
      resultados: resultados,
      totalIndicadores: indicadores.length,
    );
    final fechaTxt =
        DateFormat('dd/MM/yyyy').format(evaluacion.fechaInicio);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        theme: pw.ThemeData.withFont(
          base: brand.regular,
          bold: brand.bold,
        ),
        header: (ctx) => pw.Column(
          children: [
            PdfBranding.encabezado(
              titulo: 'Indicadores de desarrollo',
              subtitulo: alumno.nombreCompleto,
              logo: brand.logo,
              folioDerecha: fechaTxt,
            ),
            pw.SizedBox(height: 12),
            pw.Text(
              evaluacion.tituloDisplay,
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 16),
          ],
        ),
        footer: (ctx) => PdfBranding.pie(),
        build: (ctx) => [
          _resumen(conteo),
          if (serieEvolucion != null && serieEvolucion.isNotEmpty) ...[
            pw.SizedBox(height: 18),
            pw.Text(
              'Evolución (logrados)',
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 12,
              ),
            ),
            pw.SizedBox(height: 8),
            _graficaLinea(serieEvolucion),
          ],
          pw.SizedBox(height: 20),
          _tablaIndicadores(indicadores, porIndicador),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _resumen(PortageConteoEstado conteo) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Resumen',
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 12,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text('Total indicadores: ${conteo.total}'),
          pw.Text('Logrados (L): ${conteo.logrados}'),
          pw.Text('En proceso (EP): ${conteo.enProceso}'),
          pw.Text('Sin calificar: ${conteo.sinCalificar}'),
        ],
      ),
    );
  }

  /// Gráfica de evolución. Con 1 punto el Chart de pdf falla; usamos resumen.
  static pw.Widget _graficaLinea(List<PortagePuntoSerie> serie) {
    if (serie.isEmpty) return pw.SizedBox();

    if (serie.length == 1) {
      final p = serie.first;
      return pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey400),
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Primer registro · ${DateFormat('dd/MM/yyyy').format(p.fecha)}',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
            ),
            pw.SizedBox(height: 6),
            pw.Text('Logrados: ${p.logrados} de ${p.total}'),
            pw.Text('En proceso: ${p.enProceso}'),
            pw.SizedBox(height: 6),
            pw.Text(
              'Con otro seguimiento aparecerá la línea de tendencia.',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
          ],
        ),
      );
    }

    final maxY = serie
        .map((p) => math.max(p.logrados, p.total == 0 ? 1 : p.total))
        .fold<int>(1, (a, b) => a > b ? a : b)
        .toDouble();
    final step = maxY <= 10 ? 2.0 : (maxY <= 30 ? 5.0 : 10.0);
    final yMax = ((maxY / step).ceil() * step).toDouble();
    final yTicks = <double>[];
    for (double y = 0; y <= yMax + 0.01; y += step) {
      yTicks.add(y);
    }

    // Etiquetas únicas (mismo día en 2 seguimientos no rompe el eje X)
    final seen = <String, int>{};
    final labels = serie.map((p) {
      final base = DateFormat('dd/MM').format(p.fecha);
      final n = (seen[base] ?? 0) + 1;
      seen[base] = n;
      return n == 1 ? base : '$base ($n)';
    }).toList();

    try {
      return pw.SizedBox(
        height: 190,
        child: pw.Chart(
          grid: pw.CartesianGrid(
            xAxis: pw.FixedAxis.fromStrings(
              labels,
              marginStart: 0,
              marginEnd: 0,
              ticks: true,
            ),
            yAxis: pw.FixedAxis(
              yTicks,
              divisions: true,
            ),
          ),
          datasets: [
            pw.LineDataSet(
              legend: 'Logrados',
              drawLine: true,
              drawPoints: true,
              color: PdfColors.red,
              pointSize: 4,
              lineWidth: 2,
              data: List.generate(
                serie.length,
                (i) => pw.PointChartValue(
                  i.toDouble(),
                  serie[i].logrados.toDouble(),
                ),
              ),
            ),
          ],
        ),
      );
    } catch (_) {
      // Fallback tabular si el Chart falla
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          for (final p in serie)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 4),
              child: pw.Text(
                '${DateFormat('dd/MM/yyyy').format(p.fecha)}: '
                '${p.logrados} logrados / ${p.total}',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ),
        ],
      );
    }
  }

  static pw.Widget _tablaIndicadores(
    List<PortageIndicador> indicadores,
    Map<String, PortageResultado> porIndicador,
  ) {
    final filas = indicadores.map((ind) {
      final res = porIndicador[ind.id];
      final simbolo = PortageEstado.simbolo(res?.estado);
      final obs = res?.observaciones?.trim() ?? '';
      return [
        pw.Text('${ind.orden + 1}'),
        pw.Text(ind.nombre),
        pw.Center(
          child: pw.Text(
            simbolo,
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: simbolo == 'L'
                  ? PdfBranding.verde
                  : simbolo == 'EP'
                      ? PdfColors.orange800
                      : PdfColors.grey500,
            ),
          ),
        ),
        pw.Text(obs, style: const pw.TextStyle(fontSize: 9)),
      ];
    }).toList();

    return pw.TableHelper.fromTextArray(
      headers: ['#', 'Indicador', 'Est.', 'Observaciones'],
      data: filas,
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        fontSize: 10,
        color: PdfColors.white,
      ),
      headerDecoration: const pw.BoxDecoration(color: PdfBranding.morado),
      cellAlignment: pw.Alignment.centerLeft,
      columnWidths: {
        0: const pw.FixedColumnWidth(24),
        1: const pw.FlexColumnWidth(3),
        2: const pw.FixedColumnWidth(32),
        3: const pw.FlexColumnWidth(2),
      },
      cellStyle: const pw.TextStyle(fontSize: 9),
      cellPadding: const pw.EdgeInsets.all(6),
    );
  }

  static Future<void> compartir({
    required Alumno alumno,
    required PortageEvaluacion evaluacion,
    required List<PortageIndicador> indicadores,
    required List<PortageResultado> resultados,
    List<PortagePuntoSerie>? serieEvolucion,
  }) async {
    final bytes = await generar(
      alumno: alumno,
      evaluacion: evaluacion,
      indicadores: indicadores,
      resultados: resultados,
      serieEvolucion: serieEvolucion,
    );
    final slug = alumno.nombreCompleto
        .replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    final nombre = 'Indicadores_CAIPI_$slug.pdf';
    final dir = await getTemporaryDirectory();
    final archivo = File('${dir.path}${Platform.pathSeparator}$nombre');
    await archivo.writeAsBytes(bytes, flush: true);

    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile(
            archivo.path,
            mimeType: 'application/pdf',
            name: nombre,
          ),
        ],
        subject: 'Indicadores de desarrollo · ${alumno.nombreCompleto}',
        text:
            'CAIPI · ${evaluacion.tituloDisplay} · ${alumno.nombreCompleto}',
      ),
    );
  }
}
