import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../config/app_colors.dart';
import '../../models/pago.dart';
import '../../models/abono.dart';

class RegistrarAbonoScreen extends StatefulWidget {
  final Pago pago;
  final String alumnoNombre;

  const RegistrarAbonoScreen({
    super.key,
    required this.pago,
    required this.alumnoNombre,
  });

  @override
  State<RegistrarAbonoScreen> createState() => _RegistrarAbonoScreenState();
}

class _RegistrarAbonoScreenState extends State<RegistrarAbonoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;

  final _montoController = TextEditingController();
  final _referenciaController = TextEditingController();
  final _notasController = TextEditingController();

  String _formaPago = 'Efectivo';
  DateTime _fechaAbono = DateTime.now();
  bool _guardando = false;
  List<Abono> _abonos = [];
  bool _cargandoAbonos = true;

  @override
  void initState() {
    super.initState();
    // Pre-llenar con el saldo pendiente
    _montoController.text = widget.pago.saldoPendiente.toStringAsFixed(2);
    _cargarAbonos();
  }

  @override
  void dispose() {
    _montoController.dispose();
    _referenciaController.dispose();
    _notasController.dispose();
    super.dispose();
  }

  Future<void> _cargarAbonos() async {
    try {
      final response = await _supabase
          .from('abonos')
          .select()
          .eq('pago_id', widget.pago.id)
          .order('fecha_abono', ascending: false);

      setState(() {
        _abonos = response.map((json) => Abono.fromJson(json)).toList();
        _cargandoAbonos = false;
      });
    } catch (e) {
      setState(() => _cargandoAbonos = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando abonos: $e')),
        );
      }
    }
  }

  Future<void> _registrarAbono() async {
    if (!_formKey.currentState!.validate()) return;

    final monto = double.tryParse(_montoController.text);
    if (monto == null || monto <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingrese un monto válido')),
      );
      return;
    }

    // Validar que no exceda el saldo pendiente
    if (monto > widget.pago.saldoPendiente) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'El monto no puede ser mayor al saldo pendiente (\$${widget.pago.saldoPendiente.toStringAsFixed(2)})'
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _guardando = true);

    try {
      // Obtener ID del usuario actual
      final userId = _supabase.auth.currentUser?.id;

      // Insertar abono
      await _supabase.from('abonos').insert({
        'pago_id': widget.pago.id,
        'monto': monto,
        'fecha_abono': _fechaAbono.toIso8601String().split('T')[0],
        'forma_pago': _formaPago,
        'referencia': _referenciaController.text.trim().isEmpty
            ? null
            : _referenciaController.text.trim(),
        'notas': _notasController.text.trim().isEmpty
            ? null
            : _notasController.text.trim(),
        'created_by': userId,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Abono registrado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Indicar que se guardó
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _guardando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Abono'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: AppColors.gradienteArcoiris,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Información del pago
            _buildInfoPagoCard(),
            const SizedBox(height: 20),

            // Historial de abonos
            if (_abonos.isNotEmpty) ...[
              _buildHistorialAbonos(),
              const SizedBox(height: 20),
            ],

            // Formulario de abono
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Nuevo Abono',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.azulOscuro,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Monto
                  TextFormField(
                    controller: _montoController,
                    decoration: InputDecoration(
                      labelText: 'Monto del abono',
                      prefixText: '\$',
                      prefixIcon: Icon(Icons.attach_money, color: AppColors.verde),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      helperText: 'Máximo: \$${widget.pago.saldoPendiente.toStringAsFixed(2)}',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ingrese el monto';
                      }
                      final monto = double.tryParse(value);
                      if (monto == null || monto <= 0) {
                        return 'Monto inválido';
                      }
                      if (monto > widget.pago.saldoPendiente) {
                        return 'Excede el saldo pendiente';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Forma de pago
                  DropdownButtonFormField<String>(
                    value: _formaPago,
                    decoration: InputDecoration(
                      labelText: 'Forma de pago',
                      prefixIcon: Icon(Icons.payment, color: AppColors.morado),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Efectivo', child: Text('Efectivo')),
                      DropdownMenuItem(value: 'Transferencia', child: Text('Transferencia')),
                      DropdownMenuItem(value: 'Tarjeta', child: Text('Tarjeta')),
                      DropdownMenuItem(value: 'Cheque', child: Text('Cheque')),
                    ],
                    onChanged: (value) {
                      setState(() => _formaPago = value!);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Fecha del abono
                  InkWell(
                    onTap: () async {
                      final fecha = await showDatePicker(
                        context: context,
                        initialDate: _fechaAbono,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                        locale: const Locale('es', 'MX'),
                      );
                      if (fecha != null) {
                        setState(() => _fechaAbono = fecha);
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Fecha del abono',
                        prefixIcon: Icon(Icons.calendar_today, color: AppColors.naranja),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        DateFormat('dd/MM/yyyy').format(_fechaAbono),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Referencia (opcional)
                  TextFormField(
                    controller: _referenciaController,
                    decoration: InputDecoration(
                      labelText: 'Referencia (opcional)',
                      hintText: 'Número de transacción, recibo, etc.',
                      prefixIcon: Icon(Icons.confirmation_number, color: AppColors.azul),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Notas (opcional)
                  TextFormField(
                    controller: _notasController,
                    decoration: InputDecoration(
                      labelText: 'Notas (opcional)',
                      prefixIcon: Icon(Icons.note, color: AppColors.gris),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),

                  // Botón de guardar
                  ElevatedButton.icon(
                    onPressed: _guardando ? null : _registrarAbono,
                    icon: _guardando
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.save, color: Colors.white),
                    label: Text(
                      _guardando ? 'Guardando...' : 'Registrar Abono',
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.verde,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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

  Widget _buildInfoPagoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Información del Pago',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.azulOscuro,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.person, 'Alumno', widget.alumnoNombre),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.description, 'Concepto', widget.pago.concepto ?? 'Sin concepto'),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.attach_money, 'Monto Total', '\$${widget.pago.monto.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.payments, 'Pagado', '\$${widget.pago.montoPagado.toStringAsFixed(2)}', color: Colors.green),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.account_balance_wallet, 'Saldo Pendiente', '\$${widget.pago.saldoPendiente.toStringAsFixed(2)}', color: Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color ?? AppColors.gris),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: color != null ? FontWeight.bold : null,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildHistorialAbonos() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Historial de Abonos',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.azulOscuro,
              ),
            ),
            const SizedBox(height: 12),
            ..._abonos.map((abono) => _buildAbonoItem(abono)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildAbonoItem(Abono abono) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  abono.montoFormateado,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '${abono.fechaFormateada} • ${abono.formaPago ?? "Sin especificar"}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
                if (abono.reciboFolio != null)
                  Text(
                    'Folio: ${abono.reciboFolio}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
