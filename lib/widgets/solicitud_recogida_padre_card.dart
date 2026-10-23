import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_colors.dart';
import '../services/auth_service.dart';
import '../services/solicitud_recogida_service.dart';
import '../utils/mexico_time.dart';

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

    var opciones = <_OpcionRecogida>[
      _OpcionRecogida(
        titulo: 'Yo',
        subtitulo: padre.nombreCompleto,
        quienNombre: padre.nombreCompleto,
        quienParentesco: 'Papá/mamá',
      ),
    ];
    try {
      final rows = await Supabase.instance.client
          .from('personas_autorizadas')
          .select('id, nombre, parentesco')
          .eq('alumno_id', widget.alumnoId)
          .eq('es_lista_fija', true);
      for (final raw in rows as List) {
        final p = Map<String, dynamic>.from(raw as Map);
        final nombre = (p['nombre'] as String? ?? '').trim();
        final parentesco = (p['parentesco'] as String? ?? '').trim();
        if (nombre.isEmpty) continue;
        opciones.add(
          _OpcionRecogida(
            titulo: nombre,
            subtitulo: parentesco.isEmpty ? 'Persona de la lista' : parentesco,
            quienNombre: nombre,
            quienParentesco: parentesco,
            personaId: p['id'] as String?,
          ),
        );
      }
    } catch (_) {}
    opciones.add(
      const _OpcionRecogida(
        titulo: 'Ninguno de ellos',
        subtitulo: 'La escuela pedirá un código',
        requiereCodigo: true,
        quienNombre: 'Otra persona',
        quienParentesco: 'Con código',
      ),
    );
    if (!mounted) return;

    final elegida = await showModalBottomSheet<_OpcionRecogida>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                '¿Quién va por ${widget.alumnoNombre}?',
                style: GoogleFonts.fredoka(fontSize: 18),
              ),
            ),
            for (final op in opciones)
              ListTile(
                title: Text(op.titulo),
                subtitle: Text(op.subtitulo),
                onTap: () => Navigator.pop(ctx, op),
              ),
          ],
        ),
      ),
    );
    if (elegida == null || !mounted) return;

    setState(() => _enviando = true);
    try {
      await _service.solicitarRecogida(
        alumnoId: widget.alumnoId,
        padreId: padre.id,
        mensaje: elegida.requiereCodigo
            ? 'Va alguien que no está en la lista. Pedir código.'
            : 'Va ${elegida.quienNombre}',
        personaAutorizadaId: elegida.personaId,
        quienNombre: elegida.quienNombre,
        quienParentesco: elegida.quienParentesco,
        requiereCodigo: elegida.requiereCodigo,
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
            ? MexicoTime.fechaHora(pendiente.createdAt)
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
                if (pendiente != null && pendiente.esNoCoincide) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF1F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFDA4AF)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'La escuela no entregó a ${widget.alumnoNombre}. La persona de la puerta no se parece a quien elegiste.',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF9F1239),
                          ),
                        ),
                        const SizedBox(height: 8),
                        FilledButton.icon(
                          onPressed: () => context.push(
                            '/padre/hijo/${widget.alumnoId}/personas-autorizadas',
                            extra: {'alumnoNombre': widget.alumnoNombre},
                          ),
                          icon: const Icon(Icons.qr_code_2),
                          label: const Text('Generar código'),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF9F1239),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (pendiente != null) ...[
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
                            pendiente.quienVaTexto.isEmpty
                                ? 'Solicitud enviada · $hora'
                                : 'Va ${pendiente.quienVaTexto} · $hora',
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
                  pendiente != null && pendiente.requiereCodigo
                      ? 'La escuela va a pedir el código. Genéralo en Personas autorizadas.'
                      : 'Si no eres tú ni alguien de la lista, elige «Ninguno» y genera un código.',
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

class _OpcionRecogida {
  final String titulo;
  final String subtitulo;
  final String quienNombre;
  final String quienParentesco;
  final String? personaId;
  final bool requiereCodigo;

  const _OpcionRecogida({
    required this.titulo,
    required this.subtitulo,
    required this.quienNombre,
    this.quienParentesco = '',
    this.personaId,
    this.requiereCodigo = false,
  });
}
