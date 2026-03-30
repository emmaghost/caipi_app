import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/app_colors.dart';
import '../../models/bitacora.dart';
import '../../models/grado.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_drawer.dart';

class BitacorasScreen extends StatefulWidget {
  const BitacorasScreen({super.key});

  @override
  State<BitacorasScreen> createState() => _BitacorasScreenState();
}

class _BitacorasScreenState extends State<BitacorasScreen> {
  DateTime _fechaSeleccionada = DateTime.now();
  bool _rolListo = false;
  bool _esDirectora = true;
  bool _profesoraSinGrupo = false;

  List<Grado> _grados = [];
  String? _gradoFiltroId;
  String _nombreGrupo = '';
  /// id → nombre completo (alumnos del grupo seleccionado)
  final List<MapEntry<String, String>> _alumnosOrdenados = [];
  String? _alumnoFiltroId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargarRol());
  }

  Future<void> _cargarAlumnosDelGrado(String gradoId) async {
    final res = await Supabase.instance.client
        .from('alumnos')
        .select('id, nombre, apellidos')
        .eq('grado_id', gradoId)
        .eq('activo', true);
    final list = (res as List)
        .map((e) {
          final m = e as Map<String, dynamic>;
          final id = m['id'] as String;
          final nom =
              '${m['nombre'] ?? ''} ${m['apellidos'] ?? ''}'.trim();
          return MapEntry(id, nom.isEmpty ? 'Alumno' : nom);
        })
        .toList();
    list.sort((a, b) => a.value.toLowerCase().compareTo(b.value.toLowerCase()));
    if (!mounted) return;
    setState(() {
      _alumnosOrdenados
        ..clear()
        ..addAll(list);
    });
  }

  Future<void> _cargarRol() async {
    final auth = context.read<AuthService>();
    _esDirectora = auth.isDirectora;
    final client = Supabase.instance.client;

    if (_esDirectora) {
      final g = await client
          .from('grados')
          .select()
          .eq('activo', true)
          .order('nombre');
      _grados = (g as List).map((e) => Grado.fromJson(e as Map<String, dynamic>)).toList();
      if (_grados.isNotEmpty) {
        _gradoFiltroId = _grados.first.id;
        _nombreGrupo = _grados.first.nombre;
        await _cargarAlumnosDelGrado(_gradoFiltroId!);
      }
    } else {
      final uid = client.auth.currentUser?.id;
      if (uid != null) {
        final pr = await client
            .from('profesores')
            .select('grado_id')
            .eq('usuario_id', uid)
            .eq('activo', true)
            .maybeSingle();
        final gid = pr?['grado_id'] as String?;
        if (gid != null && gid.isNotEmpty) {
          _gradoFiltroId = gid;
          final gr = await client.from('grados').select('nombre').eq('id', gid).maybeSingle();
          _nombreGrupo = (gr?['nombre'] as String?) ?? 'Mi grupo';
          await _cargarAlumnosDelGrado(gid);
        } else {
          _profesoraSinGrupo = true;
        }
      }
    }

    if (mounted) setState(() => _rolListo = true);
  }

  Future<void> _onGradoDirectoraChanged(String? nuevoId) async {
    if (nuevoId == null || nuevoId == _gradoFiltroId) return;
    final i = _grados.indexWhere((gr) => gr.id == nuevoId);
    final nombre = i >= 0 ? _grados[i].nombre : '';
    setState(() {
      _gradoFiltroId = nuevoId;
      _alumnoFiltroId = null;
      _nombreGrupo = nombre;
    });
    await _cargarAlumnosDelGrado(nuevoId);
  }

  Set<String> get _idsAlumnosGrupo =>
      _alumnosOrdenados.map((e) => e.key).toSet();

  List<Bitacora> _filtrarYOrdenar(List<Map<String, dynamic>> raw) {
    if (!_esDirectora && (_profesoraSinGrupo || _idsAlumnosGrupo.isEmpty)) {
      return [];
    }
    if (_esDirectora && (_gradoFiltroId == null || _idsAlumnosGrupo.isEmpty)) {
      return [];
    }

    final nameMap = Map<String, String>.fromEntries(_alumnosOrdenados);
    var list = raw
        .map((j) => Bitacora.fromJson(j))
        .where((b) => _idsAlumnosGrupo.contains(b.alumnoId))
        .toList();

    if (_alumnoFiltroId != null) {
      list = list.where((b) => b.alumnoId == _alumnoFiltroId).toList();
    }

    list.sort((a, b) {
      final na = nameMap[a.alumnoId] ?? '';
      final nb = nameMap[b.alumnoId] ?? '';
      return na.toLowerCase().compareTo(nb.toLowerCase());
    });
    return list;
  }

  bool get _puedeVerLista =>
      _esDirectora
          ? _gradoFiltroId != null && _alumnosOrdenados.isNotEmpty
          : !_profesoraSinGrupo && _alumnosOrdenados.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.rosaClaro,
      appBar: AppBar(
        backgroundColor: AppColors.morado,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            const Icon(Icons.assignment, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              'Bitácora Diaria',
              style: GoogleFonts.fredoka(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today, color: Colors.white),
            onPressed: _seleccionarFecha,
          ),
          IconButton(
            icon: const Icon(Icons.home, color: Colors.white),
            onPressed: () => GoRouter.of(context).go('/directora'),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.morado.withOpacity(0.35)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.rosaClaro,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child:
                            Icon(Icons.event, color: AppColors.morado, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Vista por día',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              DateFormat('EEEE, dd \'de\' MMMM yyyy', 'es_MX')
                                  .format(_fechaSeleccionada),
                              style: GoogleFonts.fredoka(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF4A3F55),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.edit_calendar, color: AppColors.morado),
                        onPressed: _seleccionarFecha,
                      ),
                    ],
                  ),
                  if (_rolListo) ...[
                    const SizedBox(height: 14),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    if (_esDirectora && _grados.isNotEmpty) ...[
                      Text(
                        'Grupo / salón',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: _gradoFiltroId,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.rosaClaro.withOpacity(0.5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: AppColors.morado.withOpacity(0.3)),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                        ),
                        items: _grados
                            .map(
                              (gr) => DropdownMenuItem(
                                value: gr.id,
                                child: Text(gr.nombre,
                                    style: GoogleFonts.poppins()),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => _onGradoDirectoraChanged(v),
                      ),
                    ] else if (!_esDirectora && !_profesoraSinGrupo) ...[
                      Row(
                        children: [
                          Icon(Icons.groups_2, color: AppColors.morado, size: 22),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Grupo: $_nombreGrupo',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF4A3F55),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (_puedeVerLista) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Alumno',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String?>(
                        value: _alumnoFiltroId,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.rosaClaro.withOpacity(0.5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: AppColors.morado.withOpacity(0.3)),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                        ),
                        items: [
                          DropdownMenuItem<String?>(
                            value: null,
                            child: Text(
                              'Todos los niños del grupo',
                              style: GoogleFonts.poppins(),
                            ),
                          ),
                          ..._alumnosOrdenados.map(
                            (e) => DropdownMenuItem<String?>(
                              value: e.key,
                              child: Text(e.value,
                                  style: GoogleFonts.poppins(),
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ),
                        ],
                        onChanged: (v) => setState(() => _alumnoFiltroId = v),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),

          Expanded(
            child: !_rolListo
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.morado))
                : !_puedeVerLista
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.groups_outlined,
                                size: 64,
                                color: AppColors.morado.withOpacity(0.4),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _profesoraSinGrupo && !_esDirectora
                                    ? 'No tienes grupo asignado. La directora debe asignarte un grado.'
                                    : _esDirectora && _grados.isEmpty
                                        ? 'No hay grupos activos.'
                                        : 'No hay alumnos en este grupo.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : StreamBuilder<List<Map<String, dynamic>>>(
                        stream: Supabase.instance.client
                            .from('bitacora_diaria')
                            .stream(primaryKey: ['id'])
                            .eq(
                              'fecha',
                              DateFormat('yyyy-MM-dd')
                                  .format(_fechaSeleccionada),
                            )
                            .order('created_at', ascending: false),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }

                          if (snapshot.hasError) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.error_outline,
                                      size: 64, color: Colors.red),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Error al cargar bitácoras',
                                    style: GoogleFonts.poppins(fontSize: 18),
                                  ),
                                ],
                              ),
                            );
                          }

                          final raw = snapshot.data ?? [];
                          final bitacoras = _filtrarYOrdenar(raw);
                          var nombreAlumnoSel = '';
                          if (_alumnoFiltroId != null) {
                            for (final e in _alumnosOrdenados) {
                              if (e.key == _alumnoFiltroId) {
                                nombreAlumnoSel = e.value;
                                break;
                              }
                            }
                          }
                          final subtitulo =
                              '${bitacoras.length} registro${bitacoras.length == 1 ? '' : 's'} · $_nombreGrupo'
                              '${nombreAlumnoSel.isNotEmpty ? ' · $nombreAlumnoSel' : ''}';

                          if (bitacoras.isEmpty) {
                            return ListView(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                              children: [
                                Text(
                                  subtitulo,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Center(
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.assignment_outlined,
                                        size: 72,
                                        color: AppColors.morado.withOpacity(0.4),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        _alumnoFiltroId != null
                                            ? 'Este alumno no tiene bitácora en la fecha elegida.'
                                            : raw.isNotEmpty
                                                ? 'Ningún niño de este grupo tiene bitácora este día.'
                                                : 'No hay bitácoras para esta fecha.',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      if (_esDirectora || !_profesoraSinGrupo) ...[
                                        const SizedBox(height: 24),
                                        ElevatedButton.icon(
                                          onPressed: () {
                                            GoRouter.of(context).push(
                                              '/directora/bitacoras/crear',
                                              extra: {
                                                'fecha': _fechaSeleccionada,
                                              },
                                            );
                                          },
                                          icon: const Icon(Icons.add,
                                              color: Colors.white),
                                          label: const Text('Crear bitácora'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.morado,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 24,
                                              vertical: 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 0, 20, 8),
                                child: Text(
                                  subtitulo,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: Colors.grey[800],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: ListView.builder(
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 0, 16, 88),
                                  itemCount: bitacoras.length,
                                  itemBuilder: (context, index) {
                                    return _BitacoraCard(
                                        bitacora: bitacoras[index]);
                                  },
                                ),
                              ),
                            ],
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: (_esDirectora || !_profesoraSinGrupo)
          ? FloatingActionButton.extended(
              onPressed: () {
                GoRouter.of(context).push(
                  '/directora/bitacoras/crear',
                  extra: {'fecha': _fechaSeleccionada},
                );
              },
              backgroundColor: const Color(0xFF166534),
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(
                'Nueva bitácora',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : null,
    );
  }

  Future<void> _seleccionarFecha() async {
    final hoy = DateTime(
        DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final fecha = await showDatePicker(
      context: context,
      initialDate:
          _fechaSeleccionada.isAfter(hoy) ? hoy : _fechaSeleccionada,
      firstDate: DateTime(2020),
      lastDate: hoy,
      locale: const Locale('es', 'MX'),
    );

    if (fecha != null) {
      setState(() {
        _fechaSeleccionada = DateTime(fecha.year, fecha.month, fecha.day);
      });
    }
  }
}

class _BitacoraCard extends StatelessWidget {
  final Bitacora bitacora;

  const _BitacoraCard({required this.bitacora});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () {
          _mostrarDetalle(context);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: _getColorEstadoAnimo(bitacora.estadoAnimo),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        _getEmojiEstadoAnimo(bitacora.estadoAnimo),
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FutureBuilder<Map<String, dynamic>>(
                          future: _cargarAlumno(bitacora.alumnoId),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const Text('Cargando...');
                            }
                            final alumno = snapshot.data!;
                            return Text(
                              '${alumno['nombre']} ${alumno['apellidos']}',
                              style: GoogleFonts.fredoka(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.morado,
                              ),
                            );
                          },
                        ),
                        Text(
                          'Estado: ${bitacora.estadoAnimo}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.edit, color: AppColors.morado),
                    onPressed: () {
                      GoRouter.of(context).push(
                        '/directora/bitacoras/editar/${bitacora.id}',
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildChipComio(bitacora.comio),
                  _buildIndicador(
                    icon: Icons.local_drink,
                    label: 'Agua',
                    valor: bitacora.tomoAgua,
                  ),
                  _buildIndicador(
                    icon: Icons.water_drop,
                    label: 'Pipí',
                    valor: bitacora.pipi,
                  ),
                  _buildIndicador(
                    icon: Icons.radio_button_checked,
                    label: 'Popó',
                    valor: bitacora.popo,
                  ),
                  _buildIndicador(
                    icon: Icons.groups,
                    label: 'Respeto',
                    valor: bitacora.respetoDemas,
                  ),
                  _buildIndicador(
                    icon: Icons.draw,
                    label: 'Actividades',
                    valor: bitacora.realizoActividades,
                  ),
                  _buildIndicador(
                    icon: Icons.sentiment_very_satisfied,
                    label: 'Dientes',
                    valor: bitacora.lavoDientes,
                  ),
                  _buildIndicador(
                    icon: Icons.bed,
                    label: 'Siesta',
                    valor: bitacora.siesta,
                  ),
                ],
              ),
              if (bitacora.observaciones != null &&
                  bitacora.observaciones!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.notes, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          bitacora.observaciones!,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChipComio(String? comio) {
    final c = comio ?? 'no';
    late Color border;
    late Color bg;
    late Color fg;
    late String txt;
    switch (c) {
      case 'si':
        border = Colors.green;
        bg = Colors.green.shade50;
        fg = Colors.green.shade800;
        txt = 'Comió: Sí';
        break;
      case 'medio':
      case 'mas_o_menos':
        border = Colors.orange;
        bg = Colors.orange.shade50;
        fg = Colors.orange.shade900;
        txt = 'Comió: Más o menos';
        break;
      default:
        border = Colors.red;
        bg = Colors.red.shade50;
        fg = Colors.red.shade800;
        txt = 'Comió: No';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.restaurant, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(
            txt,
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600, color: fg),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicador({
    required IconData icon,
    required String label,
    required bool valor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: valor ? Colors.green[50] : Colors.red[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: valor ? Colors.green : Colors.red,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: valor ? Colors.green[700] : Colors.red[700],
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: valor ? Colors.green[700] : Colors.red[700],
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            valor ? Icons.check_circle : Icons.cancel,
            size: 12,
            color: valor ? Colors.green : Colors.red,
          ),
        ],
      ),
    );
  }

  Color _getColorEstadoAnimo(String? estadoAnimo) {
    if (estadoAnimo == null) return Colors.grey[300]!;
    switch (estadoAnimo.toLowerCase()) {
      case 'feliz':
        return Colors.green[100]!;
      case 'tranquilo':
        return Colors.blue[100]!;
      case 'triste':
        return Colors.orange[100]!;
      case 'irritable':
        return Colors.red[100]!;
      default:
        return Colors.grey[100]!;
    }
  }

  String _getEmojiEstadoAnimo(String? estadoAnimo) {
    if (estadoAnimo == null) return '😐';
    switch (estadoAnimo.toLowerCase()) {
      case 'feliz':
        return '😊';
      case 'tranquilo':
        return '😌';
      case 'triste':
        return '😢';
      case 'irritable':
        return '😠';
      default:
        return '😐';
    }
  }

  Future<Map<String, dynamic>> _cargarAlumno(String alumnoId) async {
    final response = await Supabase.instance.client
        .from('alumnos')
        .select('nombre, apellidos')
        .eq('id', alumnoId)
        .single();
    return response;
  }

  void _mostrarDetalle(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Detalle de Bitácora',
          style: GoogleFonts.fredoka(),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetalleItem(
                  'Estado de Ánimo', bitacora.estadoAnimo ?? 'No registrado'),
              _buildDetalleItem('Comió', Bitacora.etiquetaComio(bitacora.comio)),
              _buildDetalleItem('Tomó agua', bitacora.tomoAgua ? 'Sí' : 'No'),
              _buildDetalleItem('Pipí', bitacora.pipi ? 'Sí' : 'No'),
              _buildDetalleItem('Popó', bitacora.popo ? 'Sí' : 'No'),
              _buildDetalleItem(
                  'Respetó a los demás', bitacora.respetoDemas ? 'Sí' : 'No'),
              _buildDetalleItem('Realizó actividades',
                  bitacora.realizoActividades ? 'Sí' : 'No'),
              _buildDetalleItem(
                  'Se lavó los dientes', bitacora.lavoDientes ? 'Sí' : 'No'),
              _buildDetalleItem('Siesta', bitacora.siesta ? 'Sí' : 'No'),
              if (bitacora.observaciones != null &&
                  bitacora.observaciones!.isNotEmpty)
                _buildDetalleItem('Observaciones', bitacora.observaciones!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              GoRouter.of(context).push(
                '/directora/bitacoras/editar/${bitacora.id}',
              );
            },
            child: const Text('Editar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetalleItem(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            valor,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
}
