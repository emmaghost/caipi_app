import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../config/app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../widgets/app_drawer.dart';

class ConfigChatCanalesScreen extends StatefulWidget {
  const ConfigChatCanalesScreen({super.key});

  @override
  State<ConfigChatCanalesScreen> createState() =>
      _ConfigChatCanalesScreenState();
}

class _ConfigChatCanalesScreenState extends State<ConfigChatCanalesScreen> {
  final _service = ChatService();
  bool _cargando = true;
  bool _guardando = false;
  bool _padrePuedeDirectora = true;
  bool _padrePuedeMaestraGrupo = true;
  bool _padrePuedeMaestraIngles = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final cfg = await _service.obtenerChatConfig();
    if (!mounted) return;
    setState(() {
      _padrePuedeDirectora = cfg.padrePuedeDirectora;
      _padrePuedeMaestraGrupo = cfg.padrePuedeMaestraGrupo;
      _padrePuedeMaestraIngles = cfg.padrePuedeMaestraIngles;
      _cargando = false;
    });
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    try {
      await _service.guardarChatConfig(
        padrePuedeDirectora: _padrePuedeDirectora,
        padrePuedeMaestraGrupo: _padrePuedeMaestraGrupo,
        padrePuedeMaestraIngles: _padrePuedeMaestraIngles,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Canales de chat guardados'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al guardar. ¿Ejecutaste ADD_CHAT_MULTI_CANAL.sql?\n$e',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final esDirectora =
        context.watch<AuthService>().currentUser?.esDirectora == true;

    return Scaffold(
      backgroundColor: AppColors.grisClaro,
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Text(
          'Canales de chat',
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
      body: !esDirectora
          ? Center(
              child: Text(
                'Solo la directora puede configurar canales.',
                style: GoogleFonts.poppins(color: AppColors.gris),
              ),
            )
          : _cargando
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      'Elige con quién pueden chatear los padres.',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppColors.gris,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          SwitchListTile(
                            title: Text(
                              'Directora',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              'Padre puede escribir a dirección',
                              style: GoogleFonts.poppins(fontSize: 12),
                            ),
                            value: _padrePuedeDirectora,
                            activeColor: AppColors.morado,
                            onChanged: (v) =>
                                setState(() => _padrePuedeDirectora = v),
                          ),
                          const Divider(height: 1),
                          SwitchListTile(
                            title: Text(
                              'Maestra de grupo',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              'Padre puede escribir a la titular del grado',
                              style: GoogleFonts.poppins(fontSize: 12),
                            ),
                            value: _padrePuedeMaestraGrupo,
                            activeColor: AppColors.morado,
                            onChanged: (v) =>
                                setState(() => _padrePuedeMaestraGrupo = v),
                          ),
                          const Divider(height: 1),
                          SwitchListTile(
                            title: Text(
                              'Maestra de inglés',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              'Padre puede escribir a la maestra de inglés',
                              style: GoogleFonts.poppins(fontSize: 12),
                            ),
                            value: _padrePuedeMaestraIngles,
                            activeColor: AppColors.morado,
                            onChanged: (v) =>
                                setState(() => _padrePuedeMaestraIngles = v),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 52,
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _guardando ? null : _guardar,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.azulOscuro,
                        ),
                        child: _guardando
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Guardar',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
