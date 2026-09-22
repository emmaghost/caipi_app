import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../config/app_colors.dart';
import '../../models/grado.dart';
import '../../models/portage.dart';
import '../../services/portage_service.dart';
import '../../services/supabase_service.dart';
import '../../widgets/caipi_app_bar_leading.dart';

/// Listas del grupo: solo hitos por meses (sin plantillas por áreas).
class PortageListasAdminScreen extends StatefulWidget {
  final String? gradoIdInicial;

  const PortageListasAdminScreen({super.key, this.gradoIdInicial});

  @override
  State<PortageListasAdminScreen> createState() =>
      _PortageListasAdminScreenState();
}

class _PortageListasAdminScreenState extends State<PortageListasAdminScreen> {
  final _portage = PortageService();
  List<Grado> _grados = [];
  String? _gradoId;
  List<PortageLista> _listas = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    setState(() => _loading = true);
    try {
      final grados = await context.read<SupabaseService>().obtenerGrados();
      final activos = grados.where((g) => g.activo).toList()
        ..sort((a, b) => a.nombre.compareTo(b.nombre));
      final inicial = widget.gradoIdInicial;
      if (!mounted) return;
      setState(() {
        _grados = activos;
        _gradoId = (inicial != null && activos.any((g) => g.id == inicial))
            ? inicial
            : (activos.isNotEmpty ? activos.first.id : null);
      });
      if (_gradoId != null) await _cargar();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _cargar() async {
    final gid = _gradoId;
    if (gid == null) return;
    final listas = await _portage.listarListasPorGrado(gid);
    if (!mounted) return;
    setState(() {
      _listas = listas.where((l) => l.mesesEdad != null).toList()
        ..sort((a, b) => (a.mesesEdad ?? 0).compareTo(b.mesesEdad ?? 0));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grisClaro,
      appBar: AppBar(
        leading: const CaipiAppBarLeading(),
        title: Text(
          'Hitos del grupo',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.morado,
        foregroundColor: Colors.white,
      ),
      body: _loading && _grados.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Este grupo usa hitos de desarrollo por meses de edad. '
                  'Carga el catálogo desde «Hitos por meses» y luego asigna '
                  'tramos a cada niño en Indicadores.',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppColors.grisOscuro,
                  ),
                ),
                const SizedBox(height: 12),
                if (_grados.length > 1)
                  DropdownButtonFormField<String>(
                    value: _gradoId,
                    decoration: const InputDecoration(
                      labelText: 'Grupo',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    items: _grados
                        .map(
                          (g) => DropdownMenuItem(
                            value: g.id,
                            child: Text(g.nombre),
                          ),
                        )
                        .toList(),
                    onChanged: (v) async {
                      setState(() => _gradoId = v);
                      await _cargar();
                    },
                  )
                else if (_grados.isNotEmpty)
                  Text(
                    _grados.first.nombre,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => context.push('/directora/hitos'),
                  icon: const Icon(Icons.timeline),
                  label: const Text('Hitos por meses (cargar catálogo)'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.morado,
                    minimumSize: const Size.fromHeight(46),
                  ),
                ),
                const SizedBox(height: 16),
                if (_listas.isEmpty)
                  Text(
                    'Aún no hay hitos por meses en este grupo. '
                    'Ábrelos con el botón de arriba.',
                    style: GoogleFonts.poppins(color: AppColors.gris),
                  )
                else
                  Text(
                    'Hitos cargados en este grupo',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                const SizedBox(height: 8),
                ..._listas.map(
                  (l) => Card(
                    child: ListTile(
                      title: Text(l.nombre),
                      subtitle: Text(
                        '${l.mesesEdad} meses'
                        ' · ${l.activa ? 'Activa' : 'Inactiva'}',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        await context.push('/directora/portage/lista/${l.id}');
                        await _cargar();
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
