import 'dart:io';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/alumno.dart';
import '../models/bitacora.dart';
import '../models/bitacora_gasto.dart';
import '../models/control_salida.dart';
import '../models/entrevista_padres.dart';
import 'pdf_branding.dart';

class ReportesPdfService {
  static final _moneda = NumberFormat.currency(
    locale: 'es_MX',
    symbol: r'$',
    decimalDigits: 2,
  );
  static final _fecha = DateFormat('dd/MM/yyyy');
  static final _hora = DateFormat('HH:mm');

  static Future<void> _compartirBytes(Uint8List bytes, String fileName) async {
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}${Platform.pathSeparator}$fileName';
    await File(path).writeAsBytes(bytes, flush: true);
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile(path, mimeType: 'application/pdf', name: fileName),
        ],
        subject: fileName,
        text: 'Reporte CAIPI · $fileName',
      ),
    );
  }

  // -------------------- ENTREVISTA --------------------

  static Future<void> compartirEntrevista({
    required EntrevistaPadres entrevista,
    required Alumno alumno,
  }) async {
    final bytes = await PdfBranding.documentoSimple(
      titulo: 'Entrevista a padres',
      subtitulo: alumno.nombreCompleto,
      body: (ctx) => [
        _bloque('Alumno', [
          'Nombre: ${alumno.nombreCompleto}',
          'Estado: ${entrevista.completado ? 'Completa' : 'Borrador'}',
        ]),
        _bloque('Madre', [
          'Nombre: ${entrevista.madreNombre ?? '-'}',
          'Edad: ${entrevista.madreEdad ?? '-'}',
          'Ocupación: ${entrevista.madreOcupacion ?? '-'}',
          'Teléfono: ${entrevista.madreTelefono ?? '-'}',
          'Estudios: ${entrevista.madreGradoEstudios ?? '-'}',
          'Dirección: ${entrevista.madreDireccion ?? '-'}',
        ]),
        _bloque('Padre', [
          'Nombre: ${entrevista.padreNombre ?? '-'}',
          'Edad: ${entrevista.padreEdad ?? '-'}',
          'Ocupación: ${entrevista.padreOcupacion ?? '-'}',
          'Teléfono: ${entrevista.padreTelefono ?? '-'}',
          'Estudios: ${entrevista.padreGradoEstudios ?? '-'}',
          'Dirección: ${entrevista.padreDireccion ?? '-'}',
        ]),
        _bloque('Vivienda del alumno', [
          'Calle: ${entrevista.viveCalle ?? '-'}',
          'Colonia: ${entrevista.viveColonia ?? '-'}',
          'Número: ${entrevista.viveNumero ?? '-'}',
          'Referencia: ${entrevista.viveReferencia ?? '-'}',
          'Tipo: ${entrevista.viveTipo ?? '-'}',
          'Condición: ${entrevista.viveCondicion ?? '-'}',
        ]),
        _bloque('Hogar', [
          'Convive con: ${entrevista.personasVivenCon ?? '-'}',
          'Quién cuida: ${entrevista.quienCuidaCuandoNoEscuela ?? '-'}',
          'Enfermedades: ${entrevista.enfermedadesPadecimientos ?? '-'}',
          'Alergias: ${entrevista.alergiasCuidados ?? '-'}',
          'Control esfínteres: ${entrevista.controlEsfinteres == true ? 'Sí' : entrevista.controlEsfinteres == false ? 'No' : '-'}',
          'NEE: ${entrevista.necesidadesEducativasEspeciales ?? '-'}',
        ]),
        _bloque('Antecedentes', [
          'Embarazo planeado: ${entrevista.embarazoPlaneado ?? '-'}',
          'Tiempo: ${entrevista.tiempoEmbarazo ?? '-'}',
          'Dificultades: ${entrevista.dificultadesEmbarazo ?? '-'}',
          'Caminó: ${entrevista.edadCamino ?? '-'}',
          'Habló: ${entrevista.edadHablo ?? '-'}',
        ]),
        _bloque('Aspecto social del hijo', [
          'Carácter: ${entrevista.caracterHijo ?? '-'}',
          'Lo enoja: ${entrevista.queLaHaceEnojar ?? '-'}',
          'Lo pone triste: ${entrevista.queLaPoneTriste ?? '-'}',
          'Le gusta: ${entrevista.queMasLeGustaHacer ?? '-'}',
          'Rutina: ${entrevista.rutinaDespuesEscuela ?? '-'}',
          'Duerme / despierta: ${entrevista.horaDuerme ?? '-'} / ${entrevista.horaDespierta ?? '-'}',
        ]),
        _bloque('Expectativas', [
          'De la maestra: ${entrevista.queEsperaMaestra ?? '-'}',
          'De la escuela: ${entrevista.queEsperaEscuela ?? '-'}',
          'Apoya escuela: ${entrevista.dispuestoApoyarEscuela == true ? 'Sí' : entrevista.dispuestoApoyarEscuela == false ? 'No' : '-'}',
        ]),
      ],
    );
    final safe = alumno.nombreCompleto.replaceAll(RegExp(r'[^\w\- ]'), '_');
    await _compartirBytes(bytes, 'Entrevista_CAIPI_$safe.pdf');
  }

  // -------------------- BITÁCORA --------------------

  static Future<void> compartirBitacoraDiaria({
    required DateTime desde,
    required DateTime hasta,
  }) async {
    final client = Supabase.instance.client;
    final desdeStr = desde.toIso8601String().split('T')[0];
    final hastaStr = hasta.toIso8601String().split('T')[0];

    final bitRes = await client
        .from('bitacora_diaria')
        .select()
        .gte('fecha', desdeStr)
        .lte('fecha', hastaStr)
        .order('fecha');
    final alumnosRes =
        await client.from('alumnos').select('id, nombre, apellidos');
    final nombres = {
      for (final a in alumnosRes as List)
        a['id'] as String:
            '${a['nombre'] ?? ''} ${a['apellidos'] ?? ''}'.trim(),
    };

    final filas = (bitRes as List)
        .map((e) => Bitacora.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    final bytes = await PdfBranding.documentoSimple(
      titulo: 'Bitácora diaria',
      subtitulo: PdfBranding.rangoFechas(desde, hasta),
      body: (ctx) {
        if (filas.isEmpty) {
          return [pw.Text('No hay registros en el rango seleccionado.')];
        }
        return [
          pw.TableHelper.fromTextArray(
            headers: const [
              'Fecha',
              'Alumno',
              'Comió',
              'Ánimo',
              'Obs.',
            ],
            data: filas
                .map((b) => [
                      _fecha.format(b.fecha),
                      nombres[b.alumnoId] ?? b.alumnoId,
                      Bitacora.etiquetaComio(b.comio),
                      b.estadoAnimo ?? '-',
                      (b.observaciones ?? '').length > 40
                          ? '${b.observaciones!.substring(0, 40)}…'
                          : (b.observaciones ?? '-'),
                    ])
                .toList(),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
              fontSize: 9,
            ),
            headerDecoration: const pw.BoxDecoration(color: PdfBranding.morado),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
            },
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            'Total registros: ${filas.length}',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
        ];
      },
    );
    await _compartirBytes(
      bytes,
      'Bitacora_diaria_${desdeStr}_$hastaStr.pdf',
    );
  }

  // -------------------- GASTOS --------------------

  static Future<void> compartirBitacoraGastos({
    required DateTime desde,
    required DateTime hasta,
  }) async {
    final client = Supabase.instance.client;
    final desdeStr = desde.toIso8601String().split('T')[0];
    final hastaStr = hasta.toIso8601String().split('T')[0];
    final res = await client
        .from('bitacora_gastos')
        .select()
        .gte('fecha', desdeStr)
        .lte('fecha', hastaStr)
        .order('fecha');
    final gradosRes = await client.from('grados').select('id, nombre');
    final grados = {
      for (final g in gradosRes as List)
        g['id'] as String: g['nombre'] as String? ?? '',
    };
    final filas = (res as List)
        .map((e) => BitacoraGasto.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    final total = filas.fold<double>(0, (s, g) => s + g.monto);

    final bytes = await PdfBranding.documentoSimple(
      titulo: 'Bitácora de gastos',
      subtitulo: PdfBranding.rangoFechas(desde, hasta),
      body: (ctx) {
        if (filas.isEmpty) {
          return [pw.Text('No hay gastos en el rango seleccionado.')];
        }
        return [
          pw.TableHelper.fromTextArray(
            headers: const ['Fecha', 'Descripción', 'Grupo', 'Monto'],
            data: filas
                .map((g) => [
                      _fecha.format(g.fecha),
                      g.descripcion,
                      g.esGeneralEscuela
                          ? 'Escuela'
                          : (grados[g.gradoId] ?? g.gradoId ?? '-'),
                      _moneda.format(g.monto),
                    ])
                .toList(),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
              fontSize: 10,
            ),
            headerDecoration: const pw.BoxDecoration(color: PdfBranding.morado),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellAlignments: {3: pw.Alignment.centerRight},
          ),
          pw.SizedBox(height: 12),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'Total: ${_moneda.format(total)}',
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 13,
                color: PdfBranding.verde,
              ),
            ),
          ),
        ];
      },
    );
    await _compartirBytes(bytes, 'Gastos_CAIPI_${desdeStr}_$hastaStr.pdf');
  }

  // -------------------- CONTROL ENTRADA/SALIDA --------------------

  static Future<void> compartirControlSalidas({
    required DateTime desde,
    required DateTime hasta,
  }) async {
    final client = Supabase.instance.client;
    final desdeStr = desde.toIso8601String().split('T')[0];
    final hastaStr = hasta.toIso8601String().split('T')[0];
    final res = await client
        .from('control_salidas')
        .select()
        .gte('fecha', desdeStr)
        .lte('fecha', hastaStr)
        .order('fecha');
    final alumnosRes =
        await client.from('alumnos').select('id, nombre, apellidos');
    final nombres = {
      for (final a in alumnosRes as List)
        a['id'] as String:
            '${a['nombre'] ?? ''} ${a['apellidos'] ?? ''}'.trim(),
    };
    final filas = (res as List)
        .map((e) => ControlSalida.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    final bytes = await PdfBranding.documentoSimple(
      titulo: 'Control de entrada / salida',
      subtitulo: PdfBranding.rangoFechas(desde, hasta),
      body: (ctx) {
        if (filas.isEmpty) {
          return [pw.Text('No hay registros en el rango seleccionado.')];
        }
        return [
          pw.TableHelper.fromTextArray(
            headers: const [
              'Fecha',
              'Alumno',
              'Entrada',
              'Trajo',
              'Salida',
              'Recogió',
              'Estado',
            ],
            data: filas
                .map((c) => [
                      _fecha.format(c.fecha),
                      nombres[c.alumnoId] ?? c.alumnoId,
                      c.horaEntrada != null ? _hora.format(c.horaEntrada!) : '-',
                      c.quienTrajo ?? '-',
                      c.horaSalida != null ? _hora.format(c.horaSalida!) : '-',
                      c.quienRecogio ?? '-',
                      c.ausente ? 'Ausente' : 'Asistió',
                    ])
                .toList(),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
              fontSize: 8,
            ),
            headerDecoration: const pw.BoxDecoration(color: PdfBranding.morado),
            cellStyle: const pw.TextStyle(fontSize: 7.5),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            'Total registros: ${filas.length}',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
        ];
      },
    );
    await _compartirBytes(
      bytes,
      'Control_entradas_${desdeStr}_$hastaStr.pdf',
    );
  }

  static pw.Widget _bloque(String titulo, List<String> lineas) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            titulo,
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfBranding.morado,
              fontSize: 12,
            ),
          ),
          pw.SizedBox(height: 6),
          ...lineas.map(
            (l) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 3),
              child: pw.Text(l, style: const pw.TextStyle(fontSize: 10)),
            ),
          ),
        ],
      ),
    );
  }
}
