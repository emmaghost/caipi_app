import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/app_colors.dart';
import '../../models/alumno.dart';
import '../../models/evento.dart';
import '../../services/auth_service.dart';
import '../../services/supabase_service.dart';
import '../../utils/mexico_time.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/caipi_app_bar_leading.dart';

class EventosPadreScreen extends StatefulWidget {
  const EventosPadreScreen({Key? key}) : super(key: key);

  @override
  State<EventosPadreScreen> createState() => _EventosPadreScreenState();
}

class _EventosPadreScreenState extends State<EventosPadreScreen> {
  String _filtroTipo = 'Todos';

  DateTime _soloDia(DateTime d) => DateTime(d.year, d.month, d.day);

  bool _esHoyOFuturo(DateTime fecha) {
    final hoy = _soloDia(MexicoTime.now());
    return !_soloDia(fecha).isBefore(hoy);
  }

  bool _visibleParaPadre(Evento e, Set<String> gradoIdsHijos) {
    if (e.paraTodos) return true;
    final grados = e.gradosIds ?? const <String>[];
    if (grados.isEmpty) return true; // sin destino = escuela
    if (gradoIdsHijos.isEmpty) return false;
    return grados.any(gradoIdsHijos.contains);
  }

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<AuthService>().currentUser;

    return Scaffold(
      backgroundColor: AppColors.grisClaro,
      drawer: const AppDrawer(),
      appBar: AppBar(
        leading: const CaipiAppBarLeading(),
        backgroundColor: const Color(0xFFEC407A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Eventos',
          style: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => context.go('/padre'),
            tooltip: 'Ir al inicio',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildFiltroChip('Todos', Icons.event),
                _buildFiltroChip('academico', Icons.book, label: 'Académico'),
                _buildFiltroChip('festivo', Icons.celebration, label: 'Festivo'),
                _buildFiltroChip('reunion', Icons.groups, label: 'Reunión'),
                _buildFiltroChip('clausura', Icons.school, label: 'Clausura'),
                _buildFiltroChip('otro', Icons.more_horiz, label: 'Otro'),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Alumno>>(
              stream: usuario == null
                  ? const Stream.empty()
                  : context
                      .read<SupabaseService>()
                      .getAlumnosPorPadre(usuario.id),
              builder: (context, hijosSnap) {
                final gradoIds = <String>{
                  for (final h in hijosSnap.data ?? const <Alumno>[])
                    if (h.gradoId != null) h.gradoId!,
                };

                return StreamBuilder<List<Map<String, dynamic>>>(
                  stream: Supabase.instance.client
                      .from('eventos')
                      .stream(primaryKey: ['id'])
                      .order('fecha_evento'),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        !snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'No se pudieron cargar los eventos.\n${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(color: AppColors.rojo),
                          ),
                        ),
                      );
                    }

                    final raw = snapshot.data ?? [];
                    final eventos = <Evento>[];
                    for (final row in raw) {
                      try {
                        final e = Evento.fromJson(row);
                        if (!e.activo) continue;
                        if (!_visibleParaPadre(e, gradoIds)) continue;
                        if (_filtroTipo != 'Todos' && e.tipo != _filtroTipo) {
                          continue;
                        }
                        eventos.add(e);
                      } catch (_) {
                        // Fila incompleta: se omite
                      }
                    }

                    final proximos = eventos
                        .where((e) => _esHoyOFuturo(e.fechaEvento))
                        .toList()
                      ..sort(
                        (a, b) => a.fechaEvento.compareTo(b.fechaEvento),
                      );
                    final pasados = eventos
                        .where((e) => !_esHoyOFuturo(e.fechaEvento))
                        .toList()
                      ..sort(
                        (a, b) => b.fechaEvento.compareTo(a.fechaEvento),
                      );

                    if (proximos.isEmpty && pasados.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 80,
                              color: AppColors.gris.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _filtroTipo == 'Todos'
                                  ? 'No hay eventos'
                                  : 'No hay eventos de este tipo',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                color: AppColors.gris,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        if (proximos.isNotEmpty) ...[
                          _header('Próximos', proximos.length),
                          const SizedBox(height: 8),
                          ...proximos.map(_buildEventoCard),
                          const SizedBox(height: 20),
                        ],
                        if (pasados.isNotEmpty) ...[
                          _header('Anteriores', pasados.length),
                          const SizedBox(height: 8),
                          ...pasados.take(20).map(_buildEventoCard),
                        ],
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(String titulo, int n) {
    return Row(
      children: [
        Text(
          titulo,
          style: GoogleFonts.fredoka(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFE91E63),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFFE91E63),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$n',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFiltroChip(String tipo, IconData icon, {String? label}) {
    final isSelected = _filtroTipo == tipo;
    final displayLabel = label ?? tipo;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16),
            const SizedBox(width: 4),
            Text(displayLabel),
          ],
        ),
        selected: isSelected,
        onSelected: (_) => setState(() => _filtroTipo = tipo),
        selectedColor: const Color(0xFFEC407A),
        checkmarkColor: Colors.white,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
        ),
      ),
    );
  }

  Widget _buildEventoCard(Evento evento) {
    final ahora = _soloDia(MexicoTime.now());
    final fecha = _soloDia(evento.fechaEvento);
    final diasRestantes = fecha.difference(ahora).inDays;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.pink.shade100, width: 1),
      ),
      color: Colors.pink.shade50,
      child: InkWell(
        onTap: () => _mostrarDetalleEvento(context, evento),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 60,
                height: 70,
                decoration: BoxDecoration(
                  color: diasRestantes == 0
                      ? Colors.red
                      : const Color(0xFFE91E63),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      DateFormat('MMM', 'es').format(fecha).toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      fecha.day.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(evento.emoji, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            evento.titulo,
                            style: GoogleFonts.fredoka(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1A237E),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      evento.descripcion,
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.calendar_today,
                            size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          diasRestantes < 0
                              ? DateFormat('dd/MM/yyyy').format(fecha)
                              : diasRestantes == 0
                                  ? '¡HOY!'
                                  : diasRestantes == 1
                                      ? 'Mañana'
                                      : 'En $diasRestantes días',
                          style: TextStyle(
                            fontSize: 12,
                            color: diasRestantes == 0
                                ? Colors.red
                                : Colors.grey[600],
                            fontWeight: diasRestantes == 0
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        if (evento.horaInicio != null) ...[
                          const SizedBox(width: 16),
                          Icon(Icons.access_time,
                              size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            evento.horaInicio!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppColors.gris.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarDetalleEvento(BuildContext context, Evento evento) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text(evento.emoji),
            const SizedBox(width: 8),
            Expanded(
              child: Text(evento.titulo, style: GoogleFonts.fredoka()),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Fecha: ${DateFormat('dd/MM/yyyy').format(_soloDia(evento.fechaEvento))}',
                style: GoogleFonts.poppins(fontSize: 14),
              ),
              if (evento.horaInicio != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Hora: ${evento.horaInicio}${evento.horaFin != null ? ' - ${evento.horaFin}' : ''}',
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
              ],
              if (evento.lugar != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Lugar: ${evento.lugar}',
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                evento.descripcion,
                style: TextStyle(color: Colors.grey[700]),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}
