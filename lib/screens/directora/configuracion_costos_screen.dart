import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/app_colors.dart';
import '../../models/configuracion_costos.dart';
import '../../utils/pago_helpers.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/caipi_app_bar_leading.dart';

class ConfiguracionCostosScreen extends StatefulWidget {
  const ConfiguracionCostosScreen({super.key});

  @override
  State<ConfiguracionCostosScreen> createState() =>
      _ConfiguracionCostosScreenState();
}

class _ConfiguracionCostosScreenState extends State<ConfiguracionCostosScreen> {
  final _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();

  final _inscripcionController = TextEditingController();
  final _seguroController = TextEditingController();
  final _mensualidad12Controller = TextEditingController();
  final _mensualidad11Controller = TextEditingController();
  final _mensualidad10Controller = TextEditingController();
  final _anticipado12Controller = TextEditingController();
  final _anticipado11Controller = TextEditingController();
  final _anticipado10Controller = TextEditingController();
  final _recargo12Controller = TextEditingController();
  final _recargo11Controller = TextEditingController();
  final _recargo10Controller = TextEditingController();
  final _sesionController = TextEditingController(text: '350');
  final _paquete4Controller = TextEditingController(text: '950');
  final _paquete6Controller = TextEditingController(text: '1100');
  final _paquete8Controller = TextEditingController(text: '1150');
  final _inscripcionMaternalController = TextEditingController(text: '1150');
  final _notasController = TextEditingController();

  ConfiguracionCostos? _configActual;
  bool _cargando = true;
  bool _guardando = false;
  bool _sumarInscripcion = false;
  bool _sumarSeguro = false;
  bool _faltanColumnasDescuento = false;
  bool _faltanColumnasMaternal = false;
  String? _resumenGuardado;

  void _refrescarVista() => setState(() {});

  @override
  void initState() {
    super.initState();
    _cargarConfiguracion();
    for (final c in [
      _inscripcionController,
      _seguroController,
      _mensualidad12Controller,
      _mensualidad11Controller,
      _mensualidad10Controller,
      _anticipado12Controller,
      _anticipado11Controller,
      _anticipado10Controller,
      _recargo12Controller,
      _recargo11Controller,
      _recargo10Controller,
      _sesionController,
      _paquete4Controller,
      _paquete6Controller,
      _paquete8Controller,
      _inscripcionMaternalController,
    ]) {
      c.addListener(_refrescarVista);
    }
  }

  @override
  void dispose() {
    for (final c in [
      _inscripcionController,
      _seguroController,
      _mensualidad12Controller,
      _mensualidad11Controller,
      _mensualidad10Controller,
      _anticipado12Controller,
      _anticipado11Controller,
      _anticipado10Controller,
      _recargo12Controller,
      _recargo11Controller,
      _recargo10Controller,
      _sesionController,
      _paquete4Controller,
      _paquete6Controller,
      _paquete8Controller,
      _inscripcionMaternalController,
    ]) {
      c.removeListener(_refrescarVista);
    }
    _inscripcionController.dispose();
    _seguroController.dispose();
    _mensualidad12Controller.dispose();
    _mensualidad11Controller.dispose();
    _mensualidad10Controller.dispose();
    _anticipado12Controller.dispose();
    _anticipado11Controller.dispose();
    _anticipado10Controller.dispose();
    _recargo12Controller.dispose();
    _recargo11Controller.dispose();
    _recargo10Controller.dispose();
    _sesionController.dispose();
    _paquete4Controller.dispose();
    _paquete6Controller.dispose();
    _paquete8Controller.dispose();
    _inscripcionMaternalController.dispose();
    _notasController.dispose();
    super.dispose();
  }

  Future<void> _revisarColumnasDescuento() async {
    try {
      await _supabase
          .from('configuracion_costos')
          .select('costo_anticipado_12')
          .limit(1);
      _faltanColumnasDescuento = false;
    } catch (e) {
      final t = e.toString();
      _faltanColumnasDescuento = t.contains('42703') ||
          t.contains('costo_anticipado') ||
          t.contains('schema cache');
    }
  }

