import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../config/app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/portage_service.dart';

/// Editor de lista: repeater de nombres de indicadores (solo directora edita).
class PortageListaEditorScreen extends StatefulWidget {
  final String listaId;

  const PortageListaEditorScreen({super.key, required this.listaId});

  @override
  State<PortageListaEditorScreen> createState() =>
      _PortageListaEditorScreenState();
}

class _PortageListaEditorScreenState extends State<PortageListaEditorScreen> {
  final _portage = PortageService();
  final _nombreListaCtrl = TextEditingController();
  final List<TextEditingController> _indicadores = [];
  bool _loading = true;
  bool _saving = false;
  bool _activa = true;
  String _tipo = 'habilidades';

  bool get _puedeEditar =>
      context.read<AuthService>().currentUser?.esDirectora == true;

  bool get _esAlertas => _tipo == 'alertas';

  String get _tipoEtiqueta => _esAlertas ? 'Alertas' : 'Habilidades';

  String get _tituloItems =>
      _esAlertas ? 'Signos / ítems de alerta' : 'Indicadores de habilidades';

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _nombreListaCtrl.dispose();
    for (final c in _indicadores) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _cargar() async {
    try {
      final lista = await _portage.obtenerLista(widget.listaId);
      final inds = await _portage.listarIndicadores(widget.listaId);
      if (!mounted) return;
      for (final c in _indicadores) {
        c.dispose();
      }
      _indicadores.clear();
      for (final i in inds) {
        _indicadores.add(TextEditingController(text: i.nombre));
      }
      if (_indicadores.isEmpty) {
        _indicadores.add(TextEditingController());
      }
      setState(() {
        _nombreListaCtrl.text = lista?.nombre ?? '';
        _activa = lista?.activa ?? true;
        _tipo = lista?.tipo ?? 'habilidades';
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

  void _agregarFila() => setState(() => _indicadores.add(TextEditingController()));

  void _quitarFila(int i) {
    if (_indicadores.length <= 1) return;
    setState(() {
      _indicadores[i].dispose();
      _indicadores.removeAt(i);
    });
  }

  Future<void> _guardar() async {
    if (!_puedeEditar) return;
    setState(() => _saving = true);
    try {
      await _portage.actualizarLista(
        listaId: widget.listaId,
        nombre: _nombreListaCtrl.text.trim(),
        activa: _activa,
      );
      final nombres = _indicadores.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();
      await _portage.guardarIndicadores(widget.listaId, nombres);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lista guardada'),
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

  Future<void> _eliminarLista() async {
    if (!_puedeEditar) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar lista?'),
        content: const Text(
          'Si borras esta lista, también se borrarán las evaluaciones y '
          'calificaciones ya hechas con ella. Esta acción no se puede deshacer.',
        ),
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
    if (ok != true || !mounted) return;
    try {
      await _portage.eliminarLista(widget.listaId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lista eliminada'),
          backgroundColor: AppColors.verde,
        ),
      );
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
          _loading ? 'Lista' : _tipoEtiqueta,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.morado,
        foregroundColor: Colors.white,
        actions: [
          if (_puedeEditar && !_loading)
            IconButton(
              tooltip: 'Eliminar lista',
              onPressed: _eliminarLista,
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (!_puedeEditar)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _esAlertas
                          ? 'Solo lectura: la directora edita las alertas. Tú calificas por niño en el seguimiento.'
                          : 'Solo lectura: la directora edita las habilidades. Tú calificas por niño en el seguimiento.',
                      style: GoogleFonts.poppins(fontSize: 13),
                    ),
                  ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Chip(
                    label: Text(
                      _tipoEtiqueta,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    backgroundColor: _esAlertas
                        ? AppColors.naranjaClaro.withOpacity(0.35)
                        : AppColors.morado.withOpacity(0.12),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _nombreListaCtrl,
                  enabled: _puedeEditar,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de la lista',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                if (_puedeEditar)
                  SwitchListTile(
                    title: const Text('Lista activa'),
                    value: _activa,
                    onChanged: (v) => setState(() => _activa = v),
                  ),
                const SizedBox(height: 12),
                Text(
                  _tituloItems,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  _esAlertas
                      ? 'Logrado / En proceso / Observaciones se llenan al evaluar a cada niño en el seguimiento.'
                      : 'Logrado / En proceso / Observaciones se llenan al evaluar a cada niño.',
                  style: GoogleFonts.poppins(fontSize: 12, color: AppColors.gris),
                ),
                const SizedBox(height: 12),
                ...List.generate(_indicadores.length, (i) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: AppColors.morado.withOpacity(0.15),
                          child: Text(
                            '${i + 1}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _indicadores[i],
                            enabled: _puedeEditar,
                            maxLines: 2,
                            decoration: InputDecoration(
                              hintText: _esAlertas
                                  ? 'Ej. No camina solo a los 18 meses…'
                                  : 'Ej. Mantiene la cabeza en línea media…',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                        ),
                        if (_puedeEditar)
                          IconButton(
                            onPressed: () => _quitarFila(i),
                            icon: const Icon(Icons.remove_circle_outline,
                                color: AppColors.rojo),
                          ),
                      ],
                    ),
                  );
                }),
                if (_puedeEditar) ...[
                  OutlinedButton.icon(
                    onPressed: _agregarFila,
                    icon: const Icon(Icons.add),
                    label: Text(
                      _esAlertas ? 'Agregar alerta' : 'Agregar indicador',
                    ),
                  ),
                  const SizedBox(height: 16),
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
                        : const Text('Guardar lista'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _eliminarLista,
                    icon: const Icon(Icons.delete_outline, color: AppColors.rojo),
                    label: const Text(
                      'Eliminar lista',
                      style: TextStyle(color: AppColors.rojo),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.rojo),
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}
