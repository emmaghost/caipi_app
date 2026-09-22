import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../config/app_colors.dart';
import '../models/bitacora.dart';

/// Aviso de incidencia: bloque limpio (no chip suelto entre los indicadores).
class BitacoraIncidenciaBadge extends StatelessWidget {
  final Bitacora bitacora;
  final VoidCallback? onTap;
  final bool compacto;

  const BitacoraIncidenciaBadge({
    super.key,
    required this.bitacora,
    this.onTap,
    this.compacto = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!bitacora.huboIncidencia) {
      if (compacto) return const SizedBox.shrink();
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFBBF7D0)),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                size: 18, color: Color(0xFF16A34A)),
            const SizedBox(width: 8),
            Text(
              'Sin incidencia',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF166534),
              ),
            ),
          ],
        ),
      );
    }

    final texto = bitacora.tipoIncidencia?.trim();
    final detalle = (texto != null && texto.isNotEmpty)
        ? texto
        : 'Se registró una incidencia';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0xFFFFF7ED), Color(0xFFFFF1E8)],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFDBA74)),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compacto ? 12 : 14,
              vertical: compacto ? 10 : 12,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEA580C).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.priority_high_rounded,
                    size: 20,
                    color: Color(0xFFC2410C),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Incidencia',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                          color: const Color(0xFF9A3412),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        detalle,
                        maxLines: compacto ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          height: 1.25,
                          color: const Color(0xFF7C2D12),
                        ),
                      ),
                    ],
                  ),
                ),
                if (onTap != null) ...[
                  const SizedBox(width: 6),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.orange.shade700,
                    size: 22,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Modal de incidencia: padres solo leen; staff puede ir a editar.
Future<void> mostrarModalIncidenciaBitacora({
  required BuildContext context,
  required Bitacora bitacora,
  required bool puedeEditar,
  String? alumnoNombre,
}) {
  final texto = bitacora.tipoIncidencia?.trim();
  final fecha =
      DateFormat("EEEE d 'de' MMMM yyyy", 'es_MX').format(bitacora.fecha);

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          20 + MediaQuery.viewPaddingOf(ctx).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: bitacora.huboIncidencia
                        ? const Color(0xFFFFEDD5)
                        : const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    bitacora.huboIncidencia
                        ? Icons.priority_high_rounded
                        : Icons.check_circle_rounded,
                    color: bitacora.huboIncidencia
                        ? const Color(0xFFC2410C)
                        : const Color(0xFF16A34A),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bitacora.huboIncidencia
                            ? 'Incidencia del día'
                            : 'Sin incidencia',
                        style: GoogleFonts.fredoka(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        [
                          if (alumnoNombre != null &&
                              alumnoNombre.trim().isNotEmpty)
                            alumnoNombre.trim(),
                          fecha,
                        ].join(' · '),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.gris,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (bitacora.huboIncidencia)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFDBA74)),
                ),
                child: Text(
                  (texto != null && texto.isNotEmpty)
                      ? texto
                      : 'Se registró una incidencia, sin detalle adicional.',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    height: 1.45,
                    color: const Color(0xFF7C2D12),
                  ),
                ),
              )
            else
              Text(
                'Este día no se reportó ninguna incidencia.',
                style: GoogleFonts.poppins(fontSize: 14, color: AppColors.gris),
              ),
            if (!puedeEditar && bitacora.huboIncidencia) ...[
              const SizedBox(height: 10),
              Text(
                'Solo lectura · no puedes modificarla',
                style: GoogleFonts.poppins(fontSize: 12, color: AppColors.gris),
              ),
            ],
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cerrar'),
                  ),
                ),
                if (puedeEditar) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        context.push(
                          '/directora/bitacoras/editar/${bitacora.id}',
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.morado,
                        minimumSize: const Size.fromHeight(44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Editar'),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      );
    },
  );
}
