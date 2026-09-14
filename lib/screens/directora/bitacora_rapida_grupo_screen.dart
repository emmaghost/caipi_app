import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../config/app_colors.dart';
import '../../models/alumno.dart';
import '../../models/bitacora.dart';
import '../../models/grado.dart';
import '../../services/auth_service.dart';
import '../../services/profesor_grupos_service.dart';
import '../../widgets/caipi_app_bar_leading.dart';

/// Bitácora del grupo: llena a varios niños a la vez (chips + aplicar a todos).
class BitacoraRapidaGrupoScreen extends StatefulWidget {
  final DateTime? fechaInicial;

  const BitacoraRapidaGrupoScreen({super.key, this.fechaInicial});

  @override
  State<BitacoraRapidaGrupoScreen> createState() =>
      _BitacoraRapidaGrupoScreenState();
}

class _FilaAlumnoBitacora {
  _FilaAlumnoBitacora({required this.alumno});

  final Alumno alumno;
  String? bitacoraId;
  bool incluir = true;
  bool expandido = false;

  String comio = 'si';
  bool tomoAgua = true;
  bool pipi = true;
  bool popo = false;
  bool lavoDientes = true;
  bool respetoDemas = true;
  bool realizoActividades = true;
  bool siesta = false;
  String estadoAnimo = 'Feliz';
  bool huboIncidencia = false;
  final tipoIncidencia = TextEditingController();
  final observaciones = TextEditingController();

  void dispose() {
    tipoIncidencia.dispose();
    observaciones.dispose();
  }

  void aplicarPlantilla(_Plantilla p) {
    comio = p.comio;
    tomoAgua = p.tomoAgua;
    pipi = p.pipi;
    popo = p.popo;
    lavoDientes = p.lavoDientes;
    respetoDemas = p.respetoDemas;
    realizoActividades = p.realizoActividades;
    siesta = p.siesta;
    estadoAnimo = p.estadoAnimo;
  }

  void desdeBitacora(Bitacora b) {
    bitacoraId = b.id;
    final c = b.comio ?? 'si';
    comio = (c == 'medio' || c == 'mas_o_menos') ? 'mas_o_menos' : c;
    tomoAgua = b.tomoAgua;
    pipi = b.pipi;
    popo = b.popo;
    lavoDientes = b.lavoDientes;
    respetoDemas = b.respetoDemas;
    realizoActividades = b.realizoActividades;
    siesta = b.siesta;
    estadoAnimo = b.estadoAnimo ?? 'Feliz';
    huboIncidencia = b.huboIncidencia;
    tipoIncidencia.text = b.tipoIncidencia ?? '';
    observaciones.text = b.observaciones ?? '';
  }

  Map<String, dynamic> toPayload({
    required DateTime fecha,
    required String? profesorId,
    required bool esNuevo,
  }) {
    final now = DateTime.now().toIso8601String();
    final data = <String, dynamic>{
      'alumno_id': alumno.id,
      'fecha': DateFormat('yyyy-MM-dd').format(fecha),
      'comio': comio == 'mas_o_menos' ? 'medio' : comio,
      'tomo_agua': tomoAgua,
      'pipi': pipi,
      'popo': popo,
      'lavo_dientes': lavoDientes,
      'respeto_demas': respetoDemas,
      'realizo_actividades': realizoActividades,
      'siesta': siesta,
      'estado_animo': estadoAnimo,
      'hubo_incidencia': huboIncidencia,
      'tipo_incidencia':
          huboIncidencia ? tipoIncidencia.text.trim() : null,
      'observaciones': observaciones.text.trim().isEmpty
          ? null
          : observaciones.text.trim(),
      'updated_at': now,
    };
    if (esNuevo) {
      data['id'] = const Uuid().v4();
      data['created_at'] = now;
      data['profesor_id'] = profesorId;
    }
    return data;
  }
}

class _Plantilla {
  String comio = 'si';
  bool tomoAgua = true;
  bool pipi = true;
  bool popo = false;
  bool lavoDientes = true;
  bool respetoDemas = true;
  bool realizoActividades = true;
  bool siesta = false;
  String estadoAnimo = 'Feliz';
}

