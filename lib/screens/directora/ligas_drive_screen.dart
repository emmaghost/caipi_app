import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/app_colors.dart';
import '../../models/liga_drive.dart';
import '../../services/auth_service.dart';
import '../../services/liga_drive_service.dart';
import '../../widgets/app_drawer.dart';

class LigasDriveScreen extends StatefulWidget {
  const LigasDriveScreen({super.key});

  @override
  State<LigasDriveScreen> createState() => _LigasDriveScreenState();
}

class _LigasDriveScreenState extends State<LigasDriveScreen> {
  final _svc = LigaDriveService();
  late Future<List<LigaDrive>> _future;
  Map<String, String> _nombresGrado = {};

  bool get _puedeEditar {
    final u = context.read<AuthService>().currentUser;
    return u?.esDirectora == true || u?.esProfesorAdmin == true;
  }

  @override
  void initState() {
    super.initState();
    _future = _svc.listarTodas();
    _cargarNombresGrado();
  }

  Future<void> _cargarNombresGrado() async {
    try {
      final rows = await Supabase.instance.client
          .from('grados')
          .select('id, nombre')
          .eq('activo', true);
      final map = <String, String>{};
      for (final r in rows as List) {
        map[r['id'] as String] = r['nombre'] as String? ?? 'Grupo';
      }
      if (mounted) setState(() => _nombresGrado = map);
    } catch (_) {}
  }

  Future<void> _refrescar() async {
    setState(() => _future = _svc.listarTodas());
    await _future;
  }

