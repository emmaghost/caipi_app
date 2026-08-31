import 'dart:io';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/bitacora_gasto.dart';

class ExcelGastosGenerado {
  final List<int> bytes;
  final String fileName;
  final int registros;
  final double total;

  ExcelGastosGenerado({
    required this.bytes,
    required this.fileName,
    required this.registros,
    required this.total,
  });
}

/// Excel de bitácora de gastos (mismo flujo compartir/guardar que pagos).
class ExportacionGastosExcel {
  static final _moneda = NumberFormat.currency(
    locale: 'es_MX',
    symbol: r'$',
    decimalDigits: 2,
  );

  static bool _pasaFiltro(
    BitacoraGasto g, {
    required String alcance,
    String? gradoFiltroId,
  }) {
    if (alcance == 'todos') return true;
    if (alcance == 'general') return g.esGeneralEscuela;
    if (alcance == 'grado' && gradoFiltroId != null) {
      return g.aplicaAGrado(gradoFiltroId);
    }
    return true;
  }

  static String _etiquetaAlcance(
    BitacoraGasto g,
    Map<String, String> nombresGrado,
  ) {
    if (g.esGeneralEscuela) return 'Toda la escuela';
    if (g.gruposAlcanceIds != null && g.gruposAlcanceIds!.isNotEmpty) {
      final nombres = g.gruposAlcanceIds!
          .map((id) => nombresGrado[id] ?? '?')
          .toList()
        ..sort();
      return nombres.join(', ');
    }
    return nombresGrado[g.gradoId] ?? 'Grupo';
  }

  static Future<ExcelGastosGenerado> generar({
    String alcance = 'todos',
    String? gradoFiltroId,
    Map<String, String>? nombresGrado,
  }) async {
    final client = Supabase.instance.client;
    final rows = await client
        .from('bitacora_gastos')
        .select()
        .order('fecha', ascending: false);

    Map<String, String> mapGrado = nombresGrado ?? {};
    if (mapGrado.isEmpty) {
      final grados = await client
          .from('grados')
          .select('id, nombre')
          .eq('activo', true);
      mapGrado = {
        for (final g in grados as List)
          g['id'] as String: g['nombre'] as String? ?? 'Grupo',
      };
    }

    final gastos = (rows as List)
        .map((e) => BitacoraGasto.fromJson(Map<String, dynamic>.from(e as Map)))
        .where(
          (g) => _pasaFiltro(
            g,
            alcance: alcance,
            gradoFiltroId: gradoFiltroId,
          ),
        )
        .toList()
      ..sort((a, b) => b.fecha.compareTo(a.fecha));

    final excel = Excel.createExcel();
    final defaultSheet = excel.getDefaultSheet()!;
    excel.rename(defaultSheet, 'Gastos');
    final sheet = excel['Gastos'];

    sheet.appendRow([
      TextCellValue('Fecha'),
      TextCellValue('Descripción'),
      TextCellValue('Alcance'),
      TextCellValue('Monto'),
    ]);

    var total = 0.0;
    for (final g in gastos) {
      total += g.monto;
      sheet.appendRow([
        TextCellValue(DateFormat('dd/MM/yyyy').format(g.fecha)),
        TextCellValue(g.descripcion),
        TextCellValue(_etiquetaAlcance(g, mapGrado)),
        TextCellValue(_moneda.format(g.monto)),
      ]);
    }

    sheet.appendRow([
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue('TOTAL'),
      TextCellValue(_moneda.format(total)),
    ]);

    if (gastos.isEmpty) {
      sheet.appendRow([
        TextCellValue('No hay gastos con el filtro actual'),
      ]);
    }

    final encoded = excel.encode();
    if (encoded == null) {
      throw Exception('No se pudo generar el archivo Excel');
    }

    final name =
        'CAIPI_bitacora_gastos_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.xlsx';
    return ExcelGastosGenerado(
      bytes: encoded,
      fileName: name,
      registros: gastos.length,
      total: total,
    );
  }

  static Future<void> compartir(
    List<int> bytes,
    String fileName,
    int registros,
    double total,
  ) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);

    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile(
            file.path,
            mimeType:
                'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            name: fileName,
          ),
        ],
        subject: 'Bitácora de gastos CAIPI',
        text:
            'Gastos CAIPI — $fileName ($registros registros, total ${_moneda.format(total)})',
      ),
    );
  }

  static bool esErrorPluginFileSaver(Object e) {
    return e is MissingPluginException ||
        e.toString().contains('MissingPluginException') ||
        e.toString().contains('saveFile on channel') ||
        e.toString().contains('file_saver');
  }

  static Future<String> guardarEnDispositivo(
    List<int> bytes,
    String fileName,
  ) async {
    final base =
        fileName.replaceAll('.xlsx', '').replaceAll(RegExp(r'[^\w\-]'), '_');
    try {
      await FileSaver.instance.saveFile(
        name: base,
        bytes: Uint8List.fromList(bytes),
        fileExtension: 'xlsx',
        mimeType: MimeType.microsoftExcel,
      );
      return 'Archivo guardado en la ubicación que elegiste.';
    } catch (e) {
      if (!esErrorPluginFileSaver(e)) rethrow;
    }

    try {
      final downloads = await getDownloadsDirectory();
      if (downloads != null) {
        final path = p.join(downloads.path, fileName);
        await File(path).writeAsBytes(bytes, flush: true);
        return 'Guardado en Descargas: $fileName';
      }
    } catch (_) {}

    final appDoc = await getApplicationDocumentsDirectory();
    final folder = Directory(p.join(appDoc.path, 'CAIPI_Export'));
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }
    final path = p.join(folder.path, fileName);
    await File(path).writeAsBytes(bytes, flush: true);
    return 'Guardado en carpeta de la app:\n$path';
  }

  static bool esErrorPluginCompartir(Object e) {
    return e is MissingPluginException ||
        e.toString().contains('MissingPluginException') ||
        e.toString().contains('share on channel');
  }
}
