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

  bool get _puedeEditar =>
      context.read<AuthService>().currentUser?.esDirectora == true;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grisClaro,
      appBar: AppBar(
        title: Text(
          'Indicadores de desarrollo',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.morado,
        foregroundColor: Colors.white,
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
                      'Solo lectura: la directora edita los indicadores. Tú calificas por niño en signos de alerta.',
                      style: GoogleFonts.poppins(fontSize: 13),
                    ),
                  ),
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
                  'Indicadores de desarrollo',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'Logrado / En proceso / Observaciones se llenan al evaluar a cada niño.',
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
                              hintText: 'Ej. Mantiene la cabeza en línea media…',
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
                    label: const Text('Agregar indicador'),
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
                ],
              ],
            ),
    );
  }
}
