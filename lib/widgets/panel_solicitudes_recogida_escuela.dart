import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../config/app_colors.dart';
import '../models/solicitud_recogida.dart';
import '../services/auth_service.dart';
import '../services/solicitud_recogida_service.dart';

class PanelSolicitudesRecogidaEscuela extends StatefulWidget {
  /// Cuando se pasa, solo muestra solicitudes de alumnos de ese grado.
  /// Si es null, muestra todas (comportamiento directora).
  final String? gradoIdFiltro;

  /// Varios grupos (inglés/música). Tiene prioridad sobre [gradoIdFiltro].
  final Set<String>? gradoIdsFiltro;

  /// Si true, muestra un mensaje cuando no hay pendientes (pantalla dedicada).
  final bool mostrarVacio;

  const PanelSolicitudesRecogidaEscuela({
    super.key,
    this.gradoIdFiltro,
    this.gradoIdsFiltro,
    this.mostrarVacio = false,
  });

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
    if (_tieneFiltroGrado) _cargarAlumnos();
  }

  bool get _tieneFiltroGrado =>
      (widget.gradoIdsFiltro != null && widget.gradoIdsFiltro!.isNotEmpty) ||
      widget.gradoIdFiltro != null;

  @override
  void didUpdateWidget(PanelSolicitudesRecogidaEscuela old) {
    super.didUpdateWidget(old);
    if (old.gradoIdFiltro != widget.gradoIdFiltro ||
        old.gradoIdsFiltro != widget.gradoIdsFiltro) {
      _alumnosDelGrado = null;
      if (_tieneFiltroGrado) _cargarAlumnos();
    }
  }

  Future<void> _cargarAlumnos() async {
    try {
      final ids = widget.gradoIdsFiltro?.toList() ??
          (widget.gradoIdFiltro != null ? [widget.gradoIdFiltro!] : <String>[]);
      if (ids.isEmpty) {
        if (mounted) setState(() => _alumnosDelGrado = {});
        return;
      }
      final rows = await Supabase.instance.client
          .from('alumnos')
          .select('id')
          .inFilter('grado_id', ids)
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
    if (_tieneFiltroGrado && _alumnosDelGrado == null) {
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
        if (_alumnosDelGrado != null) {
          lista = lista
              .where((s) => _alumnosDelGrado!.contains(s.alumnoId))
              .toList();
        }
        if (lista.isEmpty) {
          if (!widget.mostrarVacio) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Column(
              children: [
                Icon(Icons.check_circle_outline,
                    size: 56, color: Colors.green.shade400),
                const SizedBox(height: 12),
                Text(
                  'Nadie esperando en la entrada',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Cuando un papá solicite recogida, aparecerá aquí '
                  'con alerta y notificación.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppColors.gris,
                  ),
                ),
              ],
            ),
          );
        }

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
                  ...lista.map(
                    (s) => _FilaSolicitud(solicitud: s, service: _service),
                  ),
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

  Future<void> _mostrarOpcionesEntrega(String nombrePadre) async {
    if (_procesando) return;
    final opcion = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '¿Cómo se entrega?',
                style: GoogleFonts.fredoka(fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                'Elige si lo recogió el papá/mamá o alguien con código QR.',
                style: GoogleFonts.poppins(fontSize: 13, color: AppColors.gris),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.family_restroom, color: AppColors.verde),
                title: const Text('Entregado al papá / mamá'),
                subtitle: Text(nombrePadre),
                onTap: () => Navigator.pop(ctx, 'padre'),
              ),
              ListTile(
                leading: const Icon(Icons.qr_code_2, color: AppColors.azulOscuro),
                title: const Text('Entregado con QR'),
                subtitle: const Text('Validar código de 8 caracteres'),
                onTap: () => Navigator.pop(ctx, 'qr'),
              ),
              ListTile(
                leading: Icon(Icons.delete_outline, color: Colors.red.shade700),
                title: const Text('Equivocación: quitar solicitud'),
                subtitle: const Text('Borra este aviso (sin histórico)'),
                onTap: () => Navigator.pop(ctx, 'borrar'),
              ),
            ],
          ),
        ),
      ),
    );
    if (opcion == null || !mounted) return;
    if (opcion == 'padre') {
      await _entregarAlPadre(nombrePadre);
    } else if (opcion == 'qr') {
      await _entregarConQr();
    } else if (opcion == 'borrar') {
      await _borrarSolicitud();
    }
  }

  Future<void> _entregarAlPadre(String nombrePadre) async {
    final user = context.read<AuthService>().currentUser;
    if (user == null) return;
    setState(() => _procesando = true);
    try {
      await widget.service.marcarAtendida(
        solicitudId: widget.solicitud.id,
        atendidaPorId: user.id,
        modalidadEntrega: 'padre',
        quienRecibio: nombrePadre,
      );
      await _registrarSalidaRapida(
        quienRecogio: nombrePadre,
        nota: 'Entregado al papá/mamá (solicitud en entrada)',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Entregado al papá/mamá · salida registrada'),
          backgroundColor: Colors.green,
        ),
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

  Future<void> _entregarConQr() async {
    final user = context.read<AuthService>().currentUser;
    if (user == null) return;

    final codigoController = TextEditingController();
    final codigo = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Validar QR', style: GoogleFonts.fredoka()),
        content: TextField(
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

    setState(() => _procesando = true);
    try {
      final raw = await Supabase.instance.client.rpc(
        'validar_qr_temporal',
        params: {'p_codigo': codigo, 'p_usuario_id': user.id},
      );
      Map<String, dynamic> data;
      if (raw is Map) {
        data = Map<String, dynamic>.from(raw);
      } else if (raw is String) {
        data = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No se pudo validar el código. Intenta de nuevo en un momento.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      if (data['valido'] != true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Ese código no sirve: ya se usó, expiró o está mal escrito. '
              'Pide al papá uno nuevo.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final alumnoId = data['alumno_id'] as String?;
      if (alumnoId == null || alumnoId != widget.solicitud.alumnoId) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Ese QR es de otro niño. Escanea o escribe el código correcto.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final personaId = data['persona_autorizada_id'] as String?;
      String nombrePersona = 'Persona autorizada';
      if (personaId != null) {
        final p = await Supabase.instance.client
            .from('personas_autorizadas')
            .select('nombre')
            .eq('id', personaId)
            .maybeSingle();
        nombrePersona = p?['nombre'] as String? ?? nombrePersona;
      }

      await widget.service.marcarAtendida(
        solicitudId: widget.solicitud.id,
        atendidaPorId: user.id,
        modalidadEntrega: 'qr',
        quienRecibio: nombrePersona,
      );
      await _registrarSalidaRapida(
        quienRecogio: nombrePersona,
        personaAutorizadaId: personaId,
        nota: 'Entregado por QR ($codigo)',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Listo · entregado a $nombrePersona'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No se pudo validar el código. Revisa que esté bien escrito '
              'o pide uno nuevo al papá.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  Future<void> _borrarSolicitud() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Quitar solicitud?'),
        content: const Text(
          'Se elimina este aviso. Úsalo si fue un error.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _procesando = true);
    try {
      await widget.service.borrar(widget.solicitud.id);
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

  Future<void> _registrarSalidaRapida({
    required String quienRecogio,
    String? personaAutorizadaId,
    String? nota,
  }) async {
    final client = Supabase.instance.client;
    final hoy = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final ahora = DateFormat('HH:mm:ss').format(DateTime.now());
    final existente = await client
        .from('control_salidas')
        .select('id, hora_entrada, quien_trajo')
        .eq('alumno_id', widget.solicitud.alumnoId)
        .eq('fecha', hoy)
        .maybeSingle();

    final payload = <String, dynamic>{
      'alumno_id': widget.solicitud.alumnoId,
      'fecha': hoy,
      'ausente': false,
      'hora_salida': ahora,
      'quien_recogio': quienRecogio,
      'persona_autorizada_id': personaAutorizadaId,
      'observaciones': nota,
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (existente != null) {
      await client
          .from('control_salidas')
          .update(payload)
          .eq('id', existente['id'] as String);
    } else {
      payload['id'] = const Uuid().v4();
      payload['created_at'] = DateTime.now().toIso8601String();
      // Si no había entrada, deja entrada nula o ahora — mejor ahora para no romper reportes.
      payload['hora_entrada'] = ahora;
      payload['quien_trajo'] = null;
      await client.from('control_salidas').insert(payload);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hora =
        DateFormat('dd/MM/yyyy HH:mm').format(widget.solicitud.createdAt.toLocal());

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
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      'Padre: $padre · $hora',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.gris,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton(
                onPressed:
                    _procesando ? null : () => _mostrarOpcionesEntrega(padre),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.verde,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                child: _procesando
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Entregar'),
              ),
            ],
          ),
        );
      },
    );
  }
}
