import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../config/app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/qr_salida_service.dart';

/// Abre la cámara. Devuelve el id del niño si la salida quedó registrada.
Future<String?> abrirEscanerQrSalida(
  BuildContext context, {
  String? alumnoEsperadoId,
}) {
  final user = context.read<AuthService>().currentUser;
  if (user == null || !(user.esDirectora || user.esProfesor)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Solo la profesora o la directora pueden escanear el QR.'),
      ),
    );
    return Future.value(null);
  }
  return Navigator.of(context).push<String?>(
    MaterialPageRoute(
      builder: (_) => EscanearQrSalidaScreen(alumnoEsperadoId: alumnoEsperadoId),
    ),
  );
}

class EscanearQrSalidaScreen extends StatefulWidget {
  const EscanearQrSalidaScreen({super.key, this.alumnoEsperadoId});

  final String? alumnoEsperadoId;

  @override
  State<EscanearQrSalidaScreen> createState() => _EscanearQrSalidaScreenState();
}

class _EscanearQrSalidaScreenState extends State<EscanearQrSalidaScreen> {
  final _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    formats: const [BarcodeFormat.qrCode],
  );
  final _servicio = QrSalidaService();
  bool _procesando = false;

  @override
  void dispose() {
    unawaited(_controller.dispose());
    super.dispose();
  }

  Future<void> _alLeer(BarcodeCapture captura) async {
    if (_procesando) return;
    final raw = captura.barcodes.isEmpty ? null : captura.barcodes.first.rawValue;
    if (raw == null || raw.trim().isEmpty) return;
    _procesando = true;
    await _controller.stop();
    final resultado = await _servicio.procesar(
      raw,
      alumnoEsperadoId: widget.alumnoEsperadoId,
    );
    if (!mounted) return;
    await _mostrarResultado(resultado);
  }

  Future<void> _mostrarResultado(ResultadoQrSalida resultado) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          resultado.salidaRegistrada ? 'Salida registrada' : 'QR no válido',
          style: GoogleFonts.fredoka(),
        ),
        content: Text(resultado.mensaje, style: GoogleFonts.poppins(fontSize: 14)),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(resultado.salidaRegistrada ? 'Listo' : 'Entendido'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (resultado.salidaRegistrada) {
      Navigator.of(context).pop(resultado.alumnoId);
      return;
    }
    _procesando = false;
    try {
      await _controller.start();
    } catch (_) {}
  }

  Future<void> _escribirCodigo() async {
    if (_procesando) return;
    final codigoController = TextEditingController();
    final codigo = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Escribir código', style: GoogleFonts.fredoka()),
        content: TextField(
          controller: codigoController,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
            LengthLimitingTextInputFormatter(8),
          ],
          decoration: const InputDecoration(
            labelText: 'Código de 8 caracteres',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(ctx, codigoController.text.trim().toUpperCase()),
            child: const Text('Validar'),
          ),
        ],
      ),
    );
    if (codigo == null || codigo.isEmpty || !mounted) return;
    _procesando = true;
    await _controller.stop();
    final resultado = await _servicio.procesar(
      codigo,
      alumnoEsperadoId: widget.alumnoEsperadoId,
    );
    if (!mounted) return;
    await _mostrarResultado(resultado);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('Escanear QR', style: GoogleFonts.fredoka()),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _alLeer,
            errorBuilder: (context, error) {
              return ColoredBox(
                color: Colors.black,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Permite el uso de la cámara para escanear el QR de recogida.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
              );
            },
          ),
          IgnorePointer(
            child: Center(
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 3),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              color: Colors.black54,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Apunta al QR que generó el papá. Si no está vigente, se avisa que generen uno nuevo.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _procesando ? null : _controller.toggleTorch,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white54),
                          ),
                          icon: const Icon(Icons.flash_on),
                          label: const Text('Luz'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _procesando ? null : _escribirCodigo,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.purpura,
                          ),
                          icon: const Icon(Icons.keyboard),
                          label: const Text('Escribir'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
