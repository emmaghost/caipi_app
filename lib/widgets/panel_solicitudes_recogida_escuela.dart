import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../config/app_colors.dart';
import '../models/solicitud_recogida.dart';
import '../services/auth_service.dart';
import '../services/notificacion_entrega_service.dart';
import '../services/solicitud_recogida_service.dart';
import '../utils/mexico_time.dart';

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
  final Set<String> _resueltas = {};
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
        lista = lista.where((s) => !_resueltas.contains(s.id)).toList();
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
                    (s) => _FilaSolicitud(
                      key: ValueKey(s.id),
                      solicitud: s,
                      service: _service,
                      onResuelta: () {
                        if (!mounted) return;
                        setState(() => _resueltas.add(s.id));
                      },
                    ),
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
  final VoidCallback onResuelta;

  const _FilaSolicitud({
    super.key,
    required this.solicitud,
    required this.service,
    required this.onResuelta,
  });

  @override
  State<_FilaSolicitud> createState() => _FilaSolicitudState();
}

class _PersonaCotejo {
  final String id;
  final String nombre;
  final String parentesco;
  final String foto;
  final bool esQuienViene;

  const _PersonaCotejo({
    required this.id,
    required this.nombre,
    required this.parentesco,
    required this.foto,
    required this.esQuienViene,
  });
}

class _DatosAviso {
  final String alumno;
  final String padre;
  final List<_PersonaCotejo> lista;

  const _DatosAviso({
    required this.alumno,
    required this.padre,
    required this.lista,
  });
}

class _FilaSolicitudState extends State<_FilaSolicitud> {
  bool _procesando = false;
  late Future<_DatosAviso> _nombresFuture;

  @override
  void initState() {
    super.initState();
    _nombresFuture = _nombres();
  }

  @override
  void didUpdateWidget(_FilaSolicitud old) {
    super.didUpdateWidget(old);
    if (old.solicitud.id != widget.solicitud.id ||
        old.solicitud.alumnoId != widget.solicitud.alumnoId ||
        old.solicitud.padreId != widget.solicitud.padreId) {
      _nombresFuture = _nombres();
    }
  }

  Future<_DatosAviso> _nombres() async {
    final client = Supabase.instance.client;
    final alumno = await client
        .from('alumnos')
        .select('nombre, apellidos')
        .eq('id', widget.solicitud.alumnoId)
        .maybeSingle();
    final padre = await client
        .from('usuarios')
        .select('nombre, apellidos, foto_url')
        .eq('id', widget.solicitud.padreId)
        .maybeSingle();

    String fmt(Map<String, dynamic>? u) {
      if (u == null) return '—';
      final n = u['nombre'] as String? ?? '';
      final a = u['apellidos'] as String?;
      return a != null && a.isNotEmpty ? '$n $a' : n;
    }

    final quienId = widget.solicitud.personaAutorizadaId;
    final lista = <_PersonaCotejo>[];
    try {
      final rows = await client
          .from('personas_autorizadas')
          .select('id, nombre, parentesco, foto_ine_url, foto_url')
          .eq('alumno_id', widget.solicitud.alumnoId)
          .eq('es_lista_fija', true);
      for (final raw in rows as List) {
        final p = Map<String, dynamic>.from(raw as Map);
        final id = p['id'] as String? ?? '';
        final ine = (p['foto_ine_url'] as String?)?.trim() ?? '';
        final otra = (p['foto_url'] as String?)?.trim() ?? '';
        lista.add(
          _PersonaCotejo(
            id: id,
            nombre: (p['nombre'] as String? ?? '').trim(),
            parentesco: (p['parentesco'] as String? ?? '').trim(),
            foto: ine.isNotEmpty ? ine : otra,
            esQuienViene: quienId != null && quienId.isNotEmpty && quienId == id,
          ),
        );
      }
    } catch (_) {}

    final fotoPadre = (padre?['foto_url'] as String?)?.trim() ?? '';
    if ((quienId == null || quienId.isEmpty) &&
        !widget.solicitud.requiereCodigo &&
        fotoPadre.isNotEmpty) {
      lista.insert(
        0,
        _PersonaCotejo(
          id: widget.solicitud.padreId,
          nombre: fmt(padre),
          parentesco: 'Papá/mamá',
          foto: fotoPadre,
          esQuienViene: true,
        ),
      );
    }

    lista.sort((a, b) {
      if (a.esQuienViene == b.esQuienViene) return 0;
      return a.esQuienViene ? -1 : 1;
    });

    return _DatosAviso(
      alumno: fmt(alumno),
      padre: fmt(padre),
      lista: lista,
    );
  }

