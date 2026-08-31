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

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<AuthService>().currentUser;

    if (usuario == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return FutureBuilder(
      future: _chatService.obtenerOCrearConversacion(usuario.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: AppColors.grisClaro,
            drawer: const AppDrawer(),
            appBar: AppBar(
              title: Text('Chat con la Escuela', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
              backgroundColor: const Color(0xFFEC407A),
              foregroundColor: Colors.white,
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            backgroundColor: AppColors.grisClaro,
            drawer: const AppDrawer(),
            appBar: AppBar(
              title: Text('Chat con la Escuela', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
              backgroundColor: const Color(0xFFEC407A),
              foregroundColor: Colors.white,
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No se pudo abrir el chat.\n¿Ejecutaste ADD_CHAT_PADRES_ESCUELA.sql en Supabase?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(color: AppColors.gris),
                ),
              ),
            ),
          );
        }

        final conversacion = snapshot.data!;
        return ChatConversacionScreen(
          conversacionId: conversacion.id,
          titulo: 'CAIPI',
          rutaInicio: '/padre',
        );
      },
    );
  }
}
