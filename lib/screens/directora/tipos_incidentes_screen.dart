import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/app_colors.dart';
import '../../widgets/app_drawer.dart';
import '../../models/tipo_incidente.dart';

class TiposIncidentesScreen extends StatelessWidget {
  const TiposIncidentesScreen({Key? key}) : super(key: key);

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
          'Catálogo de Incidentes',
          style: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _mostrarDialogoCrearTipo(context);
            },
            tooltip: 'Agregar tipo',
          ),
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => context.go('/directora'),
            tooltip: 'Ir al inicio',
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: Supabase.instance.client
            .from('tipos_incidentes')
            .stream(primaryKey: ['id'])
            .order('nivel')
            .order('nombre'),
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

          final tiposData = snapshot.data ?? [];

          if (tiposData.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.category_outlined,
                    size: 80,
                    color: AppColors.gris.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay tipos de incidentes',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      color: AppColors.gris,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => _mostrarDialogoCrearTipo(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Crear primer tipo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.azulOscuro,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          }

          // Agrupar por nivel
          final tiposPorNivel = <int, List<Map<String, dynamic>>>{};
          for (final tipoData in tiposData) {
            final nivel = tipoData['nivel'] as int;
            tiposPorNivel.putIfAbsent(nivel, () => []).add(tipoData);
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Resumen de niveles
              _buildResumenCard(tiposData.length, tiposPorNivel),
              const SizedBox(height: 16),

              // Lista agrupada por nivel
              ...tiposPorNivel.entries.map((entry) {
                return _buildNivelSection(context, entry.key, entry.value);
              }).toList(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildResumenCard(int total, Map<int, List<Map<String, dynamic>>> tiposPorNivel) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'Total de Tipos',
              style: GoogleFonts.fredoka(
                fontSize: 16,
                color: AppColors.gris,
              ),
            ),
            Text(
              total.toString(),
              style: GoogleFonts.fredoka(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: AppColors.azulOscuro,
              ),
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNivelStat(1, tiposPorNivel[1]?.length ?? 0),
                _buildNivelStat(2, tiposPorNivel[2]?.length ?? 0),
                _buildNivelStat(3, tiposPorNivel[3]?.length ?? 0),
                _buildNivelStat(4, tiposPorNivel[4]?.length ?? 0),
                _buildNivelStat(5, tiposPorNivel[5]?.length ?? 0),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNivelStat(int nivel, int cantidad) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _getColorNivel(nivel),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              nivel.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          cantidad.toString(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildNivelSection(BuildContext context, int nivel, List<Map<String, dynamic>> tipos) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header del nivel
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getColorNivel(nivel).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getColorNivel(nivel),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getEmojiNivel(nivel),
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NIVEL $nivel - ${_getLabelNivel(nivel).toUpperCase()}',
                        style: GoogleFonts.fredoka(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _getColorNivel(nivel),
                        ),
                      ),
                      if (nivel >= 4)
                        Text(
                          '🔔 Notifica al padre',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  '${tipos.length} tipos',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          // Lista de tipos de este nivel
          ...tipos.map((tipoData) {
            final tipo = TipoIncidente.fromJson(tipoData);
            return ListTile(
              leading: Text(
                tipo.categoriaEmoji,
                style: const TextStyle(fontSize: 24),
              ),
              title: Text(
                tipo.nombre,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tipo.categoria),
                  if (tipo.descripcion != null)
                    Text(
                      tipo.descripcion!,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Switch(
                    value: tipo.activo,
                    onChanged: (value) => _toggleActivo(tipo.id, value),
                    activeColor: AppColors.verdeClaro,
                  ),
                  const Icon(Icons.edit, size: 18),
                ],
              ),
              onTap: () {
                // TODO: Editar tipo
                _mostrarDialogoEditarTipo(context, tipo);
              },
            );
          }).toList(),
        ],
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
        return Colors.grey;
    }
  }

  String _getEmojiNivel(int nivel) {
    switch (nivel) {
      case 1:
        return 'ℹ️';
      case 2:
        return '⚠️';
      case 3:
        return '⚠️';
      case 4:
        return '🚨';
      case 5:
        return '🆘';
      default:
        return '📝';
    }
  }

  String _getLabelNivel(int nivel) {
    switch (nivel) {
      case 1:
        return 'Info';
      case 2:
        return 'Leve';
      case 3:
        return 'Moderado';
      case 4:
        return 'Grave';
      case 5:
        return 'Urgente';
      default:
        return 'Desconocido';
    }
  }

  Future<void> _toggleActivo(String tipoId, bool activo) async {
    try {
      await Supabase.instance.client
          .from('tipos_incidentes')
          .update({'activo': activo})
          .eq('id', tipoId);
    } catch (e) {
      print('Error cambiando estado: $e');
    }
  }

  void _mostrarDialogoCrearTipo(BuildContext context) {
    final TextEditingController nombreController = TextEditingController();
    final TextEditingController descripcionController = TextEditingController();
    int nivelSeleccionado = 1;
    String categoriaSeleccionada = 'Comportamiento';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.naranja, AppColors.rojo],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.add, color: Colors.white),
              ),
              const SizedBox(width: 12),
              const Text('Nuevo Tipo de Incidente'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre *',
                    hintText: 'Ej: Olvidó material',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descripcionController,
                  decoration: const InputDecoration(
                    labelText: 'Descripción (opcional)',
                    hintText: 'Descripción del incidente',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: categoriaSeleccionada,
                  decoration: const InputDecoration(
                    labelText: 'Categoría',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Comportamiento', child: Text('📚 Comportamiento')),
                    DropdownMenuItem(value: 'Académico', child: Text('✏️ Académico')),
                    DropdownMenuItem(value: 'Salud', child: Text('🏥 Salud')),
                    DropdownMenuItem(value: 'Seguridad', child: Text('🛡️ Seguridad')),
                    DropdownMenuItem(value: 'Social', child: Text('👥 Social')),
                    DropdownMenuItem(value: 'Otro', child: Text('📌 Otro')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      categoriaSeleccionada = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                Text('Nivel de gravedad', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                ...List.generate(5, (index) {
                  final nivel = index + 1;
                  return RadioListTile<int>(
                    value: nivel,
                    groupValue: nivelSeleccionado,
                    onChanged: (value) {
                      setState(() {
                        nivelSeleccionado = value!;
                      });
                    },
                    title: Text('Nivel $nivel - ${_getLabelNivel(nivel)}'),
                    subtitle: nivel >= 4 ? const Text('🔔 Notifica al padre', style: TextStyle(fontSize: 11)) : null,
                    activeColor: _getColorNivel(nivel),
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nombreController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('❌ El nombre es obligatorio')),
                  );
                  return;
                }

                try {
                  await Supabase.instance.client.from('tipos_incidentes').insert({
                    'nombre': nombreController.text.trim(),
                    'descripcion': descripcionController.text.trim().isEmpty ? null : descripcionController.text.trim(),
                    'categoria': categoriaSeleccionada,
                    'nivel': nivelSeleccionado,
                    'activo': true,
                  });

                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ Tipo de incidente creado'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('❌ Error: $e')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.naranja,
                foregroundColor: Colors.white,
              ),
              child: const Text('Crear'),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarDialogoEditarTipo(BuildContext context, TipoIncidente tipo) {
    final TextEditingController nombreController = TextEditingController(text: tipo.nombre);
    final TextEditingController descripcionController = TextEditingController(text: tipo.descripcion ?? '');
    int nivelSeleccionado = tipo.nivel;
    String categoriaSeleccionada = tipo.categoria;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.naranja, AppColors.rojo],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.edit, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text('Editar: ${tipo.nombre}', style: const TextStyle(fontSize: 16))),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre *',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descripcionController,
                  decoration: const InputDecoration(
                    labelText: 'Descripción (opcional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: categoriaSeleccionada,
                  decoration: const InputDecoration(
                    labelText: 'Categoría',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Comportamiento', child: Text('📚 Comportamiento')),
                    DropdownMenuItem(value: 'Académico', child: Text('✏️ Académico')),
                    DropdownMenuItem(value: 'Salud', child: Text('🏥 Salud')),
                    DropdownMenuItem(value: 'Seguridad', child: Text('🛡️ Seguridad')),
                    DropdownMenuItem(value: 'Social', child: Text('👥 Social')),
                    DropdownMenuItem(value: 'Otro', child: Text('📌 Otro')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      categoriaSeleccionada = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                Text('Nivel de gravedad', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                ...List.generate(5, (index) {
                  final nivel = index + 1;
                  return RadioListTile<int>(
                    value: nivel,
                    groupValue: nivelSeleccionado,
                    onChanged: (value) {
                      setState(() {
                        nivelSeleccionado = value!;
                      });
                    },
                    title: Text('Nivel $nivel - ${_getLabelNivel(nivel)}'),
                    subtitle: nivel >= 4 ? const Text('🔔 Notifica al padre', style: TextStyle(fontSize: 11)) : null,
                    activeColor: _getColorNivel(nivel),
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nombreController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('❌ El nombre es obligatorio')),
                  );
                  return;
                }

                try {
                  await Supabase.instance.client
                      .from('tipos_incidentes')
                      .update({
                        'nombre': nombreController.text.trim(),
                        'descripcion': descripcionController.text.trim().isEmpty ? null : descripcionController.text.trim(),
                        'categoria': categoriaSeleccionada,
                        'nivel': nivelSeleccionado,
                      })
                      .eq('id', tipo.id);

                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ Tipo de incidente actualizado'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('❌ Error: $e')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.naranja,
                foregroundColor: Colors.white,
              ),
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