  void _abrirFoto(String url, String detalle) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        final alto = MediaQuery.sizeOf(ctx).height * 0.82;
        final ancho = MediaQuery.sizeOf(ctx).width;
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
          backgroundColor: Colors.black,
          child: SizedBox(
            width: ancho,
            height: alto,
            child: Stack(
              children: [
                Positioned.fill(
                  child: InteractiveViewer(
                    minScale: 1,
                    maxScale: 4,
                    child: Center(
                      child: Image.network(
                        url,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'No se pudo abrir la foto',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ),
                Positioned(
                  left: 12,
                  right: 48,
                  bottom: 12,
                  child: Text(
                    detalle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _fotoCotejo(_PersonaCotejo p) {
    final detalle = p.parentesco.isEmpty ? p.nombre : '${p.nombre} · ${p.parentesco}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            p.esQuienViene ? 'Coteja con esta foto' : 'Foto de la lista',
            style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700),
          ),
          Text(
            detalle,
            style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF4A3F55)),
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () => _abrirFoto(p.foto, detalle),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                p.foto,
                height: 220,
                width: double.infinity,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Text(
                  'No se pudo abrir la foto de $detalle',
                  style: GoogleFonts.poppins(fontSize: 12, color: AppColors.rojo),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Toca la foto para verla grande',
            style: GoogleFonts.poppins(fontSize: 11, color: AppColors.gris),
          ),
        ],
      ),
    );
  }

  Future<void> _avisarNoCoincide() async {
    final user = context.read<AuthService>().currentUser;
    if (user == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('No se parece'),
        content: const Text(
          'No se entrega al niño. Se avisa al papá para que genere un código.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Avisar al papá')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _procesando = true);
    try {
      await widget.service.marcarNoCoincide(
        solicitudId: widget.solicitud.id,
        atendidaPorId: user.id,
      );
      try {
        final quien = widget.solicitud.quienVaTexto;
        await Supabase.instance.client.functions.invoke(
          'notify-chat',
          body: {
            'title': 'No entregamos al niño',
            'body': quien.isEmpty
                ? 'La persona de la puerta no coincide. Genera un código para autorizar la salida.'
                : 'Quien está en la puerta no se parece a $quien. Genera un código para autorizar la salida.',
            'usuario_ids': [widget.solicitud.padreId],
          },
        );
      } catch (_) {}
      if (!mounted) return;
      widget.onResuelta();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se entregó. El papá ya puede generar el código.'),
          backgroundColor: Colors.orange,
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

  Future<void> _entregarAlPadre(
    String nombrePadre, {
    required bool notificarPadres,
  }) async {
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
      await NotificacionEntregaService().avisarNinoRecogido(
        alumnoId: widget.solicitud.alumnoId,
        padreSolicitanteId: widget.solicitud.padreId,
        quienRecibio: nombrePadre,
        fechaSalida: DateTime.now(),
        notificarPadres: notificarPadres,
      );
      if (!mounted) return;
      widget.onResuelta();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            notificarPadres
                ? 'Entregado · salida registrada · padres notificados'
                : 'Entregado · salida registrada · sin aviso a padres',
          ),
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

  Future<void> _entregarConQr({required bool notificarPadres}) async {
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
      await NotificacionEntregaService().avisarNinoRecogido(
        alumnoId: widget.solicitud.alumnoId,
        quienRecibio: nombrePersona,
        fechaSalida: DateTime.now(),
        notificarPadres: notificarPadres,
      );
      if (!mounted) return;
      widget.onResuelta();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            notificarPadres
                ? 'Listo · entregado a $nombrePersona · padres notificados'
                : 'Listo · entregado a $nombrePersona · sin aviso a padres',
          ),
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
      if (mounted) widget.onResuelta();
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
    final hoy = MexicoTime.ymd(MexicoTime.now());
    final ahora = MexicoTime.hms(MexicoTime.now());
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
    final hora = MexicoTime.fechaHora(widget.solicitud.createdAt);

    return FutureBuilder<_DatosAviso>(
      future: _nombresFuture,
      builder: (context, snap) {
        final datos = snap.data;
        final alumno = datos?.alumno ?? '…';
        final padre = datos?.padre ?? '…';
        final lista = datos?.lista ?? const <_PersonaCotejo>[];
        final s = widget.solicitud;
        final quien = s.quienVaTexto.isEmpty ? padre : s.quienVaTexto;
        final pideCodigo = s.requiereCodigo;
        final conFoto = lista.where((p) => p.foto.isNotEmpty).toList();
        final sinFoto = lista.where((p) => p.foto.isEmpty).toList();
        final vieneConFoto = lista.any((p) => p.esQuienViene && p.foto.isNotEmpty);
        final texto = pideCodigo
            ? 'No es de la lista. Pide el código antes de entregar.'
            : vieneConFoto
                ? 'Va por él: $quien. Coteja con la foto de abajo. Si no se parece, no lo entregues.'
                : conFoto.isNotEmpty
                    ? 'Va por él: $quien. Abajo están las fotos que ya están en la lista de este niño.'
                    : 'Va por él: $quien. Este niño no tiene foto en la lista para cotejar.';

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                alumno,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              Text(
                'Aviso de $padre · $hora',
                style: GoogleFonts.poppins(fontSize: 12, color: AppColors.gris),
              ),
              const SizedBox(height: 6),
              Text(
                texto,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: pideCodigo ? const Color(0xFF9A3412) : const Color(0xFF166534),
                ),
              ),
              const SizedBox(height: 8),
              if (snap.connectionState == ConnectionState.waiting)
                const LinearProgressIndicator()
              else if (conFoto.isEmpty && lista.isEmpty)
                Text(
                  'Este niño no tiene personas en la lista. No hay foto para cotejar.',
                  style: GoogleFonts.poppins(fontSize: 12, color: AppColors.gris),
                )
              else
                for (final p in conFoto) _fotoCotejo(p),
              for (final p in sinFoto)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '${p.nombre.isEmpty ? 'Persona de la lista' : p.nombre} está registrada, sin foto.',
                    style: GoogleFonts.poppins(fontSize: 12, color: AppColors.gris),
                  ),
                ),
              const SizedBox(height: 8),
              if (!pideCodigo)
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: _procesando
                            ? null
                            : () => _entregarAlPadre(quien, notificarPadres: true),
                        style: FilledButton.styleFrom(backgroundColor: AppColors.verde),
                        child: const Text('Sí, se lo entregué'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _procesando ? null : _avisarNoCoincide,
                        child: const Text('No se parece'),
                      ),
                    ),
                  ],
                ),
              if (!pideCodigo) const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _procesando ? null : () => _entregarConQr(notificarPadres: true),
                icon: const Icon(Icons.qr_code_2),
                label: const Text('Entregar con código'), // visible también si viene el papá
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _procesando ? null : _borrarSolicitud,
                  child: const Text('Quitar aviso'),
                ),
              ),
              if (_procesando)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: LinearProgressIndicator(),
                ),
            ],
          ),
        );
      },
    );
  }
}
