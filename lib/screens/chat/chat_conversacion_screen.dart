import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../config/app_colors.dart';
import '../../models/mensaje_chat.dart';
import '../../services/auth_service.dart';
import '../../services/chat_horario_service.dart';
import '../../services/chat_service.dart';
import '../../widgets/app_drawer.dart';

class ChatConversacionScreen extends StatefulWidget {
  final String conversacionId;
  final String titulo;
  final String? rutaInicio;

  const ChatConversacionScreen({
    super.key,
    required this.conversacionId,
    required this.titulo,
    this.rutaInicio,
  });

  @override
  State<ChatConversacionScreen> createState() => _ChatConversacionScreenState();
}

class _ChatConversacionScreenState extends State<ChatConversacionScreen> {
  final ChatService _chatService = ChatService();
  final ChatHorarioService _horarioService = ChatHorarioService();
  final TextEditingController _mensajeController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _enviando = false;
  bool _puedeEnviar = true;
  ConfigChatHorario? _config;
  bool _cargandoHorario = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _marcarLeidos();
      _cargarHorario();
    });
  }

  Future<void> _cargarHorario() async {
    final usuario = context.read<AuthService>().currentUser;
    if (usuario == null) {
      if (mounted) setState(() => _cargandoHorario = false);
      return;
    }
    final config = await _horarioService.obtenerConfig();
    final puede = await _horarioService.usuarioPuedeEnviar(usuario.id);
    if (mounted) {
      setState(() {
        _config = config;
        _puedeEnviar = puede;
        _cargandoHorario = false;
      });
    }
  }

  @override
  void dispose() {
    _mensajeController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _marcarLeidos() async {
    final usuario = context.read<AuthService>().currentUser;
    if (usuario == null) return;
    await _chatService.marcarMensajesLeidos(
      conversacionId: widget.conversacionId,
      lectorId: usuario.id,
    );
  }

  Future<void> _enviarMensaje() async {
    final usuario = context.read<AuthService>().currentUser;
    if (usuario == null || _enviando || !_puedeEnviar) return;

    final texto = _mensajeController.text.trim();
    if (texto.isEmpty) return;

    setState(() => _enviando = true);
    _mensajeController.clear();

    try {
      await _chatService.enviarMensaje(
        conversacionId: widget.conversacionId,
        remitenteId: usuario.id,
        contenido: texto,
      );
      if (mounted) {
        await _marcarLeidos();
        // reverse:true ancla el mensaje nuevo abajo (offset 0).
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(0);
        }
      }
    } catch (e) {
      if (mounted) {
        final fuera = e is StateError && e.message == 'FUERA_HORARIO';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              fuera
                  ? (_config?.mensajeFueraHorario ??
                      'Fuera del horario de chat escolar.')
                  : 'No se pudo enviar: $e',
            ),
          ),
        );
        if (fuera) await _cargarHorario();
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  void _scrollAlFinal() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<AuthService>().currentUser;
    final rutaInicio = widget.rutaInicio ?? _rutaInicioPorRol(usuario?.rol);

    return Scaffold(
      backgroundColor: AppColors.grisClaro,
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.titulo,
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              'Chat con la escuela',
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: AppColors.azulOscuro,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => context.go(rutaInicio),
            tooltip: 'Ir al inicio',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<MensajeChat>>(
              stream: _chatService.streamMensajes(widget.conversacionId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Error al cargar mensajes.\n¿Ejecutaste ADD_CHAT_PADRES_ESCUELA.sql?',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(color: AppColors.gris),
                      ),
                    ),
                  );
                }

                final mensajes = List<MensajeChat>.from(snapshot.data ?? [])
                  ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

                // reverse:true → índice 0 queda pegado al input (abajo).
                // Por eso invertimos: el más nuevo es el primero de la lista.
                final mensajesUi = mensajes.reversed.toList();

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _marcarLeidos();
                });

                if (mensajes.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline, size: 64, color: AppColors.gris.withOpacity(0.4)),
                          const SizedBox(height: 16),
                          Text(
                            'Sin mensajes aún',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.gris,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Escribe el primer mensaje para iniciar la conversación.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(fontSize: 14, color: AppColors.gris),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: mensajesUi.length,
                  itemBuilder: (context, index) {
                    final mensaje = mensajesUi[index];
                    final esMio = mensaje.remitenteId == usuario?.id;
                    final fechaActual = DateTime(
                      mensaje.createdAt.year,
                      mensaje.createdAt.month,
                      mensaje.createdAt.day,
                    );
                    // En lista invertida, el mensaje "anterior" (más viejo) está en index+1.
                    final mostrarSeparador = index == mensajesUi.length - 1 ||
                        fechaActual !=
                            DateTime(
                              mensajesUi[index + 1].createdAt.year,
                              mensajesUi[index + 1].createdAt.month,
                              mensajesUi[index + 1].createdAt.day,
                            );

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (mostrarSeparador) _SeparadorFecha(fecha: fechaActual),
                        _MensajeBubble(mensaje: mensaje, esMio: esMio),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildInput() {
    final cerrado = !_cargandoHorario && !_puedeEnviar;
    final cfg = _config;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (cerrado)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              color: const Color(0xFFFFF3E0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.schedule, color: Color(0xFFE65100), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      cfg?.mensajeFueraHorario ??
                          'Fuera del horario escolar. El chat abre ${cfg?.resumenDias ?? 'Lun–Vie'} de ${cfg?.horaInicio ?? '08:00'} a ${cfg?.horaFin ?? '16:00'}.',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFFE65100),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (!cerrado && cfg != null && cfg.activo)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              color: const Color(0xFFE8F5E9),
              child: Text(
                'Horario chat: ${cfg.resumenDias} ${cfg.horaInicio}–${cfg.horaFin}',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF2E7D32)),
              ),
            ),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _mensajeController,
                    enabled: !cerrado && !_enviando,
                    minLines: 1,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: cerrado
                          ? 'Chat cerrado fuera de horario'
                          : 'Escribe un mensaje...',
                      filled: true,
                      fillColor: AppColors.grisClaro,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => _enviarMensaje(),
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: cerrado ? Colors.grey : AppColors.morado,
                  borderRadius: BorderRadius.circular(24),
                  child: InkWell(
                    onTap: (cerrado || _enviando) ? null : _enviarMensaje,
                    borderRadius: BorderRadius.circular(24),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: _enviando
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send_rounded, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _rutaInicioPorRol(String? rol) {
    if (rol == 'padre') return '/padre';
    return '/directora';
  }
}

