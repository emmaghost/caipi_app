import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../config/app_colors.dart';

class QrTemporalScreen extends StatelessWidget {
  final String codigo;
  final String nombrePersona;
  final String alumnoNombre;
  final DateTime? fechaExpiracion;

  const QrTemporalScreen({
    super.key,
    required this.codigo,
    required this.nombrePersona,
    required this.alumnoNombre,
    this.fechaExpiracion,
  });

  @override
  Widget build(BuildContext context) {
    final fechaExpiracion =
        this.fechaExpiracion ?? DateTime.now().add(const Duration(hours: 24));
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'QR Temporal',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.morado,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _compartirQr(context),
            tooltip: 'Compartir',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.morado.withOpacity(0.05),
              Colors.white,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Título
            Text(
              '🎫 Pase Temporal',
              textAlign: TextAlign.center,
              style: GoogleFonts.fredoka(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.morado,
              ),
            ),
            const SizedBox(height: 8),
            
            Text(
              'Un solo uso - 24 horas',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Card con QR
            Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    colors: [Colors.white, AppColors.morado.withOpacity(0.02)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  children: [
                    // QR Code
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.morado.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: QrImageView(
                        data: codigo,
                        version: QrVersions.auto,
                        size: 250,
                        backgroundColor: Colors.white,
                        embeddedImage: const AssetImage('assets/images/icono_caipi.png'),
                        embeddedImageStyle: QrEmbeddedImageStyle(
                          size: const Size(50, 50),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Código
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                      decoration: BoxDecoration(
                        color: AppColors.morado.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            codigo,
                            style: GoogleFonts.firaCode(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.morado,
                              letterSpacing: 4,
                            ),
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            icon: const Icon(Icons.copy, size: 20),
                            color: AppColors.morado,
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: codigo));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '✅ Código copiado',
                                    style: GoogleFonts.poppins(),
                                  ),
                                  backgroundColor: AppColors.verde,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                            tooltip: 'Copiar código',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Info del pase (fondo suave para mejor lectura)
            Card(
              color: AppColors.moradoClaro.withOpacity(0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(
                      Icons.person,
                      'Persona Autorizada',
                      nombrePersona,
                      AppColors.verdeClaro,
                    ),
                    const Divider(height: 24),
                    _buildInfoRow(
                      Icons.child_care,
                      'Recogerá a',
                      alumnoNombre,
                      AppColors.azulOscuro,
                    ),
                    const Divider(height: 24),
                    _buildInfoRow(
                      Icons.timer,
                      'Válido hasta',
                      DateFormat('dd/MMM/yyyy HH:mm', 'es_MX').format(fechaExpiracion),
                      AppColors.morado,
                    ),
                    const Divider(height: 24),
                    _buildInfoRow(
                      Icons.info_outline,
                      'Usos',
                      'Un solo uso',
                      AppColors.rojo,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Instrucciones
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue[200]!, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb, color: Colors.blue[700], size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'Instrucciones',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[900],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildInstruccion('1', 'Comparte este QR con la persona autorizada'),
                  _buildInstruccion('2', 'La persona muestra el QR al recoger al niño'),
                  _buildInstruccion('3', 'El profesor escanea y valida el código'),
                  _buildInstruccion('4', 'El QR se marca como usado automáticamente'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber, color: Colors.orange[700], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Este código solo puede usarse UNA VEZ',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.orange[900],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Botones de acción
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back),
                    label: Text(
                      'Volver',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: AppColors.morado, width: 2),
                      foregroundColor: AppColors.morado,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _compartirQr(context),
                    icon: const Icon(Icons.share),
                    label: Text(
                      'Compartir',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppColors.morado,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInstruccion(String numero, String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.morado,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                numero,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              texto,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.blue[900],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _compartirQr(BuildContext context) {
    final hasta = fechaExpiracion ?? DateTime.now().add(const Duration(hours: 24));
    Share.share(
      'Pase temporal CAIPI\n'
      'Persona: $nombrePersona\n'
      'Recoge a: $alumnoNombre\n'
      'Código: $codigo\n'
      'Válido hasta: ${DateFormat('dd/MM/yyyy HH:mm').format(hasta)}\n'
      'Muéstralo en la puerta. Un solo uso.',
      subject: 'QR CAIPI — $alumnoNombre',
    );
  }
}
