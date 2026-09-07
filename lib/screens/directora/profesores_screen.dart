import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/app_colors.dart';
import '../../services/profesor_grupos_service.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/caipi_app_bar_leading.dart';

class ProfesoresScreen extends StatefulWidget {
  const ProfesoresScreen({super.key});

  @override
  State<ProfesoresScreen> createState() => _ProfesoresScreenState();
}

class _StaffRow {
  final String editId; // profesor uuid OR "usuario:<id>"
  final String? usuarioId;
  final String nombre;
  final String? email;
  final String rol;
  final String? especialidad;
  final bool activo;
  final List<String> gradoNombres;

  _StaffRow({
    required this.editId,
    required this.usuarioId,
    required this.nombre,
    required this.email,
    required this.rol,
    this.especialidad,
    required this.activo,
    required this.gradoNombres,
  });
}

class _ProfesoresScreenState extends State<ProfesoresScreen> {
  late Future<List<_StaffRow>> _future;
  final _grupos = ProfesorGruposService();
  /// todos | activos
  String _filtro = 'activos';

  @override
  void initState() {
    super.initState();
    _future = _cargar();
  }

  Future<void> _refrescar() async {
    final f = _cargar();
    setState(() => _future = f);
    await f;
  }

  Future<List<_StaffRow>> _cargar() async {
    final client = Supabase.instance.client;
    final gradosRaw =
        await client.from('grados').select('id, nombre').eq('activo', true);
    final gradoNombre = {
      for (final g in gradosRaw as List)
        g['id'] as String: g['nombre'] as String? ?? '',
    };

    // Mapa profesor_id / grado por usuario_id
    final profByUsuario = <String, Map<String, dynamic>>{};
    try {
      final profesores =
          await client.from('profesores').select('id, usuario_id, grado_id, especialidad, activo');
      for (final p in profesores as List) {
        final map = Map<String, dynamic>.from(p as Map);
        final uid = map['usuario_id'] as String?;
        if (uid != null) profByUsuario[uid] = map;
      }
    } catch (_) {}

    // Fuente de verdad: todos los perfiles de escuela (no padres).
    const rolesStaff = [
      'profesor',
      'profesor_admin',
      'caja',
      'secretaria',
    ];
    List<dynamic> staffUsuarios = [];
    try {
      staffUsuarios = await client
          .from('usuarios')
          .select()
          .inFilter('rol', rolesStaff);
    } catch (_) {
      // Si RLS bloquea usuarios, al menos mostrar docentes con fila en profesores.
      staffUsuarios = [
        for (final entry in profByUsuario.entries)
          {
            'id': entry.key,
            'nombre': 'Docente',
            'email': null,
            'rol': 'profesor',
            'activo': entry.value['activo'] ?? true,
          },
      ];
    }

    final rows = <_StaffRow>[];
    for (final u in staffUsuarios) {
      final map = Map<String, dynamic>.from(u as Map);
      final id = map['id'] as String;
      final rol = map['rol'] as String? ?? '';
      final prof = profByUsuario[id];

      List<String> gradoNombres = const [];
      String? especialidad;
      String editId = 'usuario:$id';

      if (prof != null) {
        final profesorId = prof['id'] as String;
        editId = profesorId;
        especialidad = prof['especialidad'] as String?;
        final gradoIds = await _grupos.gradoIdsDeProfesorRow(profesorId);
        if (gradoIds.isEmpty && prof['grado_id'] != null) {
          gradoIds.add(prof['grado_id'] as String);
        }
        gradoNombres = [
          for (final gid in gradoIds) gradoNombre[gid] ?? 'Grupo',
        ];
      }

      rows.add(_StaffRow(
        editId: editId,
        usuarioId: id,
        nombre: map['nombre'] as String? ?? 'Sin nombre',
        email: map['email'] as String?,
        rol: rol,
        especialidad: especialidad,
        activo: map['activo'] as bool? ?? true,
        gradoNombres: gradoNombres,
      ));
    }

    rows.sort((a, b) {
      final aa = a.activo ? 0 : 1;
      final bb = b.activo ? 0 : 1;
      if (aa != bb) return aa.compareTo(bb);
      return a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase());
    });
    return rows;
  }

  Future<void> _abrirCrear() async {
    final ok = await context.push<bool>('/directora/profesores/crear');
    if (ok == true && mounted) await _refrescar();
  }

  Future<void> _abrirEditar(String editId) async {
    final ok = await context.push<bool>(
      '/directora/profesores/editar/${Uri.encodeComponent(editId)}',
    );
    if (ok == true && mounted) await _refrescar();
  }

  Future<void> _quitarAcceso(_StaffRow row) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Quitar acceso?'),
        content: Text(
          'Se desactivará a ${row.nombre}.\n'
          'El correo se modifica con “_” para poder reutilizarlo.\n'
          'No se borra el historial.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.rojo),
            child: const Text('Quitar acceso'),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;

    try {
      final uid = row.usuarioId;
      if (uid == null) throw Exception('Sin usuario vinculado');

      try {
        await Supabase.instance.client.rpc(
          'desactivar_usuario_escuela',
          params: {'p_usuario_id': uid},
        );
      } catch (_) {
        final email = row.email ?? '';
        final parts = email.split('@');
        final nuevo = parts.length == 2
            ? '${parts[0]}_x${DateTime.now().millisecondsSinceEpoch}@${parts[1]}'
            : '${email}_x';
        await Supabase.instance.client.from('usuarios').update({
          'activo': false,
          'email': nuevo,
        }).eq('id', uid);
        await Supabase.instance.client
            .from('profesores')
            .update({'activo': false})
            .eq('usuario_id', uid);
      }

      if (!mounted) return;
      await _refrescar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Acceso desactivado'),
          backgroundColor: AppColors.verde,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo desactivar: $e'),
          backgroundColor: AppColors.rojo,
        ),
      );
    }
  }

  String _rolLabel(_StaffRow r) {
    switch (r.rol) {
      case 'caja':
        return 'Caja / Pagos';
      case 'secretaria':
        return 'Secretaria';
      case 'profesor_admin':
        return 'Docente admin';
      default:
        final esp = (r.especialidad ?? '').toLowerCase();
        if (esp.contains('ingles')) return 'Inglés';
        if (esp.contains('musica')) return 'Música';
        return 'Docente';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grisClaro,
      drawer: const AppDrawer(),
      appBar: AppBar(
        leading: const CaipiAppBarLeading(),
        title: Text(
          'Personal',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refrescar,
            tooltip: 'Actualizar',
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
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Todos'),
                  selected: _filtro == 'todos',
                  onSelected: (_) => setState(() => _filtro = 'todos'),
                  selectedColor: AppColors.purpura.withValues(alpha: 0.25),
                  checkmarkColor: AppColors.purpura,
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Solo activos'),
                  selected: _filtro == 'activos',
                  onSelected: (_) => setState(() => _filtro = 'activos'),
                  selectedColor: AppColors.purpura.withValues(alpha: 0.25),
                  checkmarkColor: AppColors.purpura,
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<_StaffRow>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                var lista = snapshot.data ?? [];
                if (_filtro == 'activos') {
                  lista = lista.where((r) => r.activo).toList();
                }
                if (lista.isEmpty) {
                  return Center(
                    child: Text(
                      _filtro == 'activos'
                          ? 'No hay personal activo.'
                          : 'No hay personal. Presiona + para agregar.',
                      style: GoogleFonts.poppins(color: AppColors.gris),
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: _refrescar,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: lista.length,
                    itemBuilder: (context, i) {
                      final row = lista[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          onTap: () => _abrirEditar(row.editId),
                          leading: CircleAvatar(
                            backgroundColor:
                                row.activo ? AppColors.purpura : AppColors.gris,
                            child: Icon(
                              row.rol == 'caja'
                                  ? Icons.point_of_sale
                                  : row.rol == 'secretaria'
                                      ? Icons.badge_outlined
                                      : Icons.person,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(
                            row.nombre,
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            [
                              _rolLabel(row),
                              if (row.gradoNombres.isNotEmpty)
                                row.gradoNombres.join(', '),
                              if (row.email != null) row.email!,
                              if (!row.activo) 'SIN ACCESO',
                            ].join(' · '),
                            style: GoogleFonts.poppins(fontSize: 12),
                          ),
                          trailing: row.activo
                              ? IconButton(
                                  icon: const Icon(Icons.person_off_outlined,
                                      color: AppColors.rojo),
                                  tooltip: 'Quitar acceso',
                                  onPressed: () => _quitarAcceso(row),
                                )
                              : null,
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirCrear,
        heroTag: 'crear_profesor',
        backgroundColor: AppColors.purpura,
        icon: const Icon(Icons.person_add),
        label: const Text('Agregar'),
      ),
    );
  }
}
