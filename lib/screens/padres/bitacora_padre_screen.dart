import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/app_colors.dart';
import '../../models/bitacora.dart';

/// Bitácora del hijo: lectura rápida (etiqueta → valor), por día o por mes.
class BitacoraPadreScreen extends StatefulWidget {
  final String alumnoId;
  final String alumnoNombre;

  const BitacoraPadreScreen({
    super.key,
    required this.alumnoId,
    required this.alumnoNombre,
  });

  @override
  State<BitacoraPadreScreen> createState() => _BitacoraPadreScreenState();
}

class _BitacoraPadreScreenState extends State<BitacoraPadreScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  DateTime _diaSeleccionado =
      DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  DateTime _mesVisible =
      DateTime(DateTime.now().year, DateTime.now().month, 1);

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<Bitacora?> _bitacoraDelDia(DateTime d) async {
    final f = DateFormat('yyyy-MM-dd').format(d);
    final rows = await Supabase.instance.client
        .from('bitacora_diaria')
        .select()
        .eq('alumno_id', widget.alumnoId)
        .eq('fecha', f)
        .limit(1);
    if (rows.isEmpty) return null;
    final m = rows.first;
    return Bitacora.fromJson(Map<String, dynamic>.from(m as Map));
  }

  Future<List<Bitacora>> _bitacorasDelMes(DateTime mes) async {
    final ini = DateTime(mes.year, mes.month, 1);
    final fin = DateTime(mes.year, mes.month + 1, 0);
    final rows = await Supabase.instance.client
        .from('bitacora_diaria')
        .select()
        .eq('alumno_id', widget.alumnoId)
        .gte('fecha', DateFormat('yyyy-MM-dd').format(ini))
        .lte('fecha', DateFormat('yyyy-MM-dd').format(fin))
        .order('fecha', ascending: false);
    return (rows as List)
        .map((e) => Bitacora.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEC407A),
        foregroundColor: Colors.white,
        title: Text(
          'Bitácora',
          style: GoogleFonts.fredoka(fontWeight: FontWeight.w600),
        ),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Por día'),
            Tab(text: 'Por mes'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _tabPorDia(),
          _tabPorMes(),
        ],
      ),
    );
  }

  Widget _tabPorDia() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.alumnoNombre,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.azulOscuro,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: _diaSeleccionado,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                locale: const Locale('es', 'MX'),
              );
              if (d != null) {
                setState(() => _diaSeleccionado =
                    DateTime(d.year, d.month, d.day));
              }
            },
            icon: const Icon(Icons.calendar_today),
            label: Text(
              DateFormat("EEEE d 'de' MMMM yyyy", 'es_MX')
                  .format(_diaSeleccionado),
              style: GoogleFonts.poppins(),
            ),
          ),
          const SizedBox(height: 20),
          FutureBuilder<Bitacora?>(
            future: _bitacoraDelDia(_diaSeleccionado),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final b = snap.data;
              if (b == null) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'Todavía no hay bitácora para este día.\n'
                      'Prueba otro día o revisa el mes.',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                );
              }
              return _tarjetaLecturaRapida(b);
            },
          ),
        ],
      ),
    );
  }

  Widget _tabPorMes() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => setState(() {
                  _mesVisible =
                      DateTime(_mesVisible.year, _mesVisible.month - 1, 1);
                }),
                icon: const Icon(Icons.chevron_left),
              ),
              TextButton(
                onPressed: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: _mesVisible,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    locale: const Locale('es', 'MX'),
                  );
                  if (d != null) {
                    setState(() =>
                        _mesVisible = DateTime(d.year, d.month, 1));
                  }
                },
                child: Text(
                  DateFormat('MMMM yyyy', 'es_MX').format(_mesVisible),
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  final next = DateTime(_mesVisible.year, _mesVisible.month + 1, 1);
                  final hoy = DateTime(DateTime.now().year, DateTime.now().month, 1);
                  if (!next.isAfter(hoy)) {
                    setState(() => _mesVisible = next);
                  }
                },
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Bitacora>>(
            future: _bitacorasDelMes(_mesVisible),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final list = snap.data ?? [];
              if (list.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'No hay registros este mes.',
                      style: GoogleFonts.poppins(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: list.length,
                itemBuilder: (context, i) {
                  final b = list[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: () => _mostrarDetalle(b),
                      borderRadius: BorderRadius.circular(12),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                DateFormat('EEE d MMM', 'es_MX').format(b.fecha),
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _lineaResumenVisual(b),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  /// Carita que coincide con el ánimo registrado (no genérica).
  static String _emojiAnimo(String? estado) {
    if (estado == null) return '😐';
    switch (estado.toLowerCase()) {
      case 'feliz':
        return '😊';
      case 'tranquilo':
      case 'normal':
        return '😌';
      case 'triste':
        return '😢';
      case 'irritable':
        return '😠';
      default:
        return '😐';
    }
  }

  static String _textoAnimo(String? estado) {
    if (estado == null) return 'Sin dato';
    switch (estado.toLowerCase()) {
      case 'feliz':
        return 'Feliz';
      case 'tranquilo':
      case 'normal':
        return 'Tranquilo';
      case 'triste':
        return 'Triste';
      case 'irritable':
        return 'Enojado';
      default:
        return estado;
    }
  }

  static (String emoji, String texto) _comioEmojiYTexto(String? comio) {
    final c = comio ?? 'no';
    if (c == 'si') return ('😋', 'Sí');
    if (c == 'mas_o_menos' || c == 'medio') return ('😐', 'Más o menos');
    return ('😕', 'No');
  }

  /// Sí → carita contenta; No → carita triste (ej. no respetó).
  static Widget _iconoSiNo(bool ok, {double tamEmoji = 32}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          ok ? '😊' : '😢',
          style: TextStyle(fontSize: tamEmoji),
        ),
        const SizedBox(width: 10),
        Text(
          ok ? 'Sí' : 'No',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: ok ? const Color(0xFF166534) : const Color(0xFFB45309),
          ),
        ),
      ],
    );
  }

  static Widget _iconoSiesta(bool durmio, {double tamEmoji = 32}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          durmio ? '😴' : '😢',
          style: TextStyle(fontSize: tamEmoji),
        ),
        const SizedBox(width: 10),
        Text(
          durmio ? 'Sí' : 'No',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: durmio ? const Color(0xFF166534) : const Color(0xFFB45309),
          ),
        ),
      ],
    );
  }

  Widget _iconoAnimo(Bitacora b, {double tamEmoji = 36}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _emojiAnimo(b.estadoAnimo),
          style: TextStyle(fontSize: tamEmoji),
        ),
        const SizedBox(width: 10),
        Text(
          _textoAnimo(b.estadoAnimo),
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _iconoComio(Bitacora b, {double tamEmoji = 32}) {
    final p = _comioEmojiYTexto(b.comio);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(p.$1, style: TextStyle(fontSize: tamEmoji)),
        const SizedBox(width: 10),
        Text(
          p.$2,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  static Widget _miniCaraSiNo(bool ok) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(ok ? '😊' : '😢', style: const TextStyle(fontSize: 26)),
        Text(
          ok ? 'Sí' : 'No',
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: ok ? const Color(0xFF166534) : const Color(0xFFB45309),
          ),
        ),
      ],
    );
  }

  static Widget _miniSiesta(bool durmio) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(durmio ? '😴' : '😢', style: const TextStyle(fontSize: 26)),
        Text(
          durmio ? 'Sí' : 'No',
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: durmio ? const Color(0xFF166534) : const Color(0xFFB45309),
          ),
        ),
      ],
    );
  }

  /// Resumen mensual: ánimo = carita real; lo demás contenta+triste + Sí/No.
  Widget _lineaResumenVisual(Bitacora b) {
    Widget mini(String titulo, Widget contenido) {
      return Container(
        width: 76,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            contenido,
            const SizedBox(height: 4),
            Text(
              titulo,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(fontSize: 9, color: Colors.grey[700]),
            ),
          ],
        ),
      );
    }

    final com = _comioEmojiYTexto(b.comio);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        mini(
          'Ánimo',
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_emojiAnimo(b.estadoAnimo),
                  style: const TextStyle(fontSize: 30)),
              Text(
                _textoAnimo(b.estadoAnimo),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                    fontSize: 9, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        mini(
          'Comió',
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(com.$1, style: const TextStyle(fontSize: 26)),
              Text(
                com.$2,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: GoogleFonts.poppins(
                    fontSize: 9, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        mini('Agua', _miniCaraSiNo(b.tomoAgua)),
        mini('Pipí', _miniCaraSiNo(b.pipi)),
        mini('Popó', _miniCaraSiNo(b.popo)),
        mini('Respeto', _miniCaraSiNo(b.respetoDemas)),
        mini('Act.', _miniCaraSiNo(b.realizoActividades)),
        mini('Dientes', _miniCaraSiNo(b.lavoDientes)),
        mini('Siesta', _miniSiesta(b.siesta)),
      ],
    );
  }

  Widget _tarjetaLecturaRapida(Bitacora b) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Resumen del día',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            ..._filas(b),
            if (b.observaciones != null && b.observaciones!.trim().isNotEmpty) ...[
              const Divider(height: 24),
              Text(
                'Notas',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                b.observaciones!,
                style: GoogleFonts.poppins(fontSize: 15),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _filas(Bitacora b) {
    final filas = <(String, Widget)>[
      ('Ánimo', _iconoAnimo(b)),
      ('Comió', _iconoComio(b)),
      ('Tomó agua', _iconoSiNo(b.tomoAgua)),
      ('Pipí', _iconoSiNo(b.pipi)),
      ('Popó', _iconoSiNo(b.popo)),
      ('Respetó', _iconoSiNo(b.respetoDemas)),
      ('Actividades', _iconoSiNo(b.realizoActividades)),
      ('Dientes', _iconoSiNo(b.lavoDientes)),
      ('Siesta', _iconoSiesta(b.siesta)),
    ];
    return filas
        .map(
          (e) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 128,
                  child: Text(
                    e.$1,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
                Expanded(child: e.$2),
              ],
            ),
          ),
        )
        .toList();
  }

  void _mostrarDetalle(Bitacora b) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.35,
        maxChildSize: 0.92,
        expand: false,
        builder: (_, sc) => SingleChildScrollView(
          controller: sc,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                DateFormat('d MMMM yyyy', 'es_MX').format(b.fecha),
                style: GoogleFonts.fredoka(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ..._filas(b),
              if (b.observaciones != null &&
                  b.observaciones!.trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Notas: ${b.observaciones}', style: GoogleFonts.poppins()),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
