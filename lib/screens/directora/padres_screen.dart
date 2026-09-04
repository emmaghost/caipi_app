import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/app_colors.dart';
import '../../models/grado.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../widgets/app_drawer.dart';

class PadresScreen extends StatefulWidget {
  const PadresScreen({super.key});

  @override
  State<PadresScreen> createState() => _PadresScreenState();
}

class _PadresScreenState extends State<PadresScreen> {
  late Future<_PadresData> _padresFuture;
  String _filtroGrado = 'Todos';
  String _busqueda = '';

  @override
  void initState() {
    super.initState();
    _padresFuture = _cargarDatos();
  }

  Future<_PadresData> _cargarDatos() async {
    final client = Supabase.instance.client;

    final padresRaw = await client.from('usuarios').select().eq('rol', 'padre');
    final padres = List<Map<String, dynamic>>.from(padresRaw as List);
    padres.sort((a, b) {
      final aActivo = a['activo'] == true ? 0 : 1;
      final bActivo = b['activo'] == true ? 0 : 1;
      if (aActivo != bActivo) return aActivo.compareTo(bActivo);
      return ((a['nombre'] as String?) ?? '')
          .compareTo((b['nombre'] as String?) ?? '');
    });

    final gradosRaw =
        await client.from('grados').select().eq('activo', true).order('nombre');
    final grados = (gradosRaw as List)
        .map((e) => Grado.fromJson(Map<String, dynamic>.from(e as Map)))
        .where((g) => !g.esEstimulacion)
        .toList();

    final alumnosRaw = await client
        .from('alumnos')
        .select('id, padre_id, grado_id')
        .eq('activo', true);
    final alumnos = List<Map<String, dynamic>>.from(alumnosRaw as List);

    final padreAGrados = <String, Set<String>>{};
    final padreAHijos = <String, int>{};
    final alumnoIds = <String>[];

    for (final a in alumnos) {
      final alumnoId = a['id'] as String?;
      final padreId = a['padre_id'] as String?;
      final gradoId = a['grado_id'] as String?;
      if (alumnoId != null) alumnoIds.add(alumnoId);
      if (padreId == null) continue;
      padreAHijos[padreId] = (padreAHijos[padreId] ?? 0) + 1;
      if (gradoId != null) {
        padreAGrados.putIfAbsent(padreId, () => <String>{}).add(gradoId);
      }
    }

    if (alumnoIds.isNotEmpty) {
      try {
        final vinculos = await client
            .from('alumnos_padres')
            .select('padre_id, alumno_id')
            .inFilter('alumno_id', alumnoIds);
        final alumnoPorId = {
          for (final a in alumnos) a['id'] as String: a,
        };
        for (final v in vinculos as List) {
          final padreId = v['padre_id'] as String?;
          final alumnoId = v['alumno_id'] as String?;
          if (padreId == null || alumnoId == null) continue;
          final alumno = alumnoPorId[alumnoId];
          if (alumno == null) continue;
          // Contar hijo por vínculo solo si no era ya el padre_id principal.
          if (alumno['padre_id'] != padreId) {
            padreAHijos[padreId] = (padreAHijos[padreId] ?? 0) + 1;
          }
          final gradoId = alumno['grado_id'] as String?;
          if (gradoId != null) {
            padreAGrados.putIfAbsent(padreId, () => <String>{}).add(gradoId);
          }
        }
      } catch (_) {}
    }

    return _PadresData(
      padres: padres,
      grados: grados,
      padreAGrados: padreAGrados,
      padreAHijos: padreAHijos,
    );
  }

  Future<void> _refrescar() async {
    final future = _cargarDatos();
    setState(() => _padresFuture = future);
    await future.catchError((_) => _PadresData.empty);
  }

  Future<void> _abrirCrearPadre() async {
    await context.push('/directora/padres/crear');
    if (mounted) await _refrescar();
  }

