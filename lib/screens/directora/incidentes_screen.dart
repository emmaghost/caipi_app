import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

import '../../config/app_colors.dart';
import '../../widgets/app_drawer.dart';
import '../../models/incidente.dart';

class IncidentesScreen extends StatefulWidget {
  const IncidentesScreen({Key? key}) : super(key: key);

  @override
  State<IncidentesScreen> createState() => _IncidentesScreenState();
}

class _IncidentesScreenState extends State<IncidentesScreen> {
  int _filtroNivel = 0; // 0 = Todos, 1-5 = Niveles específicos
  String _busqueda = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grisClaro,
      drawer: const AppDrawer(),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.naranja, AppColors.rojo],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
        title: Text(
          'Incidentes',
          style: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.category),
            onPressed: () => context.push('/directora/tipos-incidentes'),
            tooltip: 'Tipos de Incidentes',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/directora/incidentes/crear'),
            tooltip: 'Crear incidente',
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
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _busqueda = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Buscar por alumno o título...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),

          // Filtros por nivel
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildNivelChip(0, 'Todos', '📋'),
                _buildNivelChip(1, 'Info', 'ℹ️'),
                _buildNivelChip(2, 'Leve', '⚠️'),
                _buildNivelChip(3, 'Moderado', '⚠️'),
                _buildNivelChip(4, 'Grave', '🚨'),
                _buildNivelChip(5, 'Urgente', '🆘'),
              ],
            ),
          ),

          // Lista de incidentes
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: Supabase.instance.client
                  .from('incidentes')
                  .stream(primaryKey: ['id'])
                  .order('fecha', ascending: false),
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

                var incidentesData = snapshot.data ?? [];

                // Aplicar filtros
                if (_filtroNivel > 0) {
                  incidentesData = incidentesData
                      .where((i) => i['nivel'] == _filtroNivel)
                      .toList();
                }

                if (_busqueda.isNotEmpty) {
                  incidentesData = incidentesData.where((i) {
                    final titulo = (i['titulo'] ?? '').toString().toLowerCase();
                    return titulo.contains(_busqueda);
                  }).toList();
                }

                if (incidentesData.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 80,
                          color: AppColors.verdeClaro,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _filtroNivel > 0 || _busqueda.isNotEmpty
                              ? 'No se encontraron incidentes'
                              : 'No hay incidentes registrados',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            color: AppColors.gris,
                          ),
                        ),
                        if (_filtroNivel == 0 && _busqueda.isEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            '¡Todo en orden! 🎉',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: AppColors.gris,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: incidentesData.length,
                  itemBuilder: (context, index) {
                    return _buildIncidenteCard(context, incidentesData[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNivelChip(int nivel, String label, String emoji) {
    final isSelected = _filtroNivel == nivel;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji),
            const SizedBox(width: 4),
            Text(label),
          ],
        ),
        selected: isSelected,
        onSelected: (_) {
          setState(() {
            _filtroNivel = nivel;
          });
        },
        selectedColor: _getColorNivel(nivel),
        checkmarkColor: Colors.white,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Color _getColorNivel(int nivel) {
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
        return AppColors.azulOscuro;
    }
  }

  Widget _buildIncidenteCard(BuildContext context, Map<String, dynamic> incidenteData) {
    final incidente = Incidente.fromJson(incidenteData);
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm', 'es_MX');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: incidente.nivel >= 4 ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: incidente.nivel >= 4
            ? BorderSide(color: _getColorNivel(incidente.nivel), width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () {
          // TODO: Navegar a detalle del incidente
          _mostrarDetalleIncidente(context, incidente);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  // Badge de nivel
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getColorNivel(incidente.nivel),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      incidente.emoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Título y nivel
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          incidente.titulo,
                          style: GoogleFonts.fredoka(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.azulOscuro,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getColorNivel(incidente.nivel).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'NIVEL ${incidente.nivel} - ${incidente.nivelLabel.toUpperCase()}',
                            style: TextStyle(
                              color: _getColorNivel(incidente.nivel),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Badges de estado
                  Column(
                    children: [
                      if (incidente.padreNotificado)
                        const Icon(Icons.notifications_active, color: Colors.orange, size: 20),
                      if (incidente.atendido)
                        const Icon(Icons.check_circle, color: Colors.green, size: 20),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Descripción
              Text(
                incidente.descripcion,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 12),

              // Footer
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    dateFormat.format(incidente.fecha),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // TODO: Mostrar nombre del alumno
                  Icon(Icons.person, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Alumno ID: ${incidente.alumnoId.substring(0, 8)}...',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarDetalleIncidente(BuildContext context, Incidente incidente) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text(incidente.emoji),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                incidente.titulo,
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
                'Nivel',
                '${incidente.nivel} - ${incidente.nivelLabel}',
                _getColorNivel(incidente.nivel),
              ),
              const Divider(),
              _buildDetalleItem(
                'Descripción',
                incidente.descripcion,
                Colors.black87,
              ),
              const Divider(),
              _buildDetalleItem(
                'Fecha',
                DateFormat('dd/MM/yyyy HH:mm', 'es_MX').format(incidente.fecha),
                Colors.black87,
              ),
              if (incidente.observaciones != null) ...[
                const Divider(),
                _buildDetalleItem(
                  'Observaciones',
                  incidente.observaciones!,
                  Colors.black87,
                ),
              ],
              const Divider(),
              Row(
                children: [
                  Icon(
                    incidente.atendido ? Icons.check_circle : Icons.pending,
                    color: incidente.atendido ? Colors.green : Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    incidente.atendido ? 'Atendido' : 'Pendiente',
                    style: TextStyle(
                      color: incidente.atendido ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (incidente.padreNotificado) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.notifications_active, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Padre notificado',
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        actions: [
          if (!incidente.atendido)
            TextButton(
              onPressed: () async {
                await _marcarComoAtendido(incidente.id);
                if (context.mounted) Navigator.of(context).pop();
              },
              child: const Text('Marcar como atendido'),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetalleItem(String label, String valor, Color color) {
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
        Text(
          valor,
          style: TextStyle(
            fontSize: 14,
            color: color,
          ),
        ),
      ],
    );
  }

  Future<void> _marcarComoAtendido(String incidenteId) async {
    try {
      await Supabase.instance.client
          .from('incidentes')
          .update({'atendido': true})
          .eq('id', incidenteId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Incidente marcado como atendido'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error marcando incidente: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
