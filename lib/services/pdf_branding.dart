import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Encabezado y tipografía compartidos para todos los PDF de CAIPI.
class PdfBranding {
  static const morado = PdfColor.fromInt(0xFF6B5B95);
  static const verde = PdfColor.fromInt(0xFF166534);

  static Future<({pw.Font regular, pw.Font bold, pw.MemoryImage? logo})>
      cargar() async {
    final regular = await PdfGoogleFonts.openSansRegular();
    final bold = await PdfGoogleFonts.openSansBold();
    pw.MemoryImage? logo;
    try {
      final data = await rootBundle.load('assets/images/icono_caipi.png');
      logo = pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {
      logo = null;
    }
    return (regular: regular, bold: bold, logo: logo);
  }

  static pw.Widget encabezado({
    required String titulo,
    required String subtitulo,
    pw.MemoryImage? logo,
    String? folioDerecha,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: morado,
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          if (logo != null) ...[
            pw.Container(
              width: 48,
              height: 48,
              decoration: const pw.BoxDecoration(
                color: PdfColors.white,
                shape: pw.BoxShape.circle,
              ),
              padding: const pw.EdgeInsets.all(4),
              child: pw.Image(logo, fit: pw.BoxFit.contain),
            ),
            pw.SizedBox(width: 12),
          ],
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'CAIPI',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  titulo,
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  subtitulo,
                  style: const pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          if (folioDerecha != null && folioDerecha.isNotEmpty)
            pw.Text(
              folioDerecha,
              style: pw.TextStyle(
                color: PdfColors.white,
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }

  static pw.Widget pie() {
    final ahora = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
    return pw.Column(
      children: [
        pw.Divider(color: PdfColors.grey400),
        pw.Text(
          'Generado por CAIPI · $ahora',
          textAlign: pw.TextAlign.center,
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
        ),
      ],
    );
  }

  static String rangoFechas(DateTime desde, DateTime hasta) {
    final f = DateFormat('dd/MM/yyyy');
    return '${f.format(desde)} — ${f.format(hasta)}';
  }

  static Future<Uint8List> documentoSimple({
    required String titulo,
    required String subtitulo,
    required List<pw.Widget> Function(pw.Context ctx) body,
  }) async {
    final brand = await cargar();
    final pdf = pw.Document(title: titulo, author: 'CAIPI');
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
            encabezado(
              titulo: titulo,
              subtitulo: subtitulo,
              logo: brand.logo,
            ),
            pw.SizedBox(height: 16),
          ],
        ),
        footer: (ctx) => pie(),
        build: body,
      ),
    );
    return pdf.save();
  }
}
