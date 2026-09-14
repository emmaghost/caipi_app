import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../config/app_colors.dart';
import '../../models/grado.dart';
import '../../models/portage.dart';
import '../../services/auth_service.dart';
import '../../services/portage_service.dart';
import '../../services/supabase_service.dart';
import '../../utils/portage_plantilla.dart';
import '../../widgets/caipi_app_bar_leading.dart';

/// Solo administración de plantillas/listas del grupo (no calificar niños).
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

  bool get _puedeEditar {
    final u = context.read<AuthService>().currentUser;
    return u?.esDirectora == true ||
        u?.esProfesorAdmin == true ||
        u?.esProfesor == true;
  }

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
    setState(() => _listas = listas);
  }

  Future<void> _crearLista() async {
    if (!_puedeEditar || _gradoId == null) return;
    String tipo = PortagePlantilla.tipoHabilidades;
    final nombreCtrl = TextEditingController(text: 'Lista de habilidades');
    void disposeNombre() {
      WidgetsBinding.instance.addPostFrameCallback((_) => nombreCtrl.dispose());
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Nueva lista'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: tipo,
                decoration: const InputDecoration(labelText: 'Tipo'),
                items: const [
                  DropdownMenuItem(
                    value: PortagePlantilla.tipoHabilidades,
                    child: Text('Habilidades'),
                  ),
                  DropdownMenuItem(
                    value: PortagePlantilla.tipoAlertas,
                    child: Text('Alertas'),
                  ),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  setLocal(() {
                    tipo = v;
                    if (nombreCtrl.text.trim().isEmpty ||
                        nombreCtrl.text == 'Lista de habilidades' ||
                        nombreCtrl.text == 'Lista de alertas') {
                      nombreCtrl.text = v == PortagePlantilla.tipoAlertas
                          ? 'Lista de alertas'
                          : 'Lista de habilidades';
                    }
                  });
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nombreCtrl,
                decoration:
                    const InputDecoration(labelText: 'Nombre de la lista'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Crear'),
            ),
          ],
        ),
      ),
    );
    if (ok != true || !mounted) {
      disposeNombre();
      return;
    }
    final user = context.read<AuthService>().currentUser!;
    final nombre = nombreCtrl.text.trim().isEmpty
        ? (tipo == PortagePlantilla.tipoAlertas
            ? 'Lista de alertas'
            : 'Lista de habilidades')
        : nombreCtrl.text.trim();
    disposeNombre();
    try {
      final lista = await _portage.crearLista(
        gradoId: _gradoId!,
        nombre: nombre,
        createdBy: user.id,
        tipo: tipo,
      );
      if (!mounted) return;
      await context.push('/directora/portage/lista/${lista.id}');
      await _cargar();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.rojo),
      );
    }
  }

  Future<void> _cargarPlantillas() async {
    if (!_puedeEditar || _gradoId == null) return;
    final user = context.read<AuthService>().currentUser!;
    final incluirAlertas = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cargar plantilla habilidades'),
        content: const Text(
          'Se crearán las listas de habilidades del grado (si aún no existen).\n\n'
          '¿También cargar una lista de alertas de ejemplo?\n'
          '(Alertas = señales de cuidado, no habilidades.)',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Solo habilidades'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Habilidades + alertas'),
          ),
        ],
      ),
    );
    if (incluirAlertas == null || !mounted) return;
    setState(() => _loading = true);
    try {
      final creadas = await _portage.cargarPlantillaHabilidades(
        gradoId: _gradoId!,
        createdBy: user.id,
        plantillas: PortagePlantilla.habilidades,
      );
      if (incluirAlertas) {
        await _portage.cargarPlantillaAlertas(
          gradoId: _gradoId!,
          createdBy: user.id,
          items: PortagePlantilla.alertasEjemplo,
        );
      }
      await _cargar();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            creadas == 0
                ? 'Las plantillas ya estaban cargadas'
                : 'Se crearon $creadas lista(s)',
          ),
          backgroundColor: AppColors.verde,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.rojo),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grisClaro,
      appBar: AppBar(
        leading: const CaipiAppBarLeading(),
        title: Text(
          'Administrar listas',
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
                  'Aquí solo se crean o editan las plantillas del grupo. '
                  'Para calificar niños vuelve a Indicadores y abre un seguimiento.',
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
                OutlinedButton.icon(
                  onPressed: () => context.push('/directora/hitos'),
                  icon: const Icon(Icons.timeline),
                  label: const Text('Hitos por meses (cargar catálogo)'),
                ),
                const SizedBox(height: 8),
                if (_puedeEditar) ...[
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _crearLista,
                          icon: const Icon(Icons.add),
                          label: const Text('Nueva lista'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.morado,
                          ),
                        ),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: _cargarPlantillas,
                    icon: const Icon(Icons.library_add_outlined),
                    label: const Text('Cargar plantilla habilidades'),
                  ),
                ],
                const SizedBox(height: 8),
                if (_listas.isEmpty)
                  Text(
                    'Sin listas aún en este grupo.',
                    style: GoogleFonts.poppins(color: AppColors.gris),
                  ),
                ..._listas.map(
                  (l) => Card(
                    child: ListTile(
                      title: Text(l.nombre),
                      subtitle: Text(
                        '${l.tipoEtiqueta}'
                        '${l.mesesEdad != null ? ' · ${l.mesesEdad} meses' : ''}'
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
