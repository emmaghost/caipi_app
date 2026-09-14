import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../config/app_colors.dart';
import '../../models/alumno.dart';
import '../../models/clase_extracurricular.dart';
import '../../models/grado.dart';
import '../../models/participante_clase.dart';
import '../../services/supabase_service.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/caipi_app_bar_leading.dart';

/// Detalle de clase: inscritos + generar cargo del mes.
class ClaseExtracurricularDetalleScreen extends StatefulWidget {
  final String claseId;

  const ClaseExtracurricularDetalleScreen({super.key, required this.claseId});

  @override
  State<ClaseExtracurricularDetalleScreen> createState() =>
      _ClaseExtracurricularDetalleScreenState();
}

class _ClaseExtracurricularDetalleScreenState
    extends State<ClaseExtracurricularDetalleScreen> {
  ClaseExtracurricular? _clase;
  List<_FilaParticipante> _filas = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final client = Supabase.instance.client;
      final claseJson = await client
          .from('clases_extracurriculares')
          .select()
          .eq('id', widget.claseId)
          .single();
      final clase = ClaseExtracurricular.fromJson(claseJson);

      final parts = await client
          .from('participantes_clases')
          .select()
          .eq('clase_id', widget.claseId)
          .order('fecha_inscripcion', ascending: false);

      if (!mounted) return;
      final alumnos = await context.read<SupabaseService>().obtenerAlumnos();
      final mapAlumno = {for (final a in alumnos) a.id: a};

      final filas = <_FilaParticipante>[];
      for (final raw in (parts as List)) {
        final p = ParticipanteClase.fromJson(Map<String, dynamic>.from(raw));
        Alumno? alumno;
        if (p.alumnoId != null) alumno = mapAlumno[p.alumnoId];
        filas.add(_FilaParticipante(participante: p, alumno: alumno));
      }

      if (!mounted) return;
      setState(() {
        _clase = clase;
        _filas = filas;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  int get _inscritosActivos =>
      _filas.where((f) => f.participante.activo).length;

  Future<void> _inscribirAlumno() async {
    final clase = _clase;
    if (clase == null) return;

    final service = context.read<SupabaseService>();
    final resultados = await Future.wait([
      service.obtenerAlumnos(),
      service.obtenerGrados(),
    ]);
    final alumnos = resultados[0] as List<Alumno>;
    final grados = List<Grado>.from(resultados[1] as List<Grado>)
      ..sort((a, b) => a.nombre.compareTo(b.nombre));
    final nombreGrado = {
      for (final g in grados) g.id: g.nombre,
    };
    final yaInscritos = _filas
        .where((f) => f.participante.activo && f.participante.alumnoId != null)
        .map((f) => f.participante.alumnoId!)
        .toSet();
    final disponibles =
        alumnos.where((a) => a.activo && !yaInscritos.contains(a.id)).toList()
          ..sort((a, b) => a.nombreCompleto.compareTo(b.nombreCompleto));

    if (!mounted) return;
    if (disponibles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay alumnos disponibles para inscribir')),
      );
      return;
    }

    final seleccionado = await showModalBottomSheet<Alumno>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) {
        var filtro = '';
        String? filtroGradoId;
        return StatefulBuilder(
          builder: (ctx, setModal) {
            final filtrados = disponibles.where((a) {
              if (filtroGradoId != null && a.gradoId != filtroGradoId) {
                return false;
              }
              if (filtro.trim().isEmpty) return true;
              return a.nombreCompleto
                  .toLowerCase()
                  .contains(filtro.trim().toLowerCase());
            }).toList();
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.75,
              minChildSize: 0.45,
              maxChildSize: 0.95,
              builder: (_, scrollCtrl) {
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        'Inscribir alumno',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: DropdownButtonFormField<String?>(
                        value: filtroGradoId,
                        decoration: const InputDecoration(
                          labelText: 'Grupo',
                          prefixIcon: Icon(Icons.groups_outlined),
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Todos los grupos'),
                          ),
                          ...grados.map(
                            (g) => DropdownMenuItem<String?>(
                              value: g.id,
                              child: Text(g.nombre),
                            ),
                          ),
                        ],
                        onChanged: (v) => setModal(() => filtroGradoId = v),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          hintText: 'Buscar niño…',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (v) => setModal(() => filtro = v),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${filtrados.length} niño(s)',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.gris,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: filtrados.isEmpty
                          ? Center(
                              child: Text(
                                filtroGradoId == null
                                    ? 'Sin resultados'
                                    : 'No hay niños en este grupo',
                                style: GoogleFonts.poppins(
                                  color: AppColors.gris,
                                ),
                              ),
                            )
                          : ListView.builder(
                              controller: scrollCtrl,
                              itemCount: filtrados.length,
                              itemBuilder: (_, i) {
                                final a = filtrados[i];
                                final grupo = a.gradoId != null
                                    ? (nombreGrado[a.gradoId] ?? 'Sin grupo')
                                    : 'Sin grupo';
                                return ListTile(
                                  title: Text(a.nombreCompleto),
                                  subtitle: Text(grupo),
                                  onTap: () => Navigator.pop(ctx, a),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );

    if (seleccionado == null || !mounted) return;

    if (_inscritosActivos >= clase.cupoMaximo) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cupo lleno (${clase.cupoMaximo})'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    var generarCargo = false;
    if (clase.costoMensual != null && clase.costoMensual! > 0) {
      final ok = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Inscribir alumno'),
          content: Text(
            '¿Cómo quieres inscribir a ${seleccionado.nombreCompleto}?\n\n'
            'Puedes solo asignarlo ahora y generar el pago después.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'cancel'),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'solo'),
              child: const Text('Solo inscribir'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, 'cobrar'),
              child: Text(
                'Inscribir y cargo \$${clase.costoMensual!.toStringAsFixed(0)}',
              ),
            ),
          ],
        ),
      );
      if (ok == null || ok == 'cancel' || !mounted) return;
      generarCargo = ok == 'cobrar';
    }

    try {
      final id = const Uuid().v4();
      await Supabase.instance.client.from('participantes_clases').insert({
        'id': id,
        'clase_id': clase.id,
        'alumno_id': seleccionado.id,
        'tipo_participante': 'alumno',
        'fecha_inscripcion': DateTime.now().toIso8601String().split('T')[0],
        'activo': true,
      });

      if (generarCargo && clase.costoMensual != null) {
        await service.agregarPagoExtracurricular(
          alumnoId: seleccionado.id,
          nombreClase: clase.nombre,
          monto: clase.costoMensual!,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            generarCargo
                ? 'Inscrito y cargo creado'
                : 'Alumno inscrito',
          ),
          backgroundColor: Colors.green,
        ),
      );
      await _cargar();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _agregarExterno() async {
    final clase = _clase;
    if (clase == null || !clase.permiteExternos) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Esta clase no admite externos. Actívalo al editar.'),
        ),
      );
      return;
    }

    final nombreCtrl = TextEditingController();
    final apeCtrl = TextEditingController();
    final telCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Participante externo'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nombreCtrl,
                decoration: const InputDecoration(labelText: 'Nombre *'),
              ),
              TextField(
                controller: apeCtrl,
                decoration: const InputDecoration(labelText: 'Apellidos'),
              ),
              TextField(
                controller: telCtrl,
                decoration: const InputDecoration(labelText: 'Teléfono'),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (ok != true || !mounted) return;
    final nombre = nombreCtrl.text.trim();
    if (nombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El nombre es obligatorio')),
      );
      return;
    }

    try {
      await Supabase.instance.client.from('participantes_clases').insert({
        'id': const Uuid().v4(),
        'clase_id': clase.id,
        'tipo_participante': 'externo',
        'nombre_externo': nombre,
        'apellidos_externo': apeCtrl.text.trim().isEmpty
            ? null
            : apeCtrl.text.trim(),
        'telefono_externo':
            telCtrl.text.trim().isEmpty ? null : telCtrl.text.trim(),
        'fecha_inscripcion': DateTime.now().toIso8601String().split('T')[0],
        'activo': true,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Externo inscrito'),
          backgroundColor: Colors.green,
        ),
      );
      await _cargar();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _toggleActivo(_FilaParticipante fila) async {
    try {
      await Supabase.instance.client.from('participantes_clases').update({
        'activo': !fila.participante.activo,
      }).eq('id', fila.participante.id);
      await _cargar();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _generarCargosMes() async {
    final clase = _clase;
    if (clase == null || clase.costoMensual == null || clase.costoMensual! <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Define un costo mensual en la clase')),
      );
      return;
    }

    final alumnosActivos = _filas
        .where((f) =>
            f.participante.activo &&
            f.participante.esAlumno &&
            f.participante.alumnoId != null)
        .toList();

    if (alumnosActivos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay alumnos activos inscritos')),
      );
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cargos del mes'),
        content: Text(
          'Se creará un pago de \$${clase.costoMensual!.toStringAsFixed(0)} '
          'por cada alumno activo (${alumnosActivos.length}). '
          'Si ya existe el cargo del mes para alguien, se omite.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Generar'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final service = context.read<SupabaseService>();
    var creados = 0;
    var omitidos = 0;
    try {
      for (final f in alumnosActivos) {
        final hecho = await service.agregarPagoExtracurricular(
          alumnoId: f.participante.alumnoId!,
          nombreClase: clase.nombre,
          monto: clase.costoMensual!,
          omitirSiExisteMes: true,
        );
        if (hecho) {
          creados++;
        } else {
          omitidos++;
        }
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cargos creados: $creados. Ya tenían: $omitidos.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final clase = _clase;
    return Scaffold(
      appBar: AppBar(
        leading: const CaipiAppBarLeading(),
        title: Text(clase?.nombre ?? 'Clase'),
        backgroundColor: AppColors.azulOscuro,
        foregroundColor: Colors.white,
        actions: [
          if (clase != null)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Editar clase',
              onPressed: () => context.push(
                '/directora/clases-extracurriculares/editar/${clase.id}',
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargar,
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Error: $_error\n\n'
                      'Si dice permiso denegado, ejecuta en Supabase el SQL '
                      'FIX_PARTICIPANTES_CLASES_RLS.sql',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _cargar,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (clase != null) ...[
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  clase.nombre,
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (clase.descripcion != null) ...[
                                  const SizedBox(height: 4),
                                  Text(clase.descripcion!),
                                ],
                                const SizedBox(height: 8),
                                Text(
                                  '${clase.horario} · Cupo $_inscritosActivos/${clase.cupoMaximo}'
                                  '${clase.costoMensual != null ? ' · \$${clase.costoMensual!.toStringAsFixed(0)}/mes' : ''}',
                                  style: TextStyle(color: Colors.grey[700]),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            FilledButton.icon(
                              onPressed: _inscribirAlumno,
                              icon: const Icon(Icons.person_add),
                              label: const Text('Inscribir alumno'),
                            ),
                            if (clase.permiteExternos)
                              OutlinedButton.icon(
                                onPressed: _agregarExterno,
                                icon: const Icon(Icons.person_outline),
                                label: const Text('Externo'),
                              ),
                            if (clase.costoMensual != null &&
                                clase.costoMensual! > 0)
                              OutlinedButton.icon(
                                onPressed: _generarCargosMes,
                                icon: const Icon(Icons.attach_money),
                                label: const Text('Cargos del mes'),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                      Text(
                        'Inscritos (${_filas.length})',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_filas.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Center(
                            child: Text(
                              'Nadie inscrito aún.\nUsa «Inscribir alumno».',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ),
                        )
                      else
                        ..._filas.map((f) {
                          final nombre = f.alumno?.nombreCompleto ??
                              f.participante.nombreCompleto;
                          final sub = f.participante.esExterno
                              ? 'Externo'
                              : 'Alumno';
                          final fecha = DateFormat('dd/MM/yyyy')
                              .format(f.participante.fechaInscripcion);
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: f.participante.activo
                                    ? AppColors.verdeClaro
                                    : Colors.grey,
                                child: Icon(
                                  f.participante.esExterno
                                      ? Icons.person_outline
                                      : Icons.child_care,
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(nombre),
                              subtitle: Text('$sub · desde $fecha'),
                              trailing: IconButton(
                                icon: Icon(
                                  f.participante.activo
                                      ? Icons.check_circle
                                      : Icons.cancel,
                                  color: f.participante.activo
                                      ? Colors.green
                                      : Colors.grey,
                                ),
                                tooltip: f.participante.activo
                                    ? 'Dar de baja'
                                    : 'Reactivar',
                                onPressed: () => _toggleActivo(f),
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
    );
  }
}

class _FilaParticipante {
  final ParticipanteClase participante;
  final Alumno? alumno;

  _FilaParticipante({required this.participante, this.alumno});
}
