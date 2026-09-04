import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/supabase_service.dart';
import '../../services/exportacion_pagos_excel.dart';
import '../../services/recibo_pago_pdf.dart';
import '../../models/pago.dart';
import '../../models/abono.dart';
import '../../models/alumno.dart';
import '../../models/grado.dart';
import '../../config/app_colors.dart';
import '../../widgets/app_drawer.dart';
import '../../services/chat_service.dart';
import '../../services/auth_service.dart';
import '../../utils/pago_helpers.dart';
import 'bitacora_gastos_screen.dart';

/// Formato de miles con coma (ej: 51,460.00)
String _formatoMonto(double monto) {
  return NumberFormat('#,##0.00', 'es_MX').format(monto);
}

class PagosScreen extends StatefulWidget {
  const PagosScreen({super.key});

  @override
  State<PagosScreen> createState() => _PagosScreenState();
}

class _PagosScreenState extends State<PagosScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _filtroGradoId;   // null = todos los grados
  String? _filtroAlumnoId;
  String? _filtroTipoPago; // null = todos, 'mensualidad', 'otro'
  String _filtroEstado = 'vencidos'; // 'todos' | 'vencidos' | 'pendientes' | 'futuros' | 'pagados'

  /// Panel de filtros de «Pagos de Alumnos» colapsado por defecto (más espacio para la lista en móvil).
  bool _filtrosAlumnosExpandidos = false;

  /// Lista de pagos pendientes: consulta HTTP (se invalida al volver de acreditar / pull / agregar).
  Future<List<Pago>>? _pagosPendientesFuture;
  SupabaseService? _pagosFutureService;
  /// Cambia al refrescar para que el [FutureBuilder] de la lista vuelva a montarse (p. ej. tras agregar uniforme).
  int _pagosListaEpoch = 0;
  /// Re-suscribe el stream de bitácora de gastos al volver de registrar un gasto (pestaña Bitácora).
  int _bitacoraGastosListaRefreshToken = 0;

  /// Selección múltiple para borrar cargos sin abonos.
  bool _modoSeleccion = false;
  final Set<String> _pagosSeleccionados = {};

  Future<List<Pago>> _futurePagosPendientes(SupabaseService s) {
    if (_pagosFutureService != s) {
      _pagosFutureService = s;
      _pagosPendientesFuture = null;
    }
    _pagosPendientesFuture ??= s.obtenerTodosPagosList();
    return _pagosPendientesFuture!;
  }

  Future<void> _refrescarPagosPendientes(SupabaseService s) async {
    try {
      final list = await s.obtenerTodosPagosList();
      if (!mounted) return;
      setState(() {
        _pagosFutureService = s;
        _pagosPendientesFuture = Future.value(list);
        _pagosListaEpoch++;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _pagosFutureService = s;
        _pagosPendientesFuture = Future.error(e);
        _pagosListaEpoch++;
      });
    }
  }

  Future<void> _exportarExcel(BuildContext context, SupabaseService s) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: AppColors.morado),
                  const SizedBox(height: 16),
                  Text(
                    'Generando Excel…',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    ExcelPagosGenerado? generado;
    try {
      generado = await ExportacionPagosExcel.generar(
        s,
        pestanaIndex: _tabController.index,
        filtroGradoId: _filtroGradoId,
        filtroAlumnoId: _filtroAlumnoId,
        filtroTipoPago: _filtroTipoPago,
        filtroEstado: _filtroEstado,
      );
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo generar el Excel: $e'),
            backgroundColor: AppColors.rojo,
          ),
        );
      }
      return;
    }

    if (context.mounted) Navigator.of(context, rootNavigator: true).pop();

    if (!context.mounted) return;
    final ex = generado!;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Exportar pagos',
                style: GoogleFonts.fredoka(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.morado,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${ex.registros} registros (mismos filtros que la pestaña actual) · ${ex.fileName}',
                style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700]),
              ),
              const SizedBox(height: 16),
              Text(
                'WhatsApp, Gmail y “a quién” no se eligen aquí: al compartir, el celular te muestra el menú y tú eliges la app y el contacto o correo.',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  height: 1.35,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: AppColors.morado.withOpacity(0.15),
                  child: Icon(Icons.share_rounded, color: AppColors.morado),
                ),
                title: Text(
                  'Compartir',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  'Abre el menú del sistema: WhatsApp, Gmail, Drive, correo…',
                  style: GoogleFonts.poppins(fontSize: 12),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  try {
                    await ExportacionPagosExcel.compartir(
                      ex.bytes,
                      ex.fileName,
                      ex.registros,
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    if (ExportacionPagosExcel.esErrorPluginCompartir(e)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Compartir no disponible. Cierra la app, vuelve a instalar o usa "Guardar". Detalle: $e',
                            style: const TextStyle(fontSize: 12),
                          ),
                          backgroundColor: Colors.orange.shade800,
                          duration: const Duration(seconds: 5),
                          action: SnackBarAction(
                            label: 'Guardar',
                            textColor: Colors.white,
                            onPressed: () async {
                              try {
                                final msg =
                                    await ExportacionPagosExcel.guardarEnDispositivo(
                                  ex.bytes,
                                  ex.fileName,
                                );
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(msg),
                                      backgroundColor: Colors.green.shade700,
                                    ),
                                  );
                                }
                              } catch (_) {}
                            },
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: $e'),
                          backgroundColor: AppColors.rojo,
                        ),
                      );
                    }
                  }
                },
              ),
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: Colors.green.shade100,
                  child: Icon(Icons.save_alt_rounded, color: Colors.green.shade800),
                ),
                title: Text(
                  'Guardar Excel en el teléfono',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  'Elige carpeta (Descargas, Documentos…). Luego lo envías tú por WhatsApp o correo.',
                  style: GoogleFonts.poppins(fontSize: 12),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  try {
                    final msg =
                        await ExportacionPagosExcel.guardarEnDispositivo(
                      ex.bytes,
                      ex.fileName,
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            msg,
                            style: GoogleFonts.poppins(fontSize: 13),
                          ),
                          backgroundColor: Colors.green.shade700,
                          duration: const Duration(seconds: 5),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('No se pudo guardar: $e'),
                          backgroundColor: AppColors.rojo,
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _onTabControllerChanged() {
    if (_tabController.indexIsChanging) return;
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabControllerChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabControllerChanged);
    _tabController.dispose();
    super.dispose();
  }

  Widget? _floatingActionButtonPagos(BuildContext context) {
    final auth = context.read<AuthService>();
    if (_tabController.index == 2) {
      if (!auth.isDirectora) return null;
      return FloatingActionButton.extended(
        onPressed: () async {
          final ok = await context.push<bool>('/directora/bitacora-gastos/crear');
          if (ok == true && mounted) {
            setState(() => _bitacoraGastosListaRefreshToken++);
          }
        },
        heroTag: 'registrar_gasto_pagos_tab',
        backgroundColor: AppColors.azulOscuro,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.receipt_long),
        label: Text('Registrar gasto', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      );
    }
    if (!auth.puedeGestionarPagos) return null;
    return FloatingActionButton.extended(
      onPressed: () => _mostrarMenuAgregarPago(context),
      heroTag: 'agregar_pago',
      backgroundColor: AppColors.verde,
      icon: const Icon(Icons.add),
      label: const Text('Agregar Pago'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = context.read<SupabaseService>();

    return Scaffold(
      backgroundColor: AppColors.rosaClaro,
      drawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: AppColors.morado,
        foregroundColor: Colors.white,
        title: Text(
          _modoSeleccion
              ? '${_pagosSeleccionados.length} seleccionados'
              : 'Gestión de Pagos',
        ),
        leading: _modoSeleccion
            ? IconButton(
                icon: const Icon(Icons.close),
                tooltip: 'Cancelar selección',
                onPressed: () => setState(() {
                  _modoSeleccion = false;
                  _pagosSeleccionados.clear();
                }),
              )
            : null,
        actions: [
          if (_modoSeleccion && context.read<AuthService>().isDirectora) ...[
            IconButton(
              icon: const Icon(Icons.delete_forever),
              tooltip: 'Eliminar seleccionados (sin abonos)',
              onPressed: () =>
                  _confirmarEliminarSeleccionados(context, firestoreService),
            ),
          ] else ...[
            if (_tabController.index < 2 &&
                context.read<AuthService>().isDirectora)
              IconButton(
                icon: const Icon(Icons.checklist),
                tooltip: 'Seleccionar para borrar',
                onPressed: () => setState(() {
                  _modoSeleccion = true;
                  _pagosSeleccionados.clear();
                }),
              ),
            if (_tabController.index < 2)
              IconButton(
                icon: const Icon(Icons.table_chart_outlined),
                tooltip: 'Exportar pagos (Excel) según filtros de esta pestaña',
                onPressed: () => _exportarExcel(context, firestoreService),
              ),
            IconButton(
              icon: const Icon(Icons.home),
              onPressed: () => context.go('/directora'),
              tooltip: 'Ir al inicio',
            ),
          ],
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(
              icon: Icon(Icons.school),
              text: 'Pagos de Alumnos',
            ),
            Tab(
              icon: Icon(Icons.sports_soccer),
              text: 'Extracurriculares',
            ),
            Tab(
              icon: Icon(Icons.receipt_long),
              text: 'Bitácora gastos',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPagosAlumnosTab(firestoreService),
          _buildListaPagos(
            firestoreService,
            filtroTipo: 'extracurriculares',
            filtroEstado: _filtroEstado,
          ),
          BitacoraGastosPanel(
            embeddedInPagos: true,
            listaRefreshToken: _bitacoraGastosListaRefreshToken,
          ),
        ],
      ),
      floatingActionButton: _floatingActionButtonPagos(context),
    );
  }

  String _etiquetaTipoPagoFiltro() {
    switch (_filtroTipoPago) {
      case 'mensualidad':
        return 'Colegiatura';
      case 'inscripcion':
        return 'Inscripción';
      case 'seguro':
        return 'Seguro';
      case 'otro':
        return 'Otro';
      default:
        return 'Todos los tipos';
    }
  }

  Set<String> _idsGradoFiltro(List<Grado> grados) {
    if (_filtroGradoId == null) return {};
    final ids = {_filtroGradoId!};
    for (final g in grados) {
      if (g.id == _filtroGradoId && g.esMaternal) {
        ids.addAll(grados.where((x) => x.esEstimulacion).map((x) => x.id));
        break;
      }
    }
    return ids;
  }

  String _etiquetaEstadoFiltroCorto() {
    switch (_filtroEstado) {
      case 'vencidos':
        return 'Vencidos';
      case 'pendientes':
        return 'Pendientes';
      case 'futuros':
        return 'Futuros';
      case 'pagados':
        return 'Pagados';
      default:
        return 'Todos';
    }
  }

  Widget _buildBarraColapsarFiltrosAlumnos(
    List<Grado> grados,
    Map<String, String> mapaNombres,
  ) {
    var gradoTxt = 'Todos los grados';
    if (_filtroGradoId != null) {
      final idx = grados.indexWhere((g) => g.id == _filtroGradoId);
      if (idx >= 0) gradoTxt = grados[idx].nombre;
    }
    final alumnoTxt = _filtroAlumnoId == null
        ? 'Todos los alumnos'
        : (mapaNombres[_filtroAlumnoId] ?? 'Alumno');
    final resumen =
        '$gradoTxt · $alumnoTxt · ${_etiquetaTipoPagoFiltro()} · ${_etiquetaEstadoFiltroCorto()}';

    return Material(
      color: Colors.white,
      elevation: 1,
      shadowColor: Colors.black26,
      child: InkWell(
        onTap: () => setState(() => _filtrosAlumnosExpandidos = !_filtrosAlumnosExpandidos),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.tune_rounded, color: AppColors.morado, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _filtrosAlumnosExpandidos ? 'Ocultar filtros' : 'Mostrar filtros',
                      style: GoogleFonts.fredoka(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2D2640),
                      ),
                    ),
                    if (!_filtrosAlumnosExpandidos) ...[
                      const SizedBox(height: 2),
                      Text(
                        resumen,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          height: 1.25,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                _filtrosAlumnosExpandidos ? Icons.expand_less : Icons.expand_more,
                color: AppColors.morado,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Pestaña "Pagos de Alumnos" con filtros por grado, alumno (con buscador) y tipo
  Widget _buildPagosAlumnosTab(SupabaseService service) {
    return FutureBuilder<List<dynamic>>(
      future: Future.wait([service.obtenerAlumnos(), service.obtenerGrados()]),
      builder: (context, snapshot) {
        final alumnos = snapshot.hasData && snapshot.data!.isNotEmpty
            ? (snapshot.data![0] as List<Alumno>)
            : <Alumno>[];
        final grados = snapshot.hasData && snapshot.data!.length > 1
            ? (snapshot.data![1] as List<Grado>)
            : <Grado>[];
        final mapaNombres = {for (var a in alumnos) a.id: a.nombreCompleto};

        return Column(
          children: [
            _buildBarraColapsarFiltrosAlumnos(grados, mapaNombres),
            AnimatedSize(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: _filtrosAlumnosExpandidos
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(bottom: BorderSide(color: AppColors.rosa.withOpacity(0.3))),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Grado',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF6B6080),
                            ),
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String?>(
                            value: _filtroGradoId,
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: AppColors.morado.withOpacity(0.5)),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            hint: Text('Todos los grados', style: GoogleFonts.poppins(fontSize: 14)),
                            items: [
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text('Todos los grados'),
                              ),
                              ...grados
                                  .where((g) =>
                                      !g.esEstimulacion ||
                                      g.id == _filtroGradoId)
                                  .map((g) => DropdownMenuItem<String?>(
                                    value: g.id,
                                    child: Text(
                                      g.nombre,
                                      style: GoogleFonts.poppins(fontSize: 14),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  )),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _filtroGradoId = value;
                                if (_filtroAlumnoId != null) {
                                  final list =
                                      alumnos.where((a) => a.id == _filtroAlumnoId).toList();
                                  final sel = list.isEmpty ? null : list.first;
                                  if (sel == null || (value != null && sel.gradoId != value)) {
                                    _filtroAlumnoId = null;
                                  }
                                }
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Alumno',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF6B6080),
                            ),
                          ),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: () => _mostrarSelectorAlumno(context, alumnos, grados),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.morado.withOpacity(0.5)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.person_search, color: Colors.grey[600], size: 22),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _filtroAlumnoId == null
                                          ? 'Todos los alumnos'
                                          : (mapaNombres[_filtroAlumnoId] ?? 'Alumno'),
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: _filtroAlumnoId == null
                                            ? Colors.grey[600]
                                            : const Color(0xFF2D2640),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Filtrar por tipo',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF6B6080),
                            ),
                          ),
                          const SizedBox(height: 6),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildChipTipo(null, 'Todos'),
                                _buildChipTipo('mensualidad', 'Colegiatura'),
                                _buildChipTipo('otro', 'Otro'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Estado',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF6B6080),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildChipEstado('todos', 'Todos'),
                              _buildChipEstado('vencidos', 'Vencidos'),
                              _buildChipEstado('pendientes', 'Pendientes'),
                              _buildChipEstado('futuros', 'Futuros'),
                              _buildChipEstado('pagados', 'Pagados', esPagados: true),
                            ],
                          ),
                        ],
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
            Expanded(
              child: _buildListaPagos(
                service,
                filtroTipo: 'alumnos',
                filtroAlumnoId: _filtroAlumnoId,
                filtroTipoPago: _filtroTipoPago,
                filtroEstado: _filtroEstado,
                mapaNombresAlumnos: mapaNombres,
                alumnoIdsPermitidosPorGrado: _filtroGradoId != null &&
                        _filtroAlumnoId == null
                    ? alumnos
                        .where((a) => _idsGradoFiltro(grados).contains(a.gradoId))
                        .map((a) => a.id)
                        .toSet()
                    : null,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildChipTipo(String? tipo, String label) {
    final selected = _filtroTipoPago == tipo;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label, style: GoogleFonts.poppins(fontSize: 13, fontWeight: selected ? FontWeight.w600 : FontWeight.w500)),
        selected: selected,
        onSelected: (_) => setState(() => _filtroTipoPago = tipo),
        backgroundColor: Colors.white,
        selectedColor: AppColors.morado.withOpacity(0.14),
        side: BorderSide(color: selected ? AppColors.morado.withOpacity(0.45) : Colors.grey.shade300),
        checkmarkColor: AppColors.morado,
        showCheckmark: selected,
        labelStyle: TextStyle(
          color: selected ? const Color(0xFF5C4D6B) : Colors.grey[700],
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
    );
  }

  Future<void> _notificarChatAdeudos(
    BuildContext context,
    SupabaseService service,
    String alumnoId,
    String nombreAlumno,
    List<Pago> pagosVencidos,
  ) async {
    final remitenteId = context.read<AuthService>().currentUser?.id;
    if (remitenteId == null) return;

    final padreIds = await service.idsPadresDeAlumno(alumnoId);
    if (padreIds.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Este alumno no tiene papás vinculados en la app.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    final mensaje = PagoHelpers.mensajeRecordatorioAdeudo(
      nombreAlumno: nombreAlumno,
      pagosVencidos: pagosVencidos,
      formatearMonto: _formatoMonto,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enviando recordatorio por chat…'),
          duration: Duration(seconds: 2),
        ),
      );
    }

    final enviados = await ChatService().enviarMensajeMasivoAPadres(
      remitenteId: remitenteId,
      contenido: mensaje,
      paraTodos: false,
      soloPadreIds: padreIds,
      omitirHorario: true,
    );

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          enviados > 0
              ? '✓ Recordatorio enviado por chat a $enviados papá(s)'
              : 'No se pudo enviar el chat. Revisa la conexión.',
        ),
        backgroundColor: enviados > 0 ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _notificarWhatsApp(
    BuildContext context,
    SupabaseService service,
    String alumnoId,
    String nombreAlumno,
    List<Pago> pagosVencidos,
  ) async {
    final telefono = await service.obtenerTelefonoPadrePorAlumnoId(alumnoId);
    if (telefono == null || telefono.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hay teléfono o WhatsApp registrado para el padre de este alumno.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }
    final conceptos = pagosVencidos.map((p) => p.concepto ?? 'Sin concepto').toList();
    final total = pagosVencidos.fold<double>(0, (sum, p) => sum + p.saldoPendiente);
    String detalle;
    if (conceptos.length == 1) {
      detalle = '${conceptos.first} por \$${_formatoMonto(total)}.';
    } else {
      detalle = '${conceptos.join(", ")}. *Total: \$${_formatoMonto(total)}*.';
    }
    final mensaje = 'CAIPI - Recordatorio de pago\n\n'
        '$nombreAlumno tiene pendiente de pago: $detalle\n\n'
        'Favor de regularizar. Gracias.';
    final soloNumeros = telefono.replaceAll(RegExp(r'[^0-9]'), '');
    final codigo = soloNumeros.length == 10 ? '52$soloNumeros' : soloNumeros;
    final uri = Uri.parse(
      'https://wa.me/$codigo?text=${Uri.encodeComponent(mensaje)}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo abrir WhatsApp. Verifique que esté instalado.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildChipEstado(String valor, String label, {bool esPagados = false}) {
    final selected = _filtroEstado == valor;
    final rojo = AppColors.rojo;
    final verde = const Color(0xFF166534);
    return FilterChip(
      label: Text(label, style: GoogleFonts.poppins(fontSize: 13, fontWeight: selected ? FontWeight.w600 : FontWeight.w500)),
      selected: selected,
      onSelected: (_) => setState(() => _filtroEstado = valor),
      backgroundColor: Colors.white,
      selectedColor: valor == 'vencidos'
          ? rojo.withOpacity(0.12)
          : esPagados
              ? verde.withOpacity(0.14)
              : AppColors.morado.withOpacity(0.14),
      side: BorderSide(
        color: selected
            ? (valor == 'vencidos'
                ? rojo.withOpacity(0.5)
                : esPagados
                    ? verde.withOpacity(0.55)
                    : AppColors.morado.withOpacity(0.45))
            : Colors.grey.shade300,
      ),
      checkmarkColor: valor == 'vencidos' ? rojo : esPagados ? verde : AppColors.morado,
      labelStyle: TextStyle(
        color: selected
            ? (valor == 'vencidos'
                ? rojo
                : esPagados
                    ? verde
                    : const Color(0xFF5C4D6B))
            : Colors.grey[700],
      ),
    );
  }

  void _mostrarSelectorAlumno(
    BuildContext context,
    List<Alumno> alumnos,
    List<Grado> grados,
  ) {
    List<Alumno> porGrado = _filtroGradoId == null
        ? alumnos
        : alumnos
            .where((a) => _idsGradoFiltro(grados).contains(a.gradoId))
            .toList();
    final mapaNombres = {for (var g in grados) g.id: g.nombre};

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SelectorAlumnoSheet(
        alumnos: porGrado,
        grados: grados,
        mapaGradoNombre: mapaNombres,
        alumnoSeleccionadoId: _filtroAlumnoId,
        onSeleccionar: (id) {
          setState(() => _filtroAlumnoId = id);
          Navigator.of(ctx).pop();
        },
      ),
    );
  }

  Widget _buildListaPagos(
    SupabaseService service, {
    required String filtroTipo,
    String? filtroAlumnoId,
    String? filtroTipoPago,
    String filtroEstado = 'todos',
    Map<String, String>? mapaNombresAlumnos,
    /// Si no es null y no hay [filtroAlumnoId], solo pagos de esos alumnos (filtro por grado).
    Set<String>? alumnoIdsPermitidosPorGrado,
  }) {
    return FutureBuilder<List<Pago>>(
      key: ValueKey('pagos_lista_$_pagosListaEpoch'),
      future: _futurePagosPendientes(service),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () {
                      setState(() {
                        _pagosFutureService = service;
                        _pagosPendientesFuture = service.obtenerTodosPagosList();
                        _pagosListaEpoch++;
                      });
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          );
        }

        final data = snapshot.data ?? [];

        var pagosFiltrados = data.where((pago) {
          if (filtroTipo == 'alumnos') {
            if (pago.tipoPago == 'extracurricular') return false;
            // Inscripción/seguro no van en el cuadro de pagos (solo informes de cobro).
            if (!PagoHelpers.esTipoCuadroPagos(
                  pago.tipoPago,
                  concepto: pago.concepto,
                )) {
              return false;
            }
          } else {
            if (pago.tipoPago != 'extracurricular') return false;
          }
          if (alumnoIdsPermitidosPorGrado != null &&
              filtroAlumnoId == null &&
              !alumnoIdsPermitidosPorGrado.contains(pago.alumnoId)) {
            return false;
          }
          if (filtroAlumnoId != null && pago.alumnoId != filtroAlumnoId) return false;
          if (filtroTipoPago != null && pago.tipoPago != filtroTipoPago) return false;
          if (filtroEstado == 'pagados') {
            if (!pago.estaPagado) return false;
          } else if (filtroEstado == 'vencidos') {
            if (pago.estaPagado || !pago.estaVencido) return false;
          } else if (filtroEstado == 'pendientes') {
            // Exigibles hoy (límite alcanzado) pero aún no vencidos del todo,
            // o vencidos: lo que corresponde cobrar ahora. Futuros fuera.
            if (pago.estaPagado || pago.esFuturo) return false;
          } else if (filtroEstado == 'futuros') {
            if (!pago.esFuturo) return false;
          }
          return true;
        }).toList();

        Future<void> onPullRefresh() => _refrescarPagosPendientes(service);

        if (pagosFiltrados.isEmpty) {
          return RefreshIndicator(
            color: AppColors.morado,
            onRefresh: onPullRefresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.savings_outlined,
                        size: 56,
                        color: AppColors.morado.withOpacity(0.45),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          filtroTipo == 'alumnos'
                              ? (filtroEstado == 'pagados'
                                  ? 'No hay pagos pagados con estos filtros.'
                                  : 'No hay pagos con estos filtros.\nDesliza hacia abajo para actualizar.')
                              : (filtroEstado == 'pagados'
                                  ? 'No hay extracurriculares pagados.'
                                  : 'No hay extracurriculares con estos filtros.'),
                          style: GoogleFonts.poppins(fontSize: 15, color: Colors.grey[700], height: 1.4),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        final esPagados = filtroEstado == 'pagados';
        final total = esPagados
            ? pagosFiltrados.fold<double>(0, (sum, p) => sum + p.monto)
            : pagosFiltrados.fold<double>(0, (sum, p) => sum + p.saldoPendiente);
        final vencidos = pagosFiltrados.where((p) => p.estaVencido).toList();
        final totalVencidos = vencidos.fold<double>(0, (sum, p) => sum + p.saldoPendiente);
        final puedeNotificar = filtroTipo == 'alumnos' &&
            filtroAlumnoId != null &&
            vencidos.isNotEmpty &&
            !esPagados;

        return RefreshIndicator(
          color: AppColors.morado,
          onRefresh: onPullRefresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
            children: [
              Card(
                elevation: 0,
                color: AppColors.rosaClaro,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: AppColors.rosa.withOpacity(0.35)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.85),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.receipt_long, color: AppColors.morado, size: 26),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  esPagados
                                      ? '${pagosFiltrados.length} pagos pagados'
                                      : '${pagosFiltrados.length} pagos en esta vista',
                                  style: GoogleFonts.poppins(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF4A3F55),
                                  ),
                                ),
                                if (!esPagados && vencidos.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    '${vencidos.length} vencidos · \$${_formatoMonto(totalVencidos)}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.rojo.withOpacity(0.9),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 6),
                                Text(
                                  esPagados
                                      ? 'Total cobrado (vista): \$${_formatoMonto(total)}'
                                      : 'Por cobrar: \$${_formatoMonto(total)}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: esPagados
                                        ? const Color(0xFF166534)
                                        : const Color(0xFF5C4D6B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (puedeNotificar) ...[
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _notificarChatAdeudos(
                                  context,
                                  service,
                                  filtroAlumnoId,
                                  mapaNombresAlumnos?[filtroAlumnoId] ??
                                      'Alumno',
                                  vencidos,
                                ),
                                icon: const Icon(Icons.forum_outlined, size: 20),
                                label: const Text('Chat adeudos'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.morado,
                                  side: BorderSide(
                                    color: AppColors.morado.withOpacity(0.6),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _notificarWhatsApp(
                                  context,
                                  service,
                                  filtroAlumnoId,
                                  mapaNombresAlumnos?[filtroAlumnoId] ??
                                      'Alumno',
                                  vencidos,
                                ),
                                icon: const Icon(Icons.chat, size: 20),
                                label: const Text('WhatsApp'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF25D366),
                                  side: const BorderSide(
                                    color: Color(0xFF25D366),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              ...pagosFiltrados.map((pago) => _buildPagoCard(
                    context,
                    service,
                    pago,
                    nombreAlumno: mapaNombresAlumnos?[pago.alumnoId],
                  )),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPagoCard(
    BuildContext context,
    SupabaseService service,
    Pago pago, {
    String? nombreAlumno,
  }) {
    final completamentePagado = pago.estaPagado;
    final vencido = !completamentePagado && pago.estaVencido;
    final futuro = !completamentePagado && pago.esFuturo;
    // Vencido: naranja/ámbar (se nota que está vencido sin ser rojo fuerte)
    const colorVencido = Color(0xFFC2410C);
    final accent = completamentePagado
        ? const Color(0xFF166534)
        : vencido
            ? colorVencido
            : futuro
                ? const Color(0xFF0369A1)
                : const Color(0xFF7C6BA8);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: _modoSeleccion && _pagosSeleccionados.contains(pago.id)
              ? AppColors.morado
              : Colors.grey.shade200,
          width: _modoSeleccion && _pagosSeleccionados.contains(pago.id) ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _modoSeleccion && pago.puedeEliminarse
            ? () => setState(() {
                  if (_pagosSeleccionados.contains(pago.id)) {
                    _pagosSeleccionados.remove(pago.id);
                  } else {
                    _pagosSeleccionados.add(pago.id);
                  }
                })
            : null,
        onLongPress: context.read<AuthService>().isDirectora &&
                pago.puedeEliminarse
            ? () => setState(() {
                  _modoSeleccion = true;
                  _pagosSeleccionados.add(pago.id);
                })
            : null,
        child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_modoSeleccion) ...[
              Row(
                children: [
                  Checkbox(
                    value: _pagosSeleccionados.contains(pago.id),
                    onChanged: pago.puedeEliminarse
                        ? (v) => setState(() {
                              if (v == true) {
                                _pagosSeleccionados.add(pago.id);
                              } else {
                                _pagosSeleccionados.remove(pago.id);
                              }
                            })
                        : null,
                  ),
                  Expanded(
                    child: Text(
                      pago.puedeEliminarse
                          ? 'Se puede eliminar'
                          : 'No se puede eliminar (tiene abonos o está pagado)',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: pago.puedeEliminarse
                            ? AppColors.verde
                            : Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],
            if (nombreAlumno != null && nombreAlumno.isNotEmpty) ...[
              Row(
                children: [
                  Icon(Icons.person_outline, size: 15, color: accent),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      nombreAlumno,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF4A3F55),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pago.concepto ?? 'Sin concepto',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF2D2640),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.morado.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          pago.descripcionCompleta,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.morado,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (completamentePagado) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF166534).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'PAGADO',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF166534),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (pago.fechaPago != null)
                          Text(
                            'Fecha de pago: ${DateFormat('dd/MM/yyyy').format(pago.fechaPago!)}',
                            style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[800]),
                          ),
                        if (pago.formaPago != null && pago.formaPago!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Forma: ${pago.formaPago}',
                            style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700]),
                          ),
                        ],
                        if (pago.recibidoPorNombre != null &&
                            pago.recibidoPorNombre!.trim().isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.person_pin_circle_outlined,
                                  size: 18, color: accent),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Cuenta: ${pago.recibidoPorNombre}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF2D2640),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ] else if (pago.estaParcial) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: pago.monto > 0 ? (pago.montoPagado / pago.monto).clamp(0.0, 1.0) : 0,
                            minHeight: 6,
                            backgroundColor: Colors.grey.shade200,
                            color: vencido
                                ? colorVencido.withOpacity(0.8)
                                : AppColors.morado.withOpacity(0.65),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Abonado \$${_formatoMonto(pago.montoPagado)} · Pendiente \$${_formatoMonto(pago.saldoPendiente)}',
                          style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700], height: 1.3),
                        ),
                        if (pago.formaPago != null && pago.formaPago!.trim().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Forma de pago: ${pago.formaPago}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                        if (pago.recibidoPorNombre != null &&
                            pago.recibidoPorNombre!.trim().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Último abono — cuenta: ${pago.recibidoPorNombre}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF6B5B95),
                            ),
                          ),
                        ],
                      ] else
                        Text(
                          'Monto \$${_formatoMonto(pago.monto)}',
                          style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (context.read<AuthService>().isDirectora &&
                        !_modoSeleccion &&
                        pago.puedeEliminarse)
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Eliminar pago',
                        onPressed: () => _confirmarEliminarPago(
                          context,
                          service,
                          pago,
                          nombreAlumno,
                        ),
                        icon: const Icon(
                          Icons.delete_outline,
                          color: AppColors.rojo,
                          size: 21,
                        ),
                      ),
                    Text(
                      completamentePagado
                          ? '\$${_formatoMonto(pago.monto)}'
                          : '\$${_formatoMonto(pago.saldoPendiente)}',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: completamentePagado
                            ? const Color(0xFF166534)
                            : vencido
                                ? colorVencido
                                : const Color(0xFF5C4D6B),
                      ),
                    ),
                    Text(
                      completamentePagado
                          ? 'liquidado'
                          : pago.estaParcial
                              ? 'por liquidar'
                              : 'a cubrir',
                      style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.event, size: 15, color: Colors.grey[500]),
                const SizedBox(width: 6),
                Text(
                  pago.fechaVencimiento != null
                      ? 'Límite ${DateFormat('dd/MM/yyyy').format(pago.fechaVencimiento!)}'
                      : 'Sin fecha límite',
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                ),
                if (vencido) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: colorVencido.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Vencido',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: colorVencido,
                      ),
                    ),
                  ),
                ] else if (futuro) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0369A1).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Futuro',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0369A1),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (!completamentePagado) ...[
              const SizedBox(height: 14),
              if (context.read<AuthService>().puedeGestionarPagos) ...[
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () async {
                      await context.push('/acreditar-pago/${pago.id}');
                      if (context.mounted) {
                        await _refrescarPagosPendientes(service);
                      }
                    },
                    icon: const Icon(Icons.payments_outlined, size: 20),
                    label: const Text('Acreditar pago'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF6B5B95),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _mostrarDialogoAjustarMonto(
                      context,
                      service,
                      pago,
                    ),
                    icon: const Icon(Icons.tune, size: 18),
                    label: const Text('Ajustar monto'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF6B5B95),
                      side: const BorderSide(color: Color(0xFF6B5B95)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ],
            if (pago.montoPagado > 0) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _compartirReciboPago(
                    context,
                    service,
                    pago,
                  ),
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: const Text('Compartir recibo'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF166534),
                    side: const BorderSide(color: Color(0xFF166534)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      ),
    );
  }

  Future<void> _confirmarEliminarPago(
    BuildContext context,
    SupabaseService service,
    Pago pago,
    String? nombreAlumno,
  ) async {
    if (!pago.puedeEliminarse) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Solo se pueden eliminar pagos sin abonos (pendientes).',
          ),
          backgroundColor: AppColors.rojo,
        ),
      );
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Eliminar pago?'),
        content: Text(
          'Se eliminará "${pago.descripcionCompleta}"'
          '${nombreAlumno == null ? '' : ' de $nombreAlumno'}.\n\n'
          'Solo se borran cargos sin abonos. Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.rojo),
            icon: const Icon(Icons.delete_forever),
            label: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;

    try {
      await service.eliminarPagoSinAbonos(pago.id);
      if (!mounted) return;
      setState(() => _pagosSeleccionados.remove(pago.id));
      await _refrescarPagosPendientes(service);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pago eliminado'),
          backgroundColor: AppColors.verde,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo eliminar el pago: $e'),
          backgroundColor: AppColors.rojo,
        ),
      );
    }
  }

  Future<void> _confirmarEliminarSeleccionados(
    BuildContext context,
    SupabaseService service,
  ) async {
    final ids = _pagosSeleccionados.toList();
    if (ids.isEmpty) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Eliminar pagos seleccionados?'),
        content: Text(
          'Se intentará eliminar ${ids.length} pago(s).\n'
          'Solo se borran los que no tengan abonos.\n\n'
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.rojo),
            icon: const Icon(Icons.delete_forever),
            label: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;

    try {
      final result = await service.eliminarPagosSinAbonos(ids);
      if (!mounted) return;
      setState(() {
        _pagosSeleccionados.clear();
        _modoSeleccion = false;
      });
      await _refrescarPagosPendientes(service);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Eliminados: ${result.eliminados}. '
            'Omitidos (con abonos u error): ${result.omitidos}.',
          ),
          backgroundColor:
              result.omitidos > 0 ? AppColors.naranja : AppColors.verde,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar: $e'),
          backgroundColor: AppColors.rojo,
        ),
      );
    }
  }

  Future<void> _compartirReciboPago(
    BuildContext context,
    SupabaseService service,
    Pago pago,
  ) async {
    try {
      final alumno = await service.obtenerAlumnoPorId(pago.alumnoId);
      if (alumno == null) {
        throw Exception('No se encontró el alumno de este pago.');
      }

      // Preferir abono real (folio REC-…). Si es un pago acreditado
      // antes del sistema de recibos, armar uno con los datos del pago.
      var abono = await service.obtenerUltimoAbono(pago.id);
      abono ??= Abono(
        id: 'legacy-${pago.id}',
        pagoId: pago.id,
        monto: pago.montoPagado > 0 ? pago.montoPagado : pago.monto,
        fechaAbono: pago.fechaPago ?? pago.updatedAt,
        formaPago: pago.formaPago,
        referencia: pago.referencia,
        notas: pago.notas,
        recibidoPorNombre: pago.recibidoPorNombre,
        reciboFolio: pago.referencia?.trim().isNotEmpty == true
            ? pago.referencia!.trim()
            : 'SIN-FOLIO-${pago.id.substring(0, 8).toUpperCase()}',
        createdAt: pago.updatedAt,
      );

      await ReciboPagoPdf.compartir(
        abono: abono,
        pago: pago,
        alumno: alumno,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo abrir el recibo: $e'),
          backgroundColor: AppColors.rojo,
        ),
      );
    }
  }

  void _mostrarMenuAgregarPago(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'Agregar pago',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildOpcionPago(
              context: context,
              titulo: 'Colegiatura / cargo nuevo',
              icono: Icons.school_outlined,
              color: AppColors.morado,
              onTap: () {
                Navigator.pop(context);
                _mostrarDialogoCrearPagoManual(context);
              },
            ),
            const SizedBox(height: 12),
            _buildOpcionPago(
              context: context,
              titulo: 'Libros',
              icono: Icons.menu_book,
              color: AppColors.purpura,
              onTap: () {
                Navigator.pop(context);
                _mostrarDialogoAgregarLibros(context);
              },
            ),
            const SizedBox(height: 12),
            _buildOpcionPago(
              context: context,
              titulo: 'Uniforme',
              icono: Icons.inventory_2_outlined,
              color: AppColors.azul,
              onTap: () {
                Navigator.pop(context);
                _mostrarDialogoAgregarUniforme(context);
              },
            ),
            const SizedBox(height: 12),
            _buildOpcionPago(
              context: context,
              titulo: 'Otro gasto',
              icono: Icons.add_circle_outline,
              color: AppColors.naranja,
              onTap: () {
                Navigator.pop(context);
                _mostrarDialogoAgregarGastoPersonalizado(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOpcionPago({
    required BuildContext context,
    required String titulo,
    required IconData icono,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icono, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Text(
              titulo,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios, size: 16, color: color),
          ],
        ),
      ),
    );
  }

  Future<void> _mostrarDialogoAjustarMonto(
    BuildContext context,
    SupabaseService service,
    Pago pago,
  ) async {
    final montoController = TextEditingController(
      text: pago.montoBruto > 0
          ? pago.montoBruto.toStringAsFixed(2)
          : pago.monto.toStringAsFixed(2),
    );
    final descuentoController = TextEditingController(
      text: pago.descuento.toStringAsFixed(2),
    );
    final notasController = TextEditingController(text: pago.notas ?? '');

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
        return AlertDialog(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          title: Row(
            children: [
              Icon(Icons.tune, color: AppColors.morado, size: 26),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Ajustar monto',
                  style: GoogleFonts.fredoka(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: StatefulBuilder(
                builder: (context, setLocal) {
                  final bruto = double.tryParse(
                        montoController.text.replaceAll(',', '.'),
                      ) ??
                      0;
                  final desc = double.tryParse(
                        descuentoController.text.replaceAll(',', '.'),
                      ) ??
                      0;
                  double? neto;
                  String? aviso;
                  try {
                    if (bruto > 0) {
                      neto = PagoHelpers.montoNeto(
                        montoBruto: bruto,
                        descuento: desc,
                      );
                      if (neto < pago.montoPagado) {
                        aviso =
                            'El neto no puede ser menor a lo abonado '
                            '(\$${_formatoMonto(pago.montoPagado)})';
                      }
                    }
                  } catch (e) {
                    neto = null;
                    aviso = e.toString().replaceFirst('Invalid argument(s): ', '');
                  }

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        pago.descripcionCompleta,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Actual: \$${_formatoMonto(pago.monto)}'
                        '${pago.montoPagado > 0 ? ' · Abonado \$${_formatoMonto(pago.montoPagado)}' : ''}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: montoController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (_) => setLocal(() {}),
                        decoration: InputDecoration(
                          labelText: 'Monto bruto *',
                          prefixText: '\$ ',
                          helperText:
                              'Puedes subir el monto (recargo) o bajarlo',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: descuentoController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (_) => setLocal(() {}),
                        decoration: InputDecoration(
                          labelText: 'Descuento',
                          prefixText: '\$ ',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      if (neto != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'A cobrar (neto): \$${_formatoMonto(neto)}',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            color: AppColors.morado,
                          ),
                        ),
                      ],
                      if (aviso != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          aviso,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.rojo,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: notasController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Notas',
                          hintText: 'Ej. ajuste por recargo / descuento',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      SizedBox(height: bottomInset > 0 ? 8 : 0),
                    ],
                  );
                },
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.morado,
                foregroundColor: Colors.white,
              ),
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) {
      montoController.dispose();
      descuentoController.dispose();
      notasController.dispose();
      return;
    }

    final bruto =
        double.tryParse(montoController.text.replaceAll(',', '.'));
    final desc =
        double.tryParse(descuentoController.text.replaceAll(',', '.')) ?? 0;
    final notas = notasController.text.trim();

    montoController.dispose();
    descuentoController.dispose();
    notasController.dispose();

    if (bruto == null || bruto <= 0) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Indica un monto bruto válido'),
          backgroundColor: AppColors.rojo,
        ),
      );
      return;
    }

    try {
      await service.ajustarMontoPago(
        pagoId: pago.id,
        montoBruto: bruto,
        descuento: desc,
        notas: notas.isEmpty ? null : notas,
      );
      if (!context.mounted) return;
      await _refrescarPagosPendientes(service);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Monto actualizado'),
          backgroundColor: AppColors.verde,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.rojo),
      );
    }
  }

  Future<void> _mostrarDialogoCrearPagoManual(BuildContext context) async {
    final montoController = TextEditingController();
    final descuentoController = TextEditingController(text: '0');
    final conceptoController = TextEditingController(text: 'Colegiatura');
    final notasController = TextEditingController();
    String? alumnoSeleccionado;
    String tipoPago = 'mensualidad';
    DateTime fechaPeriodo = DateTime(DateTime.now().year, DateTime.now().month, 1);

    final supabaseService = context.read<SupabaseService>();
    final alumnos = await supabaseService.obtenerAlumnos();
    if (!context.mounted) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
        return AlertDialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          title: Row(
            children: [
              Icon(Icons.school_outlined, color: AppColors.morado, size: 26),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Nuevo cargo / colegiatura',
                  style: GoogleFonts.fredoka(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: StatefulBuilder(
                builder: (context, setLocal) {
                  final bruto =
                      double.tryParse(montoController.text.replaceAll(',', '.')) ??
                          0;
                  final desc = double.tryParse(
                        descuentoController.text.replaceAll(',', '.'),
                      ) ??
                      0;
                  double? neto;
                  try {
                    if (bruto > 0) {
                      neto = PagoHelpers.montoNeto(
                        montoBruto: bruto,
                        descuento: desc,
                      );
                    }
                  } catch (_) {
                    neto = null;
                  }

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DropdownButtonFormField<String>(
                        value: alumnoSeleccionado,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Alumno *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: alumnos
                            .map(
                              (a) => DropdownMenuItem(
                                value: a.id,
                                child: Text(
                                  a.nombreCompleto,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setLocal(() => alumnoSeleccionado = v),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: tipoPago,
                        decoration: InputDecoration(
                          labelText: 'Tipo',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'mensualidad',
                            child: Text('Colegiatura'),
                          ),
                          DropdownMenuItem(
                            value: 'extracurricular',
                            child: Text('Extracurricular'),
                          ),
                          DropdownMenuItem(
                            value: 'otro',
                            child: Text('Otro'),
                          ),
                        ],
                        onChanged: (v) {
                          if (v == null) return;
                          setLocal(() {
                            tipoPago = v;
                            if (conceptoController.text.trim().isEmpty ||
                                conceptoController.text == 'Colegiatura') {
                              if (v == 'mensualidad') {
                                conceptoController.text = 'Colegiatura';
                              }
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: conceptoController,
                        decoration: InputDecoration(
                          labelText: 'Concepto *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: fechaPeriodo,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(DateTime.now().year + 2),
                            helpText: 'Periodo del cargo',
                          );
                          if (picked != null) {
                            setLocal(() {
                              fechaPeriodo =
                                  DateTime(picked.year, picked.month, 1);
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Periodo (mes / año) *',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            suffixIcon: const Icon(Icons.calendar_month),
                          ),
                          child: Text(
                            PagoHelpers.etiquetaPeriodo(fechaPeriodo),
                            style: GoogleFonts.poppins(fontSize: 15),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: montoController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (_) => setLocal(() {}),
                        decoration: InputDecoration(
                          labelText: 'Monto *',
                          prefixText: '\$ ',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: descuentoController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (_) => setLocal(() {}),
                        decoration: InputDecoration(
                          labelText: 'Descuento',
                          prefixText: '\$ ',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      if (neto != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'A cobrar: \$${_formatoMonto(neto)}',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            color: AppColors.morado,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: notasController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Notas',
                          hintText: 'Ej. entró con descuento a mitad de mes',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      SizedBox(height: bottomInset > 0 ? 8 : 0),
                    ],
                  );
                },
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.morado,
                foregroundColor: Colors.white,
              ),
              child: const Text('Crear'),
            ),
          ],
        );
      },
    );

    if (confirmar != true || alumnoSeleccionado == null) {
      montoController.dispose();
      descuentoController.dispose();
      conceptoController.dispose();
      notasController.dispose();
      return;
    }

    final bruto =
        double.tryParse(montoController.text.replaceAll(',', '.'));
    final desc =
        double.tryParse(descuentoController.text.replaceAll(',', '.')) ?? 0;
    final concepto = conceptoController.text.trim();
    final notas = notasController.text.trim();

    montoController.dispose();
    descuentoController.dispose();
    conceptoController.dispose();
    notasController.dispose();

    if (bruto == null || bruto <= 0 || concepto.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Concepto y monto válidos son obligatorios'),
          backgroundColor: AppColors.rojo,
        ),
      );
      return;
    }

    try {
      await supabaseService.crearPagoManual(
        alumnoId: alumnoSeleccionado!,
        tipoPago: tipoPago,
        concepto: concepto,
        montoBruto: bruto,
        descuento: desc,
        fechaPeriodo: fechaPeriodo,
        notas: notas.isEmpty ? null : notas,
      );
      if (!context.mounted) return;
      await _refrescarPagosPendientes(supabaseService);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cargo creado: $concepto · ${PagoHelpers.etiquetaPeriodo(fechaPeriodo)}',
          ),
          backgroundColor: AppColors.verde,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.rojo),
      );
    }
  }

  Future<void> _mostrarDialogoAgregarLibros(BuildContext context) async {
    final TextEditingController montoController = TextEditingController(text: '800');
    String? alumnoSeleccionado;

    final supabaseService = context.read<SupabaseService>();
    final alumnos = await supabaseService.obtenerAlumnos();

    if (!context.mounted) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
        return AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.menu_book, color: AppColors.purpura, size: 26),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Agregar pago de libros',
                style: GoogleFonts.fredoka(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: alumnoSeleccionado,
                decoration: InputDecoration(
                  labelText: 'Seleccionar alumno',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: alumnos.map((alumno) {
                  return DropdownMenuItem(
                    value: alumno.id,
                    child: Text(alumno.nombreCompleto),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => alumnoSeleccionado = value);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: montoController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Monto',
                  prefixText: '\$ ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              SizedBox(height: bottomInset > 0 ? 8 : 0),
            ],
          ),
        ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.purpura,
              foregroundColor: Colors.white,
            ),
            child: const Text('Agregar'),
          ),
        ],
      );
      },
    );

    if (confirmar == true && alumnoSeleccionado != null) {
      try {
        await supabaseService.agregarPagoLibros(
          alumnoSeleccionado!,
          double.parse(montoController.text),
        );

        if (!context.mounted) return;
        await _refrescarPagosPendientes(supabaseService);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pago de libros agregado'),
            backgroundColor: AppColors.verde,
          ),
        );
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.rojo),
        );
      }
    }
  }

  Future<void> _mostrarDialogoAgregarUniforme(BuildContext context) async {
    final TextEditingController cantidadController = TextEditingController(text: '1');
    final TextEditingController precioController = TextEditingController(text: '250');
    String? alumnoSeleccionado;

    final supabaseService = context.read<SupabaseService>();
    final alumnos = await supabaseService.obtenerAlumnos();

    if (!context.mounted) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
        return AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.inventory_2_outlined, color: AppColors.azul, size: 26),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Agregar pago de uniforme',
                style: GoogleFonts.fredoka(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: alumnoSeleccionado,
                decoration: InputDecoration(
                  labelText: 'Seleccionar alumno',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: alumnos.map((alumno) {
                  return DropdownMenuItem(
                    value: alumno.id,
                    child: Text(alumno.nombreCompleto),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => alumnoSeleccionado = value);
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: cantidadController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Cantidad',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: precioController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Precio c/u',
                        prefixText: '\$ ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: bottomInset > 0 ? 8 : 0),
            ],
          ),
        ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.azul,
              foregroundColor: Colors.white,
            ),
            child: const Text('Agregar'),
          ),
        ],
      );
      },
    );

    if (confirmar == true && alumnoSeleccionado != null) {
      try {
        await supabaseService.agregarPagoUniforme(
          alumnoSeleccionado!,
          int.parse(cantidadController.text),
          double.parse(precioController.text),
        );

        if (!context.mounted) return;
        await _refrescarPagosPendientes(supabaseService);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pago de uniforme agregado'),
            backgroundColor: AppColors.verde,
          ),
        );
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.rojo),
        );
      }
    }
  }

  Future<void> _mostrarDialogoAgregarGastoPersonalizado(BuildContext context) async {
    final nombreController = TextEditingController();
    final montoController = TextEditingController();
    String? alumnoSeleccionado;

    final supabaseService = context.read<SupabaseService>();
    final alumnos = await supabaseService.obtenerAlumnos();

    if (!context.mounted) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
        return AlertDialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          title: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.receipt_long, color: AppColors.naranja, size: 26),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Agregar otro gasto',
                  style: GoogleFonts.fredoka(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: StatefulBuilder(
              builder: (context, setState) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: alumnoSeleccionado,
                    decoration: InputDecoration(
                      labelText: 'Seleccionar alumno',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: alumnos.map((alumno) {
                      return DropdownMenuItem(
                        value: alumno.id,
                        child: Text(alumno.nombreCompleto),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => alumnoSeleccionado = value),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: nombreController,
                    decoration: InputDecoration(
                      labelText: 'Nombre del gasto *',
                      hintText: 'Ej: Material, Evento, Transporte…',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: montoController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Monto *',
                      prefixText: '\$ ',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  SizedBox(height: bottomInset > 0 ? 8 : 0),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.naranja,
                foregroundColor: Colors.white,
              ),
              child: const Text('Agregar'),
            ),
          ],
        );
      },
    );

    if (confirmar == true && alumnoSeleccionado != null) {
      final nombre = nombreController.text.trim();
      final monto = double.tryParse(montoController.text.replaceAll(',', '.'));
      if (nombre.isEmpty || monto == null || monto <= 0) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nombre del gasto y monto válido son obligatorios'),
            backgroundColor: AppColors.rojo,
          ),
        );
        return;
      }

      try {
        await supabaseService.agregarPagoPersonalizado(
          alumnoId: alumnoSeleccionado!,
          nombreGasto: nombre,
          monto: monto,
        );

        if (!context.mounted) return;
        await _refrescarPagosPendientes(supabaseService);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gasto "$nombre" agregado'),
            backgroundColor: AppColors.verde,
          ),
        );
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.rojo),
        );
      }
    }

    nombreController.dispose();
    montoController.dispose();
  }
}

