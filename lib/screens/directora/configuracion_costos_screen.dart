import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/app_colors.dart';
import '../../models/configuracion_costos.dart';

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
  final _mensualidad10Controller = TextEditingController();
  final _notasController = TextEditingController();

  ConfiguracionCostos? _configActual;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarConfiguracion();
  }

  @override
  void dispose() {
    _inscripcionController.dispose();
    _seguroController.dispose();
    _mensualidad12Controller.dispose();
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
        'costo_mensualidad_10': double.parse(_mensualidad10Controller.text),
        'notas': _notasController.text.trim().isEmpty ? null : _notasController.text.trim(),
        'vigente': true,
        'vigencia_desde': DateTime.now().toIso8601String().split('T')[0],
      };

      if (_configActual != null) {
        // Actualizar
        await _supabase
            .from('configuracion_costos')
            .update(data)
            .eq('id', _configActual!.id);
      } else {
        // Crear
        await _supabase.from('configuracion_costos').insert(data);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Configuración guardada'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración de Costos'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: AppColors.gradienteArcoiris,
          ),
        ),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildInfoCard(),
                    const SizedBox(height: 20),
                    _buildCostoField(
                      controller: _inscripcionController,
                      label: '💰 Costo de Inscripción Anual',
                      icon: Icons.school,
                    ),
                    const SizedBox(height: 16),
                    _buildCostoField(
                      controller: _seguroController,
                      label: '🏥 Costo Seguro + Credencial',
                      icon: Icons.credit_card,
                    ),
                    const SizedBox(height: 16),
                    _buildCostoField(
                      controller: _mensualidad12Controller,
                      label: '📅 Mensualidad (Plan 12 meses)',
                      icon: Icons.calendar_month,
                    ),
                    const SizedBox(height: 16),
                    _buildCostoField(
                      controller: _mensualidad10Controller,
                      label: '📅 Mensualidad (Plan 10 meses)',
                      icon: Icons.calendar_today,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _notasController,
                      decoration: InputDecoration(
                        labelText: '📝 Notas (opcional)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.notes),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),
                    _buildComparativaCard(),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _guardarConfiguracion,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.morado,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        '💾 Guardar Configuración',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      color: AppColors.rosa.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.rosa, size: 28),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Configuración de Costos',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              '• Los padres podrán elegir entre plan de 10 o 12 meses al inscribir a su hijo.\n'
              '• Al crear un alumno, se generarán automáticamente todos los pagos según el plan elegido.\n'
              '• Estos costos se aplicarán a todos los nuevos alumnos.',
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCostoField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        prefixIcon: Icon(icon),
        prefixText: '\$',
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
      ],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Este campo es obligatorio';
        }
        final monto = double.tryParse(value);
        if (monto == null || monto <= 0) {
          return 'Ingrese un monto válido';
        }
        return null;
      },
    );
  }

  Widget _buildComparativaCard() {
    final inscripcion = double.tryParse(_inscripcionController.text) ?? 0;
    final seguro = double.tryParse(_seguroController.text) ?? 0;
    final mensualidad12 = double.tryParse(_mensualidad12Controller.text) ?? 0;
    final mensualidad10 = double.tryParse(_mensualidad10Controller.text) ?? 0;

    final totalPlan12 = inscripcion + seguro + (mensualidad12 * 12);
    final totalPlan10 = inscripcion + seguro + (mensualidad10 * 10);

    return Card(
      color: AppColors.azulOscuro.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📊 Comparativa de Planes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.azulOscuro,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildPlanCard(
                    titulo: 'Plan 12 Meses',
                    mensualidad: mensualidad12,
                    total: totalPlan12,
                    color: AppColors.morado,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPlanCard(
                    titulo: 'Plan 10 Meses',
                    mensualidad: mensualidad10,
                    total: totalPlan10,
                    color: AppColors.naranja,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard({
    required String titulo,
    required double mensualidad,
    required double total,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '\$${mensualidad.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text(
            'por mes',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const Divider(height: 16),
          Text(
            'Total: \$${total.toStringAsFixed(2)}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
