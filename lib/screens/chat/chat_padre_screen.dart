import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../config/app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../widgets/app_drawer.dart';
import 'chat_conversacion_screen.dart';

class ChatPadreScreen extends StatefulWidget {
  const ChatPadreScreen({super.key});

  @override
  State<ChatPadreScreen> createState() => _ChatPadreScreenState();
}

class _ChatPadreScreenState extends State<ChatPadreScreen> {
  final ChatService _chatService = ChatService();
  Future<List<Map<String, dynamic>>>? _contactosFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_contactosFuture != null) return;
    final uid = context.read<AuthService>().currentUser?.id;
    _contactosFuture = uid == null
        ? Future.value(const [])
        : _chatService.contactosParaPadre(uid);
  }

  Future<void> _abrirContacto(Map<String, dynamic> contacto) async {
    final usuario = context.read<AuthService>().currentUser;
    if (usuario == null) return;

    final canal = (contacto['canal'] as String?) ?? 'directora';
    final staffId = contacto['staffId'] as String?;
    final titulo = (contacto['titulo'] as String?) ?? 'Chat';

    try {
      final conversacion = await _chatService.obtenerOCrearConversacion(
        usuario.id,
        canal: canal,
        staffId: staffId,
      );
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatConversacionScreen(
            conversacionId: conversacion.id,
            titulo: titulo,
            rutaInicio: '/padre',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo abrir el chat.\n'
            '¿Ejecutaste ADD_CHAT_MULTI_CANAL.sql?\n$e',
          ),
        ),
      );
    }
  }

  IconData _iconoCanal(String canal) {
    if (canal == 'profesor') return Icons.school;
    return Icons.admin_panel_settings;
  }

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<AuthService>().currentUser;

    if (usuario == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.grisClaro,
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Text(
          'Chat con la Escuela',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFEC407A),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _contactosFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No se pudieron cargar los contactos.\n'
                  '¿Ejecutaste ADD_CHAT_MULTI_CANAL.sql?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(color: AppColors.gris),
                ),
              ),
            );
          }

          final contactos = snapshot.data ?? [];
          if (contactos.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No hay canales de chat disponibles por ahora.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(color: AppColors.gris),
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: contactos.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final c = contactos[index];
              final canal = (c['canal'] as String?) ?? 'directora';
              final titulo = (c['titulo'] as String?) ?? 'Chat';
              return Card(
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
                    child: Icon(
                      _iconoCanal(canal),
                      color: AppColors.rosa,
                    ),
                  ),
                  title: Text(
                    titulo,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    canal == 'profesor'
                        ? 'Conversación con la maestra'
                        : 'Conversación con dirección',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.gris,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _abrirContacto(c),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
