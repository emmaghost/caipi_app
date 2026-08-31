import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/app_colors.dart';
import '../../models/conversacion.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../services/portage_service.dart';
import '../../widgets/app_drawer.dart';

class ChatListaEscuelaScreen extends StatefulWidget {
  const ChatListaEscuelaScreen({super.key});

  @override
  State<ChatListaEscuelaScreen> createState() => _ChatListaEscuelaScreenState();
}

class _ChatListaEscuelaScreenState extends State<ChatListaEscuelaScreen> {
  /// Si no es null, solo se muestran padres de alumnos de ese grado.
  Set<String>? _padreIdsPermitidos;
  bool _filtroListo = false;

  @override
  void initState() {
    super.initState();
    _cargarFiltroGrado();
  }

  Future<void> _cargarFiltroGrado() async {
    final user = context.read<AuthService>().currentUser;
    // Directora y profesor_admin ven todos los chats.
    if (user == null ||
        user.esDirectora ||
        user.esProfesorAdmin) {
      setState(() {
        _padreIdsPermitidos = null;
        _filtroListo = true;
      });
      return;
    }

    if (!user.esProfesor) {
      setState(() {
        _padreIdsPermitidos = {};
        _filtroListo = true;
      });
      return;
    }

    try {
      final gradoId = await PortageService().obtenerGradoIdProfesor(user.id);
      if (gradoId == null) {
        setState(() {
          _padreIdsPermitidos = {};
          _filtroListo = true;
        });
        return;
      }
      final alumnos = await Supabase.instance.client
          .from('alumnos')
          .select('id, padre_id')
          .eq('grado_id', gradoId)
          .eq('activo', true);
      final ids = <String>{};
      final alumnoIds = <String>[];
      for (final row in alumnos as List) {
        final pid = row['padre_id'] as String?;
        if (pid != null) ids.add(pid);
        final aid = row['id'] as String?;
        if (aid != null) alumnoIds.add(aid);
      }
      if (alumnoIds.isNotEmpty) {
        try {
          final vinculos = await Supabase.instance.client
              .from('alumnos_padres')
              .select('padre_id')
              .inFilter('alumno_id', alumnoIds);
          for (final row in vinculos as List) {
            final pid = row['padre_id'] as String?;
            if (pid != null) ids.add(pid);
          }
        } catch (_) {
          // Tabla alumnos_padres aún no existe.
        }
      }
      if (!mounted) return;
      setState(() {
        _padreIdsPermitidos = ids;
        _filtroListo = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _padreIdsPermitidos = {};
        _filtroListo = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatService = ChatService();

    return Scaffold(
      backgroundColor: AppColors.grisClaro,
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Text(
          'Chat con Padres',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.azulOscuro,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => context.go('/directora'),
            tooltip: 'Ir al inicio',
          ),
        ],
      ),
      body: !_filtroListo
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<List<Map<String, dynamic>>>(
              stream: Supabase.instance.client
                  .from('usuarios')
                  .stream(primaryKey: ['id'])
                  .map((data) => data
                      .where((u) => u['rol'] == 'padre' && u['activo'] == true)
                      .toList()),
              builder: (context, padresSnapshot) {
                return StreamBuilder<List<Conversacion>>(
                  stream: chatService.streamConversaciones(),
                  builder: (context, convSnapshot) {
                    if (padresSnapshot.connectionState ==
                            ConnectionState.waiting ||
                        convSnapshot.connectionState ==
                            ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (padresSnapshot.hasError || convSnapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'Error al cargar chats.\n¿Ejecutaste ADD_CHAT_PADRES_ESCUELA.sql?',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(color: AppColors.gris),
                          ),
                        ),
                      );
                    }

                    var padres =
                        List<Map<String, dynamic>>.from(padresSnapshot.data ?? []);
                    if (_padreIdsPermitidos != null) {
                      padres = padres
                          .where((p) =>
                              _padreIdsPermitidos!.contains(p['id'] as String))
                          .toList();
                    }

                    final conversaciones = convSnapshot.data ?? [];
                    final convPorPadre = {
                      for (final c in conversaciones) c.padreId: c,
                    };

                    if (padres.isEmpty) {
                      return Center(
                        child: Text(
                          _padreIdsPermitidos != null
                              ? 'No hay chats de padres de tu grupo'
                              : 'No hay padres registrados',
                          style: GoogleFonts.poppins(
                            color: AppColors.gris,
                            fontSize: 16,
                          ),
                        ),
                      );
                    }

                    padres.sort((a, b) {
                      final convA = convPorPadre[a['id'] as String];
                      final convB = convPorPadre[b['id'] as String];
                      final fechaA =
                          convA?.ultimoMensajeAt ?? convA?.createdAt;
                      final fechaB =
                          convB?.ultimoMensajeAt ?? convB?.createdAt;
                      if (fechaA == null && fechaB == null) {
                        return (a['nombre'] as String? ?? '')
                            .compareTo(b['nombre'] as String? ?? '');
                      }
                      if (fechaA == null) return 1;
                      if (fechaB == null) return -1;
                      return fechaB.compareTo(fechaA);
                    });

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: padres.length,
                      itemBuilder: (context, index) {
                        final padre = padres[index];
                        final padreId = padre['id'] as String;
                        final conv = convPorPadre[padreId];
                        final nombre = _nombrePadre(padre);

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            leading: CircleAvatar(
                              backgroundColor: AppColors.rosa.withOpacity(0.2),
                              child: const Icon(Icons.person,
                                  color: AppColors.rosa),
                            ),
                            title: Text(
                              nombre,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              conv?.ultimoMensaje ??
                                  'Toca para iniciar conversación',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: conv?.ultimoMensaje != null
                                    ? AppColors.gris
                                    : AppColors.gris.withOpacity(0.7),
                                fontStyle: conv?.ultimoMensaje == null
                                    ? FontStyle.italic
                                    : FontStyle.normal,
                              ),
                            ),
                            trailing: conv?.ultimoMensajeAt != null
                                ? Text(
                                    DateFormat('dd/MM HH:mm').format(
                                      conv!.ultimoMensajeAt!.toLocal(),
                                    ),
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: AppColors.gris,
                                    ),
                                  )
                                : const Icon(Icons.chevron_right,
                                    color: AppColors.gris),
                            onTap: () async {
                              final conversacion = conv ??
                                  await chatService
                                      .obtenerOCrearConversacion(padreId);
                              if (!context.mounted) return;
                              context.push(
                                '/directora/chat/${conversacion.id}',
                                extra: {'titulo': nombre},
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _mostrarDialogoMensajeMasivo,
        backgroundColor: AppColors.verdeClaro,
        icon: const Icon(Icons.campaign, color: Colors.white),
        label: Text(
          'Mensaje masivo',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Future<void> _mostrarDialogoMensajeMasivo() async {
    final usuario = context.read<AuthService>().currentUser;
    if (usuario == null) return;

    final tituloCtrl = TextEditingController();
    final mensajeCtrl = TextEditingController();
    var enviando = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: !enviando,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              title: Text(
                'Mensaje masivo',
                style: GoogleFonts.fredoka(),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _padreIdsPermitidos == null
                          ? 'Se enviará a todos los papás activos.'
                          : 'Se enviará a los papás de tu grupo.',
                      style: GoogleFonts.poppins(fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: tituloCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Asunto (opcional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: mensajeCtrl,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Mensaje *',
                        hintText: 'Ej: Mañana nitta mexicana…',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: enviando ? null : () => Navigator.of(ctx).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: enviando
                      ? null
                      : () async {
                          final texto = mensajeCtrl.text.trim();
                          if (texto.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Escribe el mensaje'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                            return;
                          }
                          setLocal(() => enviando = true);
                          final asunto = tituloCtrl.text.trim();
                          final cuerpo = asunto.isEmpty
                              ? texto
                              : '📢 $asunto\n\n$texto';
                          try {
                            final n = await ChatService()
                                .enviarMensajeMasivoAPadres(
                              remitenteId: usuario.id,
                              contenido: cuerpo,
                              paraTodos: _padreIdsPermitidos == null,
                              soloPadreIds: _padreIdsPermitidos?.toList(),
                              omitirHorario: true,
                            );
                            if (!ctx.mounted) return;
                            Navigator.of(ctx).pop();
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '✓ Mensaje enviado a $n papá(s)',
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } catch (e) {
                            setLocal(() => enviando = false);
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                  child: enviando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Enviar'),
                ),
              ],
            );
          },
        );
      },
    );

    tituloCtrl.dispose();
    mensajeCtrl.dispose();
  }

  String _nombrePadre(Map<String, dynamic> padre) {
    final nombre = padre['nombre'] as String? ?? '';
    final apellidos = padre['apellidos'] as String? ?? '';
    return '$nombre $apellidos'.trim().isEmpty
        ? (padre['email'] as String? ?? 'Padre')
        : '$nombre $apellidos'.trim();
  }
}