  List<Map<String, dynamic>> _filtrar(
    _PadresData data,
  ) {
    var lista = List<Map<String, dynamic>>.from(data.padres);

    if (_filtroGrado != 'Todos') {
      lista = lista.where((p) {
        final grados = data.padreAGrados[p['id'] as String] ?? {};
        return grados.contains(_filtroGrado);
      }).toList();
    }

    final q = _busqueda.trim().toLowerCase();
    if (q.isNotEmpty) {
      lista = lista.where((p) {
        final nombre = (p['nombre'] as String? ?? '').toLowerCase();
        final apellidos = (p['apellidos'] as String? ?? '').toLowerCase();
        final email = (p['email'] as String? ?? '').toLowerCase();
        return nombre.contains(q) ||
            apellidos.contains(q) ||
            email.contains(q);
      }).toList();
    }

    return lista;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grisClaro,
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Text(
          'Padres de Familia',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refrescar,
            tooltip: 'Actualizar lista',
          ),
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => context.go('/directora'),
            tooltip: 'Ir al inicio',
          ),
        ],
      ),
      body: FutureBuilder<_PadresData>(
        future: _padresFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _refrescar,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          final data = snapshot.data ?? _PadresData.empty;
          final padres = _filtrar(data);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Buscar padre por nombre o email...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (v) => setState(() => _busqueda = v),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _FiltroChip(
                      label: 'Todos',
                      isSelected: _filtroGrado == 'Todos',
                      onTap: () => setState(() => _filtroGrado = 'Todos'),
                    ),
                    ...data.grados.map(
                      (g) => _FiltroChip(
                        label: g.nombre,
                        isSelected: _filtroGrado == g.id,
                        onTap: () => setState(() => _filtroGrado = g.id),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${padres.length} padre${padres.length == 1 ? '' : 's'}'
                    '${_filtroGrado == 'Todos' ? '' : ' en este grupo'}',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: AppColors.gris,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: padres.isEmpty
                    ? Center(
                        child: Text(
                          data.padres.isEmpty
                              ? 'No hay padres registrados'
                              : 'No hay padres en este grado/grupo',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: AppColors.gris,
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _refrescar,
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(20),
                          itemCount: padres.length,
                          itemBuilder: (context, index) {
                            final padre = padres[index];
                            final id = padre['id'] as String;
                            return _buildPadreCard(
                              context,
                              padre,
                              hijos: data.padreAHijos[id] ?? 0,
                              grados: data.nombresGradosDe(id),
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirCrearPadre,
        heroTag: 'crear_padre',
        backgroundColor: AppColors.rosa,
        icon: const Icon(Icons.person_add),
        label: const Text('Agregar Padre'),
      ),
    );
  }

  Widget _buildPadreCard(
    BuildContext context,
    Map<String, dynamic> padre, {
    required int hijos,
    required String grados,
  }) {
    final nombre = [
      padre['nombre'] as String? ?? '',
      padre['apellidos'] as String? ?? '',
    ].where((s) => s.trim().isNotEmpty).join(' ');

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () async {
          await context.push('/directora/padres/ver/${padre['id']}');
          if (mounted) await _refrescar();
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.rosa, AppColors.naranja],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.family_restroom,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            nombre.isEmpty ? 'Sin nombre' : nombre,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (padre['activo'] != true)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.rojo.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Sin acceso',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.rojo,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.email, size: 14, color: AppColors.gris),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            padre['email'] ?? '',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppColors.gris,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$hijos hijo${hijos == 1 ? '' : 's'}'
                      '${grados.isEmpty ? '' : ' · $grados'}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.azul,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chat_bubble_rounded,
                    color: AppColors.morado),
                tooltip: 'Chat',
                onPressed: () async {
                  final user =
                      context.read<AuthService>().currentUser;
                  final chatService = ChatService();
                  final esProfesorCanal = user != null &&
                      user.esProfesor &&
                      !user.esDirectora &&
                      !user.esProfesorAdmin;
                  final conversacion =
                      await chatService.obtenerOCrearConversacion(
                    padre['id'] as String,
                    canal: esProfesorCanal ? 'profesor' : 'directora',
                    staffId: esProfesorCanal ? user.id : null,
                  );
                  if (!context.mounted) return;
                  context.push(
                    '/directora/chat/${conversacion.id}',
                    extra: {'titulo': nombre.isEmpty ? 'Padre' : nombre},
                  );
                },
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppColors.gris,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PadresData {
  final List<Map<String, dynamic>> padres;
  final List<Grado> grados;
  final Map<String, Set<String>> padreAGrados;
  final Map<String, int> padreAHijos;

  const _PadresData({
    required this.padres,
    required this.grados,
    required this.padreAGrados,
    required this.padreAHijos,
  });

  static final empty = _PadresData(
    padres: const [],
    grados: const [],
    padreAGrados: const {},
    padreAHijos: const {},
  );

  String nombresGradosDe(String padreId) {
    final ids = padreAGrados[padreId];
    if (ids == null || ids.isEmpty) return '';
    final nombres = grados
        .where((g) => ids.contains(g.id))
        .map((g) => g.nombre)
        .toList();
    return nombres.join(', ');
  }
}

class _FiltroChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FiltroChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: Theme.of(context).colorScheme.primaryContainer,
      ),
    );
  }
}
