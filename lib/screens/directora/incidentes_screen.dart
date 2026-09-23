import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

import '../../config/app_colors.dart';
import '../../widgets/app_drawer.dart';
import '../../models/incidente.dart';
import '../../widgets/caipi_app_bar_leading.dart';

/// Filtro: todas / nuevas (no leídas) / pasadas (leídas).
enum _FiltroEstadoIncidente { todas, nuevas, pasadas }

class IncidentesScreen extends StatefulWidget {
  const IncidentesScreen({Key? key}) : super(key: key);

  @override
  State<IncidentesScreen> createState() => _IncidentesScreenState();
}

class _IncidentesScreenState extends State<IncidentesScreen> {
  int _filtroNivel = 0; // 0 = Todos, 1-5 = Niveles específicos
  _FiltroEstadoIncidente _filtroEstado = _FiltroEstadoIncidente.todas;
  String _busqueda = '';
  final Map<String, String> _nombresAlumno = {};

  @override
  void initState() {
    super.initState();
    _cargarNombresAlumnos();
  }

  Future<void> _cargarNombresAlumnos() async {
    try {
      final rows = await Supabase.instance.client
          .from('alumnos')
          .select('id, nombre, apellidos');
      if (!mounted) return;
      setState(() {
        for (final r in rows as List) {
          final id = r['id'] as String?;
          if (id == null) continue;
          final n = '${r['nombre'] ?? ''} ${r['apellidos'] ?? ''}'.trim();
          _nombresAlumno[id] = n.isEmpty ? 'Alumno' : n;
        }
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grisClaro,
      drawer: const AppDrawer(),
      appBar: AppBar(
        leading: const CaipiAppBarLeading(),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              onChanged: (value) {
                setState(() => _busqueda = value.toLowerCase());
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

          // Nuevas / Pasadas / Todas
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: SegmentedButton<_FiltroEstadoIncidente>(
                    segments: const [
                      ButtonSegment(
                        value: _FiltroEstadoIncidente.todas,
                        label: Text('Todas'),
                        icon: Icon(Icons.list, size: 16),
                      ),
                      ButtonSegment(
                        value: _FiltroEstadoIncidente.nuevas,
                        label: Text('Nuevas'),
                        icon: Icon(Icons.mark_email_unread, size: 16),
                      ),
                      ButtonSegment(
                        value: _FiltroEstadoIncidente.pasadas,
                        label: Text('Pasadas'),
                        icon: Icon(Icons.mark_email_read, size: 16),
                      ),
                    ],
                    selected: {_filtroEstado},
                    onSelectionChanged: (s) {
                      setState(() => _filtroEstado = s.first);
                    },
                    style: ButtonStyle(
                      visualDensity: VisualDensity.compact,
                      textStyle: WidgetStatePropertyAll(
                        GoogleFonts.poppins(fontSize: 12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Filtros por nivel
          Container(
            height: 56,
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
                        const Icon(Icons.error_outline,
                            size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Error: ${snapshot.error}'),
                      ],
                    ),
                  );
                }

                var incidentesData = snapshot.data ?? [];

                if (_filtroNivel > 0) {
                  incidentesData = incidentesData
                      .where((i) => i['nivel'] == _filtroNivel)
                      .toList();
                }

                if (_filtroEstado == _FiltroEstadoIncidente.nuevas) {
                  incidentesData = incidentesData
                      .where((i) => i['leido_padre'] != true)
                      .toList();
                } else if (_filtroEstado == _FiltroEstadoIncidente.pasadas) {
                  incidentesData = incidentesData
                      .where((i) => i['leido_padre'] == true)
                      .toList();
                }

                if (_busqueda.isNotEmpty) {
                  incidentesData = incidentesData.where((i) {
                    final titulo =
                        (i['titulo'] ?? '').toString().toLowerCase();
                    final alumnoId = i['alumno_id']?.toString() ?? '';
                    final nombre =
                        (_nombresAlumno[alumnoId] ?? '').toLowerCase();
                    return titulo.contains(_busqueda) ||
                        nombre.contains(_busqueda);
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
                          'No se encontraron incidentes',
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
        onSelected: (_) => setState(() => _filtroNivel = nivel),
        selectedColor: AppColors.naranja.withValues(alpha: 0.25),
      ),
    );
  }

  Widget _buildIncidenteCard(
      BuildContext context, Map<String, dynamic> incidenteData) {
    final incidente = Incidente.fromJson(incidenteData);
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm', 'es_MX');
    final nombreAlumno =
        _nombresAlumno[incidente.alumnoId] ?? 'Alumno';
    final esNueva = incidente.esNueva;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: esNueva ? 4 : 1,
      color: esNueva ? const Color(0xFFFFF7ED) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: esNueva
              ? const Color(0xFFFDBA74)
              : (incidente.nivel >= 4
                  ? _getColorNivel(incidente.nivel)
                  : Colors.transparent),
          width: esNueva || incidente.nivel >= 4 ? 2 : 0,
        ),
      ),
      child: InkWell(
        onTap: () => _mostrarDetalleIncidente(context, incidente),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (esNueva) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'NUEVA',
                                  style: GoogleFonts.poppins(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                            Expanded(
                              child: Text(
                                incidente.titulo,
                                style: GoogleFonts.fredoka(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.azulOscuro,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          nombreAlumno,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getColorNivel(incidente.nivel)
                                .withValues(alpha: 0.2),
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
                  Column(
                    children: [
                      Icon(
                        esNueva
                            ? Icons.mark_email_unread
                            : Icons.mark_email_read,
                        color: esNueva ? Colors.orange : Colors.green,
                        size: 20,
                      ),
                      if (incidente.atendido)
                        const Icon(Icons.check_circle,
                            color: Colors.green, size: 20),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                incidente.descripcion,
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    dateFormat.format(incidente.fecha),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
    final nombreAlumno = _nombresAlumno[incidente.alumnoId] ?? 'Alumno';

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Row(
          children: [
            Text(incidente.emoji),
            const SizedBox(width: 8),
            Expanded(
              child: Text(incidente.titulo, style: GoogleFonts.fredoka()),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetalleItem('Alumno', nombreAlumno, Colors.black87),
              const Divider(),
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
              Text(
                incidente.leidoPadre
                    ? 'Estado: leída por el papá'
                    : 'Estado: no leída (nueva)',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: incidente.leidoPadre ? Colors.green : Colors.orange,
                ),
              ),
            ],
          ),
        ),
        actionsAlignment: MainAxisAlignment.start,
        actions: [
          if (!incidente.atendido)
            TextButton(
              onPressed: () async {
                await _marcarComoAtendido(incidente.id);
                if (dialogCtx.mounted) Navigator.of(dialogCtx).pop();
              },
              child: const Text('Atendido'),
            ),
          TextButton(
            onPressed: () async {
              await _setLeidoPadre(incidente.id, !incidente.leidoPadre);
              if (dialogCtx.mounted) Navigator.of(dialogCtx).pop();
            },
            child: Text(
              incidente.leidoPadre ? 'Marcar no leída' : 'Marcar leída',
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              final ok = await _confirmarBorrar(dialogCtx);
              if (ok != true) return;
              await _borrarIncidente(incidente.id);
              if (dialogCtx.mounted) Navigator.of(dialogCtx).pop();
            },
            child: const Text('Eliminar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _confirmarBorrar(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar incidente'),
        content: const Text(
          '¿Seguro que quieres borrar este incidente? No se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
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
        Text(valor, style: TextStyle(fontSize: 14, color: color)),
      ],
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
        return Colors.grey;
    }
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
            content: Text('Incidente marcado como atendido'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _setLeidoPadre(String incidenteId, bool leido) async {
    try {
      await Supabase.instance.client
          .from('incidentes')
          .update({'leido_padre': leido})
          .eq('id', incidenteId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(leido ? 'Marcada como leída' : 'Marcada como no leída'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _borrarIncidente(String incidenteId) async {
    try {
      await Supabase.instance.client
          .from('incidentes')
          .delete()
          .eq('id', incidenteId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Incidente eliminado'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al borrar: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
