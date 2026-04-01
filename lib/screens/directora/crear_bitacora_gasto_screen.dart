import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../config/app_colors.dart';
import '../../models/bitacora_gasto.dart';
import '../../models/grado.dart';
import '../../widgets/app_drawer.dart';

class CrearBitacoraGastoScreen extends StatefulWidget {
  final String? gastoId;

  const CrearBitacoraGastoScreen({super.key, this.gastoId});

  @override
  State<CrearBitacoraGastoScreen> createState() => _CrearBitacoraGastoScreenState();
}

class _CrearBitacoraGastoScreenState extends State<CrearBitacoraGastoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descripcionController = TextEditingController();
  final _montoController = TextEditingController();

  DateTime _fecha = DateTime.now();
  /// true = toda la escuela; false = uno o varios grupos.
  bool _alcanceGeneral = true;
  final Set<String> _gradoIdsSeleccionados = {};
  List<Grado> _grados = [];
  bool _cargando = true;
  bool _enviando = false;
  bool _esEdicion = false;

  @override
  void initState() {
    super.initState();
    _esEdicion = widget.gastoId != null;
    WidgetsBinding.instance.addPostFrameCallback((_) => _boot());
  }

  Future<void> _boot() async {
    setState(() => _cargando = true);
    try {
      final g = await Supabase.instance.client
          .from('grados')
          .select()
          .eq('activo', true)
          .order('nombre');
      _grados = (g as List)
          .map((e) => Grado.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();

      if (widget.gastoId != null) {
        final row = await Supabase.instance.client
            .from('bitacora_gastos')
            .select()
            .eq('id', widget.gastoId!)
            .single();
        final gasto = BitacoraGasto.fromJson(Map<String, dynamic>.from(row as Map));
        _fecha = gasto.fecha;
        _descripcionController.text = gasto.descripcion;
        _montoController.text = gasto.monto.toStringAsFixed(2);
        if (gasto.esGeneralEscuela) {
          _alcanceGeneral = true;
          _gradoIdsSeleccionados.clear();
        } else {
          _alcanceGeneral = false;
          _gradoIdsSeleccionados.clear();
          if (gasto.gruposAlcanceIds != null && gasto.gruposAlcanceIds!.isNotEmpty) {
            _gradoIdsSeleccionados.addAll(gasto.gruposAlcanceIds!);
          } else if (gasto.gradoId != null) {
            _gradoIdsSeleccionados.add(gasto.gradoId!);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar: $e'), backgroundColor: Colors.red),
        );
      }
    }
    if (mounted) setState(() => _cargando = false);
  }

  @override
  void dispose() {
    _descripcionController.dispose();
    _montoController.dispose();
    super.dispose();
  }

  double? _parseMonto(String raw) {
    final t = raw.trim().replaceAll(',', '');
    return double.tryParse(t);
  }

  void _seleccionarPorNombre(bool Function(String lower) pred) {
    setState(() {
      for (final gr in _grados) {
        if (pred(gr.nombre.toLowerCase())) _gradoIdsSeleccionados.add(gr.id);
      }
    });
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    final monto = _parseMonto(_montoController.text);
    if (monto == null || monto < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Indica un monto válido'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final desc = _descripcionController.text.trim();
    if (desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Describe el gasto'), backgroundColor: Colors.orange),
      );
      return;
    }

    if (!_alcanceGeneral && _gradoIdsSeleccionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Elige al menos un grupo, o deja «Toda la escuela»'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _enviando = true);

    final String? gradoIdPayload;
    final String? gruposJsonPayload;

    if (_alcanceGeneral) {
      gradoIdPayload = null;
      gruposJsonPayload = null;
    } else {
      final lista = _gradoIdsSeleccionados.toList()..sort();
      if (lista.length == 1) {
        gradoIdPayload = lista.first;
        gruposJsonPayload = null;
      } else {
        gradoIdPayload = null;
        gruposJsonPayload = jsonEncode(lista);
      }
    }

    final payload = <String, dynamic>{
      'fecha': DateFormat('yyyy-MM-dd').format(_fecha),
      'descripcion': desc,
      'monto': monto,
      'grado_id': gradoIdPayload,
      'grupos_alcance_ids': gruposJsonPayload,
      'updated_at': DateTime.now().toIso8601String(),
    };

    try {
      if (_esEdicion) {
        await Supabase.instance.client
            .from('bitacora_gastos')
            .update(payload)
            .eq('id', widget.gastoId!);
      } else {
        payload['id'] = const Uuid().v4();
        payload['created_at'] = DateTime.now().toIso8601String();
        await Supabase.instance.client.from('bitacora_gastos').insert(payload);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_esEdicion ? 'Gasto actualizado' : 'Gasto registrado'),
            backgroundColor: Colors.green,
          ),
        );
        final r = GoRouter.of(context);
        if (r.canPop()) {
          r.pop(true);
        } else {
          r.go('/directora/bitacora-gastos');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: $e\nSi falta la columna grupos_alcance_ids, ejecuta ADD_BITACORA_GASTOS_GRUPOS_ALCANCE.sql en Supabase.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Future<void> _eliminar() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('¿Eliminar este registro?', style: GoogleFonts.fredoka()),
        content: Text(
          'Se borrará de la bitácora de gastos.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _cargando = true);
    try {
      await Supabase.instance.client.from('bitacora_gastos').delete().eq('id', widget.gastoId!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Eliminado'), backgroundColor: Colors.green),
        );
        final r = GoRouter.of(context);
        if (r.canPop()) {
          r.pop(true);
        } else {
          r.go('/directora/bitacora-gastos');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _elegirFecha() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('es', 'MX'),
    );
    if (d != null) setState(() => _fecha = d);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.rosaClaro,
      drawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: AppColors.morado,
        foregroundColor: Colors.white,
        title: Text(
          _esEdicion ? 'Editar gasto' : 'Registrar gasto',
          style: GoogleFonts.fredoka(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Anota en texto lo que necesites (qué fue, para qué evento, tienda, etc.). '
                      'No hace falta un catálogo fijo.',
                      style: GoogleFonts.poppins(fontSize: 13, color: AppColors.grisOscuro),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      tileColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      leading: const Icon(Icons.calendar_today, color: AppColors.morado),
                      title: Text(
                        DateFormat.yMMMMd('es_MX').format(_fecha),
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text('Fecha del gasto', style: GoogleFonts.poppins(fontSize: 12)),
                      onTap: _elegirFecha,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _montoController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Monto total',
                        prefixText: r'$ ',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (v) {
                        final m = _parseMonto(v ?? '');
                        if (m == null) return 'Monto inválido';
                        if (m < 0) return 'No puede ser negativo';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descripcionController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        labelText: 'Descripción',
                        hintText: 'Ej: Dulces Halloween, 3 bolsas en Dulcería Lulu…',
                        alignLabelWithHint: true,
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Escribe una descripción';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '¿A qué aplica este gasto?',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppColors.gris,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment<bool>(
                          value: true,
                          label: Text('Toda la escuela'),
                          icon: Icon(Icons.apartment, size: 18),
                        ),
                        ButtonSegment<bool>(
                          value: false,
                          label: Text('Grupo(s)'),
                          icon: Icon(Icons.groups_outlined, size: 18),
                        ),
                      ],
                      selected: {_alcanceGeneral},
                      onSelectionChanged: (s) => setState(() {
                        _alcanceGeneral = s.first;
                        if (_alcanceGeneral) _gradoIdsSeleccionados.clear();
                      }),
                    ),
                    if (!_alcanceGeneral) ...[
                      const SizedBox(height: 14),
                      Text(
                        'Rápido',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ActionChip(
                            avatar: const Icon(Icons.child_care, size: 18),
                            label: const Text('Todo Maternal'),
                            onPressed: () => _seleccionarPorNombre((n) => n.contains('maternal')),
                          ),
                          ActionChip(
                            avatar: const Icon(Icons.school_outlined, size: 18),
                            label: const Text('Todo Kinder'),
                            onPressed: () => _seleccionarPorNombre((n) => n.contains('kinder')),
                          ),
                          ActionChip(
                            label: const Text('Quitar selección'),
                            onPressed: () => setState(() => _gradoIdsSeleccionados.clear()),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Grupos (uno o varios)',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _grados.map((gr) {
                          final sel = _gradoIdsSeleccionados.contains(gr.id);
                          return FilterChip(
                            label: Text(gr.nombre),
                            selected: sel,
                            onSelected: (_) => setState(() {
                              if (sel) {
                                _gradoIdsSeleccionados.remove(gr.id);
                              } else {
                                _gradoIdsSeleccionados.add(gr.id);
                              }
                            }),
                            selectedColor: AppColors.morado.withValues(alpha: 0.25),
                            checkmarkColor: AppColors.morado,
                          );
                        }).toList(),
                      ),
                      if (_gradoIdsSeleccionados.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            _gradoIdsSeleccionados.length == 1
                                ? 'Un grupo seleccionado.'
                                : '${_gradoIdsSeleccionados.length} grupos seleccionados (mismo registro de gasto).',
                            style: GoogleFonts.poppins(fontSize: 12, color: AppColors.grisOscuro),
                          ),
                        ),
                    ],
                    const SizedBox(height: 28),
                    FilledButton.icon(
                      onPressed: _cargando ? null : _guardar,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.azulOscuro,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      icon: _enviando
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.save),
                      label: Text(
                        _esEdicion ? 'Guardar cambios' : 'Guardar gasto',
                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (_esEdicion) ...[
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _enviando ? null : _eliminar,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: const Icon(Icons.delete_outline),
                        label: Text('Eliminar', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}