  Future<void> _cargarConfiguracion() async {
    try {
      await _revisarColumnasDescuento();
      final response = await _supabase
          .from('configuracion_costos')
          .select()
          .eq('vigente', true)
          .order('vigencia_desde', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response != null) {
        _configActual = ConfiguracionCostos.fromJson(response);
        _inscripcionController.text = _configActual!.costoInscripcion.toString();
        _seguroController.text = _configActual!.costoSeguroCredencial.toString();
        _mensualidad12Controller.text = _configActual!.costoMensualidad12.toString();
        _mensualidad11Controller.text = _configActual!.costoMensualidad11.toString();
        _mensualidad10Controller.text = _configActual!.costoMensualidad10.toString();
        _anticipado12Controller.text = _fmtOpcional(_configActual!.costoAnticipado12);
        _anticipado11Controller.text = _fmtOpcional(_configActual!.costoAnticipado11);
        _anticipado10Controller.text = _fmtOpcional(_configActual!.costoAnticipado10);
        _recargo12Controller.text = _fmtOpcional(_configActual!.costoRecargo12);
        _recargo11Controller.text = _fmtOpcional(_configActual!.costoRecargo11);
        _recargo10Controller.text = _fmtOpcional(_configActual!.costoRecargo10);
        _sesionController.text = _numODefault(response['estim_sesion'], 350);
        _paquete4Controller.text = _numODefault(response['estim_paquete_4'], 950);
        _paquete6Controller.text = _numODefault(response['estim_paquete_6'], 1100);
        _paquete8Controller.text = _numODefault(response['estim_paquete_8'], 1150);
        _inscripcionMaternalController.text =
            _numODefault(response['estim_inscripcion_anual'], 1150);
        _notasController.text = _configActual!.notas ?? '';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar configuración: $e')),
        );
      }
    } finally {
      setState(() => _cargando = false);
    }
  }

  Future<void> _guardarConfiguracion() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);

    try {
      final data = {
        'costo_inscripcion': double.parse(_inscripcionController.text),
        'costo_seguro_credencial': double.parse(_seguroController.text),
        'costo_mensualidad_12': double.parse(_mensualidad12Controller.text),
        'costo_mensualidad_11': double.parse(_mensualidad11Controller.text),
        'costo_mensualidad_10': double.parse(_mensualidad10Controller.text),
        'costo_anticipado_12': _montoOpcional(_anticipado12Controller.text),
        'costo_anticipado_11': _montoOpcional(_anticipado11Controller.text),
        'costo_anticipado_10': _montoOpcional(_anticipado10Controller.text),
        'costo_recargo_12': _montoOpcional(_recargo12Controller.text),
        'costo_recargo_11': _montoOpcional(_recargo11Controller.text),
        'costo_recargo_10': _montoOpcional(_recargo10Controller.text),
        'estim_sesion': double.parse(_sesionController.text),
        'estim_paquete_4': double.parse(_paquete4Controller.text),
        'estim_paquete_6': double.parse(_paquete6Controller.text),
        'estim_paquete_8': double.parse(_paquete8Controller.text),
        'estim_inscripcion_anual': double.parse(_inscripcionMaternalController.text),
        'notas': _notasController.text.trim().isEmpty ? null : _notasController.text.trim(),
        'vigente': true,
        'vigencia_desde': DateTime.now().toIso8601String().split('T')[0],
      };

      var extrasOk = true;
      var maternalOk = true;
      try {
        await _persistirConfig(data);
      } catch (e) {
        var payload = Map<String, dynamic>.from(data);
        final faltanDescuento = _errorDeColumna(e, const [
          'costo_anticipado',
          'costo_recargo',
        ]);
        final faltanMaternal = _errorDeColumna(e, const ['estim_']);
        if (!faltanDescuento && !faltanMaternal) rethrow;
        if (faltanDescuento) {
          extrasOk = false;
          payload.removeWhere((k, _) =>
              k.startsWith('costo_anticipado_') || k.startsWith('costo_recargo_'));
        }
        if (faltanMaternal) {
          maternalOk = false;
          payload.removeWhere((k, _) => k.startsWith('estim_'));
        }
        try {
          await _persistirConfig(payload);
        } catch (e2) {
          final faltanDescuento2 = _errorDeColumna(e2, const [
            'costo_anticipado',
            'costo_recargo',
          ]);
          final faltanMaternal2 = _errorDeColumna(e2, const ['estim_']);
          if (!faltanDescuento2 && !faltanMaternal2) rethrow;
          if (faltanDescuento2) {
            extrasOk = false;
            payload.removeWhere((k, _) =>
                k.startsWith('costo_anticipado_') || k.startsWith('costo_recargo_'));
          }
          if (faltanMaternal2) {
            maternalOk = false;
            payload.removeWhere((k, _) => k.startsWith('estim_'));
          }
          await _persistirConfig(payload);
        }
      }

      if (!extrasOk || !maternalOk) {
        if (!mounted) return;
        setState(() {
          _faltanColumnasDescuento = !extrasOk;
          _faltanColumnasMaternal = !maternalOk;
          if (!extrasOk) _resumenGuardado = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              !extrasOk
                  ? 'La mensualidad sí se guardó. El descuento y el recargo no: '
                      'todavía no existen en el sistema. El recuadro naranja dice qué falta.'
                  : 'Kínder sí se guardó. Maternal y lactante no: '
                      'faltan esas columnas. El recuadro naranja dice qué falta.',
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 7),
          ),
        );
        if (!extrasOk) return;
      }

      await _cargarConfiguracion();
      if (!mounted) return;

      final c = _configActual;
      setState(() {
        _faltanColumnasMaternal = false;
        _resumenGuardado = c == null
            ? 'Guardado. Vuelve a abrir esta pantalla para ver los montos.'
            : 'Sí quedó guardado.\n'
                'Descuento por mes 12/11/10: ${_lineaPlan(c.costoAnticipado12, 12)} · '
                '${_lineaPlan(c.costoAnticipado11, 11)} · '
                '${_lineaPlan(c.costoAnticipado10, 10)}\n'
                'Recargo por mes 12/11/10: ${_lineaPlan(c.costoRecargo12, 12)} · '
                '${_lineaPlan(c.costoRecargo11, 11)} · '
                '${_lineaPlan(c.costoRecargo10, 10)}';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configuración guardada. Revisa el recuadro verde abajo.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _persistirConfig(Map<String, dynamic> data) async {
    if (_configActual != null) {
      await _supabase
          .from('configuracion_costos')
          .update(data)
          .eq('id', _configActual!.id);
    } else {
      await _supabase.from('configuracion_costos').insert(data);
    }
  }

  static String _fmt(double v) => '\$${v.toStringAsFixed(2)}';

  static String _fmtOpcional(double? v) {
    if (v == null || v <= 0) return '';
    return v.toString();
  }

  static String _numODefault(dynamic value, num fallback) {
    if (value is num) return value.toDouble().toString();
    return fallback.toString();
  }

  static bool _errorDeColumna(Object error, List<String> pistas) {
    final t = error.toString();
    if (!t.contains('42703') &&
        !t.contains('PGRST204') &&
        !t.contains('schema cache')) {
      return false;
    }
    return pistas.any(t.contains);
  }

  static String _lineaPlan(double? porMes, int meses) {
    if (porMes == null || porMes <= 0) return 'sin cambio';
    return '${_fmt(porMes)} (ciclo ${_fmt(porMes * meses)})';
  }

  static double? _montoOpcional(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return null;
    final n = double.tryParse(t);
    if (n == null || n <= 0) return null;
    return n;
  }

  InputDecoration _fieldDecoration({
    required String label,
    required IconData icon,
    String? hintText,
  }) {
    return InputDecoration(
      labelText: label,
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      filled: true,
      fillColor: Colors.white,
      prefixIcon: Icon(icon, color: AppColors.morado.withValues(alpha: 0.9), size: 22),
      hintText: hintText,
      hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 15),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.morado, width: 2),
      ),
      labelStyle: GoogleFonts.poppins(fontSize: 14, color: AppColors.gris),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FC),
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Text(
          'Configuración de costos',
          style: GoogleFonts.fredoka(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        leading: const CaipiAppBarLeading(),
        actions: [
          Builder(
            builder: (ctx) {
              final canPop = ModalRoute.of(ctx)?.canPop ?? false;
              if (!canPop) {
                return const SizedBox.shrink();
              }
              return IconButton(
                icon: const Icon(Icons.menu_rounded),
                tooltip: 'Menú',
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.home_rounded),
            tooltip: 'Ir al inicio',
            onPressed: () => context.go('/directora'),
          ),
        ],
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.morado, AppColors.purpura],
            ),
          ),
        ),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: AppColors.morado))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildInfoCard(),
                    const SizedBox(height: 20),
                    _encabezadoSeccion(
                      titulo: 'Kínder',
                      detalle:
                          'Colegiatura de 10, 11 o 12 meses. Al dar de alta un niño de kínder se generan estos pagos.',
                      icono: Icons.school_rounded,
                      color: AppColors.morado,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _inscripcionController,
                      decoration: _fieldDecoration(
                        label: 'Inscripción anual de kínder',
                        icon: Icons.school_outlined,
                        hintText: r'0.00',
                      ),
                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      validator: _validarMontoCero,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _seguroController,
                      decoration: _fieldDecoration(
                        label: 'Seguro y credencial de kínder',
                        icon: Icons.health_and_safety_outlined,
                        hintText: r'0.00',
                      ),
                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      validator: _validarMontoCero,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Inscripción y seguro de kínder se guardan como referencia. No se suman solos en los cuadritos; tú eliges si incluirlos.',
                      style: GoogleFonts.poppins(fontSize: 12, color: AppColors.gris),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _mensualidad12Controller,
                      decoration: _fieldDecoration(
                        label: 'Mensualidad de kínder · 12 meses',
                        icon: Icons.calendar_month_outlined,
                        hintText: r'0.00',
                      ),
                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      validator: _validarMonto,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _mensualidad11Controller,
                      decoration: _fieldDecoration(
                        label: 'Mensualidad de kínder · 11 meses',
                        icon: Icons.date_range_outlined,
                        hintText: r'0.00',
                      ),
                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      validator: _validarMonto,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _mensualidad10Controller,
                      decoration: _fieldDecoration(
                        label: 'Mensualidad de kínder · 10 meses',
                        icon: Icons.event_repeat_outlined,
                        hintText: r'0.00',
                      ),
                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      validator: _validarMonto,
                    ),
                    const SizedBox(height: 14),
                    if (_faltanColumnasDescuento) ...[
                      _avisoColumnasFaltantes(),
                      const SizedBox(height: 14),
                    ],
                    TextFormField(
                      controller: _notasController,
                      decoration: _fieldDecoration(
                        label: 'Notas (opcional)',
                        icon: Icons.edit_note_rounded,
                      ).copyWith(
                        alignLabelWithHint: true,
                        hintText: null,
                      ),
                      style: GoogleFonts.poppins(fontSize: 15),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 28),
                    _buildComparativaSection(),
                    const SizedBox(height: 28),
                    _buildSeccionMaternal(),
                    if (_resumenGuardado != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F8F0),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.exitoPago.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.check_circle, color: Color(0xFF166534)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _resumenGuardado!,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  height: 1.4,
                                  color: const Color(0xFF166534),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 28),
                    FilledButton.icon(
                      onPressed: _guardando ? null : _guardarConfiguracion,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.morado,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 2,
                      ),
                      icon: const Icon(Icons.save_rounded, size: 22),
                      label: Text(
                        _guardando ? 'Guardando…' : 'Guardar configuración',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  String? _validarMonto(String? value) {
    if (value == null || value.isEmpty) return 'Obligatorio';
    final monto = double.tryParse(value);
    if (monto == null || monto <= 0) return 'Monto inválido';
    return null;
  }

  String? _validarMontoCero(String? value) {
    if (value == null || value.isEmpty) return 'Obligatorio';
    final monto = double.tryParse(value);
    if (monto == null || monto < 0) return 'Monto inválido';
    return null;
  }

  Widget _avisoColumnasFaltantes() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDBA74)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFC2410C)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'El descuento y el recargo se calculan aquí, pero todavía no se guardan. '
              'Hay que activar esas columnas una sola vez y volver a picar Guardar. '
              'Si sales de esta pantalla, lo escrito en descuento y recargo se pierde.',
              style: GoogleFonts.poppins(
                fontSize: 13,
                height: 1.4,
                color: const Color(0xFF9A3412),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _encabezadoSeccion({
    required String titulo,
    required String detalle,
    required IconData icono,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: GoogleFonts.fredoka(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  detalle,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    height: 1.35,
                    color: AppColors.grisOscuro,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeccionMaternal() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _encabezadoSeccion(
          titulo: 'Maternal y lactante',
          detalle:
              'Precios por sesión o por paquete al mes. Si al niño no le eliges paquete, no se le arma el año.',
          icono: Icons.child_care_rounded,
          color: const Color(0xFF0F766E),
        ),
        const SizedBox(height: 14),
        if (_faltanColumnasMaternal) ...[
          _avisoColumnasFaltantesMaternal(),
          const SizedBox(height: 14),
        ],
        _campoMonto(
          controller: _sesionController,
          label: '1 sesión',
          hint: '350',
          icon: Icons.looks_one_outlined,
        ),
        _campoMonto(
          controller: _paquete4Controller,
          label: 'Paquete de 4 sesiones al mes',
          hint: '950',
          icon: Icons.calendar_view_week_outlined,
        ),
        _campoMonto(
          controller: _paquete6Controller,
          label: 'Paquete de 6 sesiones al mes',
          hint: '1100',
          icon: Icons.groups_outlined,
        ),
        _campoMonto(
          controller: _paquete8Controller,
          label: 'Paquete de 8 sesiones al mes',
          hint: '1150',
          icon: Icons.stacked_bar_chart_rounded,
        ),
        _campoMonto(
          controller: _inscripcionMaternalController,
          label: 'Inscripción anual de maternal / lactante',
          hint: '1150',
          icon: Icons.description_outlined,
        ),
        Text(
          'Al guardar un niño con 8 sesiones, cada mes del ciclo usa el precio de 8 sesiones. '
          'La de 1 sesión no rellena el año: esa clase se carga cuando va.',
          style: GoogleFonts.poppins(fontSize: 12, height: 1.35, color: AppColors.gris),
        ),
      ],
    );
  }

  Widget _avisoColumnasFaltantesMaternal() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDBA74)),
      ),
      child: Text(
        'Estos precios de maternal y lactante todavía no se pueden guardar. '
        'Hay que activar esas columnas una sola vez y volver a picar Guardar.',
        style: GoogleFonts.poppins(
          fontSize: 13,
          height: 1.4,
          color: const Color(0xFF9A3412),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _campoMonto({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        decoration: _fieldDecoration(
          label: label,
          icon: icon,
          hintText: hint,
        ),
        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
        ],
        validator: _validarMonto,
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.morado.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 5,
                color: AppColors.morado,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.morado.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.info_outline_rounded,
                                color: AppColors.morado, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Cómo se usan estos costos',
                              style: GoogleFonts.fredoka(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: AppColors.azulOscuro,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _infoLine('Kínder: al inscribir se elige 10, 11 o 12 meses y se generan las colegiaturas.'),
                      _infoLine('Maternal y lactante: si eliges 1, 4, 6 u 8 sesiones, se usa el precio de esa sección. Si no eliges, no se rellena el año.'),
                      _infoLine('Cambiar un precio aquí no reescribe pagos que ya existen.'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoLine(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppColors.purpura,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 14,
                height: 1.45,
                color: AppColors.grisOscuro,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparativaSection() {
    final mensualidad12 = double.tryParse(_mensualidad12Controller.text) ?? 0;
    final mensualidad11 = double.tryParse(_mensualidad11Controller.text) ?? 0;
    final mensualidad10 = double.tryParse(_mensualidad10Controller.text) ?? 0;
    final inscripcion = double.tryParse(_inscripcionController.text) ?? 0;
    final seguro = double.tryParse(_seguroController.text) ?? 0;

    final subMeses12 = PagoHelpers.totalColegiaturas(mensualidad12, 12);
    final subMeses11 = PagoHelpers.totalColegiaturas(mensualidad11, 11);
    final subMeses10 = PagoHelpers.totalColegiaturas(mensualidad10, 10);
    final totalPlan12 = PagoHelpers.totalPlanMostrado(
      mensualidad: mensualidad12,
      meses: 12,
      inscripcion: inscripcion,
      seguro: seguro,
      sumarInscripcion: _sumarInscripcion,
      sumarSeguro: _sumarSeguro,
    );
    final totalPlan11 = PagoHelpers.totalPlanMostrado(
      mensualidad: mensualidad11,
      meses: 11,
      inscripcion: inscripcion,
      seguro: seguro,
      sumarInscripcion: _sumarInscripcion,
      sumarSeguro: _sumarSeguro,
    );
    final totalPlan10 = PagoHelpers.totalPlanMostrado(
      mensualidad: mensualidad10,
      meses: 10,
      inscripcion: inscripcion,
      seguro: seguro,
      sumarInscripcion: _sumarInscripcion,
      sumarSeguro: _sumarSeguro,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.azulOscuro.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.balance_rounded,
                color: AppColors.azulOscuro,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Planes de kínder',
              style: GoogleFonts.fredoka(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.azulOscuro,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'En cada plan escribe el monto por mes del descuento (1 día antes) y del recargo (desde el día 11). '
          'Abajo se ve al instante cuánto queda el mes y cuánto el ciclo. Vacío = se cobra la mensualidad.',
          style: GoogleFonts.poppins(fontSize: 13, color: AppColors.gris),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilterChip(
              label: const Text('Sumar inscripción'),
              selected: _sumarInscripcion,
              onSelected: (v) => setState(() => _sumarInscripcion = v),
              selectedColor: AppColors.morado.withValues(alpha: 0.22),
              checkmarkColor: AppColors.azulOscuro,
              labelStyle: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.azulOscuro,
              ),
            ),
            FilterChip(
              label: const Text('Sumar seguro'),
              selected: _sumarSeguro,
              onSelected: (v) => setState(() => _sumarSeguro = v),
              selectedColor: AppColors.morado.withValues(alpha: 0.22),
              checkmarkColor: AppColors.azulOscuro,
              labelStyle: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.azulOscuro,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < 720;
            final card12 = _buildPlanCard(
              titulo: 'Dividido a 12 meses',
              subtitulo: PagoHelpers.etiquetaRangoPlan(12),
              mensualidad: mensualidad12,
              meses: 12,
              subtotalMensualidades: subMeses12,
              inscripcion: inscripcion,
              seguro: seguro,
              total: totalPlan12,
              descuentoController: _anticipado12Controller,
              recargoController: _recargo12Controller,
              hintDescuento: '2400',
              hintRecargo: '2650',
              accent: AppColors.exitoPago,
              lightAccent: const Color(0xFFE8F8F0),
            );
            final card11 = _buildPlanCard(
              titulo: 'Dividido a 11 meses',
              subtitulo: PagoHelpers.etiquetaRangoPlan(11),
              mensualidad: mensualidad11,
              meses: 11,
              subtotalMensualidades: subMeses11,
              inscripcion: inscripcion,
              seguro: seguro,
              total: totalPlan11,
              descuentoController: _anticipado11Controller,
              recargoController: _recargo11Controller,
              hintDescuento: '2622',
              hintRecargo: '2898',
              accent: AppColors.azul,
              lightAccent: const Color(0xFFE8F4FC),
            );
            final card10 = _buildPlanCard(
              titulo: 'Dividido a 10 meses',
              subtitulo: PagoHelpers.etiquetaRangoPlan(10),
              mensualidad: mensualidad10,
              meses: 10,
              subtotalMensualidades: subMeses10,
              inscripcion: inscripcion,
              seguro: seguro,
              total: totalPlan10,
              descuentoController: _anticipado10Controller,
              recargoController: _recargo10Controller,
              hintDescuento: '2885',
              hintRecargo: '3187',
              accent: AppColors.purpura,
              lightAccent: const Color(0xFFF3EEFF),
            );
            if (narrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  card12,
                  const SizedBox(height: 12),
                  card11,
                  const SizedBox(height: 12),
                  card10,
                ],
              );
            }
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: card12),
                  const SizedBox(width: 12),
                  Expanded(child: card11),
                  const SizedBox(width: 12),
                  Expanded(child: card10),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPlanCard({
    required String titulo,
    required String subtitulo,
    required double mensualidad,
    required int meses,
    required double subtotalMensualidades,
    required double inscripcion,
    required double seguro,
    required double total,
    required TextEditingController descuentoController,
    required TextEditingController recargoController,
    required String hintDescuento,
    required String hintRecargo,
    required Color accent,
    required Color lightAccent,
  }) {
    return Material(
      elevation: 3,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withValues(alpha: 0.35), width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: lightAccent,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: GoogleFonts.fredoka(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.negro,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitulo,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.grisOscuro,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _fmt(mensualidad),
                    style: GoogleFonts.fredoka(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: accent,
                    ),
                  ),
                  Text(
                    'por mes · $meses pagos',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.grisOscuro,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Divider(height: 1, color: Colors.grey.shade200),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _miniRow('$meses × mensualidad', _fmt(subtotalMensualidades)),
                  _bloqueMonto(
                    titulo: 'Con descuento (1 día antes)',
                    controller: descuentoController,
                    meses: meses,
                    mensualidad: mensualidad,
                    hint: hintDescuento,
                    esDescuento: true,
                  ),
                  _bloqueMonto(
                    titulo: 'Con recargo (desde día 11)',
                    controller: recargoController,
                    meses: meses,
                    mensualidad: mensualidad,
                    hint: hintRecargo,
                    esDescuento: false,
                  ),
                  if (_sumarInscripcion)
                    _miniRow('Inscripción', _fmt(inscripcion)),
                  if (_sumarSeguro) _miniRow('Seguro + credencial', _fmt(seguro)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            (_sumarInscripcion || _sumarSeguro)
                                ? 'Total'
                                : 'Total colegiaturas',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: accent,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _fmt(total),
                          style: GoogleFonts.fredoka(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  double? _guardado(bool esDescuento, int meses) {
    final actual = _configActual;
    if (actual == null) return null;
    if (esDescuento) return actual.anticipadoMensualDePlan(meses);
    return actual.recargoMensualDePlan(meses);
  }

  Widget _bloqueMonto({
    required String titulo,
    required TextEditingController controller,
    required int meses,
    required double mensualidad,
    required String hint,
    required bool esDescuento,
  }) {
    final capturado = _montoOpcional(controller.text);
    final porMes = capturado ?? mensualidad;
    final ciclo = porMes * meses;
    final normal = mensualidad * meses;
    final diferencia = (normal - ciclo).abs();
    final hay = capturado != null;
    final guardado = _guardado(esDescuento, meses);
    final igualGuardado = (capturado == null && (guardado == null || guardado <= 0)) ||
        (capturado != null &&
            guardado != null &&
            (capturado - guardado).abs() < 0.009);

    late final String estado;
    late final Color estadoColor;
    if (_faltanColumnasDescuento && hay) {
      estado = 'Escrito aquí, pero todavía no se puede guardar';
      estadoColor = const Color(0xFFC2410C);
    } else if (!hay) {
      estado = esDescuento
          ? 'Sin descuento: se cobra la mensualidad'
          : 'Sin recargo: se cobra la mensualidad';
      estadoColor = AppColors.gris;
    } else if (igualGuardado && !_faltanColumnasDescuento) {
      estado = 'Guardado';
      estadoColor = const Color(0xFF166534);
    } else {
      estado = 'Todavía no está guardado';
      estadoColor = const Color(0xFFC2410C);
    }

    final nombre = esDescuento ? 'descuento' : 'recargo';

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            titulo,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.azulOscuro,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            estado,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: estadoColor,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: const Color(0xFFF8F7FC),
              labelText: 'Por mes',
              hintText: hint,
              prefixText: r'$ ',
              labelStyle: GoogleFonts.poppins(fontSize: 12, color: AppColors.gris),
              hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade400),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.morado, width: 1.6),
              ),
            ),
            style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
          ),
          const SizedBox(height: 6),
          _miniRow(
            '$meses × $nombre',
            _fmt(ciclo),
            valueColor: hay ? (esDescuento ? const Color(0xFF166534) : const Color(0xFFC2410C)) : null,
          ),
          if (hay && diferencia >= 0.01)
            _miniRow(
              esDescuento ? 'Ahorro en el ciclo' : 'De más en el ciclo',
              _fmt(diferencia),
              valueColor: esDescuento ? const Color(0xFF166534) : const Color(0xFFC2410C),
            ),
        ],
      ),
    );
  }

  Widget _miniRow(String k, String v, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              k,
              style: GoogleFonts.poppins(fontSize: 12, color: AppColors.grisOscuro),
            ),
          ),
          Text(
            v,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppColors.negro,
            ),
          ),
        ],
      ),
    );
  }
}

extension on Color {
  Color darken(double amount) {
    final hsl = HSLColor.fromColor(this);
    final l = (hsl.lightness - amount).clamp(0.0, 1.0);
    return hsl.withLightness(l).toColor();
  }
}
