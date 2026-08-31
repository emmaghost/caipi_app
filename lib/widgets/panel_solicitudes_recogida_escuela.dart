import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_colors.dart';
import '../models/solicitud_recogida.dart';
import '../services/auth_service.dart';
import '../services/solicitud_recogida_service.dart';

class PanelSolicitudesRecogidaEscuela extends StatefulWidget {
  /// Cuando se pasa, solo muestra solicitudes de alumnos de ese grado.
  /// Si es null, muestra todas (comportamiento directora).
  final String? gradoIdFiltro;

  const PanelSolicitudesRecogidaEscuela({super.key, this.gradoIdFiltro});

  @override
  State<PanelSolicitudesRecogidaEscuela> createState() =>
      _PanelSolicitudesRecogidaEscuelaState();
}

class _PanelSolicitudesRecogidaEscuelaState
    extends State<PanelSolicitudesRecogidaEscuela> {
  Set<String>? _alumnosDelGrado; // null = sin filtro
  late final SolicitudRecogidaService _service;

  @override
  void initState() {
    super.initState();
    _service = SolicitudRecogidaService();
    if (widget.gradoIdFiltro != null) _cargarAlumnos();
  }

  @override
  void didUpdateWidget(PanelSolicitudesRecogidaEscuela old) {
    super.didUpdateWidget(old);
    if (old.gradoIdFiltro != widget.gradoIdFiltro) {
      _alumnosDelGrado = null;
      if (widget.gradoIdFiltro != null) _cargarAlumnos();
    }
  }

  Future<void> _cargarAlumnos() async {
    try {
      final rows = await Supabase.instance.client
          .from('alumnos')
          .select('id')
          .eq('grado_id', widget.gradoIdFiltro!)
          .eq('activo', true);
      if (mounted) {
        setState(() {
          _alumnosDelGrado =
              (rows as List).map((r) => r['id'] as String).toSet();
        });
      }
    } catch (_) {
      if (mounted) setState(() => _alumnosDelGrado = {});
    }
  }

  @override
  Widget build(BuildContext context) {
    // Esperar a tener el set de alumnos antes de mostrar
    if (widget.gradoIdFiltro != null && _alumnosDelGrado == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<List<SolicitudRecogida>>(
      stream: _service.streamPendientes(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              'Solicitudes de entrada: error al cargar',
              style: GoogleFonts.poppins(fontSize: 12, color: AppColors.rojo),
            ),
          );
        }

        var lista = snapshot.data ?? [];
        // Filtrar por grado si aplica
        if (_alumnosDelGrado != null) {
          lista = lista
              .where((s) => _alumnosDelGrado!.contains(s.alumnoId))
              .toList();
        }
        if (lista.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Card(
            color: Colors.orange.shade50,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: Colors.orange.shade300),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(Icons.door_front_door, color: Colors.orange.shade800),
                      const SizedBox(width: 8),
                      Text(
                        'Padres en la entrada (${lista.length})',
                        style: GoogleFonts.fredoka(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange.shade900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...lista.map((s) => _FilaSolicitud(solicitud: s, service: _service)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FilaSolicitud extends StatefulWidget {
  final SolicitudRecogida solicitud;
  final SolicitudRecogidaService service;

  const _FilaSolicitud({required this.solicitud, required this.service});

  @override
  State<_FilaSolicitud> createState() => _FilaSolicitudState();
}

class _FilaSolicitudState extends State<_FilaSolicitud> {
  bool _procesando = false;

  Future<Map<String, String>> _nombres() async {
    final client = Supabase.instance.client;
    final alumno = await client
        .from('alumnos')
        .select('nombre, apellidos')
        .eq('id', widget.solicitud.alumnoId)
        .maybeSingle();
    final padre = await client
        .from('usuarios')
        .select('nombre, apellidos')
        .eq('id', widget.solicitud.padreId)
        .maybeSingle();

    String fmt(Map<String, dynamic>? u) {
      if (u == null) return '—';
      final n = u['nombre'] as String? ?? '';
      final a = u['apellidos'] as String?;
      return a != null && a.isNotEmpty ? '$n $a' : n;
    }

    return {
      'alumno': fmt(alumno),
      'padre': fmt(padre),
    };
  }

  Future<void> _atender() async {
    final user = context.read<AuthService>().currentUser;
    if (user == null || _procesando) return;
    setState(() => _procesando = true);
    try {
      await widget.service.marcarAtendida(
        solicitudId: widget.solicitud.id,
        atendidaPorId: user.id,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.rojo),
        );
      }
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hora = DateFormat('dd/MM/yyyy HH:mm').format(widget.solicitud.createdAt.toLocal());

    return FutureBuilder<Map<String, String>>(
      future: _nombres(),
      builder: (context, snap) {
        final alumno = snap.data?['alumno'] ?? '…';
        final padre = snap.data?['padre'] ?? '…';

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alumno,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    Text(
                      'Padre: $padre · $hora',
                      style: GoogleFonts.poppins(fontSize: 12, color: AppColors.gris),
                    ),
                  ],
                ),
              ),
              FilledButton(
                onPressed: _procesando ? null : _atender,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.verde,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                child: _procesando
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Listo'),
              ),
            ],
          ),
        );
      },
    );
  }
}
