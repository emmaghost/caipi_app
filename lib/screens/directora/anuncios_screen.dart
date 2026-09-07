import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/profesor_grupos_service.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/caipi_app_bar_leading.dart';

class AnunciosScreen extends StatefulWidget {
  const AnunciosScreen({super.key});

  @override
  State<AnunciosScreen> createState() => _AnunciosScreenState();
}

class _AnunciosScreenState extends State<AnunciosScreen> {
  List<String>? _gradosMaestra;
  String? _usuarioId;
  /// Fuerza nuevo stream al volver de crear/editar (realtime a veces no pinta al instante).
  int _listaEpoch = 0;

  @override
  void initState() {
    super.initState();
    _cargarAlcance();
  }

  Future<void> _abrirCrear() async {
    final cambio = await GoRouter.of(context).push<bool>(
      '/directora/anuncios/crear',
    );
    if (!mounted) return;
    if (cambio == true) {
      setState(() => _listaEpoch++);
    }
  }

  Future<void> _abrirEditar(String id) async {
    final cambio = await GoRouter.of(context).push<bool>(
      '/directora/anuncios/editar/$id',
    );
    if (!mounted) return;
    if (cambio == true) {
      setState(() => _listaEpoch++);
    }
  }

  Future<void> _cargarAlcance() async {
    final user = context.read<AuthService>().currentUser;
    _usuarioId = user?.id;
    if (user == null || !user.esMaestraAula) {
      setState(() => _gradosMaestra = null);
      return;
    }
    final ids = await ProfesorGruposService().gradoIdsDeUsuario(user.id);
    if (!mounted) return;
    setState(() => _gradosMaestra = ids);
  }

