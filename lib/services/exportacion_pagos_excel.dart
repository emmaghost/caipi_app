import 'dart:io';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:path/path.dart' as p;
import 'package:file_saver/file_saver.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/alumno.dart';
import '../models/pago.dart';
import 'supabase_service.dart';

/// Resultado de generar el Excel (bytes + nombre sugerido).
class ExcelPagosGenerado {
  final List<int> bytes;
  final String fileName;
  final int registros;

  ExcelPagosGenerado({
    required this.bytes,
    required this.fileName,
    required this.registros,
  });
}

class ExportacionPagosExcel {
  static String _tipoLabel(String? t) {
    switch (t) {
      case 'inscripcion':
        return 'Inscripción';
      case 'mensualidad':
        return 'Colegiatura';
      case 'seguro':
        return 'Seguro';
      case 'extracurricular':
        return 'Extracurricular';
      default:
        return t ?? '';
    }
  }

  static String _estatus(Pago p) {
    if (p.estaPagado) return 'Pagado';
    if (p.estaParcial) return 'Parcial';
    if (p.estaVencido) return 'Vencido';
    return 'Pendiente';
  }

  static Alumno? _alumnoDe(List<Alumno> alumnos, String id) {
    for (final a in alumnos) {
      if (a.id == id) return a;
    }
    return null;
  }

  /// Misma lógica que la lista en [PagosScreen] (grado, alumno, tipo, estado).
  static List<Pago> aplicarFiltrosVista({
    required List<Pago> data,
    required String filtroTipo,
    String? filtroGradoId,
    String? filtroAlumnoId,
    String? filtroTipoPago,
    String filtroEstado = 'todos',
    required List<Alumno> alumnos,
  }) {
    Set<String>? idsEnGrado;
    if (filtroTipo == 'alumnos' &&
        filtroGradoId != null &&
        filtroAlumnoId == null) {
      idsEnGrado = alumnos
          .where((a) => a.gradoId == filtroGradoId)
          .map((a) => a.id)
          .toSet();
    }

    return data.where((pago) {
      if (filtroTipo == 'alumnos') {
        if (pago.tipoPago != 'inscripcion' &&
            pago.tipoPago != 'mensualidad' &&
            pago.tipoPago != 'seguro' &&
            pago.tipoPago != null) {
          return false;
        }
      } else {
        if (pago.tipoPago != 'extracurricular') return false;
      }
      if (idsEnGrado != null && !idsEnGrado.contains(pago.alumnoId)) {
        return false;
      }
      if (filtroAlumnoId != null && pago.alumnoId != filtroAlumnoId) {
        return false;
      }
      if (filtroTipoPago != null && pago.tipoPago != filtroTipoPago) {
        return false;
      }
      if (filtroEstado == 'pagados') {
        if (!pago.estaPagado) return false;
      } else if (filtroEstado == 'vencidos') {
        if (pago.estaPagado || !pago.estaVencido) return false;
      } else if (filtroEstado == 'pendientes') {
        if (pago.estaPagado || !pago.esFechaLimiteAlcanzada) return false;
      }
      return true;
    }).toList();
  }

  /// Solo genera el archivo en memoria (sin compartir).
  /// [pestanaIndex] 0 = Pagos de alumnos (usa grado/alumno/tipo/estado), 1 = Extracurriculares (solo estado).
  static Future<ExcelPagosGenerado> generar(
    SupabaseService s, {
    required int pestanaIndex,
    String? filtroGradoId,
    String? filtroAlumnoId,
    String? filtroTipoPago,
    String filtroEstado = 'todos',
  }) async {
    final todosPagos = await s.obtenerTodosPagosList();
    final alumnos = await s.obtenerAlumnos();
    final grados = await s.obtenerGrados();
    final mapNombre = {for (final a in alumnos) a.id: a.nombreCompleto};
    final mapGrado = {for (final g in grados) g.id: g.nombre};

    final filtroTipo = pestanaIndex == 0 ? 'alumnos' : 'extracurriculares';
    final pagos = aplicarFiltrosVista(
      data: todosPagos,
      filtroTipo: filtroTipo,
      filtroGradoId: pestanaIndex == 0 ? filtroGradoId : null,
      filtroAlumnoId: pestanaIndex == 0 ? filtroAlumnoId : null,
      filtroTipoPago: pestanaIndex == 0 ? filtroTipoPago : null,
      filtroEstado: filtroEstado,
      alumnos: alumnos,
    );

    pagos.sort((a, b) {
      final na = mapNombre[a.alumnoId] ?? '';
      final nb = mapNombre[b.alumnoId] ?? '';
      final c = na.toLowerCase().compareTo(nb.toLowerCase());
      if (c != 0) return c;
      return (a.concepto ?? '').compareTo(b.concepto ?? '');
    });

    final excel = Excel.createExcel();
    final nombreHoja = excel.getDefaultSheet() ?? excel.tables.keys.first;
    excel.rename(nombreHoja, 'Pagos');
    final sheet = excel['Pagos'];

    final headers = [
      'Alumno',
      'Grado',
      'Concepto',
      'Tipo',
      'Monto total',
      'Monto pagado',
      'Saldo pendiente',
      'Estatus',
      'Fecha límite',
      'Fecha pago',
      'Forma de pago',
      'Recibió',
    ];
    sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());

