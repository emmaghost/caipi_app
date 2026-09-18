import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../config/app_colors.dart';
import '../../models/alumno.dart';
import '../../models/portage.dart';
import '../../services/auth_service.dart';
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

  PortageEvaluacion? get _ultima {
    // Más reciente con calificaciones dentro de la lista elegida
    for (final e in _evalsDeLista) {
      final res = _resPorEval[e.id] ?? const [];
      if (res.any((r) => !r.sinCalificar)) return e;
    }
    return null;
  }

  List<PortageIndicador> _indsUltima = [];
  Map<String, PortageResultado> _resUltima = {};
  PortageConteoEstado? _conteoUltima;

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

  Future<void> _aplicarUltimaDetalle(PortageEvaluacion? ultima) async {
    if (ultima == null) {
      _indsUltima = [];
      _resUltima = {};
      _conteoUltima = null;
      return;
    }
    final inds = await _portage.listarIndicadores(ultima.listaId);
    final res = _resPorEval[ultima.id] ??
        await _portage.obtenerResultados(ultima.id, widget.alumnoId);
    _indsUltima = inds;
    _resUltima = {for (final r in res) r.indicadorId: r};
    _conteoUltima = PortageStats.contarPorEstado(
      resultados: res,
      totalIndicadores: inds.length,
    );
  }

  Future<void> _cambiarLista(String? listaId) async {
    setState(() => _listaIdSel = listaId);
    await _aplicarUltimaDetalle(_ultima);
    if (mounted) setState(() {});
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
          _indsUltima = [];
          _resUltima = {};
          _conteoUltima = null;
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
      await _aplicarUltimaDetalle(_ultima);

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
      // Solo indicadores calificados del último
      final r = _resUltima[i.id];
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
                          else if (_ultima == null)
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
                            _resumenUltimo(),
                            const SizedBox(height: 16),
                            _seccionGrafica(),
                            const SizedBox(height: 16),
                            _seccionDetalleUltimo(),
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
                  'Último seguimiento',
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

  Widget _resumenUltimo() {
    final c = _conteoUltima!;
    final fecha = DateFormat('dd/MM/yyyy').format(_ultima!.fechaInicio);
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

  Widget _seccionDetalleUltimo() {
    final areas = _agruparPorArea(_indsUltima);
    final titulo = _ultima!.tituloDisplay;
    final fecha = DateFormat('dd/MM/yyyy').format(_ultima!.fechaInicio);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Último seguimiento',
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
                    final r = _resUltima[ind.id];
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
