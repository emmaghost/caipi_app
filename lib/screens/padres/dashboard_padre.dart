import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/auth_service.dart';
import '../../services/supabase_service.dart';
import '../../models/alumno.dart';
import '../../widgets/hijo_card.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/campana_anuncios_padre.dart';
import '../../widgets/menu_padre_tile.dart';

class DashboardPadre extends StatelessWidget {
  const DashboardPadre({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final firestoreService = context.read<SupabaseService>();
    final usuario = authService.currentUser;

    // Si no hay usuario, mostrar loading o redirigir
    if (usuario == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Text(
          'Mis Hijos',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: const Color(0xFFEC407A), // Rosa pastel
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          const CampanaAnunciosPadre(),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Saludo
          Text(
            '¡Hola, ${usuario.nombre}!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Aquí puedes ver el progreso de tus hijos',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 20),

          AnunciosSinLeerBuilder(
            builder: (context, sinLeer) {
              return GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.28,
                children: [
                  MenuPadreTile(
                    titulo: 'Anuncios',
                    subtitulo: sinLeer > 0
                        ? '$sinLeer sin leer'
                        : 'Avisos de la escuela',
                    icono: Icons.campaign_outlined,
                    color: const Color(0xFF7C4DFF),
                    badge: sinLeer,
                    onTap: () => context.push('/padre/anuncios'),
                  ),
                  MenuPadreTile(
                    titulo: 'Eventos',
                    subtitulo: 'Actividades de la escuela',
                    icono: Icons.event,
                    color: const Color(0xFFE91E63),
                    onTap: () => context.go('/padre/eventos'),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 24),

          // Mis hijos
          Text(
            'Mis hijos',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          StreamBuilder<List<Alumno>>(
            stream: firestoreService.getAlumnosPorPadre(usuario.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(
                          Icons.family_restroom,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No hay hijos registrados',
                          style: TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Contacta a la directora para registrar a tus hijos',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final hijos = snapshot.data!;

              return Column(
                children: hijos.map((hijo) {
                  return HijoCard(
                    alumno: hijo,
                    onTap: () => context.push('/padre/hijo/${hijo.id}'),
                  );
                }).toList(),
              );
            },
          ),

        ],
      ),
    );
  }
}
