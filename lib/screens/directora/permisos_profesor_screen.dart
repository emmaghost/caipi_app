import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/permisos_service.dart';
import '../../models/permiso.dart';
import '../../models/usuario.dart';
import '../../config/app_colors.dart';
import '../../widgets/app_drawer.dart';

class PermisosProfesorScreen extends StatefulWidget {
  final String usuarioId;
  final String nombreProfesor;

  const PermisosProfesorScreen({
    Key? key,
    required this.usuarioId,
    required this.nombreProfesor,
  }) : super(key: key);

  @override
  State<PermisosProfesorScreen> createState() => _PermisosProfesorScreenState();
}

class _PermisosProfesorScreenState extends State<PermisosProfesorScreen> {
  final _permisosService = PermisosService();
  List<Permiso> _todosLosPermisos = [];
  List<Permiso> _permisosActuales = [];
  bool _cargando = true;
  String _filtroModulo = 'Todos';

  @override
  void initState() {
    super.initState();
    _cargarPermisos();
  }

  Future<void> _cargarPermisos() async {
    setState(() => _cargando = true);

    final todos = await _permisosService.obtenerTodosLosPermisos();
    final actuales = await _permisosService.obtenerPermisosAdicionalesDeUsuario(widget.usuarioId);

    setState(() {
      _todosLosPermisos = todos;
      _permisosActuales = actuales;
      _cargando = false;
    });
  }

  bool _tienePermiso(String codigo) {
    return _permisosActuales.any((p) => p.codigo == codigo);
  }

  Future<void> _togglePermiso(Permiso permiso) async {
    final tiene = _tienePermiso(permiso.codigo);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          tiene ? 'Revocando permiso...' : 'Otorgando permiso...',
        ),
        duration: const Duration(seconds: 1),
      ),
    );

    final exito = tiene
        ? await _permisosService.revocarPermisoDeUsuario(
            usuarioId: widget.usuarioId,
            permisoId: permiso.id,
          )
        : await _permisosService.otorgarPermisoAUsuario(
            usuarioId: widget.usuarioId,
            permisoId: permiso.id,
          );

    if (exito) {
      await _cargarPermisos();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tiene
                  ? '✅ Permiso revocado correctamente'
                  : '✅ Permiso otorgado correctamente',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Error al actualizar permiso'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grisClaro,
      drawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: AppColors.azulOscuro,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gestionar Permisos',
              style: TextStyle(fontSize: 18),
            ),
            Text(
              widget.nombreProfesor,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => context.go('/directora'),
            tooltip: 'Ir al inicio',
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Header con resumen
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.azulOscuro,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatCard(
                        'Total Permisos',
                        _todosLosPermisos.length.toString(),
                        Icons.key,
                        Colors.white,
                      ),
                      _buildStatCard(
                        'Permisos Otorgados',
                        _permisosActuales.length.toString(),
                        Icons.check_circle,
                        AppColors.verdeClaro,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Filtros por módulo
                SizedBox(
                  height: 50,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _buildFiltroChip('Todos'),
                      ..._obtenerModulosUnicos().map((m) => _buildFiltroChip(m)),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Lista de permisos
                Expanded(
                  child: _buildListaPermisos(),
                ),
              ],
            ),
    );
  }

  Widget _buildStatCard(String titulo, String valor, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          valor,
          style: GoogleFonts.fredoka(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          titulo,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildFiltroChip(String modulo) {
    final isSelected = _filtroModulo == modulo;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(modulo),
        selected: isSelected,
        onSelected: (_) {
          setState(() {
            _filtroModulo = modulo;
          });
        },
        selectedColor: AppColors.azulOscuro,
        checkmarkColor: Colors.white,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
        ),
      ),
    );
  }

  List<String> _obtenerModulosUnicos() {
    final modulos = _todosLosPermisos.map((p) => p.modulo).toSet().toList();
    modulos.sort();
    return modulos;
  }

  List<Permiso> _obtenerPermisosFiltrados() {
    if (_filtroModulo == 'Todos') {
      return _todosLosPermisos;
    }
    return _todosLosPermisos.where((p) => p.modulo == _filtroModulo).toList();
  }

  Widget _buildListaPermisos() {
    final permisosFiltrados = _obtenerPermisosFiltrados();

    if (permisosFiltrados.isEmpty) {
      return const Center(
        child: Text('No hay permisos disponibles'),
      );
    }

    // Agrupar por módulo
    final permisosPorModulo = <String, List<Permiso>>{};
    for (final permiso in permisosFiltrados) {
      permisosPorModulo.putIfAbsent(permiso.modulo, () => []).add(permiso);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: permisosPorModulo.entries.map((entry) {
        return _buildModuloSection(entry.key, entry.value);
      }).toList(),
    );
  }

  Widget _buildModuloSection(String modulo, List<Permiso> permisos) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header del módulo
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.azulOscuro.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Text(
                  permisos.first.icono,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  modulo.toUpperCase(),
                  style: GoogleFonts.fredoka(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.azulOscuro,
                  ),
                ),
                const Spacer(),
                Text(
                  '${permisos.where((p) => _tienePermiso(p.codigo)).length}/${permisos.length}',
                  style: TextStyle(
                    color: AppColors.azulOscuro.withOpacity(0.7),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Lista de permisos del módulo
          ...permisos.map((permiso) => _buildPermisoTile(permiso)),
        ],
      ),
    );
  }

  Widget _buildPermisoTile(Permiso permiso) {
    final tiene = _tienePermiso(permiso.codigo);

    return CheckboxListTile(
      value: tiene,
      onChanged: (_) => _togglePermiso(permiso),
      title: Text(
        permiso.nombre,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (permiso.descripcion != null)
            Text(
              permiso.descripcion!,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: _getColorTipo(permiso.tipo),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  permiso.tipo.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      activeColor: AppColors.verdeClaro,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
    );
  }

  Color _getColorTipo(String tipo) {
    switch (tipo) {
      case 'lectura':
        return Colors.green;
      case 'escritura':
        return Colors.blue;
      case 'eliminacion':
        return Colors.red;
      case 'especial':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
