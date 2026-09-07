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

/// Una línea de recibo (un mes / cargo) con su abono o datos del pago.
class ReciboPagoLinea {
  final Pago pago;
  final Abono abono;

  const ReciboPagoLinea({required this.pago, required this.abono});
}

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
    return generarMultiple(
      alumno: alumno,
      lineas: [ReciboPagoLinea(pago: pago, abono: abono)],
    );
  }

  /// Un solo PDF con uno o varios meses/cargos pagados del mismo alumno.
  static Future<Uint8List> generarMultiple({
    required Alumno alumno,
    required List<ReciboPagoLinea> lineas,
  }) async {
    if (lineas.isEmpty) {
      throw ArgumentError('No hay pagos para el recibo');
    }
    final brand = await PdfBranding.cargar();
    final ordenadas = [...lineas]..sort((a, b) {
      final fa = a.pago.fechaVencimiento ?? a.abono.fechaAbono;
      final fb = b.pago.fechaVencimiento ?? b.abono.fechaAbono;
      return fa.compareTo(fb);
    });

    final total = ordenadas.fold<double>(0, (s, l) => s + l.abono.monto);
    final folios = ordenadas
        .map((l) => l.abono.reciboFolio)
        .whereType<String>()
        .where((f) => f.trim().isNotEmpty)
        .toSet()
        .toList();
    final folioCabecera = folios.length == 1
        ? folios.first
        : (ordenadas.length > 1
            ? '${ordenadas.length} MESES'
            : (ordenadas.first.abono.reciboFolio ?? 'RECIBO'));

    final pdf = pw.Document(
      title: ordenadas.length > 1
          ? 'Recibo ${ordenadas.length} pagos — ${alumno.nombreCompleto}'
          : 'Recibo ${ordenadas.first.abono.reciboFolio ?? ordenadas.first.abono.id}',
      author: 'Administración CAIPI',
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(42),
        theme: pw.ThemeData.withFont(
          base: brand.regular,
          bold: brand.bold,
        ),
        footer: (context) => PdfBranding.pie(),
        build: (context) => [
          PdfBranding.encabezado(
            titulo: ordenadas.length > 1
                ? 'Recibo de pagos escolares'
                : 'Recibo de pago escolar',
            subtitulo: 'Administración CAIPI · ${alumno.nombreCompleto}',
            logo: brand.logo,
            folioDerecha: folioCabecera,
          ),
          pw.SizedBox(height: 22),
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
          pw.SizedBox(height: 8),
          pw.Text(
            ordenadas.length > 1
                ? '${ordenadas.length} periodos / cargos incluidos'
                : ordenadas.first.pago.descripcionCompleta,
            style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 20),
          if (ordenadas.length == 1) ..._detalleUnPago(ordenadas.first)
          else ..._tablaVariosPagos(ordenadas),
          pw.SizedBox(height: 16),
          pw.Divider(color: PdfColors.grey400),
          _filaMoneda('Total recibido', total, destacado: true),
          pw.SizedBox(height: 16),
          pw.Text(
            'Documento emitido por Administración CAIPI.',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  static List<pw.Widget> _detalleUnPago(ReciboPagoLinea linea) {
    final pago = linea.pago;
    final abono = linea.abono;
    final saldoRestante = pago.saldoPendiente.clamp(0.0, double.infinity);
    return [
      _fila('Concepto', pago.descripcionCompleta),
      _fila(
        'Fecha',
        DateFormat('dd/MM/yyyy').format(abono.fechaAbono),
      ),
      _fila('Forma de pago', abono.formaPago ?? 'No especificada'),
      _fila('Cuenta', abono.recibidoPorNombre ?? 'No especificada'),
      if (abono.referencia != null && abono.referencia!.isNotEmpty)
        _fila('Referencia', abono.referencia!),
      if (abono.reciboFolio != null && abono.reciboFolio!.isNotEmpty)
        _fila('Folio', abono.reciboFolio!),
      pw.Divider(height: 28, color: PdfColors.grey400),
      _filaMoneda('Monto recibido', abono.monto, destacado: true),
      _filaMoneda('Total del cargo', pago.monto),
      _filaMoneda('Saldo restante', saldoRestante),
      if (abono.notas != null && abono.notas!.isNotEmpty) ...[
        pw.SizedBox(height: 18),
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
    ];
  }

  static List<pw.Widget> _tablaVariosPagos(List<ReciboPagoLinea> lineas) {
    return [
      pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.6),
        columnWidths: {
          0: const pw.FlexColumnWidth(2.2),
          1: const pw.FlexColumnWidth(1.1),
          2: const pw.FlexColumnWidth(1.2),
          3: const pw.FlexColumnWidth(1.3),
        },
        children: [
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.grey200),
            children: [
              _celdaTabla('Periodo / concepto', negrita: true),
              _celdaTabla('Fecha', negrita: true),
              _celdaTabla('Forma', negrita: true),
              _celdaTabla('Monto', negrita: true, derecha: true),
            ],
          ),
          for (final l in lineas)
            pw.TableRow(
              children: [
                _celdaTabla(
                  '${l.pago.descripcionCompleta}'
                  '${l.abono.reciboFolio != null && l.abono.reciboFolio!.isNotEmpty ? '\n${l.abono.reciboFolio}' : ''}',
                ),
                _celdaTabla(
                  DateFormat('dd/MM/yyyy').format(l.abono.fechaAbono),
                ),
                _celdaTabla(l.abono.formaPago ?? '—'),
                _celdaTabla(_moneda.format(l.abono.monto), derecha: true),
              ],
            ),
        ],
      ),
    ];
  }

  static pw.Widget _celdaTabla(
    String texto, {
    bool negrita = false,
    bool derecha = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 7),
      child: pw.Text(
        texto,
        textAlign: derecha ? pw.TextAlign.right : pw.TextAlign.left,
        style: pw.TextStyle(
          fontSize: 9.5,
          fontWeight: negrita ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
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
    await compartirMultiple(
      alumno: alumno,
      lineas: [ReciboPagoLinea(pago: pago, abono: abono)],
    );
  }

  static Future<void> compartirMultiple({
    required Alumno alumno,
    required List<ReciboPagoLinea> lineas,
  }) async {
    final bytes = await generarMultiple(alumno: alumno, lineas: lineas);
    final safeName = alumno.nombreCompleto
        .replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    final nombre = lineas.length > 1
        ? 'Recibo_CAIPI_${lineas.length}meses_$safeName.pdf'
        : 'Recibo_CAIPI_${(lineas.first.abono.reciboFolio ?? lineas.first.abono.id).replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_')}.pdf';
    final dir = await getTemporaryDirectory();
    final archivo = File('${dir.path}${Platform.pathSeparator}$nombre');
    await archivo.writeAsBytes(bytes, flush: true);

    final periodos = lineas
        .map((l) => l.pago.mes ?? l.pago.concepto ?? l.pago.descripcionCompleta)
        .join(', ');

    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile(
            archivo.path,
            mimeType: 'application/pdf',
            name: nombre,
          ),
        ],
        subject: lineas.length > 1
            ? 'Recibo CAIPI · ${lineas.length} pagos · ${alumno.nombreCompleto}'
            : 'Recibo de pago ${lineas.first.abono.reciboFolio ?? ''}',
        text: lineas.length > 1
            ? 'Administración CAIPI — Recibo de ${lineas.length} pagos de '
                '${alumno.nombreCompleto}: $periodos'
            : 'Recibo CAIPI de ${alumno.nombreCompleto} · '
                '${lineas.first.pago.descripcionCompleta}',
      ),
    );
  }
}
