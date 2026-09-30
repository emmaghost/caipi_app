import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_colors.dart';
import '../services/app_actualizacion_service.dart';

/// Pantalla bloqueante: no hay atrás. El botón abre Play Store o App Store.
class ActualizarAppScreen extends StatelessWidget {
  final AppActualizacionService actualizacion;

  const ActualizarAppScreen({super.key, required this.actualizacion});

  Future<void> _abrirTienda(BuildContext context) async {
    final raw = actualizacion.urlTienda.trim();
    final uri = Uri.tryParse(raw);
    if (uri == null || !uri.hasScheme) {
      _aviso(context, 'No hay enlace de ${actualizacion.nombreTienda}.');
      return;
    }
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        _aviso(context, 'No se pudo abrir ${actualizacion.nombreTienda}.');
      }
    } catch (_) {
      if (context.mounted) {
        _aviso(context, 'No se pudo abrir ${actualizacion.nombreTienda}.');
      }
    }
  }

  void _aviso(BuildContext context, String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.purpura,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                const Spacer(),
                const Icon(Icons.system_update_alt, size: 72, color: Colors.white),
                const SizedBox(height: 20),
                Text(
                  'Actualiza CAIPI',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.fredoka(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  actualizacion.mensaje,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    height: 1.4,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: () => _abrirTienda(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.purpura,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.shop),
                    label: Text(
                      'Abrir ${actualizacion.nombreTienda}',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'En iPhone abre App Store. En Android abre Play Store.',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
