import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/app_colors.dart';

/// Edad en meses, en una frase corta, para hitos.
class EdadNino {
  EdadNino._();

  static int meses(DateTime nacimiento, {DateTime? hoy}) {
    final h = hoy ?? DateTime.now();
    var total = (h.year - nacimiento.year) * 12 + h.month - nacimiento.month;
    if (h.day < nacimiento.day) total--;
    if (total < 0) return 0;
    return total;
  }

  static String frase(DateTime nacimiento, {DateTime? hoy}) {
    final m = meses(nacimiento, hoy: hoy);
    if (m < 1) return 'Tiene menos de 1 mes';
    final anos = m ~/ 12;
    final resto = m % 12;
    if (anos == 0) {
      return 'Tiene $m ${m == 1 ? 'mes' : 'meses'}';
    }
    if (resto == 0) {
      return 'Tiene $anos ${anos == 1 ? 'año' : 'años'} · $m meses';
    }
    final anioTxt = anos == 1 ? '1 año' : '$anos años';
    final mesTxt = resto == 1 ? '1 mes' : '$resto meses';
    return 'Tiene $anioTxt y $mesTxt · $m meses';
  }
}

class EdadNinoBanner extends StatelessWidget {
  final String nombre;
  final DateTime nacimiento;
  final int? hitosDeMeses;

  const EdadNinoBanner({
    super.key,
    required this.nombre,
    required this.nacimiento,
    this.hitosDeMeses,
  });

  @override
  Widget build(BuildContext context) {
    final corto = nombre.trim().split(' ').first;
    return Material(
      color: const Color(0xFFFFF7ED),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Row(
          children: [
            const Text('🎂', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    corto.isEmpty ? EdadNino.frase(nacimiento) : '$corto ${EdadNino.frase(nacimiento).replaceFirst('Tiene', 'tiene')}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF9A3412),
                    ),
                  ),
                  if (hitosDeMeses != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Hitos de los $hitosDeMeses meses',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.grisOscuro,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