/// Sheet con buscador para elegir alumno (filtrado por grado ya aplicado).
class _SelectorAlumnoSheet extends StatefulWidget {
  const _SelectorAlumnoSheet({
    required this.alumnos,
    required this.grados,
    required this.mapaGradoNombre,
    required this.alumnoSeleccionadoId,
    required this.onSeleccionar,
  });

  final List<Alumno> alumnos;
  final List<Grado> grados;
  final Map<String, String> mapaGradoNombre;
  final String? alumnoSeleccionadoId;
  final ValueChanged<String?> onSeleccionar;

  @override
  State<_SelectorAlumnoSheet> createState() => _SelectorAlumnoSheetState();
}

class _SelectorAlumnoSheetState extends State<_SelectorAlumnoSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Alumno> get _filtered {
    if (_query.isEmpty) return widget.alumnos;
    return widget.alumnos
        .where((a) => a.nombreCompleto.toLowerCase().contains(_query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final maxH = MediaQuery.of(context).size.height * 0.6;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      constraints: BoxConstraints(maxHeight: maxH),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                isDense: true,
              ),
              style: GoogleFonts.poppins(fontSize: 15),
              autofocus: true,
            ),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: 1 + filtered.length,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return ListTile(
                    leading: Icon(Icons.group_off, color: Colors.grey[600]),
                    title: Text(
                      'Todos los alumnos',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    selected: widget.alumnoSeleccionadoId == null,
                    onTap: () => widget.onSeleccionar(null),
                  );
                }
                final a = filtered[index - 1];
                final gradoNombre = a.gradoId != null
                    ? widget.mapaGradoNombre[a.gradoId] ?? ''
                    : '';
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.morado.withOpacity(0.2),
                    child: Text(
                      a.nombre.isNotEmpty ? a.nombre[0].toUpperCase() : '?',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: AppColors.morado,
                      ),
                    ),
                  ),
                  title: Text(
                    a.nombreCompleto,
                    style: GoogleFonts.poppins(fontSize: 15),
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: gradoNombre.isNotEmpty
                      ? Text(
                          gradoNombre,
                          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                        )
                      : null,
                  selected: widget.alumnoSeleccionadoId == a.id,
                  onTap: () => widget.onSeleccionar(a.id),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
