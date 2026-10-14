import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/app_colors.dart';
import '../../models/incidente.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/caipi_app_bar_leading.dart';
import '../../widgets/campana_anuncios_padre.dart';

enum _FiltroIncPadre { todas, nuevas, pasadas }

class IncidentesPadreScreen extends StatefulWidget {
  final String alumnoId;
  final String alumnoNombre;

  const IncidentesPadreScreen({
    super.key,
    required this.alumnoId,
    required this.alumnoNombre,
  });

  @override
  State<IncidentesPadreScreen> createState() => _IncidentesPadreScreenState();
}

class _IncidentesPadreScreenState extends State<IncidentesPadreScreen> {
  _FiltroIncPadre _filtro = _FiltroIncPadre.todas;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7FA),
      drawer: const AppDrawer(),
      appBar: AppBar(
        leading: const CaipiAppBarLeading(),
        title: Text(
          'Incidentes',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: const Color(0xFFEC407A),
        foregroundColor: Colors.white,
        actions: const [
          CampanaAnunciosPadre(),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          Text(
            widget.alumnoNombre,
            style: GoogleFonts.fredoka(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF2D2640),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Avisitos de la escuela sobre tu hijo. Toca uno para leerlo.',
            style: GoogleFonts.poppins(fontSize: 13, color: AppColors.gris),
          ),
          const SizedBox(height: 14),
          SegmentedButton<_FiltroIncPadre>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(
                value: _FiltroIncPadre.todas,
                label: Text('Todas'),
              ),
              ButtonSegment(
                value: _FiltroIncPadre.nuevas,
                label: Text('Nuevas'),
              ),
              ButtonSegment(
                value: _FiltroIncPadre.pasadas,
                label: Text('Pasadas'),
              ),
            ],
            selected: {_filtro},
            onSelectionChanged: (s) => setState(() => _filtro = s.first),
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              textStyle: WidgetStatePropertyAll(
                GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 14),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: Supabase.instance.client
                .from('incidentes')
                .stream(primaryKey: ['id'])
                .eq('alumno_id', widget.alumnoId)
                .order('fecha', ascending: false),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Card(
                  elevation: 0,
                  color: const Color(0xFFE8F8F0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green[600], size: 36),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '¡Todo bien!',
                                style: GoogleFonts.fredoka(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[800],
                                ),
                              ),
                              Text(
                                'No hay incidentes reportados',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: AppColors.grisOscuro,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              var incidentes = snapshot.data!
                  .map((json) => Incidente.fromJson(json))
                  .toList();
              final nuevasCount = incidentes.where((i) => i.esNueva).length;

              if (_filtro == _FiltroIncPadre.nuevas) {
                incidentes = incidentes.where((i) => i.esNueva).toList();
              } else if (_filtro == _FiltroIncPadre.pasadas) {
                incidentes = incidentes.where((i) => !i.esNueva).toList();
              }

              if (incidentes.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    _filtro == _FiltroIncPadre.nuevas
                        ? 'No hay incidentes nuevos'
                        : 'No hay incidentes en este filtro',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(color: AppColors.gris),
                  ),
                );
              }

              return Column(
                children: [
                  if (nuevasCount > 0 && _filtro != _FiltroIncPadre.pasadas)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.notifications_active, color: Colors.orange),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '$nuevasCount incidente${nuevasCount > 1 ? 's' : ''} sin leer. Si tienes duda, platica con la directora.',
                              style: GoogleFonts.poppins(
                                color: Colors.orange[900],
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.push('/padre/chat'),
                            child: const Text('Chat'),
                          ),
                        ],
                      ),
                    ),
                  ...incidentes.map(_tarjeta),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _tarjeta(Incidente incidente) {
    final colorNivel = _colorNivel(incidente.nivel);
    final esNueva = incidente.esNueva;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: esNueva ? 2 : 0,
      color: esNueva ? const Color(0xFFFFF7ED) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: esNueva
              ? const Color(0xFFFDBA74)
              : (incidente.nivel >= 4 ? colorNivel : const Color(0xFFE8E2F0)),
          width: esNueva || incidente.nivel >= 4 ? 2 : 1,
        ),
      ),
      child: ListTile(
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: colorNivel,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(incidente.emoji, style: const TextStyle(fontSize: 20)),
          ),
        ),
        title: Row(
          children: [
            if (esNueva) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'NUEVA',
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 6),
            ],
            Expanded(
              child: Text(
                incidente.titulo,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              incidente.descripcion,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('dd/MM/yyyy HH:mm', 'es_MX').format(incidente.fecha),
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: Icon(
          esNueva ? Icons.mark_email_unread : Icons.mark_email_read,
          color: esNueva ? Colors.orange : Colors.green,
        ),
        isThreeLine: true,
        onTap: () => _mostrarDetalle(incidente),
      ),
    );
  }

  Color _colorNivel(int nivel) {
    switch (nivel) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.yellow[700]!;
      case 3:
        return Colors.orange;
      case 4:
        return Colors.deepOrange;
      case 5:
        return Colors.red[900]!;
      default:
        return Colors.grey;
    }
  }

  Future<void> _setLeido(String id, bool leido) async {
    try {
      await Supabase.instance.client
          .from('incidentes')
          .update({'leido_padre': leido})
          .eq('id', id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo actualizar: $e')),
        );
      }
    }
  }

  void _mostrarDetalle(Incidente incidente) {
    if (incidente.esNueva) {
      _setLeido(incidente.id, true);
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (dialogCtx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            16 + MediaQuery.viewPaddingOf(dialogCtx).bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Text(incidente.emoji, style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        incidente.titulo,
                        style: GoogleFonts.fredoka(fontSize: 22),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _detalleItem(
                  'Nivel',
                  '${incidente.nivel} - ${incidente.nivelLabel}',
                  _colorNivel(incidente.nivel),
                ),
                const Divider(),
                _detalleItem('Descripción', incidente.descripcion, Colors.black87),
                const Divider(),
                _detalleItem(
                  'Fecha',
                  DateFormat('dd/MM/yyyy HH:mm', 'es_MX').format(incidente.fecha),
                  Colors.black87,
                ),
                if (incidente.observaciones != null) ...[
                  const Divider(),
                  _detalleItem(
                    'Observaciones',
                    incidente.observaciones!,
                    Colors.black87,
                  ),
                ],
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Si tienes dudas, platica con la directora por el chat de la escuela.',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.blue[900],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    Navigator.of(dialogCtx).pop();
                    context.push('/padre/chat');
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.rosa,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Chat con la escuela'),
                ),
                TextButton(
                  onPressed: () async {
                    await _setLeido(incidente.id, false);
                    if (dialogCtx.mounted) Navigator.of(dialogCtx).pop();
                  },
                  child: const Text('Marcar no leída'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _detalleItem(String label, String valor, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(valor, style: TextStyle(fontSize: 14, color: color)),
      ],
    );
  }
}
