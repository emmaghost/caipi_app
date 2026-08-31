import 'dart:io';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../models/abono.dart';
import '../models/alumno.dart';
import '../models/pago.dart';
import 'pdf_branding.dart';

class ReciboPagoPdf {
  static final _moneda = NumberFormat.currency(
    locale: 'es_MX',
    symbol: r'$',
    decimalDigits: 2,
  );

  static Future<Uint8List> generar({
    required Abono abono,
    required Pago pago,
    required Alumno alumno,
  }) async {
    final brand = await PdfBranding.cargar();
    final pdf = pw.Document(
      title: 'Recibo ${abono.reciboFolio ?? abono.id}',
      author: 'CAIPI',
    );
    final saldoRestante = pago.saldoPendiente.clamp(0.0, double.infinity);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(42),
        theme: pw.ThemeData.withFont(
          base: brand.regular,
          bold: brand.bold,
        ),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            PdfBranding.encabezado(
              titulo: 'Recibo de pago escolar',
              subtitulo: alumno.nombreCompleto,
              logo: brand.logo,
              folioDerecha: abono.reciboFolio ?? 'RECIBO',
            ),
            pw.SizedBox(height: 28),
            pw.Text(
              'RECIBIMOS DE',
              style: pw.TextStyle(
                color: PdfColors.grey700,
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              alumno.nombreCompleto,
              style: pw.TextStyle(
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 24),
            _fila('Concepto', pago.descripcionCompleta),
            _fila(
              'Fecha',
              DateFormat('dd/MM/yyyy').format(abono.fechaAbono),
            ),
            _fila('Forma de pago', abono.formaPago ?? 'No especificada'),
            _fila('Cuenta', abono.recibidoPorNombre ?? 'No especificada'),
            if (abono.referencia != null && abono.referencia!.isNotEmpty)
              _fila('Referencia', abono.referencia!),
            pw.Divider(height: 32, color: PdfColors.grey400),
            _filaMoneda('Monto recibido', abono.monto, destacado: true),
            _filaMoneda('Total del cargo', pago.monto),
            _filaMoneda('Saldo restante', saldoRestante),
            if (abono.notas != null && abono.notas!.isNotEmpty) ...[
              pw.SizedBox(height: 24),
              pw.Text(
                'Comentario',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey700,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Text(abono.notas!),
            ],
            pw.Spacer(),
            PdfBranding.pie(),
          ],
        ),
      ),
    );

    return pdf.save();
  }

  static pw.Widget _fila(String etiqueta, String valor) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 125,
            child: pw.Text(
              etiqueta,
              style: pw.TextStyle(
                color: PdfColors.grey700,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.Expanded(child: pw.Text(valor)),
        ],
      ),
    );
  }

  static pw.Widget _filaMoneda(
    String etiqueta,
    num monto, {
    bool destacado = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 7),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            etiqueta,
            style: pw.TextStyle(
              fontSize: destacado ? 16 : 12,
              fontWeight:
                  destacado ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            _moneda.format(monto),
            style: pw.TextStyle(
              fontSize: destacado ? 20 : 12,
              fontWeight: pw.FontWeight.bold,
              color: destacado
                  ? const PdfColor.fromInt(0xFF166534)
                  : PdfColors.black,
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> compartir({
    required Abono abono,
    required Pago pago,
    required Alumno alumno,
  }) async {
    final bytes = await generar(abono: abono, pago: pago, alumno: alumno);
    final folio = (abono.reciboFolio ?? abono.id)
        .replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    final nombre = 'Recibo_CAIPI_$folio.pdf';
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
        subject: 'Recibo de pago ${abono.reciboFolio ?? ''}',
        text:
            'Recibo CAIPI de ${alumno.nombreCompleto} · ${pago.descripcionCompleta}',
      ),
    );
  }
}
