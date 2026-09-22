import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../config/app_colors.dart';
import '../../models/grado.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../services/pago_avisos_service.dart';
import '../../services/supabase_service.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/caipi_app_bar_leading.dart';

/// Directora y caja: programar avisos de pronto pago y de adeudo/recargo.
class PagoAvisosScreen extends StatefulWidget {
  const PagoAvisosScreen({super.key});

  @override
  State<PagoAvisosScreen> createState() => _PagoAvisosScreenState();
}

class _PagoAvisosScreenState extends State<PagoAvisosScreen> {
  final _service = PagoAvisosService();
  late Future<List<PagoAvisoProgramado>> _future;
  bool _enviando = false;
  bool _ayudaExpandida = false;

  @override
  void initState() {
    super.initState();
    _future = _service.listar();
  }

  Future<void> _refrescar() async {
    final f = _service.listar();
    setState(() => _future = f);
    await f;
  }

  Future<void> _editar([PagoAvisoProgramado? existente]) async {
    var tipo = existente?.tipo ?? PagoAvisoTipo.prontoPago;
    final nombreCtrl = TextEditingController(
      text: existente?.nombre ?? PagoAvisoTipo.nombreDefault(tipo),
    );
    final tituloCtrl = TextEditingController(
      text: existente?.titulo ?? PagoAvisoTipo.tituloDefault(tipo),
    );
    final mensajeCtrl = TextEditingController(
      text: existente?.mensaje ?? PagoAvisoTipo.mensajeDefault(tipo),
    );
    var dia = existente?.diaMes ?? PagoAvisoTipo.diaDefault(tipo);
    var activo = existente?.activo ?? true;
    var chat = existente?.enviarChat ?? true;
    var push = existente?.enviarPush ?? true;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          void aplicarTipo(String nuevo) {
            final eraNuevo = existente == null;
            final mensajeEraDefault = mensajeCtrl.text.trim().isEmpty ||
                mensajeCtrl.text == PagoAvisoTipo.mensajeDefault(tipo);
            final tituloEraDefault = tituloCtrl.text.trim().isEmpty ||
                tituloCtrl.text == PagoAvisoTipo.tituloDefault(tipo);
            final nombreEraDefault = nombreCtrl.text.trim().isEmpty ||
                nombreCtrl.text == PagoAvisoTipo.nombreDefault(tipo);
            setLocal(() {
              tipo = nuevo;
              if (eraNuevo || nombreEraDefault) {
                nombreCtrl.text = PagoAvisoTipo.nombreDefault(nuevo);
              }
              if (eraNuevo || tituloEraDefault) {
                tituloCtrl.text = PagoAvisoTipo.tituloDefault(nuevo);
              }
              if (eraNuevo || mensajeEraDefault) {
                mensajeCtrl.text = PagoAvisoTipo.mensajeDefault(nuevo);
              }
              if (eraNuevo) dia = PagoAvisoTipo.diaDefault(nuevo);
            });
          }

          return AlertDialog(
            title: Text(
              existente == null ? 'Nuevo aviso' : 'Editar aviso',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            content: SizedBox(
              width: 420,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Tipo de mensaje',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Pronto pago'),
                          selected: tipo == PagoAvisoTipo.prontoPago,
                          onSelected: (_) =>
                              aplicarTipo(PagoAvisoTipo.prontoPago),
                        ),
                        ChoiceChip(
                          label: const Text('Adeudo'),
                          selected: tipo == PagoAvisoTipo.adeudo,
                          onSelected: (_) => aplicarTipo(PagoAvisoTipo.adeudo),
                        ),
                        ChoiceChip(
                          label: const Text('Administración'),
                          selected: tipo == PagoAvisoTipo.admin,
                          onSelected: (_) => aplicarTipo(PagoAvisoTipo.admin),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      PagoAvisoTipo.descripcion(tipo),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[700],
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Los mensajes salen firmados por Administración CAIPI.',
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.azulOscuro,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: nombreCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nombre interno',
                        hintText: 'Ej. Pronto pago día 5',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text('Día del mes:', style: GoogleFonts.poppins()),
                        const SizedBox(width: 12),
                        DropdownButton<int>(
                          value: dia,
                          items: [
                            for (var d = 1; d <= 28; d++)
                              DropdownMenuItem(value: d, child: Text('$d')),
                          ],
                          onChanged: (v) => setLocal(() => dia = v ?? dia),
                        ),
                      ],
                    ),
                    TextFormField(
                      controller: tituloCtrl,
                      decoration:
                          const InputDecoration(labelText: 'Título (push / chat)'),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: mensajeCtrl,
                      maxLines: 6,
                      decoration: const InputDecoration(
                        labelText: 'Mensaje',
                        alignLabelWithHint: true,
                        helperText:
                            'Placeholders: {nombres_hijos} {nombre_hijo} {saldo}',
                      ),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Activo (se dispara ese día)'),
                      value: activo,
                      onChanged: (v) => setLocal(() => activo = v),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Enviar por chat'),
                      value: chat,
                      onChanged: (v) => setLocal(() => chat = v),
                    ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Notificación al celular',
                        ),
                        subtitle: const Text(
                          'Solo llega si el papá tiene la app instalada '
                          'y aceptó avisos (token FCM). Si no, igual puede ir por chat.',
                        ),
                        value: push,
                        onChanged: (v) => setLocal(() => push = v),
                      ),
                  ],
                ),
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
          );
        },
      ),
    );

    if (ok != true || !mounted) return;
    if (mensajeCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El mensaje no puede ir vacío')),
      );
      return;
    }

    try {
      final user = context.read<AuthService>().currentUser;
      await _service.guardar(
        id: existente?.id,
        nombre: nombreCtrl.text.isEmpty
            ? PagoAvisoTipo.nombreDefault(tipo)
            : nombreCtrl.text,
        diaMes: dia,
        titulo: tituloCtrl.text.isEmpty
            ? PagoAvisoTipo.tituloDefault(tipo)
            : tituloCtrl.text,
        mensaje: mensajeCtrl.text,
        tipo: tipo,
        activo: activo,
        soloConAdeudo: true,
        enviarChat: chat,
        enviarPush: push,
        createdBy: user?.id,
      );
      await _refrescar();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aviso guardado'),
          backgroundColor: AppColors.verde,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error. ¿Ejecutaste ADD_PAGO_AVISOS_PROGRAMADOS.sql?\n$e',
          ),
          backgroundColor: AppColors.rojo,
        ),
      );
    }
  }

  Future<void> _enviarAhora(PagoAvisoProgramado aviso, {bool forzar = false}) async {
    final user = context.read<AuthService>().currentUser;
    if (user == null || _enviando) return;

    final hoy = DateTime.now().day;
    if (!forzar && aviso.diaMes != hoy) {
      final cont = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('¿Enviar fuera de día?'),
          content: Text(
            'Este aviso (${PagoAvisoTipo.etiqueta(aviso.tipo)}) está '
            'programado para el día ${aviso.diaMes} y hoy es $hoy. '
            '¿Enviar de todos modos?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Enviar ahora'),
            ),
          ],
        ),
      );
      if (cont != true || !mounted) return;
    }

    setState(() => _enviando = true);
    try {
      var filas = await _service.destinatariosPara(aviso);
      if (filas.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              aviso.esAdeudo
                  ? 'Nadie con adeudo vencido en Kínder 1–3. No se envió nada.'
                  : 'Nadie con colegiatura pendiente en Kínder 1–3. No se envió nada.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      if (!mounted) return;
      final seleccion = await _elegirDestinatarios(filas);
      if (seleccion == null || !mounted) {
        setState(() => _enviando = false);
        return;
      }
      filas = seleccion;

      final porPadre = _service.agruparPorPadre(filas);
      var enviadosChat = 0;
      var omitidos = 0;

      if (aviso.enviarChat) {
        for (final entry in porPadre.entries) {
          final padreId = entry.key;
          if (await _service.yaEnviadoHoy(
            avisoId: aviso.id,
            padreId: padreId,
            canal: 'chat',
          )) {
            omitidos++;
            continue;
          }
          final texto = PagoAvisosService.personalizar(
            plantilla: aviso.mensaje,
            nombresHijos: entry.value.hijos,
            saldo: entry.value.saldo,
          );
          final tituloFirma =
              PagoAvisoTipo.tituloConFirma(aviso.titulo);
          final cuerpo = texto.contains('Administración CAIPI')
              ? texto
              : '$texto\n\n— ${PagoAvisoTipo.firma}';
          final n = await ChatService().enviarMensajeMasivoAPadres(
            remitenteId: user.id,
            contenido: '$tituloFirma\n\n$cuerpo',
            paraTodos: false,
            soloPadreIds: [padreId],
            omitirHorario: true,
          );
          if (n > 0) {
            enviadosChat += n;
            await _service.registrarEnvio(
              avisoId: aviso.id,
              padreId: padreId,
              canal: 'chat',
            );
          }
        }
      }

      await _service.marcarEjecutado(aviso.id);
      await _refrescar();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Chat: $enviadosChat enviado(s)'
            '${omitidos > 0 ? ' · $omitidos ya notificados hoy' : ''}. '
            '${PagoAvisoTipo.etiqueta(aviso.tipo)}.',
          ),
          backgroundColor: AppColors.verde,
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al enviar: $e'),
          backgroundColor: AppColors.rojo,
        ),
      );
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Future<List<PadreAdeudoResumen>?> _elegirDestinatarios(
    List<PadreAdeudoResumen> todos,
  ) async {
    final svc = context.read<SupabaseService>();
    final grados = await svc.obtenerGrados();
    final alumnos = await svc.obtenerAlumnos();
    final gradoPorAlumno = {
      for (final a in alumnos)
        if (a.gradoId != null) a.id: a.gradoId!,
    };
    final gradosOk = grados.where((g) => g.muestraModuloPagos).toList();
    gradosOk.sort((a, b) => a.nombre.compareTo(b.nombre));
    if (!mounted) return null;

    String modo = 'todos'; // todos | grupo | varios
    String? gradoId;
    final seleccionados = <String>{};

    return showDialog<List<PadreAdeudoResumen>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          final visibles = todos.where((f) {
            if (modo == 'todos') return true;
            if (modo == 'grupo') {
              if (gradoId == null) return false;
              return gradoPorAlumno[f.alumnoId] == gradoId;
            }
            return seleccionados.contains(f.alumnoId);
          }).toList();

          return AlertDialog(
            title: const Text('¿A quién enviar?'),
            content: SizedBox(
              width: 420,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Base: ${todos.length} hijo(s) con saldo según el tipo de aviso.',
                      style: GoogleFonts.poppins(fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Todos'),
                          selected: modo == 'todos',
                          onSelected: (_) => setLocal(() {
                            modo = 'todos';
                            seleccionados.clear();
                          }),
                        ),
                        ChoiceChip(
                          label: const Text('Por grupo'),
                          selected: modo == 'grupo',
                          onSelected: (_) => setLocal(() {
                            modo = 'grupo';
                            seleccionados.clear();
                          }),
                        ),
                        ChoiceChip(
                          label: const Text('Uno / varios'),
                          selected: modo == 'varios',
                          onSelected: (_) => setLocal(() {
                            modo = 'varios';
                            gradoId = null;
                          }),
                        ),
                      ],
                    ),
                    if (modo == 'grupo') ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: gradoId,
                        decoration: const InputDecoration(
                          labelText: 'Grupo (Kínder)',
                          border: OutlineInputBorder(),
                        ),
                        items: gradosOk
                            .map(
                              (g) => DropdownMenuItem(
                                value: g.id,
                                child: Text(g.nombre),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setLocal(() => gradoId = v),
                      ),
                    ],
                    if (modo == 'varios') ...[
                      const SizedBox(height: 8),
                      ...todos.map(
                        (f) => CheckboxListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          value: seleccionados.contains(f.alumnoId),
                          title: Text(
                            f.alumnoNombre,
                            style: GoogleFonts.poppins(fontSize: 13),
                          ),
                          subtitle: Text(
                            'Saldo ${PagoAvisoTipo.formatoMxn.format(f.saldo)}',
                            style: GoogleFonts.poppins(fontSize: 11),
                          ),
                          onChanged: (v) => setLocal(() {
                            if (v == true) {
                              seleccionados.add(f.alumnoId);
                            } else {
                              seleccionados.remove(f.alumnoId);
                            }
                          }),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      'Se enviará a ${visibles.length} registro(s).',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: visibles.isEmpty
                    ? null
                    : () => Navigator.pop(ctx, visibles),
                child: const Text('Enviar'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grisClaro,
      drawer: const AppDrawer(),
      appBar: AppBar(
        leading: const CaipiAppBarLeading(),
        title: Text(
          'Avisos de pago',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.azulOscuro,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => context.go('/directora'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _enviando ? null : () => _editar(),
        backgroundColor: AppColors.morado,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo aviso'),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                initiallyExpanded: false,
                onExpansionChanged: (v) =>
                    setState(() => _ayudaExpandida = v),
                tilePadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                title: Text(
                  _ayudaExpandida
                      ? 'Cómo funcionan los avisos'
                      : 'Avisos configurables · toca para ver ayuda',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade900,
                  ),
                ),
                children: [
                  Text(
                    'Día del mes, tipo, título y texto. Placeholders: '
                    '{nombres_hijos}, {nombre_hijo}, {saldo}.\n\n'
                    '• Pronto pago — el pago está por llegar.\n'
                    '• Adeudo — saldo vencido.\n'
                    '• Administración — aviso institucional.\n\n'
                    'Al enviar puedes elegir: todos, un grupo, varios niños o uno solo.\n'
                    'Notificación al celular solo si el papá tiene la app con avisos activos.',
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      color: Colors.blue.shade900,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<PagoAvisoProgramado>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Error al cargar.\n¿Ejecutaste ADD_PAGO_AVISOS_PROGRAMADOS.sql?\n${snap.error}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                final lista = snap.data ?? [];
                if (lista.isEmpty) {
                  return Center(
                    child: Text(
                      'Sin avisos. Crea Pronto pago, Adeudo y Administración.',
                      style: GoogleFonts.poppins(color: AppColors.gris),
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: _refrescar,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                    itemCount: lista.length,
                    itemBuilder: (context, i) {
                      final a = lista[i];
                      final colorTipo = a.esAdeudo
                          ? Colors.orange.shade800
                          : a.esAdmin
                              ? AppColors.morado
                              : AppColors.azulOscuro;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                a.activo ? colorTipo : AppColors.gris,
                            child: Text(
                              '${a.diaMes}',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(
                            a.nombre,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            '${PagoAvisoTipo.etiqueta(a.tipo)} · Día ${a.diaMes} · '
                            '${a.enviarChat ? 'chat' : ''}'
                            '${a.enviarChat && a.enviarPush ? '+' : ''}'
                            '${a.enviarPush ? 'push' : ''}\n'
                            '${a.mensaje.length > 80 ? '${a.mensaje.substring(0, 80)}…' : a.mensaje}',
                            style: GoogleFonts.poppins(fontSize: 12),
                          ),
                          isThreeLine: true,
                          trailing: PopupMenuButton<String>(
                            onSelected: (v) async {
                              if (v == 'edit') await _editar(a);
                              if (v == 'send') await _enviarAhora(a);
                              if (v == 'del') {
                                final ok = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('¿Eliminar aviso?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, false),
                                        child: const Text('No'),
                                      ),
                                      FilledButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, true),
                                        child: const Text('Sí'),
                                      ),
                                    ],
                                  ),
                                );
                                if (ok == true) {
                                  await _service.eliminar(a.id);
                                  await _refrescar();
                                }
                              }
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                value: 'send',
                                child: Text('Enviar ahora'),
                              ),
                              PopupMenuItem(
                                value: 'edit',
                                child: Text('Editar'),
                              ),
                              PopupMenuItem(
                                value: 'del',
                                child: Text('Eliminar'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
