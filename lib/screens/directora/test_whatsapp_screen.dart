import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/whatsapp_service.dart';
import '../../config/app_colors.dart';

/// Prueba Twilio + vista previa de plantillas (adeudo vs pago de mes).
class TestWhatsAppScreen extends StatefulWidget {
  const TestWhatsAppScreen({super.key});

  @override
  State<TestWhatsAppScreen> createState() => _TestWhatsAppScreenState();
}

enum _PlantillaDemo { pruebaTwilio, adeudo, pagoMes }

class _TestWhatsAppScreenState extends State<TestWhatsAppScreen> {
  final _telefonoController = TextEditingController();
  final _mensajeController = TextEditingController();

  _PlantillaDemo _plantilla = _PlantillaDemo.pruebaTwilio;

  bool _enviando = false;
  String? _resultado;

  @override
  void initState() {
    super.initState();
    _mensajeController.text = _textoPlantilla(_PlantillaDemo.pruebaTwilio);
  }

  String _textoPlantilla(_PlantillaDemo p) {
    switch (p) {
      case _PlantillaDemo.pruebaTwilio:
        return '🏫 CAIPI - Mensaje de Prueba\n\n'
            'Este es un mensaje de prueba del sistema CAIPI.\n\n'
            'Si recibes este mensaje, significa que WhatsApp está funcionando correctamente. ✅';
      case _PlantillaDemo.adeudo:
        return WhatsAppService.mensajePagoPendiente(
          nombrePadre: 'María Pérez',
          nombreAlumno: 'Ana García',
          concepto: 'Colegiatura marzo 2026',
          monto: '1,500.00',
          fechaVencimiento: '10/03/2026',
        );
      case _PlantillaDemo.pagoMes:
        return WhatsAppService.mensajePagoRegistrado(
          nombrePadre: 'María Pérez',
          nombreAlumno: 'Ana García',
          concepto: 'Colegiatura',
          monto: '1,500.00',
          periodoEtiqueta: 'Marzo 2026',
          fechaPago: '27/03/2026',
        );
    }
  }

  void _aplicarPlantilla(_PlantillaDemo p) {
    setState(() {
      _plantilla = p;
      _mensajeController.text = _textoPlantilla(p);
    });
  }

  @override
  void dispose() {
    _telefonoController.dispose();
    _mensajeController.dispose();
    super.dispose();
  }

  Future<void> _abrirWhatsAppConTextoActual() async {
    if (_telefonoController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un número (10 dígitos)')),
      );
      return;
    }
    if (!WhatsAppService.validarTelefono(_telefonoController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Número inválido (10 dígitos, sin espacios raros)'),
        ),
      );
      return;
    }
    final soloNumeros =
        _telefonoController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final codigo =
        soloNumeros.length == 10 ? '52$soloNumeros' : soloNumeros;
    final uri = Uri.parse(
      'https://wa.me/$codigo?text=${Uri.encodeComponent(_mensajeController.text)}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo abrir WhatsApp'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _enviarMensajePrueba() async {
    // Validar teléfono
    if (_telefonoController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un número de teléfono')),
      );
      return;
    }

    if (!WhatsAppService.validarTelefono(_telefonoController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Número de teléfono inválido (debe tener 10 dígitos)')),
      );
      return;
    }

    setState(() {
      _enviando = true;
      _resultado = null;
    });

    try {
      final exito = await WhatsAppService.enviarMensaje(
        telefono: _telefonoController.text,
        mensaje: _mensajeController.text,
      );

      setState(() {
        if (exito) {
          _resultado = '✅ ¡Mensaje enviado correctamente!\n\n'
                      'Revisa WhatsApp en el número: ${_telefonoController.text}';
        } else {
          _resultado = '❌ Error al enviar mensaje.\n\n'
                      'Verifica:\n'
                      '1. Credenciales de Twilio\n'
                      '2. El número debe estar unido al sandbox\n'
                      '3. Que tengas crédito en Twilio';
        }
      });

      if (exito && mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('✅ ¡Éxito!'),
            content: const Text(
              'WhatsApp enviado correctamente.\n\n'
              'Revisa tu teléfono.'
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() {
        _resultado = '❌ Error: $e';
      });
    } finally {
      setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Volver',
        ),
        title: const Text('Prueba de WhatsApp'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: AppColors.gradienteArcoiris,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        const Text(
                          'Pantalla de Prueba',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '• Twilio: envía el mensaje desde el servidor (sandbox / producción).\n'
                      '• wa.me: abre WhatsApp con el texto listo (igual que WhatsApp adeudos en Pagos).\n\n'
                      'Pagos: en Gestión de pagos, "WhatsApp adeudos" solo sale con un alumno elegido, sin filtro Pagados, y con pagos vencidos. Si el mes ya está pagado, no aparece: usa el chip Pagados para comprobarlo.\n\n'
                      'Sandbox Twilio: el número debe estar unido al sandbox.',
                      style: TextStyle(fontSize: 13, height: 1.45),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Plantilla de ejemplo',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Prueba Twilio'),
                  selected: _plantilla == _PlantillaDemo.pruebaTwilio,
                  onSelected: (_) => _aplicarPlantilla(_PlantillaDemo.pruebaTwilio),
                ),
                ChoiceChip(
                  label: const Text('Adeudo / mes pendiente'),
                  selected: _plantilla == _PlantillaDemo.adeudo,
                  onSelected: (_) => _aplicarPlantilla(_PlantillaDemo.adeudo),
                ),
                ChoiceChip(
                  label: const Text('Pago ya registrado'),
                  selected: _plantilla == _PlantillaDemo.pagoMes,
                  onSelected: (_) => _aplicarPlantilla(_PlantillaDemo.pagoMes),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Campo de teléfono
            TextField(
              controller: _telefonoController,
              decoration: InputDecoration(
                labelText: 'Número de teléfono',
                hintText: '5551234567',
                prefixIcon: const Icon(Icons.phone),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                helperText: 'Solo números, 10 dígitos',
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),

            // Campo de mensaje
            TextField(
              controller: _mensajeController,
              decoration: InputDecoration(
                labelText: 'Mensaje',
                prefixIcon: const Icon(Icons.message),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 20),

            OutlinedButton.icon(
              onPressed: _abrirWhatsAppConTextoActual,
              icon: const Icon(Icons.open_in_new, color: Color(0xFF25D366)),
              label: const Text(
                'Abrir WhatsApp con este texto (wa.me)',
                style: TextStyle(color: Color(0xFF128C7E)),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF25D366)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: _enviando ? null : _enviarMensajePrueba,
              icon: _enviando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.cloud_upload, color: Colors.white),
              label: Text(
                _enviando ? 'Enviando...' : 'Enviar vía Twilio (API)',
                style: const TextStyle(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Resultado
            if (_resultado != null)
              Card(
                color: _resultado!.contains('✅') 
                    ? Colors.green.shade50 
                    : Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _resultado!,
                    style: const TextStyle(fontSize: 14, height: 1.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
