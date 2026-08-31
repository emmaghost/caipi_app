import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../config/app_colors.dart';
import '../services/auth_service.dart';
import '../services/solicitud_recogida_service.dart';

class SolicitudRecogidaPadreCard extends StatefulWidget {
  final String alumnoId;
  final String alumnoNombre;

  const SolicitudRecogidaPadreCard({
    super.key,
    required this.alumnoId,
    required this.alumnoNombre,
  });

  @override
  State<SolicitudRecogidaPadreCard> createState() => _SolicitudRecogidaPadreCardState();
}

class _SolicitudRecogidaPadreCardState extends State<SolicitudRecogidaPadreCard> {
  final SolicitudRecogidaService _service = SolicitudRecogidaService();
  bool _enviando = false;

  Future<void> _solicitarRecogida() async {
    final padre = context.read<AuthService>().currentUser;
    if (padre == null || _enviando) return;

    setState(() => _enviando = true);
    try {
      await _service.solicitarRecogida(
        alumnoId: widget.alumnoId,
        padreId: padre.id,
        mensaje: 'Padre/madre en la entrada',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Aviso enviado: preparar a ${widget.alumnoNombre}'),
            backgroundColor: AppColors.verde,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No se pudo enviar. ¿Ejecutaste ADD_SOLICITUDES_RECOGIDA.sql?\n$e',
            ),
            backgroundColor: AppColors.rojo,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Future<void> _cancelar(String solicitudId) async {
    try {
      await _service.cancelar(solicitudId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.rojo),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _service.streamPendientePorAlumno(widget.alumnoId),
      builder: (context, snapshot) {
        final pendiente = snapshot.data;
        final hora = pendiente != null
            ? DateFormat('dd/MM/yyyy HH:mm').format(pendiente.createdAt.toLocal())
            : null;

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade700,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.door_front_door, color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Estoy en la entrada',
                            style: GoogleFonts.fredoka(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade900,
                            ),
                          ),
                          Text(
                            'Pide a la escuela que te entreguen a ${widget.alumnoNombre}',
                            style: GoogleFonts.poppins(fontSize: 13, color: AppColors.grisOscuro),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (pendiente != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.schedule, size: 18, color: Colors.orange.shade800),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Solicitud enviada · $hora',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () => _cancelar(pendiente.id),
                    icon: const Icon(Icons.close),
                    label: const Text('Cancelar solicitud'),
                  ),
                ] else ...[
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: _enviando ? null : _solicitarRecogida,
                    icon: _enviando
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.notifications_active),
                    label: Text(_enviando ? 'Enviando…' : 'Avisar a la escuela'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.orange.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  'Para otra persona usa Personas autorizadas y el QR temporal.',
                  style: GoogleFonts.poppins(fontSize: 11, color: AppColors.gris),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
