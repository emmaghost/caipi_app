import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

import '../../config/app_colors.dart';
import '../../widgets/app_drawer.dart';
import '../../models/evento.dart';

class EventosPadreScreen extends StatefulWidget {
  const EventosPadreScreen({Key? key}) : super(key: key);

  @override
  State<EventosPadreScreen> createState() => _EventosPadreScreenState();
}

class _EventosPadreScreenState extends State<EventosPadreScreen> {
  String _filtroTipo = 'Todos';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grisClaro,
      drawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEC407A), // Rosa pastel (igual que Mis Hijos)
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Próximos Eventos',
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
          // Filtros por tipo
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
              ],
            ),
          ),

          // Lista de eventos
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: Supabase.instance.client
                  .from('eventos')
                  .stream(primaryKey: ['id'])
                  .order('fecha_evento'),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Error: ${snapshot.error}'),
                      ],
                    ),
                  );
                }

                final eventosData = snapshot.data ?? [];
                
                // Filtrar solo eventos futuros
                final ahora = DateTime.now();
                var eventosFuturos = eventosData.where((e) {
                  final fechaEvento = DateTime.parse(e['fecha_evento']);
                  return fechaEvento.isAfter(ahora) || _esMismoDia(fechaEvento, ahora);
                }).toList();

                // Aplicar filtro de tipo
                if (_filtroTipo != 'Todos') {
                  eventosFuturos = eventosFuturos
                      .where((e) => e['tipo'] == _filtroTipo)
                      .toList();
                }

                if (eventosFuturos.isEmpty) {
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
                              ? 'No hay eventos próximos'
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

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: eventosFuturos.length,
                  itemBuilder: (context, index) {
                    return _buildEventoCard(eventosFuturos[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  bool _esMismoDia(DateTime fecha1, DateTime fecha2) {
    return fecha1.year == fecha2.year &&
        fecha1.month == fecha2.month &&
        fecha1.day == fecha2.day;
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
        onSelected: (_) {
          setState(() {
            _filtroTipo = tipo;
          });
        },
        selectedColor: const Color(0xFFEC407A),
        checkmarkColor: Colors.white,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
        ),
      ),
    );
  }

  Widget _buildEventoCard(Map<String, dynamic> eventoData) {
    final evento = Evento.fromJson(eventoData);
    final dateFormat = DateFormat('dd/MM/yyyy', 'es_MX');
    final ahora = DateTime.now();
    final diasRestantes = evento.fechaEvento.difference(ahora).inDays;

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
              // Fecha en formato calendario (rosa pastel)
              Container(
                width: 60,
                height: 70,
                decoration: BoxDecoration(
                  color: diasRestantes == 0 ? Colors.red : const Color(0xFFE91E63),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.pink.shade300.withOpacity(0.4),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      DateFormat('MMM', 'es_MX').format(evento.fechaEvento).toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      evento.fechaEvento.day.toString(),
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

              // Información del evento
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          evento.emoji,
                          style: const TextStyle(fontSize: 20),
                        ),
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
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          diasRestantes == 0
                              ? '¡HOY!'
                              : diasRestantes == 1
                                  ? 'Mañana'
                                  : 'En $diasRestantes días',
                          style: TextStyle(
                            fontSize: 12,
                            color: diasRestantes == 0 ? Colors.red : Colors.grey[600],
                            fontWeight: diasRestantes == 0 ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        if (evento.horaInicio != null) ...[
                          const SizedBox(width: 16),
                          Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
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

              // Icono
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
              child: Text(
                evento.titulo,
                style: GoogleFonts.fredoka(),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetalleItem(
                '📅 Fecha',
                DateFormat('EEEE, d MMMM yyyy', 'es_MX').format(evento.fechaEvento),
              ),
              if (evento.horaInicio != null) ...[
                const SizedBox(height: 12),
                _buildDetalleItem(
                  '🕐 Hora',
                  '${evento.horaInicio}${evento.horaFin != null ? ' - ${evento.horaFin}' : ''}',
                ),
              ],
              if (evento.lugar != null) ...[
                const SizedBox(height: 12),
                _buildDetalleItem('📍 Lugar', evento.lugar!),
              ],
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),
              Text(
                'Descripción:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.morado,
                ),
              ),
              const SizedBox(height: 8),
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

  Widget _buildDetalleItem(String label, String valor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            valor,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}
