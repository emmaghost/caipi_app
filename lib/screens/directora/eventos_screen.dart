import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

import '../../config/app_colors.dart';
import '../../widgets/app_drawer.dart';
import '../../models/evento.dart';

class EventosScreen extends StatefulWidget {
  const EventosScreen({Key? key}) : super(key: key);

  @override
  State<EventosScreen> createState() => _EventosScreenState();
}

class _EventosScreenState extends State<EventosScreen> {
  String _filtroTipo = 'Todos';
  int _streamEpoch = 0;

  Future<void> _abrirCrearEvento() async {
    final ok = await context.push<bool>('/directora/eventos/crear');
    if (ok == true && mounted) setState(() => _streamEpoch++);
  }

  Future<void> _abrirEditarEvento(String id) async {
    final ok = await context.push<bool>('/directora/eventos/editar/$id');
    if (ok == true && mounted) setState(() => _streamEpoch++);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grisClaro,
      drawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: AppColors.morado,
        foregroundColor: Colors.white,
        title: Text(
          'Eventos',
          style: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _abrirCrearEvento,
            tooltip: 'Crear evento',
          ),
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => context.go('/directora'),
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
                _buildFiltroChip('otro', Icons.more_horiz, label: 'Otro'),
              ],
            ),
          ),

          // Lista de eventos
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              key: ValueKey(_streamEpoch),
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
                
                // Aplicar filtro
                var eventosFiltrados = eventosData;
                if (_filtroTipo != 'Todos') {
                  eventosFiltrados = eventosData
                      .where((e) => e['tipo'] == _filtroTipo)
                      .toList();
                }

                if (eventosFiltrados.isEmpty) {
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
                              ? 'No hay eventos registrados'
                              : 'No hay eventos de este tipo',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            color: AppColors.gris,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: _abrirCrearEvento,
                          icon: const Icon(Icons.add),
                          label: const Text('Crear primer evento'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.morado,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Separar eventos por estado
                final ahora = DateTime.now();
                final eventosProximos = <Map<String, dynamic>>[];
                final eventosPasados = <Map<String, dynamic>>[];

                for (final eventoData in eventosFiltrados) {
                  final fechaEvento = DateTime.parse(eventoData['fecha_evento']);
                  if (fechaEvento.isAfter(ahora) || _esMismoDia(fechaEvento, ahora)) {
                    eventosProximos.add(eventoData);
                  } else {
                    eventosPasados.add(eventoData);
                  }
                }

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (eventosProximos.isNotEmpty) ...[
                      _buildSeccionHeader('🔔 Próximos Eventos', eventosProximos.length),
                      const SizedBox(height: 8),
                      ...eventosProximos.map((e) => _buildEventoCard(context, e, false)),
                      const SizedBox(height: 24),
                    ],
                    if (eventosPasados.isNotEmpty) ...[
                      _buildSeccionHeader('📅 Eventos Pasados', eventosPasados.length),
                      const SizedBox(height: 8),
                      ...eventosPasados.map((e) => _buildEventoCard(context, e, true)),
                    ],
                  ],
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

  Widget _buildSeccionHeader(String titulo, int cantidad) {
    return Row(
      children: [
        Text(
          titulo,
          style: GoogleFonts.fredoka(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.morado,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.morado,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            cantidad.toString(),
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
        onSelected: (_) {
          setState(() {
            _filtroTipo = tipo;
          });
        },
        selectedColor: AppColors.morado,
        checkmarkColor: Colors.white,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
        ),
      ),
    );
  }

  Widget _buildEventoCard(BuildContext context, Map<String, dynamic> eventoData, bool pasado) {
    final evento = Evento.fromJson(eventoData);
    final dateFormat = DateFormat('dd/MM/yyyy', 'es_MX');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: pasado ? 1 : 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => _abrirEditarEvento(evento.id),
        borderRadius: BorderRadius.circular(16),
        child: Opacity(
          opacity: pasado ? 0.6 : 1.0,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fecha en formato calendario
                Container(
                  width: 60,
                  height: 70,
                  decoration: BoxDecoration(
                    color: pasado ? Colors.grey : AppColors.morado,
                    borderRadius: BorderRadius.circular(12),
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
                                color: AppColors.morado,
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
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          if (evento.horaInicio != null)
                            _buildChip(
                              '🕐 ${evento.horaInicio}',
                              AppColors.verdeClaro,
                            ),
                          if (evento.lugar != null)
                            _buildChip(
                              '📍 ${evento.lugar}',
                              AppColors.morado,
                            ),
                          if (evento.paraTodos)
                            _buildChip(
                              '👨‍👩‍👧 Todos',
                              AppColors.rosaClaro,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Icono de ir
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppColors.gris.withOpacity(0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