  List<Map<String, dynamic>> _filtrarParaMaestra(
    List<Map<String, dynamic>> list,
  ) {
    final grados = _gradosMaestra;
    if (grados == null) return list;
    return list.where((a) {
      if (a['creado_por']?.toString() == _usuarioId) return true;
      if (a['para_todos'] == true) return true;
      final raw = a['para_grados'] ?? a['grados'];
      if (raw is! List) return false;
      return raw.map((e) => e.toString()).any(grados.contains);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final esMaestra =
        context.read<AuthService>().currentUser?.esMaestraAula == true;

    return Scaffold(
      appBar: AppBar(
        leading: const CaipiAppBarLeading(),
        title: Row(
          children: [
            const Icon(Icons.campaign, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              esMaestra ? 'Anuncios de mi grupo' : 'Anuncios',
              style: GoogleFonts.fredoka(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.azulOscuro,
        actions: [
          IconButton(
            icon: const Icon(Icons.home, color: Colors.white),
            onPressed: () => GoRouter.of(context).go('/directora'),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.azulOscuro.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: StreamBuilder<List<Map<String, dynamic>>>(
          key: ValueKey('anuncios-stream-$_listaEpoch'),
          stream: Supabase.instance.client
              .from('anuncios')
              .stream(primaryKey: ['id'])
              .map((rows) {
            final list = List<Map<String, dynamic>>.from(rows);
            list.sort((a, b) {
              final fa = DateTime.tryParse(
                    (a['fecha_publicacion'] ?? a['fecha'] ?? '').toString(),
                  ) ??
                  DateTime.fromMillisecondsSinceEpoch(0);
              final fb = DateTime.tryParse(
                    (b['fecha_publicacion'] ?? b['fecha'] ?? '').toString(),
                  ) ??
                  DateTime.fromMillisecondsSinceEpoch(0);
              return fb.compareTo(fa);
            });
            return _filtrarParaMaestra(list);
          }),
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
                    Text(
                      'Error al cargar anuncios',
                      style: GoogleFonts.poppins(fontSize: 18),
                    ),
                  ],
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.campaign_outlined,
                        size: 80,
                        color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No hay anuncios publicados',
                      style: GoogleFonts.fredoka(
                        fontSize: 18,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _abrirCrear,
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: Text(
                        'Crear Primer Anuncio',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: Colors.white,
                        elevation: 3,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            final anuncios = snapshot.data!;

            return RefreshIndicator(
              onRefresh: () async {
                setState(() => _listaEpoch++);
                await Future<void>.delayed(const Duration(milliseconds: 350));
              },
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: anuncios.length,
                itemBuilder: (context, index) {
                  final anuncio = anuncios[index];
                  return _AnuncioCard(
                    anuncio: anuncio,
                    onEditar: () => _abrirEditar(anuncio['id'] as String),
                    onEliminado: () {
                      if (mounted) setState(() => _listaEpoch++);
                    },
                  );
                },
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirCrear,
        backgroundColor: const Color(0xFF059669),
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'Nuevo Anuncio',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _AnuncioCard extends StatelessWidget {
  final Map<String, dynamic> anuncio;
  final VoidCallback? onEditar;
  final VoidCallback? onEliminado;

  const _AnuncioCard({
    required this.anuncio,
    this.onEditar,
    this.onEliminado,
  });

  DateTime get _fecha {
    final raw = anuncio['fecha_publicacion'] ?? anuncio['fecha'];
    return DateTime.tryParse(raw?.toString() ?? '') ?? DateTime.now();
  }

  List<String> get _grados {
    final raw = anuncio['para_grados'] ?? anuncio['grados'];
    if (raw is! List) return const [];
    return raw.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
  }

  @override
  Widget build(BuildContext context) {
    final fecha = _fecha;
    final paraTodos = anuncio['para_todos'] as bool? ?? false;
    final grados = _grados;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          _mostrarDetalleAnuncio(context);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.rosa, AppColors.morado],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.campaign, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          anuncio['titulo'] as String,
                          style: GoogleFonts.fredoka(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.azulOscuro,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.calendar_today,
                                size: 12, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('dd/MM/yyyy', 'es_MX').format(fecha),
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    tooltip: 'Editar',
                    onPressed: onEditar ??
                        () {
                          GoRouter.of(context).push(
                            '/directora/anuncios/editar/${anuncio['id']}',
                          );
                        },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    tooltip: 'Eliminar',
                    onPressed: () => _confirmarEliminar(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Contenido
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  anuncio['mensaje'] as String,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[800],
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 12),

              // Destinatarios
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (paraTodos)
                    _buildChip(
                      icon: Icons.public,
                      label: 'Todos',
                      color: Colors.green,
                    )
                  else
                    ...grados.map((grado) {
                      return FutureBuilder<String>(
                        future: _obtenerNombreGrado(grado),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const SizedBox.shrink();
                          }
                          return _buildChip(
                            icon: Icons.school,
                            label: snapshot.data!,
                            color: AppColors.purpura,
                          );
                        },
                      );
                    }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Future<String> _obtenerNombreGrado(String gradoId) async {
    try {
      final response = await Supabase.instance.client
          .from('grados')
          .select('nombre')
          .eq('id', gradoId)
          .single();
      return response['nombre'] as String;
    } catch (e) {
      return 'Grado';
    }
  }

  Future<void> _confirmarEliminar(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Eliminar anuncio', style: GoogleFonts.fredoka()),
        content: Text(
          '¿Segura que quieres eliminar “${anuncio['titulo']}”? No se puede deshacer.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await Supabase.instance.client
          .from('anuncios')
          .delete()
          .eq('id', anuncio['id']);
      if (!context.mounted) return;
      onEliminado?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anuncio eliminado'),
          backgroundColor: Color(0xFF059669),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo eliminar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _mostrarDetalleAnuncio(BuildContext context) {
    final fecha = _fecha;
    final paraTodos = anuncio['para_todos'] as bool? ?? false;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.campaign),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                anuncio['titulo'] as String,
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
                'Fecha',
                DateFormat('dd/MM/yyyy HH:mm', 'es_MX').format(fecha),
              ),
              const Divider(),
              _buildDetalleItem('Mensaje', anuncio['mensaje'] as String),
              const Divider(),
              _buildDetalleItem(
                'Destinatarios',
                paraTodos ? 'Todos los padres' : 'Grados específicos',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              GoRouter.of(context).push(
                '/directora/anuncios/editar/${anuncio['id']}',
              );
            },
            child: const Text('Editar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetalleItem(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            valor,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
}
