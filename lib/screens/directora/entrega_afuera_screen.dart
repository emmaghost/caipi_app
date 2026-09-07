import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../config/app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/profesor_grupos_service.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/panel_solicitudes_recogida_escuela.dart';

/// Menú dedicado: papás que ya están en la entrada y piden entregar al niño.
class EntregaAfueraScreen extends StatefulWidget {
  const EntregaAfueraScreen({super.key});

  @override
  State<EntregaAfueraScreen> createState() => _EntregaAfueraScreenState();
}

class _EntregaAfueraScreenState extends State<EntregaAfueraScreen> {
  Set<String>? _gradoIdsFiltro;
  bool _cargandoFiltro = true;

  @override
  void initState() {
    super.initState();
    _cargarFiltroProfesor();
  }

  Future<void> _cargarFiltroProfesor() async {
    final user = context.read<AuthService>().currentUser;
    if (user == null || user.esDirectora || user.esProfesorAdmin) {
      if (mounted) setState(() => _cargandoFiltro = false);
      return;
    }
    if (!user.esProfesor) {
      if (mounted) setState(() => _cargandoFiltro = false);
      return;
    }
    try {
      final ids = await ProfesorGruposService().gradoIdsDeUsuario(user.id);
      if (mounted) {
        setState(() {
          _gradoIdsFiltro = ids.toSet();
          _cargandoFiltro = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _cargandoFiltro = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grisClaro,
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Text(
          'Niños afuera',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.azulOscuro,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            tooltip: 'Inicio',
            onPressed: () => context.go('/directora'),
          ),
        ],
      ),
      body: _cargandoFiltro
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                Card(
                  color: Colors.orange.shade50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: Colors.orange.shade300),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Icon(Icons.door_front_door,
                            color: Colors.orange.shade800, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Aquí aparecen los niños cuando el papá/mamá '
                            'avisa que ya está en la entrada. '
                            'Toca «Entregar» y elige: al papá/mamá o con QR.',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.orange.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                PanelSolicitudesRecogidaEscuela(
                  gradoIdsFiltro: _gradoIdsFiltro,
                  mostrarVacio: true,
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => context.go('/directora/control-salidas'),
                  icon: const Icon(Icons.access_time),
                  label: const Text('Ir a Control entrada/salida'),
                ),
              ],
            ),
    );
  }
}
