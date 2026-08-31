import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/supabase_service.dart';
import '../../services/recibo_pago_pdf.dart';
import '../../models/pago.dart';
import '../../models/alumno.dart';
import '../../config/app_colors.dart';
import '../../utils/constantes.dart';

class AcreditarPagoScreen extends StatefulWidget {
  final String pagoId;

  const AcreditarPagoScreen({super.key, required this.pagoId});

  @override
  State<AcreditarPagoScreen> createState() => _AcreditarPagoScreenState();
}

class _AcreditarPagoScreenState extends State<AcreditarPagoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _referenciaController = TextEditingController();
  final _montoController = TextEditingController();
  final _comentarioController = TextEditingController();

  String? _metodoPago = 'Efectivo';
  final Set<String> _pagadoA = {};
  bool _isLoading = true;
  bool _isSaving = false;
  Pago? _pago;
  Alumno? _alumno;

  final List<Map<String, dynamic>> _metodosPago = [
    {'valor': 'Efectivo', 'icono': Icons.money, 'color': AppColors.verde},
    {'valor': 'Transferencia', 'icono': Icons.account_balance, 'color': AppColors.azul},
    {'valor': 'Tarjeta', 'icono': Icons.credit_card, 'color': AppColors.purpura},
  ];

  String get _pagadoATexto => _pagadoA.join(', ');

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    try {
      final supabaseService = context.read<SupabaseService>();

      _pago = await supabaseService.obtenerPagoPorId(widget.pagoId);

      if (_pago == null) {
        throw Exception('Pago no encontrado');
      }

      _alumno = await supabaseService.obtenerAlumnoPorId(_pago!.alumnoId);

      if (_alumno == null) {
        throw Exception('Alumno no encontrado');
      }

      _montoController.text = _pago!.saldoPendiente.toStringAsFixed(2);
      if (_pago!.notas != null && _pago!.notas!.trim().isNotEmpty) {
        _comentarioController.text = _pago!.notas!;
      }
      setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.rojo),
        );
        context.pop();
      }
    }
  }

  Future<void> _acreditarPago() async {
    if (!_formKey.currentState!.validate()) return;

    if (_pagadoA.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona al menos una cuenta'),
          backgroundColor: AppColors.rojo,
        ),
      );
      return;
    }

    final montoAbonar = double.tryParse(_montoController.text.replaceAll(',', '.')) ?? 0;
    if (montoAbonar <= 0 || montoAbonar > _pago!.saldoPendiente) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Monto inválido. Saldo pendiente: \$${_pago!.saldoPendiente.toStringAsFixed(2)}',
          ),
          backgroundColor: AppColors.rojo,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final supabaseService = context.read<SupabaseService>();

      final abono = await supabaseService.acreditarPagoParcial(
        pagoId: widget.pagoId,
        montoAbonar: montoAbonar,
        metodoPago: _metodoPago!,
        recibidoPorNombre: _pagadoATexto,
        referencia: _referenciaController.text.trim().isEmpty
            ? null
            : _referenciaController.text.trim(),
        notas: _comentarioController.text.trim().isEmpty
            ? null
            : _comentarioController.text.trim(),
      );

      if (mounted) {
        final msg = montoAbonar >= _pago!.saldoPendiente
            ? '¡Pago acreditado! Cuenta: $_pagadoATexto'
            : 'Abono registrado (\$${montoAbonar.toStringAsFixed(2)}). Cuenta: $_pagadoATexto · Pendiente: \$${(_pago!.saldoPendiente - montoAbonar).toStringAsFixed(2)}';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: AppColors.verde,
            duration: const Duration(seconds: 3),
          ),
        );
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            icon: const Icon(
              Icons.check_circle,
              color: AppColors.verde,
              size: 48,
            ),
            title: const Text('Pago registrado'),
            content: Text(
              'Folio: ${abono.reciboFolio ?? 'generado'}\n\n'
              'Puedes enviar el recibo PDF por WhatsApp, correo '
              'o cualquier aplicación disponible en el teléfono.',
              textAlign: TextAlign.center,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cerrar'),
              ),
              FilledButton.icon(
                onPressed: () async {
                  try {
                    await ReciboPagoPdf.compartir(
                      abono: abono,
                      pago: _pago!,
                      alumno: _alumno!,
                    );
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('No se pudo compartir el recibo: $e'),
                        backgroundColor: AppColors.rojo,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Compartir PDF'),
              ),
            ],
          ),
        );
        if (!mounted) return;
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al acreditar pago: $e'),
            backgroundColor: AppColors.rojo,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    _referenciaController.dispose();
    _montoController.dispose();
    _comentarioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.grisClaro,
      appBar: AppBar(
        title: Text(
          'Acreditar Pago',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(20, 20, 20, 12 + bottomInset),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildInfoAlumno(),
                          const SizedBox(height: 24),
                          _buildMontoField(),
                          const SizedBox(height: 24),
                          _buildMetodoPago(),
                          const SizedBox(height: 24),
                          _buildPagadoA(),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: _referenciaController,
                            decoration: InputDecoration(
                              labelText: 'Número de recibo (opcional)',
                              hintText: 'Ej: REC-001',
                              prefixIcon: const Icon(Icons.receipt_long, color: AppColors.naranja),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            textCapitalization: TextCapitalization.characters,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _comentarioController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              labelText: 'Comentario (opcional)',
                              hintText: 'Notas sobre este pago…',
                              prefixIcon: const Icon(Icons.comment_outlined, color: AppColors.gris),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            textCapitalization: TextCapitalization.sentences,
                          ),
                        ],
                      ),
                    ),
                  ),
                  _buildBotonAcreditar(bottomInset),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoAlumno() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.purpura.withOpacity(0.2),
            child: Text(
              _alumno!.nombre.substring(0, 1).toUpperCase(),
              style: GoogleFonts.poppins(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.purpura,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _alumno!.nombreCompleto,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.azulClaro,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.azul.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Concepto del pago',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gris,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _pago!.descripcionCompleta,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.azulOscuro,
                  ),
                ),
                if (_pago!.concepto != null &&
                    _pago!.mes != null &&
                    _pago!.concepto!.trim().isNotEmpty &&
                    _pago!.concepto!.trim() != _pago!.mes!.trim()) ...[
                  const SizedBox(height: 4),
                  Text(
                    _pago!.concepto!,
                    style: GoogleFonts.poppins(fontSize: 13, color: AppColors.gris),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.verde, AppColors.turquesa],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Total: \$${_pago!.monto.toStringAsFixed(2)}',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          if (_pago!.montoPagado > 0) ...[
            const SizedBox(height: 8),
            Text(
              'Pagado: \$${_pago!.montoPagado.toStringAsFixed(2)} · Saldo: \$${_pago!.saldoPendiente.toStringAsFixed(2)}',
              style: GoogleFonts.poppins(fontSize: 13, color: AppColors.gris),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMontoField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Monto a acreditar',
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _montoController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: 'Máx. \$${_pago!.saldoPendiente.toStringAsFixed(2)}',
            prefixText: '\$ ',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            filled: true,
            fillColor: Colors.white,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) return 'Ingresa el monto';
            final n = double.tryParse(value.replaceAll(',', '.'));
            if (n == null || n <= 0) return 'Monto inválido';
            if (n > _pago!.saldoPendiente) {
              return 'Máximo \$${_pago!.saldoPendiente.toStringAsFixed(2)}';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildMetodoPago() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Método de pago',
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ..._metodosPago.map((metodo) {
          final isSelected = _metodoPago == metodo['valor'];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () => setState(() => _metodoPago = metodo['valor'] as String),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? (metodo['color'] as Color) : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(metodo['icono'] as IconData, color: metodo['color'] as Color),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        metodo['valor'] as String,
                        style: GoogleFonts.poppins(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Icon(Icons.check_circle, color: metodo['color'] as Color),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPagadoA() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cuenta',
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Elige una o varias cuentas destino',
          style: GoogleFonts.poppins(fontSize: 12, color: AppColors.gris),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: Constantes.opcionesPagadoA.map((opcion) {
            final selected = _pagadoA.contains(opcion);
            return FilterChip(
              label: Text(opcion),
              selected: selected,
              onSelected: (value) {
                setState(() {
                  if (value) {
                    _pagadoA.add(opcion);
                  } else {
                    _pagadoA.remove(opcion);
                  }
                });
              },
              selectedColor: AppColors.rosa.withOpacity(0.35),
              checkmarkColor: AppColors.morado,
              labelStyle: GoogleFonts.poppins(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBotonAcreditar(double bottomInset) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + bottomInset),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SizedBox(
        height: 52,
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _isSaving ? null : _acreditarPago,
          icon: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.check_circle, color: Colors.white),
          label: Text(
            _isSaving ? 'Acreditando…' : 'Acreditar pago',
            style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.verde,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
    );
  }
}
