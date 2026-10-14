import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../config/app_colors.dart';
import '../../services/auth_service.dart';
import '../../widgets/anuncios_padre_section.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/caipi_app_bar_leading.dart';

class AnunciosPadreScreen extends StatelessWidget {
  const AnunciosPadreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AuthService>().currentUser?.id;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF7FA),
      drawer: const AppDrawer(),
      appBar: AppBar(
        leading: const CaipiAppBarLeading(),
        title: Text(
          'Anuncios',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: const Color(0xFFEC407A),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Inicio',
            icon: const Icon(Icons.home_outlined),
            onPressed: () => context.go('/padre'),
          ),
        ],
      ),
      body: uid == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Avisos y tareas de la escuela',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppColors.gris,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: AnunciosPadreSection(
                      usuarioId: uid,
                      pantallaCompleta: true,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
