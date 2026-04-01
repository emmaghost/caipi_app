import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/app_colors.dart';
import '../../models/bitacora_gasto.dart';
import '../../models/grado.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_drawer.dart';

String _formatoMonto(double monto) {
  return NumberFormat.currency(locale: 'es_MX', symbol: r'$').format(monto);
}

class BitacoraGastosScreen extends StatefulWidget {
  const BitacoraGastosScreen({super.key});

  @override
  State<BitacoraGastosScreen> createState() => _BitacoraGastosScreenState();
}

class _BitacoraGastosScreenState extends State<BitacoraGastosScreen> {
  /// 'todos' | 'general' | 'grado'
  String _alcance = 'todos';
  String? _gradoFiltroId;
  List<Grado> _grados = [];
  bool _cargandoGrados = true;
  int _listaEpoch = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _boot());
  }

  Future<void> _boot() async {
    final auth = context.read<AuthService>();
    if (!auth.isDirectora) {
      if (mounted) setState(() => _cargandoGrados = false);
      return;
    }
    try {
      final g = await Supabase.instance.client
          .from('grados')
          .select()
          .eq('activo', true)
          .order('nombre');
      _grados = (g as List)
          .map((e) => Grado.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {}
    if (mounted) setState(() => _cargandoGrados = false);
  }

  bool _pasaFiltro(BitacoraGasto g) {
    if (_alcance == 'todos') return true;
    if (_alcance == 'general') return g.esGeneralEscuela;
    if (_alcance == 'grado' && _gradoFiltroId != null) {
      return g.gradoId == _gradoFiltroId;
    }
    return true;
  }

  String _etiquetaAlcance(BitacoraGasto g, Map<String, String> nombresGrado) {
    if (g.esGeneralEscuela) return 'Toda la escuela';
    final n = nombresGrado[g.gradoId];
    return n ?? 'Grupo';
  }

  Future<void> _abrirCrear() async {
    final ok = await context.push<bool>('/directora/bitacora-gastos/crear');
    if (ok == true && mounted) setState(() => _listaEpoch++);
  }

  Future<void> _abrirEditar(String id) async {
    final ok = await context.push<bool>('/directora/bitacora-gastos/editar/$id');
    if (ok == true && mounted) setState(() => _listaEpoch++);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    if (!auth.isDirectora) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Bitácora de gastos'),
          backgroundColor: AppColors.morado,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Solo la directora puede usar la bitácora de gastos.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 16),
            ),
          ),
        ),
      );
    }

    final nombresGrado = {for (final gr in _grados) gr.id: gr.nombre};

    return Scaffold(
      backgroundColor: AppColors.rosaClaro,
      drawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: AppColors.morado,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            const Icon(Icons.receipt_long),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Bitácora de gastos',
                style: GoogleFonts.fredoka(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => context.go('/directora'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirCrear,
        backgroundColor: AppColors.azulOscuro,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text('Registrar gasto', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      ),
      body: _cargandoGrados
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Material(
                  color: Colors.white,
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Alcance',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.gris,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  label: const Text('Todos'),
                                  selected: _alcance == 'todos',
                                  onSelected: (_) => setState(() => _alcance = 'todos'),
                                  selectedColor: AppColors.morado.withOpacity(0.2),
                                  checkmarkColor: AppColors.morado,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  label: const Text('Solo escuela'),
                                  selected: _alcance == 'general',
                                  onSelected: (_) => setState(() => _alcance = 'general'),
                                  selectedColor: AppColors.morado.withOpacity(0.2),
                                  checkmarkColor: AppColors.morado,
                                ),
                              ),
                              ..._grados.map(
                                (gr) => Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: FilterChip(
                                    label: Text(gr.nombre, overflow: TextOverflow.ellipsis),
                                    selected:
                                        _alcance == 'grado' && _gradoFiltroId == gr.id,
                                    onSelected: (_) => setState(() {
                                      _alcance = 'grado';
                                      _gradoFiltroId = gr.id;
                                    }),
                                    selectedColor: AppColors.morado.withOpacity(0.2),
                                    checkmarkColor: AppColors.morado,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Texto libre: qué compraste, para qué, aproximadamente cuándo. '
                          'El monto es el total de ese registro.',
                          style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    key: ValueKey(_listaEpoch),
                    stream: Supabase.instance.client
                        .from('bitacora_gastos')
                        .stream(primaryKey: ['id']),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'No se pudo cargar. ¿Ejecutaste ADD_BITACORA_GASTOS.sql en Supabase?\n\n${snapshot.error}',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      var lista = snapshot.data!
                          .map((row) => BitacoraGasto.fromJson(
                                Map<String, dynamic>.from(row as Map),
                              ))
                          .where(_pasaFiltro)
                          .toList();
                      lista.sort((a, b) => b.fecha.compareTo(a.fecha));

                      final total = lista.fold<double>(0, (s, g) => s + g.monto);

                      if (lista.isEmpty) {
                        return ListView(
                          padding: const EdgeInsets.all(24),
                          children: [
                            const SizedBox(height: 32),
                            Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'No hay gastos con este filtro.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.fredoka(fontSize: 18, color: Colors.grey[700]),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Toca «Registrar gasto» para anotar una compra o gasto.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
                            ),
                          ],
                        );
                      }

                      return Column(
                        children: [
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.morado.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.morado.withOpacity(0.25)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${lista.length} registro(s) · Total: ${_formatoMonto(total)}',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: const Color(0xFF2D2640),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: RefreshIndicator(
                              onRefresh: () async => setState(() => _listaEpoch++),
                              child: ListView.builder(
                                padding: const EdgeInsets.fromLTRB(12, 8, 12, 88),
                                itemCount: lista.length,
                                itemBuilder: (context, i) {
                                  final g = lista[i];
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: InkWell(
                                      onTap: () => _abrirEditar(g.id),
                                      borderRadius: BorderRadius.circular(14),
                                      child: Padding(
                                        padding: const EdgeInsets.all(14),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    _formatoMonto(g.monto),
                                                    style: GoogleFonts.fredoka(
                                                      fontSize: 20,
                                                      fontWeight: FontWeight.bold,
                                                      color: AppColors.azulOscuro,
                                                    ),
                                                  ),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: g.esGeneralEscuela
                                                        ? AppColors.turquesa.withOpacity(0.2)
                                                        : AppColors.naranja.withOpacity(0.15),
                                                    borderRadius: BorderRadius.circular(20),
                                                  ),
                                                  child: Text(
                                                    _etiquetaAlcance(g, nombresGrado),
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              DateFormat.yMMMMd('es_MX').format(g.fecha),
                                              style: GoogleFonts.poppins(
                                                fontSize: 13,
                                                color: AppColors.gris,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              g.descripcion,
                                              style: GoogleFonts.poppins(
                                                fontSize: 14,
                                                height: 1.35,
                                                color: const Color(0xFF2D2640),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
