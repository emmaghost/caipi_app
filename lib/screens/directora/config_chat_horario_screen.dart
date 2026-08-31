import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../config/app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/chat_horario_service.dart';
import '../../widgets/app_drawer.dart';

class ConfigChatHorarioScreen extends StatefulWidget {
  const ConfigChatHorarioScreen({super.key});

  @override
  State<ConfigChatHorarioScreen> createState() => _ConfigChatHorarioScreenState();
}

class _ConfigChatHorarioScreenState extends State<ConfigChatHorarioScreen> {
  final _service = ChatHorarioService();
  final _mensajeCtrl = TextEditingController();
  bool _cargando = true;
  bool _guardando = false;
  bool _activo = true;
  bool _staffSiempre = true;
  TimeOfDay _inicio = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _fin = const TimeOfDay(hour: 16, minute: 0);
  final Set<int> _dias = {1, 2, 3, 4, 5};

  static const _labels = {
    1: 'Lun',
    2: 'Mar',
    3: 'Mié',
    4: 'Jue',
    5: 'Vie',
    6: 'Sáb',
    7: 'Dom',
  };

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _mensajeCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    final cfg = await _service.obtenerConfig();
    if (!mounted) return;
    setState(() {
      _activo = cfg.activo;
      _staffSiempre = cfg.staffSiemprePuede;
      _dias
        ..clear()
        ..addAll(cfg.diasActivos);
      _inicio = _parseTime(cfg.horaInicio);
      _fin = _parseTime(cfg.horaFin);
      _mensajeCtrl.text = cfg.mensajeFueraHorario;
      _cargando = false;
    });
  }

  TimeOfDay _parseTime(String s) {
    final parts = s.split(':');
    return TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 8,
      minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
    );
  }

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickInicio() async {
    final t = await showTimePicker(context: context, initialTime: _inicio);
    if (t != null) setState(() => _inicio = t);
  }

  Future<void> _pickFin() async {
    final t = await showTimePicker(context: context, initialTime: _fin);
    if (t != null) setState(() => _fin = t);
  }

  Future<void> _guardar() async {
    if (_dias.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Elige al menos un día')),
      );
      return;
    }
    setState(() => _guardando = true);
    try {
      final user = context.read<AuthService>().currentUser;
      await _service.guardarConfig(
        activo: _activo,
        diasActivos: _dias.toList()..sort(),
        horaInicio: _fmt(_inicio),
        horaFin: _fmt(_fin),
        staffSiemprePuede: _staffSiempre,
        mensajeFueraHorario: _mensajeCtrl.text.trim().isEmpty
            ? 'El chat está disponible en horario escolar.'
            : _mensajeCtrl.text.trim(),
        updatedBy: user?.id,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Horario de chat guardado'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al guardar. ¿Ejecutaste ADD_CHAT_HORARIO_Y_PUSH_TOKENS.sql?\n$e',
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
    return Scaffold(
      backgroundColor: AppColors.grisClaro,
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Text(
          'Horario del chat',
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
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SwitchListTile(
                  value: _activo,
                  onChanged: (v) => setState(() => _activo = v),
                  title: const Text('Restringir chat por horario'),
                  subtitle: const Text(
                    'Si está apagado, se puede chatear a cualquier hora',
                  ),
                  activeColor: AppColors.morado,
                ),
                const SizedBox(height: 8),
                Text('Días activos', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _labels.entries.map((e) {
                    final sel = _dias.contains(e.key);
                    return FilterChip(
                      label: Text(e.value),
                      selected: sel,
                      onSelected: (v) {
                        setState(() {
                          if (v) {
                            _dias.add(e.key);
                          } else {
                            _dias.remove(e.key);
                          }
                        });
                      },
                      selectedColor: AppColors.morado.withOpacity(0.25),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Hora de inicio'),
                  subtitle: Text(_fmt(_inicio)),
                  trailing: const Icon(Icons.access_time),
                  onTap: _pickInicio,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  title: const Text('Hora de fin'),
                  subtitle: Text(_fmt(_fin)),
                  trailing: const Icon(Icons.access_time),
                  onTap: _pickFin,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  value: _staffSiempre,
                  onChanged: (v) => setState(() => _staffSiempre = v),
                  title: const Text('Escuela puede responder siempre'),
                  subtitle: const Text(
                    'Directora/profesoras envían aunque esté cerrado el horario',
                  ),
                  activeColor: AppColors.morado,
                ),
                const SizedBox(height: 12),
                Text(
                  'Mensaje fuera de horario',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _mensajeCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _guardando ? null : _guardar,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.morado,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _guardando
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Guardar horario'),
                ),
              ],
            ),
    );
  }
}
