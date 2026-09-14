import 'dart:io';

import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Exporta vínculo papá ↔ hijo a Excel (sesión autenticada).
class ExportacionPadresHijosExcel {
  ExportacionPadresHijosExcel({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<({List<int> bytes, String fileName, int filas})> generar() async {
    final alumnosRes = await _client
        .from('alumnos')
        .select(
          'id, nombre, apellidos, activo, padre_id, grado_id, grados(nombre)',
        )
        .order('apellidos')
        .order('nombre');
    final alumnos = List<Map<String, dynamic>>.from(alumnosRes as List);

    List<Map<String, dynamic>> vinculos = [];
    try {
      final v = await _client
          .from('alumnos_padres')
          .select('alumno_id, padre_id, es_principal');
      vinculos = List<Map<String, dynamic>>.from(v as List);
    } catch (_) {}

    final padreIds = <String>{};
    for (final a in alumnos) {
      final pid = a['padre_id'] as String?;
      if (pid != null) padreIds.add(pid);
    }
    for (final v in vinculos) {
      final pid = v['padre_id'] as String?;
      if (pid != null) padreIds.add(pid);
    }

    final usuarios = <String, Map<String, dynamic>>{};
    if (padreIds.isNotEmpty) {
      final u = await _client
          .from('usuarios')
          .select('id, nombre, apellidos, email, telefono, whatsapp, rol')
          .inFilter('id', padreIds.toList());
      for (final row in u as List) {
        final m = Map<String, dynamic>.from(row as Map);
        usuarios[m['id'] as String] = m;
      }
    }

    final porAlumno = <String, Map<String, bool>>{};
    for (final a in alumnos) {
      final aid = a['id'] as String;
      porAlumno.putIfAbsent(aid, () => {});
      final pid = a['padre_id'] as String?;
      if (pid != null) porAlumno[aid]![pid] = true;
    }
    for (final v in vinculos) {
      final aid = v['alumno_id'] as String?;
      final pid = v['padre_id'] as String?;
      if (aid == null || pid == null) continue;
      porAlumno.putIfAbsent(aid, () => {});
      final prev = porAlumno[aid]![pid] ?? false;
      porAlumno[aid]![pid] = prev || (v['es_principal'] as bool? ?? false);
    }

    final excel = Excel.createExcel();
    final defaultSheet = excel.getDefaultSheet()!;
    excel.rename(defaultSheet, 'Padres-Hijos');
    final sheet = excel['Padres-Hijos'];
    sheet.appendRow([
      TextCellValue('Grado'),
      TextCellValue('Alumno'),
      TextCellValue('Alumno activo'),
      TextCellValue('Padre'),
      TextCellValue('Email padre'),
      TextCellValue('Tel / WhatsApp'),
      TextCellValue('Tipo vínculo'),
    ]);

    var filas = 0;
    for (final a in alumnos) {
      final aid = a['id'] as String;
      final gradoMap = a['grados'];
      final grado = gradoMap is Map
          ? (gradoMap['nombre'] as String? ?? '(sin grado)')
          : '(sin grado)';
      final alumno = '${a['nombre'] ?? ''} ${a['apellidos'] ?? ''}'.trim();
      final activo = (a['activo'] as bool? ?? true) ? 'Sí' : 'No';
      final padres = porAlumno[aid] ?? {};

      if (padres.isEmpty) {
        sheet.appendRow([
          TextCellValue(grado),
          TextCellValue(alumno),
          TextCellValue(activo),
          TextCellValue('(sin papá vinculado)'),
          TextCellValue(''),
          TextCellValue(''),
          TextCellValue(''),
        ]);
        filas++;
        continue;
      }

      final entries = padres.entries.toList()
        ..sort((x, y) {
          final c = (y.value ? 1 : 0).compareTo(x.value ? 1 : 0);
          if (c != 0) return c;
          return x.key.compareTo(y.key);
        });

      for (final e in entries) {
        final u = usuarios[e.key];
        if (u != null && u['rol'] != null && u['rol'] != 'padre') continue;
        final padre =
            '${u?['nombre'] ?? ''} ${u?['apellidos'] ?? ''}'.trim();
        final tel = (u?['whatsapp'] as String?)?.trim().isNotEmpty == true
            ? u!['whatsapp'] as String
            : (u?['telefono'] as String? ?? '');
        final tipo = (e.value || a['padre_id'] == e.key)
            ? 'Principal'
            : 'Segundo tutor';
        sheet.appendRow([
          TextCellValue(grado),
          TextCellValue(alumno),
          TextCellValue(activo),
          TextCellValue(padre.isEmpty ? e.key : padre),
          TextCellValue(u?['email'] as String? ?? ''),
          TextCellValue(tel),
          TextCellValue(tipo),
        ]);
        filas++;
      }
    }

    final bytes = excel.encode();
    if (bytes == null) {
      throw Exception('No se pudo generar el Excel');
    }
    final stamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    return (
      bytes: bytes,
      fileName: 'padres_hijos_$stamp.xlsx',
      filas: filas,
    );
  }

  Future<void> generarYCompartir() async {
    final r = await generar();
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${r.fileName}');
    await file.writeAsBytes(r.bytes, flush: true);
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile(
            file.path,
            mimeType:
                'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            name: r.fileName,
          ),
        ],
        subject: 'Padres y alumnos CAIPI',
        text: 'Vinculos papa-hijo — ${r.filas} filas',
      ),
    );
  }
}
