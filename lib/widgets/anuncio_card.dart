import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/app_colors.dart';
import '../models/anuncio.dart';
import '../utils/mexico_time.dart';

class AnuncioCard extends StatelessWidget {
  final Anuncio anuncio;
  final String usuarioId;
  final Future<void> Function()? onMarcarLeido;
  final bool leidoForzado;

  const AnuncioCard({
    super.key,
    required this.anuncio,
    required this.usuarioId,
    this.onMarcarLeido,
    this.leidoForzado = false,
  });

  bool get _leido => leidoForzado || anuncio.fueLeidoPor(usuarioId);

  @override
  Widget build(BuildContext context) {
    final leido = _leido;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: leido ? 0 : 2,
      color: leido ? Colors.white : const Color(0xFFFFF4F8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: leido
              ? const Color(0xFFE8E2F0)
              : AppColors.rosa.withValues(alpha: 0.45),
        ),
      ),
      child: InkWell(
        onTap: () => _mostrarDetalleAnuncio(context),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (anuncio.prioridad == PrioridadAnuncio.alta) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'URGENTE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: leido ? const Color(0xFFCBD5E1) : AppColors.rosa,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      MexicoTime.format(
                        anuncio.fechaPublicacion,
                        'dd/MMM/yyyy HH:mm',
                      ),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  Text(
                    leido ? 'Leído' : 'Sin leer',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: leido ? AppColors.gris : AppColors.rosa,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                anuncio.titulo,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: leido ? FontWeight.w500 : FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                anuncio.mensajeVisible,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              if (anuncio.urlFoto != null) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: ColoredBox(
                    color: const Color(0xFFF3F0FA),
                    child: SizedBox(
                      height: 180,
                      width: double.infinity,
                      child: Image.network(
                        anuncio.urlFoto!,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ),
              ],
              if (anuncio.fechaEvento != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.event,
                      size: 16,
                      color: anuncio.prioridadColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Evento: ${MexicoTime.format(anuncio.fechaEvento!, 'dd/MMM/yyyy')}',
                      style: TextStyle(
                        fontSize: 13,
                        color: anuncio.prioridadColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _mostrarDetalleAnuncio(BuildContext context) async {
    final leido = _leido;
    var marcando = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                16 + MediaQuery.viewPaddingOf(ctx).bottom,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5E7EB),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      anuncio.titulo,
                      style: GoogleFonts.fredoka(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      MexicoTime.format(
                        anuncio.fechaPublicacion,
                        'dd/MM/yyyy HH:mm',
                      ),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (anuncio.urlFoto != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: ColoredBox(
                          color: const Color(0xFFF3F0FA),
                          child: SizedBox(
                            height: 280,
                            width: double.infinity,
                            child: Image.network(
                              anuncio.urlFoto!,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Text(
                      anuncio.mensajeVisible,
                      style: GoogleFonts.poppins(fontSize: 15, height: 1.45),
                    ),
                    if (anuncio.fechaEvento != null) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.event, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Fecha del evento',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        MexicoTime.format(
                          anuncio.fechaEvento!,
                          'EEEE, dd de MMMM de yyyy',
                        ),
                        style: GoogleFonts.poppins(fontSize: 15),
                      ),
                    ],
                    const SizedBox(height: 18),
                    if (!leido && onMarcarLeido != null) ...[
                      FilledButton.icon(
                        onPressed: marcando
                            ? null
                            : () async {
                                setLocal(() => marcando = true);
                                try {
                                  await onMarcarLeido!();
                                  if (ctx.mounted) Navigator.pop(ctx);
                                } catch (_) {
                                  setLocal(() => marcando = false);
                                  if (ctx.mounted) {
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'No se pudo marcar como leído. Intenta de nuevo.',
                                        ),
                                        backgroundColor: AppColors.rojo,
                                      ),
                                    );
                                  }
                                }
                              },
                        icon: marcando
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.mark_email_read_outlined),
                        label: Text(
                          marcando ? 'Marcando…' : 'Leído y cerrar',
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.rosa,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: marcando
                            ? null
                            : () async {
                                setLocal(() => marcando = true);
                                try {
                                  await onMarcarLeido!();
                                  if (ctx.mounted) Navigator.pop(ctx);
                                } catch (_) {
                                  setLocal(() => marcando = false);
                                }
                              },
                        child: const Text('Marcar como leído'),
                      ),
                    ] else
                      FilledButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.morado,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Cerrar'),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