String _formatearFechaMensaje(DateTime fecha) {
  final local = fecha.toLocal();
  final hoy = DateTime.now();
  final hoySolo = DateTime(hoy.year, hoy.month, hoy.day);
  final ayer = hoySolo.subtract(const Duration(days: 1));
  final fechaSolo = DateTime(local.year, local.month, local.day);
  final hora = DateFormat('HH:mm').format(local);

  if (fechaSolo == hoySolo) return 'Hoy · $hora';
  if (fechaSolo == ayer) return 'Ayer · $hora';
  return '${DateFormat('dd/MM/yyyy').format(local)} · $hora';
}

String _formatearEtiquetaDia(DateTime fecha) {
  final local = fecha.toLocal();
  final hoy = DateTime.now();
  final hoySolo = DateTime(hoy.year, hoy.month, hoy.day);
  final ayer = hoySolo.subtract(const Duration(days: 1));
  final fechaSolo = DateTime(local.year, local.month, local.day);

  if (fechaSolo == hoySolo) return 'Hoy';
  if (fechaSolo == ayer) return 'Ayer';
  return DateFormat('EEEE d MMM yyyy', 'es_MX').format(local);
}

class _SeparadorFecha extends StatelessWidget {
  final DateTime fecha;

  const _SeparadorFecha({required this.fecha});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
              ),
            ],
          ),
          child: Text(
            _formatearEtiquetaDia(fecha),
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.gris,
            ),
          ),
        ),
      ),
    );
  }
}

class _MensajeBubble extends StatelessWidget {
  final MensajeChat mensaje;
  final bool esMio;

  const _MensajeBubble({required this.mensaje, required this.esMio});

  @override
  Widget build(BuildContext context) {
    final etiqueta = _formatearFechaMensaje(mensaje.createdAt);

    return Align(
      alignment: esMio ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: esMio ? AppColors.morado : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(esMio ? 16 : 4),
            bottomRight: Radius.circular(esMio ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              mensaje.contenido,
              style: GoogleFonts.poppins(
                color: esMio ? Colors.white : AppColors.negro,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              etiqueta,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: esMio ? Colors.white70 : AppColors.gris,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
