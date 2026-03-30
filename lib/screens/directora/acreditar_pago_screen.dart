import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../services/supabase_service.dart';
import '../../models/pago.dart';
import '../../models/alumno.dart';
import '../../config/app_colors.dart';

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
  final _otroNombreController = TextEditingController();

  String? _metodoPago = 'Efectivo';
  String? _recibidoPor = 'directora';
  bool _isLoading = true;
  bool _isSaving = false;
  Pago? _pago;
  Alumno? _alumno;

  final List<Map<String, dynamic>> _metodosPago = [
    {'valor': 'Efectivo', 'icono': Icons.money, 'color': AppColors.verde},
    {'valor': 'Transferencia', 'icono': Icons.account_balance, 'color': AppColors.azul},
    {'valor': 'Tarjeta', 'icono': Icons.credit_card, 'color': AppColors.purpura},
  ];

  final List<Map<String, dynamic>> _receptores = [
    {'valor': 'directora', 'nombre': 'Directora', 'icono': Icons.person},
    {'valor': 'joss', 'nombre': 'Joss', 'icono': Icons.person_outline},
    {'valor': 'otro', 'nombre': 'Otro (escribir quién recibió)', 'icono': Icons.edit_note},
  ];

  String _nombreQuienRecibio() {
    switch (_recibidoPor) {
      case 'joss':
        return 'Joss';
      case 'otro':
        final t = _otroNombreController.text.trim();
        return t.isEmpty ? 'Otro' : t;
      default:
        return 'Directora';
    }
  }

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    try {
      final supabaseService = context.read<SupabaseService>();
      
      // Cargar pago
      _pago = await supabaseService.obtenerPagoPorId(widget.pagoId);
      
      if (_pago == null) {
        throw Exception('Pago no encontrado');
      }
      
      // Cargar alumno
      _alumno = await supabaseService.obtenerAlumnoPorId(_pago!.alumnoId);
      
      if (_alumno == null) {
        throw Exception('Alumno no encontrado');
      }
      
      _montoController.text = _pago!.saldoPendiente.toStringAsFixed(2);
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

    if (_recibidoPor == 'otro' && _otroNombreController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Escribe quién recibió el pago'),
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
      
      await supabaseService.acreditarPagoParcial(
        pagoId: widget.pagoId,
        montoAbonar: montoAbonar,
        metodoPago: _metodoPago!,
        recibidoPorNombre: _nombreQuienRecibio(),
        referencia: _referenciaController.text.trim().isEmpty
            ? null
            : _referenciaController.text.trim(),
      );

      if (mounted) {
        final quien = _nombreQuienRecibio();
        final msg = montoAbonar >= _pago!.saldoPendiente
            ? '¡Pago acreditado! Lo recibió: $quien'
            : 'Abono registrado (\$${montoAbonar.toStringAsFixed(2)}). Lo recibió: $quien · Pendiente: \$${(_pago!.saldoPendiente - montoAbonar).toStringAsFixed(2)}';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: AppColors.verde,
            duration: const Duration(seconds: 3),
          ),
        );
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
    _otroNombreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Información del alumno
                    Container(
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
                          const SizedBox(height: 8),
                          Text(
                            _pago!.concepto ?? 'Sin concepto',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: AppColors.gris,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppColors.verde, AppColors.turquesa],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '\$${_pago!.monto.toStringAsFixed(2)}',
                              style: GoogleFonts.poppins(
                                fontSize: 28,
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
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: AppColors.gris,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Monto a acreditar (permite pagos parciales)
                    Text(
                      'Monto a acreditar',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _montoController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        hintText: 'Máx. \$${_pago!.saldoPendiente.toStringAsFixed(2)}',
                        prefixText: '\$ ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
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
                    const SizedBox(height: 24),

                    // Método de pago
                    Text(
                      'Método de Pago',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._metodosPago.map((metodo) {
                      final isSelected = _metodoPago == metodo['valor'];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () {
                            setState(() => _metodoPago = metodo['valor'] as String);
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected 
                                    ? (metodo['color'] as Color)
                                    : Colors.grey.shade300,
                                width: isSelected ? 2 : 1,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: (metodo['color'] as Color).withOpacity(0.3),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: (metodo['color'] as Color).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    metodo['icono'] as IconData,
                                    color: metodo['color'] as Color,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    metodo['valor'] as String,
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: isSelected 
                                          ? FontWeight.bold 
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Icon(
                                    Icons.check_circle,
                                    color: metodo['color'] as Color,
                                    size: 24,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 24),

                    // Recibido por
                    Text(
                      'Recibido por',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._receptores.map((receptor) {
                      final isSelected = _recibidoPor == receptor['valor'];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () {
                            setState(() => _recibidoPor = receptor['valor'] as String);
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected 
                                    ? AppColors.rosa
                                    : Colors.grey.shade300,
                                width: isSelected ? 2 : 1,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: AppColors.rosa.withOpacity(0.3),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.rosa.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    receptor['icono'] as IconData,
                                    color: AppColors.rosa,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    receptor['nombre'] as String,
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: isSelected 
                                          ? FontWeight.bold 
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(
                                    Icons.check_circle,
                                    color: AppColors.rosa,
                                    size: 24,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                    if (_recibidoPor == 'otro') ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _otroNombreController,
                        decoration: InputDecoration(
                          labelText: 'Nombre de quien recibió *',
                          hintText: 'Ej: María, contadora…',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        textCapitalization: TextCapitalization.words,
                      ),
                    ],
                    const SizedBox(height: 24),

                    // Referencia/Recibo
                    TextFormField(
                      controller: _referenciaController,
                      decoration: InputDecoration(
                        labelText: 'Número de Recibo (opcional)',
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
                    const SizedBox(height: 32),

                    // Botón acreditar
                    Container(
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.verde, AppColors.turquesa],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.verde.withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _acreditarPago,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(Icons.check_circle, color: Colors.white),
                        label: Text(
                          _isSaving ? 'Acreditando...' : 'Acreditar Pago',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
