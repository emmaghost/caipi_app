import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/app_colors.dart';
import '../../models/configuracion_costos.dart';
import '../../widgets/app_drawer.dart';

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
  final _notasController = TextEditingController();

  ConfiguracionCostos? _configActual;
  bool _cargando = true;

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
    ]) {
      c.removeListener(_refrescarVista);
    }
    _inscripcionController.dispose();
    _seguroController.dispose();
    _mensualidad12Controller.dispose();
    _mensualidad11Controller.dispose();
    _mensualidad10Controller.dispose();
    _notasController.dispose();
    super.dispose();
  }

  Future<void> _cargarConfiguracion() async {
    try {
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

    try {
      final data = {
        'costo_inscripcion': double.parse(_inscripcionController.text),
        'costo_seguro_credencial': double.parse(_seguroController.text),
        'costo_mensualidad_12': double.parse(_mensualidad12Controller.text),
        'costo_mensualidad_11': double.parse(_mensualidad11Controller.text),
        'costo_mensualidad_10': double.parse(_mensualidad10Controller.text),
        'notas': _notasController.text.trim().isEmpty ? null : _notasController.text.trim(),
        'vigente': true,
        'vigencia_desde': DateTime.now().toIso8601String().split('T')[0],
      };

      if (_configActual != null) {
        await _supabase
            .from('configuracion_costos')
            .update(data)
            .eq('id', _configActual!.id);
      } else {
        await _supabase.from('configuracion_costos').insert(data);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configuración guardada'),
            backgroundColor: Colors.green,
          ),
        );
        // go() deja sin stack: pop() → pantalla negra
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          context.go('/directora');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  static String _fmt(double v) => '\$${v.toStringAsFixed(2)}';

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
        leading: Builder(
          builder: (ctx) {
            final canPop = ModalRoute.of(ctx)?.canPop ?? false;
            if (canPop) {
              return IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                tooltip: 'Volver',
                onPressed: () => Navigator.maybePop(ctx),
              );
            }
            return IconButton(
              icon: const Icon(Icons.menu_rounded),
              tooltip: 'Menú',
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            );
          },
        ),
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
                    Text(
                      'Montos',
                      style: GoogleFonts.fredoka(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.azulOscuro,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Se usan al dar de alta alumnos y para los planes de pago. Montos en pesos (sin símbolo en el campo).',
                      style: GoogleFonts.poppins(fontSize: 13, color: AppColors.gris),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _inscripcionController,
                      decoration: _fieldDecoration(
                        label: 'Inscripción anual (referencia)',
                        icon: Icons.school_outlined,
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
                      controller: _seguroController,
                      decoration: _fieldDecoration(
                        label: 'Seguro + credencial (referencia)',
                        icon: Icons.health_and_safety_outlined,
                        hintText: r'0.00',
                      ),
                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      validator: _validarMonto,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Inscripción y seguro se calculan en costos, pero no aparecen en el cuadro de pagos (solo colegiaturas).',
                      style: GoogleFonts.poppins(fontSize: 12, color: AppColors.gris),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _mensualidad12Controller,
                      decoration: _fieldDecoration(
                        label: 'Mensualidad plan 12 meses',
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
                        label: 'Mensualidad plan 11 meses',
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
                        label: 'Mensualidad plan 10 meses',
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
                    FilledButton.icon(
                      onPressed: _guardarConfiguracion,
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
                        'Guardar configuración',
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
                      _infoLine('Al inscribir se elige plan de 10, 11 o 12 mensualidades.'),
                      _infoLine('Al crear un alumno se generan los pagos según el plan.'),
                      _infoLine('Estos valores aplican a alumnos nuevos con esta configuración.'),
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

    final subMeses12 = mensualidad12 * 12;
    final subMeses11 = mensualidad11 * 11;
    final subMeses10 = mensualidad10 * 10;
    // Totales solo de colegiaturas (sin inscripción ni seguro).
    final totalPlan12 = subMeses12;
    final totalPlan11 = subMeses11;
    final totalPlan10 = subMeses10;

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
              'Comparativa de planes',
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
          'Total = solo colegiaturas (sin inscripción ni seguro).',
          style: GoogleFonts.poppins(fontSize: 13, color: AppColors.gris),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < 720;
            final card12 = _buildPlanCard(
              titulo: '12 mensualidades',
              subtitulo: 'Agosto - Julio',
              mensualidad: mensualidad12,
              meses: 12,
              subtotalMensualidades: subMeses12,
              total: totalPlan12,
              accent: AppColors.exitoPago,
              lightAccent: const Color(0xFFE8F8F0),
            );
            final card11 = _buildPlanCard(
              titulo: '11 mensualidades',
              subtitulo: 'Agosto - Junio',
              mensualidad: mensualidad11,
              meses: 11,
              subtotalMensualidades: subMeses11,
              total: totalPlan11,
              accent: AppColors.azul,
              lightAccent: const Color(0xFFE8F4FC),
            );
            final card10 = _buildPlanCard(
              titulo: '10 mensualidades',
              subtitulo: 'Agosto - Mayo',
              mensualidad: mensualidad10,
              meses: 10,
              subtotalMensualidades: subMeses10,
              total: totalPlan10,
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
    required double total,
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
                            'Total colegiaturas',
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

  Widget _miniRow(String k, String v) {
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
              color: AppColors.negro,
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