  String _subtitulo(LigaDrive liga) {
    if (liga.esGeneral) return 'General · todos los padres';
    if (liga.gradoIds.isEmpty) return 'Por grupo · sin grupos';
    final nombres = liga.gradoIds
        .map((id) => _nombresGrado[id] ?? 'Grupo')
        .join(', ');
    return 'Grupos · $nombres';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grisClaro,
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Text(
          'Ligas Drive',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.azulOscuro,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => context.go('/directora'),
          ),
        ],
      ),
      floatingActionButton: _puedeEditar
          ? FloatingActionButton.extended(
              onPressed: () async {
                await context.push('/directora/ligas/crear');
                if (mounted) await _refrescar();
              },
              backgroundColor: AppColors.morado,
              icon: const Icon(Icons.add_link),
              label: const Text('Crear nueva liga'),
            )
          : null,
      body: FutureBuilder<List<LigaDrive>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Error: ${snap.error}\n'
                  '¿Ejecutaste ADD_LIGAS_DRIVE.sql y FIX_LIGAS_DRIVE_POR_GRADO.sql?',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final ligas = snap.data ?? [];
          if (ligas.isEmpty) {
            return Center(
              child: Text(
                'Aún no hay ligas.\nUsa “Crear nueva liga”.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: AppColors.gris),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: _refrescar,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
              itemCount: ligas.length,
              itemBuilder: (context, i) {
                final liga = ligas[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: Icon(
                      Icons.link,
                      color: liga.activa ? AppColors.morado : AppColors.gris,
                    ),
                    title: Text(
                      liga.nombre,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(_subtitulo(liga)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      await context.push('/directora/ligas/editar/${liga.id}');
                      if (mounted) await _refrescar();
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class LigaDriveFormScreen extends StatefulWidget {
  final String? ligaId;

  const LigaDriveFormScreen({super.key, this.ligaId});

  @override
  State<LigaDriveFormScreen> createState() => _LigaDriveFormScreenState();
}

class _LigaDriveFormScreenState extends State<LigaDriveFormScreen> {
  final _svc = LigaDriveService();
  final _nombreCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  String _alcance = 'general';
  bool _activa = true;
  bool _loading = true;
  bool _saving = false;
  final Set<String> _gradoIds = {};
  List<Map<String, dynamic>> _grados = [];

  bool get _esEdicion => widget.ligaId != null;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    try {
      final rows = await Supabase.instance.client
          .from('grados')
          .select('id, nombre')
          .eq('activo', true)
          .order('nombre');
      final list = List<Map<String, dynamic>>.from(rows as List);

      if (widget.ligaId != null) {
        final liga = await _svc.obtener(widget.ligaId!);
        if (liga != null) {
          _nombreCtrl.text = liga.nombre;
          _urlCtrl.text = liga.url;
          _alcance = liga.esPorGrados ? 'grados' : 'general';
          _activa = liga.activa;
          _gradoIds
            ..clear()
            ..addAll(liga.gradoIds);
        }
      }
      if (!mounted) return;
      setState(() {
        _grados = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.rojo),
      );
    }
  }

  Future<void> _guardar() async {
    final nombre = _nombreCtrl.text.trim();
    final url = _urlCtrl.text.trim();
    if (nombre.isEmpty || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nombre y URL son obligatorios'),
          backgroundColor: AppColors.rojo,
        ),
      );
      return;
    }
    if (_alcance == 'grados' && _gradoIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona al menos un grupo'),
          backgroundColor: AppColors.rojo,
        ),
      );
      return;
    }
    final user = context.read<AuthService>().currentUser;
    if (user == null) return;
    setState(() => _saving = true);
    try {
      if (_esEdicion) {
        await _svc.actualizar(
          id: widget.ligaId!,
          nombre: nombre,
          url: url,
          alcance: _alcance,
          activa: _activa,
          gradoIds: _gradoIds.toList(),
        );
      } else {
        await _svc.crear(
          nombre: nombre,
          url: url,
          alcance: _alcance,
          createdBy: user.id,
          gradoIds: _gradoIds.toList(),
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Liga guardada'),
          backgroundColor: AppColors.verde,
        ),
      );
      context.pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.rojo),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _eliminar() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar liga?'),
        content: const Text('Los padres ya no la verán.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.rojo),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok != true || widget.ligaId == null) return;
    try {
      await _svc.eliminar(widget.ligaId!);
      if (!mounted) return;
      context.pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.rojo),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grisClaro,
      appBar: AppBar(
        title: Text(
          _esEdicion ? 'Editar liga' : 'Crear nueva liga',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.azulOscuro,
        foregroundColor: Colors.white,
        actions: [
          if (_esEdicion)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _eliminar,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  controller: _nombreCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre que verá el padre *',
                    hintText: 'Ej. Guía de desarrollo Maternal',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _urlCtrl,
                  decoration: const InputDecoration(
                    labelText: 'URL de Google Drive *',
                    hintText: 'https://drive.google.com/...',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 16),
                Text(
                  '¿Dónde mostrarla?',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                ),
                RadioListTile<String>(
                  title: const Text('General (todos los padres)'),
                  subtitle: const Text('Aparece en la ficha de cada hijo'),
                  value: 'general',
                  groupValue: _alcance,
                  onChanged: (v) => setState(() => _alcance = v!),
                ),
                RadioListTile<String>(
                  title: const Text('Por grupo(s)'),
                  subtitle: const Text(
                    'Ej. Maternal, Maternal 2… puedes marcar varios',
                  ),
                  value: 'grados',
                  groupValue: _alcance,
                  onChanged: (v) => setState(() => _alcance = v!),
                ),
                if (_alcance == 'grados') ...[
                  const SizedBox(height: 8),
                  Text(
                    '${_gradoIds.length} grupo(s) seleccionado(s)',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.gris,
                    ),
                  ),
                  ..._grados.map((g) {
                    final id = g['id'] as String;
                    final nombre = g['nombre'] as String? ?? 'Grupo';
                    return CheckboxListTile(
                      value: _gradoIds.contains(id),
                      title: Text(nombre),
                      onChanged: (v) => setState(() {
                        if (v == true) {
                          _gradoIds.add(id);
                        } else {
                          _gradoIds.remove(id);
                        }
                      }),
                    );
                  }),
                ],
                if (_esEdicion)
                  SwitchListTile(
                    title: const Text('Liga activa'),
                    value: _activa,
                    onChanged: (v) => setState(() => _activa = v),
                  ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _saving ? null : _guardar,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.morado,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(_esEdicion ? 'Guardar cambios' : 'Crear liga'),
                ),
              ],
            ),
    );
  }
}
