import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../config/app_colors.dart';
import '../models/configuracion_costos.dart';

/// Referencia de cotización para mostrar a papás en la tableta (Pagos).
class PlanesPagoReferencia extends StatelessWidget {
  const PlanesPagoReferencia({
    super.key,
    required this.config,
    this.initiallyExpanded = true,
  });

  final ConfiguracionCostos config;
  final bool initiallyExpanded;

  static final _fmt = NumberFormat('#,##0.00', 'es_MX');

  static String _money(double v) => '\$${_fmt.format(v)}';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      child: Material(
        color: Colors.white,
        elevation: 1,
        shadowColor: Colors.black26,
        borderRadius: BorderRadius.circular(16),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: initiallyExpanded,
            tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.morado.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.table_view_rounded,
                color: AppColors.morado,
                size: 22,
              ),
            ),
            title: Text(
              'Planes para cotizar',
              style: GoogleFonts.fredoka(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF2D2640),
              ),
            ),
            subtitle: Text(
              'Anticipado y con recargo · 12, 11 y 10 meses',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[700],
              ),
            ),
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final stacked = constraints.maxWidth < 560;
                  final anticipado = _bloque(
                    titulo: 'Pago anticipado',
                    color: AppColors.exitoPago,
                    lineas: [
                      ('12 meses', config.anticipadoDePlan(12)),
                      ('11 meses', config.anticipadoDePlan(11)),
                      ('10 meses', config.anticipadoDePlan(10)),
                    ],
                  );
                  final recargo = _bloque(
                    titulo: 'Pago con recargo',
                    color: AppColors.purpura,
                    lineas: [
                      ('12 meses', config.recargoDePlan(12)),
                      ('11 meses', config.recargoDePlan(11)),
                      ('10 meses', config.recargoDePlan(10)),
                    ],
                  );
                  if (stacked) {
                    return Column(
                      children: [
                        anticipado,
                        const SizedBox(height: 10),
                        recargo,
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: anticipado),
                      const SizedBox(width: 10),
                      Expanded(child: recargo),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bloque({
    required String titulo,
    required Color color,
    required List<(String, double)> lineas,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          for (final linea in lineas)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'a ${linea.$1}',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        height: 1.25,
                        color: const Color(0xFF2D2640),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _money(linea.$2),
                    style: GoogleFonts.fredoka(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2D2640),
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
