import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../config/app_colors.dart';
import '../../models/alumno.dart';
import '../../models/portage.dart';
import '../../services/auth_service.dart';
import '../../services/portage_pdf.dart';
import '../../services/portage_service.dart';
import '../../services/supabase_service.dart';
import '../../utils/portage_stats.dart';
import '../../widgets/caipi_app_bar_leading.dart';
import '../../widgets/portage_line_chart.dart';

/// Hub: elige hijo para ver indicadores (entrada desde el menú).
class IndicadoresPadreHubScreen extends StatelessWidget {
  const IndicadoresPadreHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<AuthService>().currentUser;
    if (usuario == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppColors.grisClaro,
      appBar: AppBar(
        leading: const CaipiAppBarLeading(),
        title: Text(
          'Indicadores',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.morado,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Alumno>>(
        stream: context.read<SupabaseService>().getAlumnosPorPadre(usuario.id),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting &&
              !snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final hijos = snap.data ?? const <Alumno>[];
          if (hijos.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No hay hijos registrados para mostrar indicadores.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(color: AppColors.gris),
                ),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                '¿De quién quieres ver el desarrollo?',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Solo verás datos del niño que elijas.',
                style: GoogleFonts.poppins(fontSize: 12, color: AppColors.gris),
              ),
              const SizedBox(height: 16),
              ...hijos.map((h) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: AppColors.moradoClaro,
                      child: Icon(
                        Icons.child_care,
                        color: AppColors.morado,
                      ),
                    ),
                    title: Text(
                      h.nombreCompleto,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      h.portageVisiblePadre
                          ? 'Indicadores disponibles'
                          : 'Aún no habilitados por la escuela',
                      style: GoogleFonts.poppins(fontSize: 12),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () =>
                        context.push('/padre/hijo/${h.id}/indicadores'),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

/// Pantalla de muestreo: gráfica histórica + solo el último seguimiento calificado.
/// 100% acotada al [alumnoId] y verificada contra el padre en sesión.
class IndicadoresPadreScreen extends StatefulWidget {
  final String alumnoId;

  const IndicadoresPadreScreen({super.key, required this.alumnoId});

  @override
  State<IndicadoresPadreScreen> createState() => _IndicadoresPadreScreenState();
}

class _IndicadoresPadreScreenState extends State<IndicadoresPadreScreen> {
  final _portage = PortageService();
  bool _loading = true;
  String? _error;
  bool _noEsTuHijo = false;
  Alumno? _alumno;

  /// Todas las evaluaciones del grupo + resultados de ESTE niño.
  List<PortageEvaluacion> _evals = [];
  Map<String, List<PortageResultado>> _resPorEval = {};
  Map<String, int> _totalesPorEval = {};
  Map<String, String> _nombreLista = {}; // listaId → nombre

  /// Lista seleccionada (si hay varias con datos).
  String? _listaIdSel;

  /// Evaluación mostrada en detalle (por defecto la más reciente calificada).
  String? _evalIdSel;

  List<String> get _listasConDatos {
    final ids = <String>{};
    for (final e in _evals) {
      final res = _resPorEval[e.id] ?? const [];
      if (res.any((r) => !r.sinCalificar)) ids.add(e.listaId);
    }
    final orden = ids.toList()
      ..sort((a, b) => (_nombreLista[a] ?? a).compareTo(_nombreLista[b] ?? b));
    return orden;
  }

  List<PortageEvaluacion> get _evalsDeLista {
    final id = _listaIdSel;
    if (id == null) return _evals;
    return _evals.where((e) => e.listaId == id).toList();
  }

  List<PortageEvaluacion> get _evalsCalificadas {
    return _evalsDeLista
        .where((e) {
          final res = _resPorEval[e.id] ?? const [];
          return res.any((r) => !r.sinCalificar);
        })
        .toList();
  }

  PortageEvaluacion? get _evalMostrada {
    final id = _evalIdSel;
    if (id != null) {
      for (final e in _evalsCalificadas) {
        if (e.id == id) return e;
      }
    }
    return _evalsCalificadas.isEmpty ? null : _evalsCalificadas.first;
  }

  PortageEvaluacion? get _ultima =>
      _evalsCalificadas.isEmpty ? null : _evalsCalificadas.first;

  List<PortageIndicador> _indsDetalle = [];
  Map<String, PortageResultado> _resDetalle = {};
  PortageConteoEstado? _conteoDetalle;
  bool _compartiendoPdf = false;

  List<PortagePuntoSerie> get _serie => PortageStats.seriePorSeguimientos(
        evaluaciones: _evalsDeLista,
        resultadosPorEvaluacion: _resPorEval,
        totalIndicadoresPorEvaluacion: _totalesPorEval,
        maxSeguimientos: null,
      );

  String get _listaNombre =>
      _listaIdSel == null ? '' : (_nombreLista[_listaIdSel!] ?? '');

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _aplicarDetalle(PortageEvaluacion? eval) async {
    if (eval == null) {
      _indsDetalle = [];
      _resDetalle = {};
      _conteoDetalle = null;
      _evalIdSel = null;
      return;
    }
    final inds = await _portage.listarIndicadores(eval.listaId);
    final res = _resPorEval[eval.id] ??
        await _portage.obtenerResultados(eval.id, widget.alumnoId);
    _indsDetalle = inds;
    _resDetalle = {for (final r in res) r.indicadorId: r};
    _conteoDetalle = PortageStats.contarPorEstado(
      resultados: res,
      totalIndicadores: inds.length,
    );
    _evalIdSel = eval.id;
  }

  Future<void> _cambiarLista(String? listaId) async {
    setState(() {
      _listaIdSel = listaId;
      _evalIdSel = null;
    });
    await _aplicarDetalle(_ultima);
    if (mounted) setState(() {});
  }

  Future<void> _seleccionarEval(PortageEvaluacion e) async {
    await _aplicarDetalle(e);
    if (mounted) setState(() {});
  }

  Future<void> _compartirPdf(PortageEvaluacion e) async {
    final alumno = _alumno;
    if (alumno == null || _compartiendoPdf) return;
    setState(() => _compartiendoPdf = true);
    try {
      final inds = e.id == _evalIdSel
          ? _indsDetalle
          : await _portage.listarIndicadores(e.listaId);
      final res = _resPorEval[e.id] ??
          await _portage.obtenerResultados(e.id, widget.alumnoId);
      if (!mounted) return;
      await PortagePdf.compartir(
        alumno: alumno,
        evaluacion: e,
        indicadores: inds,
        resultados: res,
        serieEvolucion: _serie.length >= 2 ? _serie : null,
        context: context,
      );
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo compartir el PDF: $err'),
          backgroundColor: AppColors.rojo,
        ),
      );
    } finally {
      if (mounted) setState(() => _compartiendoPdf = false);
    }
  }

  Future<void> _cargar() async {
    setState(() {
      _loading = true;
      _error = null;
      _noEsTuHijo = false;
    });
    try {
      final user = context.read<AuthService>().currentUser;
      if (user == null || !user.esPadre) {
        throw Exception('Sesión de padre requerida');
      }

      final svc = context.read<SupabaseService>();
      final ids = await svc.idsAlumnosDePadre(user.id);
      if (!ids.contains(widget.alumnoId)) {
        if (!mounted) return;
        setState(() {
          _noEsTuHijo = true;
          _loading = false;
        });
        return;
      }

      final alumno = await svc.obtenerAlumnoPorId(widget.alumnoId);
      if (alumno == null || alumno.id != widget.alumnoId) {
        throw Exception('Alumno no encontrado');
      }

      if (!alumno.portageVisiblePadre) {
        if (!mounted) return;
        setState(() {
          _alumno = alumno;
          _evals = [];
          _resPorEval = {};
          _totalesPorEval = {};
          _nombreLista = {};
          _listaIdSel = null;
          _evalIdSel = null;
          _indsDetalle = [];
          _resDetalle = {};
          _conteoDetalle = null;
          _loading = false;
        });
        return;
      }

      if (alumno.gradoId == null) {
        throw Exception('El niño no tiene grupo asignado');
      }

      final evals =
          await _portage.listarEvaluacionesPorGrado(alumno.gradoId!);
      final resultadosPorEval = <String, List<PortageResultado>>{};
      final totales = <String, int>{};
      final nombres = <String, String>{};

      for (final e in evals) {
        final inds = await _portage.listarIndicadores(e.listaId);
        totales[e.id] = inds.length;
        resultadosPorEval[e.id] =
            await _portage.obtenerResultados(e.id, widget.alumnoId);
        if (!nombres.containsKey(e.listaId)) {
          final lista = await _portage.obtenerLista(e.listaId);
          nombres[e.listaId] = lista?.nombre ?? 'Lista';
        }
      }

      _evals = evals;
      _resPorEval = resultadosPorEval;
      _totalesPorEval = totales;
      _nombreLista = nombres;

      final conDatos = <String>{};
      for (final e in evals) {
        final res = resultadosPorEval[e.id] ?? const [];
        if (res.any((r) => !r.sinCalificar)) conDatos.add(e.listaId);
      }
      // Por defecto: la lista del seguimiento más reciente con datos
      String? listaSel;
      for (final e in evals) {
        if (conDatos.contains(e.listaId)) {
          listaSel = e.listaId;
          break;
        }
      }
      _listaIdSel = listaSel;
      await _aplicarDetalle(_ultima);

      if (!mounted) return;
      setState(() {
        _alumno = alumno;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  Map<String, List<PortageIndicador>> _agruparPorArea(
    List<PortageIndicador> inds,
  ) {
    final map = <String, List<PortageIndicador>>{};
    for (final i in inds) {
      final r = _resDetalle[i.id];
      if (r == null || r.sinCalificar) continue;
      final key = (i.area == null || i.area!.trim().isEmpty)
          ? 'General'
          : i.area!;
      map.putIfAbsent(key, () => []).add(i);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F4FB),
      appBar: AppBar(
        leading: const CaipiAppBarLeading(),
        title: Text(
          'Indicadores',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.morado,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _loading ? null : _cargar,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _noEsTuHijo
              ? _estado(
                  Icons.lock_outline,
                  'No puedes ver estos indicadores',
                  'Este perfil no está vinculado a tu cuenta.',
                )
              : _error != null
                  ? _estado(Icons.error_outline, 'No se pudo cargar', _error!)
                  : RefreshIndicator(
                      onRefresh: _cargar,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                        children: [
                          _heroHijo(),
                          const SizedBox(height: 16),
                          if (_alumno != null &&
                              !_alumno!.portageVisiblePadre)
                            _estadoCard(
                              Icons.visibility_off_outlined,
                              'Aún no disponible',
                              'La escuela todavía no habilitó los indicadores '
                                  'para ${_alumno!.nombre}.',
                            )
                          else if (_evalMostrada == null)
                            _estadoCard(
                              Icons.hourglass_empty,
                              'Sin calificaciones todavía',
                              'Cuando la escuela registre un seguimiento, '
                                  'aquí verás el último resultado.',
                            )
                          else ...[
                            if (_listasConDatos.length > 1) ...[
                              _selectorLista(),
                              const SizedBox(height: 12),
                            ],
                            _resumenMostrada(),
                            const SizedBox(height: 12),
                            _botonPdf(_evalMostrada!),
                            const SizedBox(height: 16),
                            _seccionGrafica(),
                            if (_serie.length >= 2) ...[
                              const SizedBox(height: 16),
                              _tablaComparativa(),
                            ],
                            const SizedBox(height: 16),
                            _seccionDetalleMostrada(),
                            if (_evalsCalificadas.length > 1) ...[
                              const SizedBox(height: 20),
                              _seccionHistorial(),
                            ],
                          ],
                        ],
                      ),
                    ),
    );
  }

  Widget _selectorLista() {
    return DropdownButtonFormField<String>(
      value: _listaIdSel,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Lista',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
      items: _listasConDatos
          .map(
            (id) => DropdownMenuItem(
              value: id,
              child: Text(
                _nombreLista[id] ?? 'Lista',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: (v) {
        if (v != null) _cambiarLista(v);
      },
    );
  }

  Widget _heroHijo() {
    final a = _alumno;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8B5CF6), Color(0xFFDA70D6)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.morado.withOpacity(0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_graph, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  a?.nombreCompleto ?? 'Desarrollo',
                  style: GoogleFonts.fredoka(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _evalMostrada != null &&
                          _ultima != null &&
                          _evalMostrada!.id != _ultima!.id
                      ? 'Historial · seguimiento seleccionado'
                      : 'Último seguimiento',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.95),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _resumenMostrada() {
    final c = _conteoDetalle!;
    final eval = _evalMostrada!;
    final fecha = DateFormat('dd/MM/yyyy').format(eval.fechaInicio);
    return Row(
      children: [
        Expanded(
          child: _miniStat('Logrados', '${c.logrados}', AppColors.exitoPago),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _miniStat('En proceso', '${c.enProceso}', Colors.orange),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _miniStat('Fecha', fecha, AppColors.morado),
        ),
      ],
    );
  }

  Widget _botonPdf(PortageEvaluacion e) {
    return OutlinedButton.icon(
      onPressed: _compartiendoPdf ? null : () => _compartirPdf(e),
      icon: _compartiendoPdf
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.picture_as_pdf_outlined),
      label: Text(
        'Imprimir / compartir PDF',
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.morado,
        minimumSize: const Size.fromHeight(44),
        side: BorderSide(color: AppColors.morado.withOpacity(0.45)),
      ),
    );
  }

  Widget _tablaComparativa() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Comparativo',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Logrados en cada seguimiento (más reciente primero).',
            style: GoogleFonts.poppins(fontSize: 12, color: AppColors.gris),
          ),
          const SizedBox(height: 10),
          ..._serie.reversed.map((p) {
            final pct =
                p.total <= 0 ? 0 : ((p.logrados / p.total) * 100).round();
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      DateFormat('dd/MM/yyyy').format(p.fecha),
                      style: GoogleFonts.poppins(fontSize: 12),
                    ),
                  ),
                  Text(
                    '${p.logrados}/${p.total} ($pct%)',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.morado,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: color,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 11, color: AppColors.gris),
          ),
        ],
      ),
    );
  }

  Widget _seccionGrafica() {
    // Solo mostrar gráfica cuando hay al menos 2 seguimientos
    if (_serie.length < 2) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Evolución',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: PortageLineChart(
              serie: _serie,
              anotarValores: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _seccionDetalleMostrada() {
    final areas = _agruparPorArea(_indsDetalle);
    final eval = _evalMostrada!;
    final titulo = eval.tituloDisplay;
    final fecha = DateFormat('dd/MM/yyyy').format(eval.fechaInicio);
    final esUltima = _ultima != null && eval.id == _ultima!.id;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          esUltima ? 'Último seguimiento' : 'Seguimiento seleccionado',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$titulo · $fecha'
          '${_listaNombre.isNotEmpty ? ' · $_listaNombre' : ''}',
          style: GoogleFonts.poppins(fontSize: 12, color: AppColors.gris),
        ),
        const SizedBox(height: 10),
        if (areas.isEmpty)
          _estadoCard(
            Icons.info_outline,
            'Sin detalle',
            'El seguimiento existe pero no hay indicadores calificados.',
          )
        else
          ...areas.entries.map((e) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: Theme(
                data: Theme.of(context)
                    .copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  initiallyExpanded: false,
                  tilePadding: const EdgeInsets.symmetric(horizontal: 14),
                  childrenPadding: const EdgeInsets.only(bottom: 8),
                  title: Text(
                    e.key,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    '${e.value.length} indicador(es)',
                    style: GoogleFonts.poppins(fontSize: 11),
                  ),
                  children: e.value.map((ind) {
                    final r = _resDetalle[ind.id];
                    final logrado = PortageEstado.isLogrado(r?.estado);
                    return ListTile(
                      dense: true,
                      title: Text(
                        ind.nombre,
                        style: GoogleFonts.poppins(fontSize: 13),
                      ),
                      subtitle: Text(
                        PortageEstado.etiqueta(r?.estado),
                        style: GoogleFonts.poppins(fontSize: 12),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: (logrado ? AppColors.exitoPago : Colors.orange)
                              .withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          PortageEstado.simbolo(r?.estado),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: logrado
                                ? AppColors.exitoPago
                                : Colors.orange.shade800,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _seccionHistorial() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Historial',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Toca uno anterior para ver el detalle o compartir su PDF.',
          style: GoogleFonts.poppins(fontSize: 12, color: AppColors.gris),
        ),
        const SizedBox(height: 10),
        ..._evalsCalificadas.map((e) {
          final res = _resPorEval[e.id] ?? const [];
          final total = _totalesPorEval[e.id] ?? 0;
          var logrados = 0;
          var ep = 0;
          for (final r in res) {
            if (r.esLogrado) logrados++;
            if (r.esEnProceso) ep++;
          }
          final seleccionada = _evalMostrada?.id == e.id;
          final esUltima = _ultima?.id == e.id;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: seleccionada
                  ? BorderSide(color: AppColors.morado.withOpacity(0.55), width: 1.5)
                  : BorderSide.none,
            ),
            child: ListTile(
              title: Text(
                e.tituloDisplay,
                style: GoogleFonts.poppins(
                  fontWeight: seleccionada ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              subtitle: Text(
                '${DateFormat('dd/MM/yyyy').format(e.fechaInicio)}'
                ' · $logrados L · $ep EP'
                '${total > 0 ? ' · ${logrados + ep}/$total' : ''}'
                '${esUltima ? ' · más reciente' : ''}',
                style: GoogleFonts.poppins(fontSize: 12),
              ),
              trailing: IconButton(
                tooltip: 'PDF',
                icon: const Icon(Icons.picture_as_pdf_outlined),
                onPressed:
                    _compartiendoPdf ? null : () => _compartirPdf(e),
              ),
              onTap: () => _seleccionarEval(e),
            ),
          );
        }),
      ],
    );
  }

  Widget _estado(IconData icon, String title, String body) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: AppColors.gris),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              body,
              style: GoogleFonts.poppins(color: AppColors.gris, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _estadoCard(IconData icon, String title, String body) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.morado, size: 36),
          const SizedBox(height: 10),
          Text(
            title,
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: GoogleFonts.poppins(fontSize: 13, color: AppColors.gris),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