class _BitacoraRapidaGrupoScreenState extends State<BitacoraRapidaGrupoScreen> {
  static const _estadosAnimo = ['Feliz', 'Tranquilo', 'Triste', 'Irritable'];

  final _plantilla = _Plantilla();
  final _filas = <_FilaAlumnoBitacora>[];

  DateTime _fecha = DateTime.now();
  bool _cargando = true;
  bool _guardando = false;
  bool _esDirectora = false;
  String? _miProfesorId;
  List<Grado> _grados = [];
  String? _gradoId;
  String _nombreGrupo = '';

  DateTime _soloFecha(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  void initState() {
    super.initState();
    if (widget.fechaInicial != null) {
      _fecha = _soloFecha(widget.fechaInicial!);
    } else {
      _fecha = _soloFecha(DateTime.now());
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _boot());
  }

  @override
  void dispose() {
    for (final f in _filas) {
      f.dispose();
    }
    super.dispose();
  }

  Future<void> _boot() async {
    setState(() => _cargando = true);
    try {
      final auth = context.read<AuthService>();
      _esDirectora = auth.isDirectora;
      final client = Supabase.instance.client;
      final uid = client.auth.currentUser?.id;

      if (_esDirectora) {
        final gr = await client
            .from('grados')
            .select()
            .eq('activo', true)
            .order('nombre');
        _grados = (gr as List)
            .map((j) => Grado.fromJson(Map<String, dynamic>.from(j as Map)))
            .toList();
        if (_grados.isNotEmpty) {
          _gradoId = _grados.first.id;
          _nombreGrupo = _grados.first.nombre;
        }
      } else if (uid != null) {
        final pr = await client
            .from('profesores')
            .select('id')
            .eq('usuario_id', uid)
            .eq('activo', true)
            .maybeSingle();
        _miProfesorId = pr?['id'] as String?;

        final gradoIds =
            await ProfesorGruposService().gradoIdsDeUsuario(uid);
        if (gradoIds.isEmpty) {
          if (mounted) {
            setState(() {
              _cargando = false;
              _gradoId = null;
            });
          }
          return;
        }
        final gr = await client
            .from('grados')
            .select()
            .inFilter('id', gradoIds)
            .eq('activo', true)
            .order('nombre');
        _grados = (gr as List)
            .map((j) => Grado.fromJson(Map<String, dynamic>.from(j as Map)))
            .toList();
        _gradoId = _grados.isNotEmpty ? _grados.first.id : gradoIds.first;
        _nombreGrupo = _grados.isNotEmpty
            ? _grados.first.nombre
            : 'Mi grupo';
      }

      if (_gradoId != null) {
        await _cargarAlumnosYBitacoras();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
    if (mounted) setState(() => _cargando = false);
  }

  Future<void> _cargarAlumnosYBitacoras() async {
    if (_gradoId == null) return;
    final client = Supabase.instance.client;
    final al = await client
        .from('alumnos')
        .select()
        .eq('grado_id', _gradoId!)
        .eq('activo', true)
        .order('apellidos')
        .order('nombre');
    final alumnos = (al as List)
        .map((j) => Alumno.fromJson(Map<String, dynamic>.from(j as Map)))
        .toList();

    for (final f in _filas) {
      f.dispose();
    }
    _filas
      ..clear()
      ..addAll(alumnos.map((a) => _FilaAlumnoBitacora(alumno: a)));

    if (_filas.isEmpty) return;

    final ids = _filas.map((f) => f.alumno.id).toList();
    final fechaStr = DateFormat('yyyy-MM-dd').format(_fecha);
    final bit = await client
        .from('bitacora_diaria')
        .select()
        .eq('fecha', fechaStr)
        .inFilter('alumno_id', ids);

    final porAlumno = <String, Bitacora>{};
    for (final row in bit as List) {
      final b = Bitacora.fromJson(Map<String, dynamic>.from(row as Map));
      porAlumno[b.alumnoId] = b;
    }

    for (final f in _filas) {
      final existente = porAlumno[f.alumno.id];
      if (existente != null) {
        f.desdeBitacora(existente);
        // Ya calificados: desmarcados para no pisarlos al guardar de nuevo.
        f.incluir = false;
      } else {
        f.aplicarPlantilla(_plantilla);
        f.incluir = true;
      }
    }
    // Pendientes primero, luego los que ya tienen bitácora.
    _filas.sort((a, b) {
      final aOk = a.bitacoraId != null;
      final bOk = b.bitacoraId != null;
      if (aOk == bOk) {
        return a.alumno.nombreCompleto
            .toLowerCase()
            .compareTo(b.alumno.nombreCompleto.toLowerCase());
      }
      return aOk ? 1 : -1;
    });
  }

  Future<void> _cambiarFecha() async {
    final hoy = _soloFecha(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: _fecha.isAfter(hoy) ? hoy : _fecha,
      firstDate: DateTime(2020),
      lastDate: hoy,
      locale: const Locale('es', 'MX'),
    );
    if (picked == null) return;
    setState(() {
      _fecha = _soloFecha(picked);
      _cargando = true;
    });
    try {
      await _cargarAlumnosYBitacoras();
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _cambiarGrado(String? id) async {
    if (id == null || id == _gradoId) return;
    final g = _grados.where((x) => x.id == id).firstOrNull;
    setState(() {
      _gradoId = id;
      _nombreGrupo = g?.nombre ?? '';
      _cargando = true;
    });
    try {
      await _cargarAlumnosYBitacoras();
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _aplicarATodos() {
    setState(() {
      for (final f in _filas) {
        if (f.incluir) f.aplicarPlantilla(_plantilla);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Valores aplicados a ${_filas.where((f) => f.incluir).length} alumnos',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: Colors.green.shade700,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _guardarTodas() async {
    final aGuardar = _filas.where((f) => f.incluir).toList();
    if (aGuardar.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Marca al menos un alumno'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!_esDirectora && _miProfesorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Tu usuario no está registrado como profesora. Contacta a la directora.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _guardando = true);
    final client = Supabase.instance.client;
    var ok = 0;
    var errores = 0;

    try {
      for (final f in aGuardar) {
        try {
          final esNuevo = f.bitacoraId == null;
          final data = f.toPayload(
            fecha: _fecha,
            profesorId: _esDirectora ? null : _miProfesorId,
            esNuevo: esNuevo,
          );
          if (esNuevo) {
            await client.from('bitacora_diaria').insert(data);
            f.bitacoraId = data['id'] as String;
          } else {
            await client
                .from('bitacora_diaria')
                .update(data)
                .eq('id', f.bitacoraId!);
          }
          ok++;
        } catch (_) {
          errores++;
        }
      }

      if (!mounted) return;
      if (errores == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Guardadas $ok bitácoras'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/directora/bitacoras');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Guardadas $ok. Fallaron $errores.'),
            backgroundColor: Colors.deepOrange,
            duration: const Duration(seconds: 5),
          ),
        );
        setState(() {});
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 700;
    final sinGrupo = !_esDirectora && _gradoId == null && !_cargando;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FA),
      appBar: AppBar(
        backgroundColor: AppColors.morado,
        foregroundColor: Colors.white,
        leading: const CaipiAppBarLeading(),
        title: Text(
          'Bitácora del grupo',
          style: GoogleFonts.fredoka(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: _cargando ? null : _cambiarFecha,
            icon: const Icon(Icons.calendar_today, color: Colors.white, size: 18),
            label: Text(
              DateFormat('d MMM', 'es').format(_fecha),
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : sinGrupo
              ? _mensajeSinGrupo()
              : Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.fromLTRB(
                          wide ? 24 : 12,
                          12,
                          wide ? 24 : 12,
                          100,
                        ),
                        children: [
                          if (_grados.length > 1) ...[
                            DropdownButtonFormField<String>(
                              key: ValueKey(_gradoId),
                              value: _gradoId,
                              decoration: InputDecoration(
                                labelText: 'Grupo',
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              items: _grados
                                  .map(
                                    (g) => DropdownMenuItem(
                                      value: g.id,
                                      child: Text(g.nombre),
                                    ),
                                  )
                                  .toList(),
                              onChanged: _cambiarGrado,
                            ),
                            const SizedBox(height: 12),
                          ] else if (_nombreGrupo.isNotEmpty) ...[
                            Text(
                              _nombreGrupo,
                              style: GoogleFonts.fredoka(
                                fontSize: 16,
                                color: AppColors.morado,
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          _tarjetaPlantilla(),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Alumnos (${_filas.length})',
                                      style: GoogleFonts.fredoka(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (_filas.isNotEmpty)
                                      Text(
                                        _resumenDia,
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: _faltan > 0
                                              ? Colors.deepOrange.shade800
                                              : Colors.green.shade800,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: () => setState(() {
                                  for (final f in _filas) {
                                    f.incluir = f.bitacoraId == null;
                                  }
                                }),
                                child: const Text('Solo faltantes'),
                              ),
                              TextButton(
                                onPressed: () => setState(() {
                                  for (final f in _filas) {
                                    f.incluir = true;
                                  }
                                }),
                                child: const Text('Todos'),
                              ),
                            ],
                          ),
                          if (_filas.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                'No hay alumnos activos en este grupo.',
                                style: GoogleFonts.poppins(),
                                textAlign: TextAlign.center,
                              ),
                            )
                          else
                            ..._filas.map(_tarjetaAlumno),
                        ],
                      ),
                    ),
                    SafeArea(
                      top: false,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 8,
                              offset: const Offset(0, -2),
                            ),
                          ],
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: _guardando || _filas.isEmpty
                                ? null
                                : _guardarTodas,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF166534),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: _guardando
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.save),
                            label: Text(
                              _guardando
                                  ? 'Guardando…'
                                  : 'Guardar ${_filas.where((f) => f.incluir).length} bitácoras',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  int get _listos => _filas.where((f) => f.bitacoraId != null).length;
  int get _faltan => _filas.length - _listos;
  String get _resumenDia {
    if (_filas.isEmpty) return '';
    if (_faltan == 0) {
      return 'Listas $_listos de ${_filas.length} · ninguna pendiente';
    }
    return 'Listas $_listos de ${_filas.length} · faltan $_faltan';
  }

  Widget _mensajeSinGrupo() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'No tienes un grupo asignado. Pide a la directora que te asigne un grado.',
          style: GoogleFonts.poppins(fontSize: 15),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _tarjetaPlantilla() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppColors.rosa.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flash_on, color: AppColors.morado),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Valores para todos',
                    style: GoogleFonts.fredoka(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                FilledButton.tonal(
                  onPressed: _filas.isEmpty ? null : _aplicarATodos,
                  child: const Text('Aplicar a todos'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Ajusta aquí y toca “Aplicar a todos”. Luego cambia solo quien sea distinto.',
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[700]),
            ),
            const SizedBox(height: 12),
            _etiquetaSeccion('Comió', Icons.restaurant),
            const SizedBox(height: 6),
            _filaComio(
              valor: _plantilla.comio,
              onChanged: (v) => setState(() => _plantilla.comio = v),
            ),
            const SizedBox(height: 12),
            _etiquetaSeccion('Estado de ánimo', Icons.mood),
            const SizedBox(height: 6),
            _filaAnimo(
              valor: _plantilla.estadoAnimo,
              onChanged: (v) => setState(() => _plantilla.estadoAnimo = v),
            ),
            const SizedBox(height: 12),
            _etiquetaSeccion('Actividades del día', Icons.checklist),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                _chipToggle(
                  'Agua',
                  _plantilla.tomoAgua,
                  (v) => setState(() => _plantilla.tomoAgua = v),
                ),
                _chipToggle(
                  'Pipí',
                  _plantilla.pipi,
                  (v) => setState(() => _plantilla.pipi = v),
                ),
                _chipToggle(
                  'Popó',
                  _plantilla.popo,
                  (v) => setState(() => _plantilla.popo = v),
                ),
                _chipToggle(
                  'Dientes',
                  _plantilla.lavoDientes,
                  (v) => setState(() => _plantilla.lavoDientes = v),
                ),
                _chipToggle(
                  'Respetó',
                  _plantilla.respetoDemas,
                  (v) => setState(() => _plantilla.respetoDemas = v),
                ),
                _chipToggle(
                  'Actividades',
                  _plantilla.realizoActividades,
                  (v) => setState(() => _plantilla.realizoActividades = v),
                ),
                _chipToggle(
                  'Siesta',
                  _plantilla.siesta,
                  (v) => setState(() => _plantilla.siesta = v),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _tarjetaAlumno(_FilaAlumnoBitacora f) {
    final yaExiste = f.bitacoraId != null;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: f.incluir ? Colors.white : Colors.grey.shade100,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: yaExiste
              ? Colors.green.shade300
              : Colors.deepOrange.shade200,
          width: yaExiste ? 1 : 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Checkbox(
                  value: f.incluir,
                  activeColor: AppColors.morado,
                  onChanged: (v) =>
                      setState(() => f.incluir = v ?? false),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        f.alumno.nombreCompleto,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: yaExiste
                              ? Colors.green.shade50
                              : Colors.deepOrange.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          yaExiste
                              ? 'Listo · ya tiene bitácora'
                              : 'Pendiente · falta calificar',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: yaExiste
                                ? Colors.green.shade800
                                : Colors.deepOrange.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: f.expandido
                      ? 'Ocultar detalle'
                      : 'Incidencia / notas',
                  onPressed: () =>
                      setState(() => f.expandido = !f.expandido),
                  icon: Icon(
                    f.huboIncidencia || f.observaciones.text.isNotEmpty
                        ? Icons.note_alt
                        : (f.expandido
                            ? Icons.expand_less
                            : Icons.expand_more),
                    color: f.huboIncidencia
                        ? Colors.deepOrange
                        : Colors.grey[700],
                  ),
                ),
              ],
            ),
            if (f.incluir) ...[
              _etiquetaSeccion('Comió', Icons.restaurant, small: true),
              const SizedBox(height: 4),
              _filaComio(
                valor: f.comio,
                dense: true,
                onChanged: (v) => setState(() => f.comio = v),
              ),
              const SizedBox(height: 8),
              _etiquetaSeccion('Estado de ánimo', Icons.mood, small: true),
              const SizedBox(height: 4),
              _filaAnimo(
                valor: f.estadoAnimo,
                dense: true,
                onChanged: (v) => setState(() => f.estadoAnimo = v),
              ),
              const SizedBox(height: 8),
              _etiquetaSeccion('Actividades', Icons.checklist, small: true),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  _chipToggle('Agua', f.tomoAgua,
                      (v) => setState(() => f.tomoAgua = v),
                      dense: true),
                  _chipToggle(
                      'Pipí', f.pipi, (v) => setState(() => f.pipi = v),
                      dense: true),
                  _chipToggle(
                      'Popó', f.popo, (v) => setState(() => f.popo = v),
                      dense: true),
                  _chipToggle('Dientes', f.lavoDientes,
                      (v) => setState(() => f.lavoDientes = v),
                      dense: true),
                  _chipToggle('Respetó', f.respetoDemas,
                      (v) => setState(() => f.respetoDemas = v),
                      dense: true),
                  _chipToggle('Actividades', f.realizoActividades,
                      (v) => setState(() => f.realizoActividades = v),
                      dense: true),
                  _chipToggle('Siesta', f.siesta,
                      (v) => setState(() => f.siesta = v),
                      dense: true),
                ],
              ),
              if (f.expandido) ...[
                const SizedBox(height: 10),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(
                    'Hubo incidencia',
                    style: GoogleFonts.poppins(fontSize: 13),
                  ),
                  value: f.huboIncidencia,
                  activeThumbColor: Colors.deepOrange,
                  onChanged: (v) => setState(() => f.huboIncidencia = v),
                ),
                if (f.huboIncidencia)
                  TextField(
                    controller: f.tipoIncidencia,
                    decoration: InputDecoration(
                      labelText: 'Tipo de incidencia',
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                TextField(
                  controller: f.observaciones,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Notas (opcional)',
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _etiquetaSeccion(String texto, IconData icono, {bool small = false}) {
    return Row(
      children: [
        Icon(icono, size: small ? 14 : 16, color: AppColors.morado),
        const SizedBox(width: 4),
        Text(
          texto,
          style: GoogleFonts.poppins(
            fontSize: small ? 11 : 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF4A3F55),
          ),
        ),
      ],
    );
  }

  /// Semáforo: verde = sí, amarillo = más o menos, rojo = no.
  Widget _filaComio({
    required String valor,
    required ValueChanged<String> onChanged,
    bool dense = false,
  }) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        _chipSemaforo(
          label: dense ? 'Sí' : 'Sí comió',
          selected: valor == 'si',
          color: const Color(0xFF16A34A),
          fill: const Color(0xFFDCFCE7),
          onTap: () => onChanged('si'),
          dense: dense,
        ),
        _chipSemaforo(
          label: dense ? '±' : 'Más o menos',
          selected: valor == 'mas_o_menos',
          color: const Color(0xFFCA8A04),
          fill: const Color(0xFFFEF9C3),
          onTap: () => onChanged('mas_o_menos'),
          dense: dense,
        ),
        _chipSemaforo(
          label: dense ? 'No' : 'No comió',
          selected: valor == 'no',
          color: const Color(0xFFDC2626),
          fill: const Color(0xFFFEE2E2),
          onTap: () => onChanged('no'),
          dense: dense,
        ),
      ],
    );
  }

  Widget _filaAnimo({
    required String valor,
    required ValueChanged<String> onChanged,
    bool dense = false,
  }) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: _estadosAnimo.map((estado) {
        final selected = valor == estado;
        final color = _colorAnimo(estado);
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onChanged(estado),
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: EdgeInsets.symmetric(
                horizontal: dense ? 8 : 10,
                vertical: dense ? 6 : 8,
              ),
              decoration: BoxDecoration(
                color: selected ? color.withValues(alpha: 0.22) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected ? color : Colors.grey.shade300,
                  width: selected ? 2 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _emojiAnimo(estado),
                    style: TextStyle(fontSize: dense ? 16 : 18),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    estado,
                    style: GoogleFonts.poppins(
                      fontSize: dense ? 11 : 12,
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? color : Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _colorAnimo(String estado) {
    switch (estado.toLowerCase()) {
      case 'feliz':
        return const Color(0xFF16A34A);
      case 'tranquilo':
        return const Color(0xFF2563EB);
      case 'triste':
        return const Color(0xFF64748B);
      case 'irritable':
        return const Color(0xFFEA580C);
      default:
        return AppColors.morado;
    }
  }

  String _emojiAnimo(String estado) {
    switch (estado.toLowerCase()) {
      case 'feliz':
        return '😊';
      case 'tranquilo':
        return '😌';
      case 'triste':
        return '😢';
      case 'irritable':
        return '😠';
      default:
        return '🙂';
    }
  }

  Widget _chipSemaforo({
    required String label,
    required bool selected,
    required Color color,
    required Color fill,
    required VoidCallback onTap,
    bool dense = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: EdgeInsets.symmetric(
            horizontal: dense ? 12 : 14,
            vertical: dense ? 7 : 9,
          ),
          decoration: BoxDecoration(
            color: selected ? color : fill,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color, width: selected ? 2.5 : 1.5),
          ),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: dense ? 12 : 13,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : color,
            ),
          ),
        ),
      ),
    );
  }

  Widget _chipToggle(
    String label,
    bool value,
    ValueChanged<bool> onChanged, {
    bool dense = false,
  }) {
    return FilterChip(
      label: Text(
        label,
        style: GoogleFonts.poppins(fontSize: dense ? 11 : 12),
      ),
      selected: value,
      onSelected: onChanged,
      visualDensity: dense ? VisualDensity.compact : VisualDensity.standard,
      selectedColor: AppColors.verdeClaro,
      checkmarkColor: const Color(0xFF166534),
      side: BorderSide(
        color: value ? const Color(0xFF166534) : Colors.grey.shade400,
      ),
    );
  }
}