    final headerStyle = CellStyle(
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
      backgroundColorHex: ExcelColor.fromHexString('FFE8DEF8'),
    );
    for (var c = 0; c < headers.length; c++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0))
          .cellStyle = headerStyle;
    }

    for (final p in pagos) {
      final alumno = _alumnoDe(alumnos, p.alumnoId);
      final gid = alumno?.gradoId;
      final grado = gid != null ? (mapGrado[gid] ?? '') : '';

      sheet.appendRow([
        TextCellValue(mapNombre[p.alumnoId] ?? '—'),
        TextCellValue(grado),
        TextCellValue(p.concepto ?? ''),
        TextCellValue(_tipoLabel(p.tipoPago)),
        DoubleCellValue(p.monto),
        DoubleCellValue(p.montoPagado),
        DoubleCellValue(p.saldoPendiente),
        TextCellValue(_estatus(p)),
        TextCellValue(
          p.fechaVencimiento != null
              ? DateFormat('yyyy-MM-dd').format(p.fechaVencimiento!)
              : '',
        ),
        TextCellValue(
          p.fechaPago != null
              ? DateFormat('yyyy-MM-dd').format(p.fechaPago!)
              : '',
        ),
        TextCellValue(p.formaPago ?? ''),
        TextCellValue(p.recibidoPorNombre ?? ''),
      ]);
    }

    final tm = pagos.fold<double>(0, (sum, p) => sum + p.monto);
    final tp = pagos.fold<double>(0, (sum, p) => sum + p.montoPagado);
    final ts = pagos.fold<double>(0, (sum, p) => sum + p.saldoPendiente);

    final totalStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('FFF5F0FF'));
    final totalRowIndex = 1 + pagos.length;
    sheet.appendRow([
      TextCellValue('TOTALES'),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      DoubleCellValue(tm),
      DoubleCellValue(tp),
      DoubleCellValue(ts),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
    ]);
    for (var c = 0; c < headers.length; c++) {
      sheet
          .cell(CellIndex.indexByColumnRow(
              columnIndex: c, rowIndex: totalRowIndex))
          .cellStyle = totalStyle;
    }

    final encoded = excel.encode();
    if (encoded == null) {
      throw Exception('No se pudo generar el archivo Excel');
    }

    final sufijo = pestanaIndex == 0 ? 'alumnos' : 'extracurricular';
    final name =
        'CAIPI_pagos_${sufijo}_filtrado_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.xlsx';
    return ExcelPagosGenerado(bytes: encoded, fileName: name, registros: pagos.length);
  }

  /// Abre el menú del sistema: ahí eliges WhatsApp, Gmail, etc. y el contacto.
  static Future<void> compartir(List<int> bytes, String fileName, int registros) async {
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
        subject: 'Exportación pagos CAIPI',
        text: 'Pagos CAIPI — $fileName ($registros registros)',
      ),
    );
  }

  /// Si falla el canal nativo de file_saver (p. ej. hot reload / APK vieja).
  static bool esErrorPluginFileSaver(Object e) {
    return e is MissingPluginException ||
        e.toString().contains('MissingPluginException') ||
        e.toString().contains('saveFile on channel') ||
        e.toString().contains('file_saver');
  }

  /// Guardar: primero selector del sistema; si el plugin no existe, Descargas o carpeta de la app.
  /// Devuelve texto para mostrar al usuario (ruta o mensaje genérico).
  static Future<String> guardarEnDispositivo(List<int> bytes, String fileName) async {
    final base = fileName.replaceAll('.xlsx', '').replaceAll(RegExp(r'[^\w\-]'), '_');
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
    } catch (_) {
      /* siguiente fallback */
    }

    final appDoc = await getApplicationDocumentsDirectory();
    final folder = Directory(p.join(appDoc.path, 'CAIPI_Export'));
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }
    final path = p.join(folder.path, fileName);
    await File(path).writeAsBytes(bytes, flush: true);
    return 'Guardado en carpeta de la app:\n$path';
  }

  /// true si falló el plugin nativo de compartir.
  static bool esErrorPluginCompartir(Object e) {
    return e is MissingPluginException ||
        e.toString().contains('MissingPluginException') ||
        e.toString().contains('share on channel');
  }
}
