import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../config/app_colors.dart';
import '../../models/alumno.dart';
import '../../models/control_salida.dart';
import '../../models/grado.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/panel_solicitudes_recogida_escuela.dart';

/// Vista diaria por **grupo (grado)**: todos los alumnos del curso y su entrada/salida del día.
/// El QR de salida lo genera el padre (Personas autorizadas); aquí se registra quién recogió y la hora.
class ControlSalidasScreen extends StatefulWidget {
  const ControlSalidasScreen({super.key});

  @override
  State<ControlSalidasScreen> createState() => _ControlSalidasScreenState();
}

class _ControlSalidasScreenState extends State<ControlSalidasScreen> {
  DateTime _fechaSeleccionada = DateTime.now();
  List<Grado> _grados = [];
  String? _gradoSeleccionadoId;
  bool _cargandoContexto = true;
  bool _profesoraSinGrado = false;
  int _listaEpoch = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargarContextoGrado());
  }

  Future<void> _cargarContextoGrado() async {
    final auth = context.read<AuthService>();
    final client = Supabase.instance.client;

    try {
      if (auth.isDirectora) {
        final g = await client
            .from('grados')
            .select()
            .eq('activo', true)
            .order('nombre');
        _grados = (g as List)
            .map((e) => Grado.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
        if (_gradoSeleccionadoId == null && _grados.isNotEmpty) {
          _gradoSeleccionadoId = _grados.first.id;
        }
      } else {
        final uid = client.auth.currentUser?.id;
        if (uid != null) {
          final prList = await client
              .from('profesores')
              .select('grado_id')
              .eq('usuario_id', uid)
              .eq('activo', true)
              .limit(1);
          final pr = (prList as List).isEmpty
              ? null
              : Map<String, dynamic>.from(prList.first as Map);
          final gid = pr?['grado_id'] as String?;
          if (gid != null && gid.isNotEmpty) {
            _gradoSeleccionadoId = gid;
            final gr = await client.from('grados').select().eq('id', gid).single();
            _grados = [
              Grado.fromJson(Map<String, dynamic>.from(gr as Map)),
            ];
          } else {
            _profesoraSinGrado = true;
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar grupos: $e'), backgroundColor: Colors.red),
        );
      }
    }

    if (mounted) {
      setState(() => _cargandoContexto = false);
    }
  }

  String get _fechaStr => DateFormat('yyyy-MM-dd').format(_fechaSeleccionada);

  Future<_DatosListaAsistencia> _cargarListaAsistencia() async {
    final gid = _gradoSeleccionadoId;
    if (gid == null) {
      return _DatosListaAsistencia(alumnos: [], porAlumno: {});
    }

    final client = Supabase.instance.client;
    final alRes = await client
        .from('alumnos')
        .select()
        .eq('grado_id', gid)
        .eq('activo', true)
        .order('apellidos');

    final alumnos = (alRes as List)
        .map((j) => Alumno.fromJson(Map<String, dynamic>.from(j as Map)))
        .toList();

    final ctrlRes =
        await client.from('control_salidas').select().eq('fecha', _fechaStr).order('created_at');

    final porAlumno = <String, ControlSalida>{};
    for (final row in ctrlRes as List) {
      final c = ControlSalida.fromJson(Map<String, dynamic>.from(row as Map));
      porAlumno.putIfAbsent(c.alumnoId, () => c);
    }

    return _DatosListaAsistencia(alumnos: alumnos, porAlumno: porAlumno);
  }

  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('es', 'MX'),
    );

    if (fecha != null) {
      setState(() {
        _fechaSeleccionada = fecha;
        _listaEpoch++;
      });
    }
  }

  Future<void> _abrirRegistroAlumno(Alumno alumno, {String? controlId}) async {
    final router = GoRouter.of(context);
    final bool? ok;
    if (controlId != null) {
      ok = await router.push<bool>('/directora/control-salidas/editar/$controlId');
    } else {
      ok = await router.push<bool>(
        '/directora/control-salidas/crear',
        extra: {
          'fecha': _fechaSeleccionada,
          'alumnoId': alumno.id,
        },
      );
    }
    if (ok == true && mounted) setState(() => _listaEpoch++);
  }

  Future<void> _validarCodigoQr() async {
    final codigoController = TextEditingController();
    final codigo = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Validar QR de recogida', style: GoogleFonts.fredoka()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Escribe el código de 8 caracteres que muestra el papá o la persona autorizada.',
              style: GoogleFonts.poppins(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: codigoController,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                LengthLimitingTextInputFormatter(12),
              ],
              decoration: const InputDecoration(
                labelText: 'Código',
                hintText: 'Ej. A1B2C3D4',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(ctx, codigoController.text.trim().toUpperCase()),
            child: const Text('Validar'),
          ),
        ],
      ),
    );
    if (codigo == null || codigo.isEmpty || !mounted) return;

    final uid = context.read<AuthService>().currentUser?.id;
    if (uid == null) return;

    try {
      final raw = await Supabase.instance.client.rpc(
        'validar_qr_temporal',
        params: {'p_codigo': codigo, 'p_usuario_id': uid},
      );
      Map<String, dynamic> data;
      if (raw is Map) {
        data = Map<String, dynamic>.from(raw);
      } else if (raw is String) {
        data = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      } else {
        throw Exception('Respuesta inesperada del servidor');
      }

      final valido = data['valido'] == true;
      if (!valido) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['mensaje'] as String? ?? 'QR inválido o ya usado'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final alumnoId = data['alumno_id'] as String?;
      final personaId = data['persona_autorizada_id'] as String?;
      if (alumnoId == null) {
        throw Exception('El QR no trae alumno');
      }

      final client = Supabase.instance.client;
      final alumno = await client
          .from('alumnos')
          .select('nombre, apellidos')
          .eq('id', alumnoId)
          .maybeSingle();
      final persona = personaId == null
          ? null
          : await client
              .from('personas_autorizadas')
              .select('nombre')
              .eq('id', personaId)
              .maybeSingle();
      final nombreAlumno = alumno == null
          ? 'Alumno'
          : '${alumno['nombre'] ?? ''} ${alumno['apellidos'] ?? ''}'.trim();
      final nombrePersona = persona?['nombre'] as String? ?? 'Persona autorizada';

      if (!mounted) return;
      final continuar = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('QR válido', style: GoogleFonts.fredoka()),
          content: Text(
            '$nombrePersona puede recoger a $nombreAlumno.\n\n'
            'El código ya quedó usado. Continúa para registrar la salida.',
            style: GoogleFonts.poppins(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cerrar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Registrar salida'),
            ),
          ],
        ),
      );
      if (continuar != true || !mounted) return;

      final ok = await GoRouter.of(context).push<bool>(
        '/directora/control-salidas/crear',
        extra: {
          'fecha': _fechaSeleccionada,
          'alumnoId': alumnoId,
          'quienRecogio': nombrePersona,
          'personaAutorizadaId': personaId,
          'prellenarSalida': true,
        },
      );
      if (ok == true && mounted) setState(() => _listaEpoch++);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo validar. ¿Corriste FIX_SISTEMA_QR_TEMPORAL.sql?\n$e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _abrirRegistroLibre() async {
    final ok = await GoRouter.of(context).push<bool>(
      '/directora/control-salidas/crear',
      extra: {'fecha': _fechaSeleccionada},
    );
    if (ok == true && mounted) setState(() => _listaEpoch++);
  }

  Future<void> _marcarNoAsistio(Alumno alumno, ControlSalida? existente) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('¿No asistió?', style: GoogleFonts.fredoka()),
        content: Text(
          '${alumno.nombreCompleto} no vino el ${DateFormat('dd/MM/yyyy').format(_fechaSeleccionada)}.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirmar')),
        ],
      ),
    );
    if (ok != true) return;

    final client = Supabase.instance.client;
    try {
      if (existente != null) {
        await client.from('control_salidas').update({
          'ausente': true,
          'hora_entrada': null,
          'hora_salida': null,
          'quien_trajo': null,
          'quien_recogio': null,
          'persona_autorizada_id': null,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', existente.id);
      } else {
        await client.from('control_salidas').insert({
          'id': const Uuid().v4(),
          'alumno_id': alumno.id,
          'fecha': _fechaStr,
          'ausente': true,
          'hora_entrada': null,
          'hora_salida': null,
          'quien_trajo': null,
          'quien_recogio': null,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Marcado como no asistió'), backgroundColor: Colors.green),
        );
        setState(() => _listaEpoch++);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No se pudo guardar. Si el error menciona «ausente», ejecuta en Supabase el archivo ADD_CONTROL_SALIDAS_AUSENTE.sql',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _quitarAusencia(ControlSalida existente) async {
    try {
      await Supabase.instance.client.from('control_salidas').delete().eq('id', existente.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Listo: puedes registrar entrada/salida'), backgroundColor: Colors.green),
        );
        setState(() => _listaEpoch++);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.amarillo, AppColors.naranja],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Row(
          children: [
            const Icon(Icons.access_time, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Control de Entrada/Salida',
                style: GoogleFonts.fredoka(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
            tooltip: 'Validar código QR',
            onPressed: _validarCodigoQr,
          ),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirRegistroLibre,
        backgroundColor: AppColors.azulOscuro,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt_1),
        label: Text(
          'Otro alumno',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.moradoClaro.withValues(alpha: 0.35),
              Colors.white,
            ],
          ),
        ),
        child: _cargandoContexto
            ? const Center(child: CircularProgressIndicator())
            : _profesoraSinGrado && !auth.isDirectora
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Tu usuario de profesora no tiene un grupo asignado. Pide a la directora que vincule tu cuenta a un grado.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(fontSize: 16, color: AppColors.grisOscuro),
                      ),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _TarjetaFecha(
                        fecha: _fechaSeleccionada,
                        onCambiarFecha: _seleccionarFecha,
                      ),
                      PanelSolicitudesRecogidaEscuela(
                        // Directora ve todas; profesor solo ve su grado
                        gradoIdFiltro: auth.isDirectora ? null : _gradoSeleccionadoId,
                      ),
                      if (auth.isDirectora && _grados.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'No hay grupos activos en la base de datos. Crea grados en el catálogo.',
                            style: GoogleFonts.poppins(color: AppColors.grisOscuro),
                          ),
                        ),
                      if (auth.isDirectora && _grados.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: DropdownButtonFormField<String>(
                            value: _gradoSeleccionadoId,
                            decoration: InputDecoration(
                              labelText: 'Grupo / grado',
                              prefixIcon: Icon(Icons.school, color: AppColors.azulOscuro),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            items: _grados
                                .map(
                                  (g) => DropdownMenuItem(value: g.id, child: Text(g.nombre)),
                                )
                                .toList(),
                            onChanged: (v) {
                              if (v == null) return;
                              setState(() {
                                _gradoSeleccionadoId = v;
                                _listaEpoch++;
                              });
                            },
                          ),
                        )
                      else if (!auth.isDirectora && _grados.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: ListTile(
                            tileColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            leading: Icon(Icons.school, color: AppColors.azulOscuro),
                            title: Text(
                              _grados.first.nombre,
                              style: GoogleFonts.fredoka(
                                fontWeight: FontWeight.w600,
                                color: AppColors.azulOscuro,
                              ),
                            ),
                            subtitle: Text('Tu grupo', style: GoogleFonts.poppins(fontSize: 13)),
                          ),
                        ),
                      _InfoQrSalida(),
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: () async => setState(() => _listaEpoch++),
                          child: FutureBuilder<_DatosListaAsistencia>(
                            key: ValueKey(
                              '${_gradoSeleccionadoId}_$_fechaStr$_listaEpoch',
                            ),
                            future: _cargarListaAsistencia(),
                            builder: (context, snap) {
                              if (snap.connectionState == ConnectionState.waiting) {
                                return ListView(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  children: const [
                                    SizedBox(height: 120),
                                    Center(child: CircularProgressIndicator()),
                                  ],
                                );
                              }
                              if (snap.hasError) {
                                return ListView(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.all(24),
                                  children: [
                                    Icon(Icons.error_outline, size: 56, color: Colors.red[300]),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Error al cargar: ${snap.error}',
                                      style: GoogleFonts.poppins(),
                                    ),
                                  ],
                                );
                              }

                              final datos = snap.data!;
                              if (_gradoSeleccionadoId == null) {
                                return ListView(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.all(24),
                                  children: [
                                    Text(
                                      'Selecciona un grupo para ver la lista del día.',
                                      style: GoogleFonts.poppins(fontSize: 16),
                                    ),
                                  ],
                                );
                              }

                              if (datos.alumnos.isEmpty) {
                                return ListView(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.all(24),
                                  children: [
                                    Icon(Icons.groups_outlined, size: 72, color: Colors.grey[400]),
                                    const SizedBox(height: 12),
                                    Text(
                                      'No hay alumnos activos en este grupo.',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.fredoka(fontSize: 18, color: Colors.grey[700]),
                                    ),
                                  ],
                                );
                              }

                              return ListView.builder(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                                itemCount: datos.alumnos.length,
                                itemBuilder: (context, i) {
                                  final a = datos.alumnos[i];
                                  final c = datos.porAlumno[a.id];
                                  return _AlumnoAsistenciaTile(
                                    alumno: a,
                                    control: c,
                                    onTap: () => _abrirRegistroAlumno(
                                      a,
                                      controlId: c?.id,
                                    ),
                                    onMarcarAusente: () => _marcarNoAsistio(a, c),
                                    onQuitarAusencia:
                                        c != null && c.ausente ? () => _quitarAusencia(c) : null,
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}

class _DatosListaAsistencia {
  final List<Alumno> alumnos;
  final Map<String, ControlSalida> porAlumno;

  _DatosListaAsistencia({required this.alumnos, required this.porAlumno});
}

class _TarjetaFecha extends StatelessWidget {
  final DateTime fecha;
  final VoidCallback onCambiarFecha;

  const _TarjetaFecha({required this.fecha, required this.onCambiarFecha});

  @override
  Widget build(BuildContext context) {
    final texto = DateFormat('EEEE, dd \'de\' MMMM yyyy', 'es_MX').format(fecha);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.naranja.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: AppColors.amarillo.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_today, color: AppColors.naranja, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Día de control',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gris,
                  ),
                ),
                Text(
                  texto,
                  style: GoogleFonts.fredoka(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.negro,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.edit_calendar, color: AppColors.azulOscuro),
            onPressed: onCambiarFecha,
          ),
        ],
      ),
    );
  }
}

class _InfoQrSalida extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Material(
        color: AppColors.azulClaro,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.qr_code_2, color: AppColors.azulOscuro, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'En la salida, el padre puede mostrar un QR temporal (Personas autorizadas) para acreditar quién recoge. Aquí registras la hora de salida y el nombre de quien recogió.',
                  style: GoogleFonts.poppins(fontSize: 12.5, height: 1.35, color: AppColors.grisOscuro),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlumnoAsistenciaTile extends StatelessWidget {
  final Alumno alumno;
  final ControlSalida? control;
  final VoidCallback onTap;
  final VoidCallback onMarcarAusente;
  final VoidCallback? onQuitarAusencia;

  const _AlumnoAsistenciaTile({
    required this.alumno,
    required this.control,
    required this.onTap,
    required this.onMarcarAusente,
    this.onQuitarAusencia,
  });

  String _horaCorta(DateTime? d) {
    if (d == null) return '—';
    final t = TimeOfDay.fromDateTime(d);
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final c = control;
    String estado;
    Color chipColor;
    Color chipFg = Colors.white;

    if (c == null) {
      estado = 'Pendiente';
      chipColor = AppColors.alertaPago;
      chipFg = AppColors.negro;
    } else if (c.ausente) {
      estado = 'No asistió';
      chipColor = AppColors.errorPago;
    } else if (c.horaSalida != null) {
      estado = 'Completo';
      chipColor = AppColors.exitoPago;
    } else if (c.horaEntrada != null) {
      estado = 'En escuela';
      chipColor = AppColors.info;
    } else {
      estado = 'Sin horarios';
      chipColor = AppColors.gris;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.azulOscuro,
                child: Text(
                  alumno.nombre.isNotEmpty ? alumno.nombre[0].toUpperCase() : '?',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alumno.nombreCompleto,
                      style: GoogleFonts.fredoka(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.azulOscuro,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (c != null && !c.ausente) ...[
                      Text(
                        'Entrada ${_horaCorta(c.horaEntrada)} · Salida ${_horaCorta(c.horaSalida)}',
                        style: GoogleFonts.poppins(fontSize: 12, color: AppColors.grisOscuro),
                      ),
                      if ((c.quienTrajo ?? '').isNotEmpty || (c.quienRecogio ?? '').isNotEmpty)
                        Text(
                          [
                            if ((c.quienTrajo ?? '').isNotEmpty) 'Trajo: ${c.quienTrajo}',
                            if ((c.quienRecogio ?? '').isNotEmpty) 'Recogió: ${c.quienRecogio}',
                          ].join(' · '),
                          style: GoogleFonts.poppins(fontSize: 11, color: AppColors.gris),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ] else if (c != null && c.ausente)
                      Text(
                        'Sin registro de horario',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.gris,
                          fontStyle: FontStyle.italic,
                        ),
                      )
                    else
                      Text(
                        'Toca para registrar entrada o marcar ausencia',
                        style: GoogleFonts.poppins(fontSize: 12, color: AppColors.gris),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: chipColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      estado,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: chipFg,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: AppColors.gris),
                    onSelected: (v) {
                      if (v == 'ausente') onMarcarAusente();
                      if (v == 'quitar') onQuitarAusencia?.call();
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(value: 'ausente', child: Text('Marcar que no vino')),
                      if (onQuitarAusencia != null)
                        const PopupMenuItem(value: 'quitar', child: Text('Quitar “no asistió”')),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
