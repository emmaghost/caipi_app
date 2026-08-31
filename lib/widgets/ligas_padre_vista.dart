import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/app_colors.dart';
import '../../models/liga_drive.dart';
import '../../services/liga_drive_service.dart';

/// Ligas Drive visibles para el padre en la ficha del hijo.
class LigasPadreVista extends StatelessWidget {
  final String alumnoId;

  const LigasPadreVista({super.key, required this.alumnoId});

  Future<void> _abrir(String url) async {
    final uri = Uri.tryParse(url.trim());
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<LigaDrive>>(
      future: LigaDriveService().listarParaAlumno(alumnoId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }
        final ligas = snap.data ?? [];
        if (ligas.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Guías y documentos',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            ...ligas.map(
              (liga) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.cloud_download_outlined,
                      color: AppColors.morado),
                  title: Text(
                    liga.nombre,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    liga.esGeneral ? 'General' : 'De su grupo',
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.open_in_new, size: 20),
                  onTap: () => _abrir(liga.url),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
