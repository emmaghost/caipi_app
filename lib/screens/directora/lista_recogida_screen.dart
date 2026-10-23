import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/profesor_grupos_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/caipi_app_bar_leading.dart';

/// Lista fija de quién puede recoger a cada niño.
/// La directora la carga y la edita. Maestras y profesores solo la ven.
class ListaRecogidaScreen extends StatefulWidget {
  const ListaRecogidaScreen({super.key});

  @override
  State<ListaRecogidaScreen> createState() => _ListaRecogidaScreenState();
}

class _ListaRecogidaScreenState extends State<ListaRecogidaScreen> {
  final _busqueda = TextEditingController();
  bool _cargando = true;
  bool _puedeEditar = false;
  String? _gradoFiltro;
  List<Map<String, dynamic>> _grados = [];
  List<Map<String, dynamic>> _alumnos = [];
  List<Map<String, dynamic>> _cambios = [];
  String? _errorSql;

  @override
  void initState() {
    super.initState();
    _busqueda.addListener(() => setState(() {}));
    _cargar();
  }

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    final user = context.read<AuthService>().currentUser;
    final client = Supabase.instance.client;
    setState(() {
      _cargando = true;
      _errorSql = null;
    });
    try {
      final puedeEditar = user?.esDirectora == true;
      List<String>? gradosPermitidos;
      if (user != null && !user.puedeVerTodosLosAlumnos) {
        gradosPermitidos = await ProfesorGruposService().gradoIdsDeUsuario(user.id);
      }

      final gradosRows = await client.from('grados').select('id, nombre').order('nombre');
      var grados = List<Map<String, dynamic>>.from(gradosRows as List);
      if (gradosPermitidos != null) {
        final permitidos = gradosPermitidos.toSet();
        grados = grados.where((g) => permitidos.contains(g['id'])).toList();
      }

      final alumnosRows = await client
          .from('alumnos')
          .select('id, nombre, apellidos, grado_id')
          .eq('activo', true)
          .order('nombre');
      var alumnos = List<Map<String, dynamic>>.from(alumnosRows as List);
      if (gradosPermitidos != null) {
        final permitidos = gradosPermitidos.toSet();
        alumnos = alumnos.where((a) => permitidos.contains(a['grado_id'])).toList();
      }

      var cambios = <Map<String, dynamic>>[];
      if (puedeEditar) {
        try {
          final cambioRows = await client
              .from('solicitudes_cambio_recogida')
              .select('id, alumno_id, mensaje, created_at')
              .eq('estado', 'pendiente')
              .order('created_at', ascending: false);
          cambios = List<Map<String, dynamic>>.from(cambioRows as List);
        } catch (_) {}
      }

      if (!mounted) return;
      setState(() {
        _puedeEditar = puedeEditar;
        _grados = grados;
        _alumnos = alumnos;
        _cambios = cambios;
        _cargando = false;
        if (_gradoFiltro != null && grados.every((g) => g['id'] != _gradoFiltro)) {
          _gradoFiltro = null;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _errorSql = '$e';
      });
    }
  }

  String _nombreAlumno(Map<String, dynamic> a) {
    final n = a['nombre'] as String? ?? '';
    final ap = a['apellidos'] as String? ?? '';
    return ap.isEmpty ? n : '$n $ap';
  }

  String _nombreGrado(String? id) {
    for (final g in _grados) {
      if (g['id'] == id) return g['nombre'] as String? ?? '';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final q = _busqueda.text.trim().toLowerCase();
    final visibles = _alumnos.where((a) {
      if (_gradoFiltro != null && a['grado_id'] != _gradoFiltro) return false;
      if (q.isEmpty) return true;
      return _nombreAlumno(a).toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FC),
      drawer: const AppDrawer(),
      appBar: AppBar(
        leading: const CaipiAppBarLeading(),
        title: Text(
          'Quién puede recoger',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.azulOscuro,
        foregroundColor: Colors.white,
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _cargar,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  Text(
                    _puedeEditar
                        ? 'Cada niño tiene su propia lista, máximo 3 personas. La foto de la INE es opcional.'
                        : 'Solo consulta. Cada niño tiene su lista. Si hay que cambiarla, lo hace la directora.',
                    style: GoogleFonts.poppins(fontSize: 13, color: AppColors.gris),
                  ),
                  if (_errorSql != null) ...[
                    const SizedBox(height: 12),
                    Text(_errorSql!, style: GoogleFonts.poppins(color: AppColors.rojo, fontSize: 12)),
                  ],
                  if (_puedeEditar && _cambios.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _bannerCambios(),
                  ],
                  const SizedBox(height: 14),
                  TextField(
                    controller: _busqueda,
                    decoration: InputDecoration(
                      hintText: 'Buscar niño',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (_puedeEditar)
                        FilterChip(
                          label: const Text('Todos'),
                          selected: _gradoFiltro == null,
                          onSelected: (_) => setState(() => _gradoFiltro = null),
                        ),
                      for (final g in _grados)
                        FilterChip(
                          label: Text(g['nombre'] as String? ?? ''),
                          selected: _gradoFiltro == g['id'],
                          onSelected: (_) => setState(() {
                            _gradoFiltro = _gradoFiltro == g['id'] ? null : g['id'] as String;
                          }),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (visibles.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 32),
                      child: Text(
                        'No hay niños en este filtro.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(color: AppColors.gris),
                      ),
                    )
                  else
                    ...visibles.map((a) {
                      final id = a['id'] as String;
                      final cambiosDeEste = _cambios.where((c) => c['alumno_id'] == id).length;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(
                            _nombreAlumno(a),
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            [
                              _nombreGrado(a['grado_id'] as String?),
                              if (cambiosDeEste > 0) 'Pidieron cambio',
                            ].where((s) => s.isNotEmpty).join(' · '),
                            style: GoogleFonts.poppins(fontSize: 12),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => _AlumnoRecogidaPage(
                                  alumnoId: id,
                                  alumnoNombre: _nombreAlumno(a),
                                  puedeEditar: _puedeEditar,
                                ),
                              ),
                            );
                            if (mounted) _cargar();
                          },
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }

  Widget _bannerCambios() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDBA74)),
      ),
      child: Text(
        '${_cambios.length} papá(s) pidieron cambiar la lista. '
        'Tienen que ir a la escuela con los papeles. Entra al niño para ver el aviso.',
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF9A3412),
        ),
      ),
    );
  }
}

class _AlumnoRecogidaPage extends StatefulWidget {
  final String alumnoId;
  final String alumnoNombre;
  final bool puedeEditar;

  const _AlumnoRecogidaPage({
    required this.alumnoId,
    required this.alumnoNombre,
    required this.puedeEditar,
  });

  @override
  State<_AlumnoRecogidaPage> createState() => _AlumnoRecogidaPageState();
}

class _AlumnoRecogidaPageState extends State<_AlumnoRecogidaPage> {
  bool _cargando = true;
  String? _error;
  List<Map<String, dynamic>> _personas = [];
  List<Map<String, dynamic>> _cambios = [];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final client = Supabase.instance.client;
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final rows = await client
          .from('personas_autorizadas')
          .select()
          .eq('alumno_id', widget.alumnoId)
          .eq('es_lista_fija', true)
          .order('created_at');
      var cambios = <Map<String, dynamic>>[];
      if (widget.puedeEditar) {
        final c = await client
            .from('solicitudes_cambio_recogida')
            .select()
            .eq('alumno_id', widget.alumnoId)
            .eq('estado', 'pendiente')
            .order('created_at', ascending: false);
        cambios = List<Map<String, dynamic>>.from(c as List);
      }
      if (!mounted) return;
      setState(() {
        _personas = List<Map<String, dynamic>>.from(rows as List);
        _cambios = cambios;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _error = 'Falta correr ADD_LISTA_RECOGIDA.sql en Supabase.\n$e';
      });
    }
  }

  Future<void> _marcarCambioListo(String id) async {
    await Supabase.instance.client
        .from('solicitudes_cambio_recogida')
        .update({'estado': 'atendida'})
        .eq('id', id);
    await _cargar();
  }

  Future<void> _eliminar(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quitar de la lista'),
        content: const Text('Esta persona ya no podrá recoger a este niño sin código.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Quitar')),
        ],
      ),
    );
    if (ok != true) return;
    await Supabase.instance.client.from('personas_autorizadas').delete().eq('id', id);
    await _cargar();
  }

  Future<void> _abrirFormulario({Map<String, dynamic>? persona}) async {
    if (_personas.length >= 3 && persona == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Este niño ya tiene 3 personas. Quita una para agregar otra.')),
      );
      return;
    }
    final nombre = TextEditingController(text: persona?['nombre'] as String? ?? '');
    final parentesco = TextEditingController(text: persona?['parentesco'] as String? ?? '');
    final telefono = TextEditingController(text: persona?['telefono'] as String? ?? '');
    File? fotoNueva;
    var fotoUrl = persona?['foto_ine_url'] as String?;

    final guardar = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(persona == null ? 'Agregar persona' : 'Editar persona'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nombre,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: parentesco,
                  decoration: const InputDecoration(
                    labelText: 'Parentesco',
                    hintText: 'Abuelo, tía, compadre',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: telefono,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Teléfono'),
                ),
                const SizedBox(height: 12),
                Text(
                  'Foto de la INE (opcional). Si no hay copia, se deja vacía.',
                  style: GoogleFonts.poppins(fontSize: 12, color: AppColors.gris),
                ),
                const SizedBox(height: 8),
                if (fotoNueva != null)
                  Image.file(fotoNueva as File, height: 120, fit: BoxFit.cover)
                else if (fotoUrl != null && fotoUrl.isNotEmpty)
                  CachedNetworkImage(imageUrl: fotoUrl, height: 120, fit: BoxFit.cover),
                TextButton.icon(
                  onPressed: () async {
                    final file = await StorageService().seleccionarImagenGaleria();
                    if (file == null) return;
                    setLocal(() => fotoNueva = file);
                  },
                  icon: const Icon(Icons.photo_outlined),
                  label: const Text('Subir fotocopia'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Guardar')),
          ],
        ),
      ),
    );

    if (guardar != true || !mounted) return;
    if (nombre.text.trim().isEmpty || parentesco.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nombre y parentesco son obligatorios')),
      );
      return;
    }

    final client = Supabase.instance.client;
    try {
      String id;
      if (persona == null) {
        final row = await client
            .from('personas_autorizadas')
            .insert({
              'alumno_id': widget.alumnoId,
              'nombre': nombre.text.trim(),
              'parentesco': parentesco.text.trim(),
              'telefono': telefono.text.trim(),
              'es_lista_fija': true,
            })
            .select('id')
            .single();
        id = row['id'] as String;
      } else {
        id = persona['id'] as String;
        await client.from('personas_autorizadas').update({
          'nombre': nombre.text.trim(),
          'parentesco': parentesco.text.trim(),
          'telefono': telefono.text.trim(),
        }).eq('id', id);
      }

      if (fotoNueva != null) {
        final url = await StorageService().subirFotoIne(fotoNueva!, widget.alumnoId, id);
        if (url != null) {
          await client.from('personas_autorizadas').update({'foto_ine_url': url}).eq('id', id);
        }
      }
      await _cargar();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar: $e'), backgroundColor: AppColors.rojo),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.alumnoNombre, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.azulOscuro,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: widget.puedeEditar && _personas.length < 3
          ? FloatingActionButton.extended(
              onPressed: () => _abrirFormulario(),
              icon: const Icon(Icons.person_add),
              label: const Text('Agregar'),
            )
          : null,
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                Text(
                  widget.puedeEditar
                      ? 'Hasta 3 personas para este niño. Otro hijo del mismo papá lleva su propia lista.'
                      : 'Personas que pueden recoger a este niño. No se editan desde aquí.',
                  style: GoogleFonts.poppins(fontSize: 13, color: AppColors.gris),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: GoogleFonts.poppins(color: AppColors.rojo, fontSize: 13)),
                ],
                for (final c in _cambios) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'El papá pidió un cambio. Tiene que ir a la escuela con los papeles.',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                        if ((c['mensaje'] as String?)?.trim().isNotEmpty == true)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(c['mensaje'] as String, style: GoogleFonts.poppins(fontSize: 13)),
                          ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => _marcarCambioListo(c['id'] as String),
                            child: const Text('Ya lo atendí'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                if (_personas.isEmpty && _error == null)
                  Text(
                    'Todavía no hay personas cargadas.',
                    style: GoogleFonts.poppins(color: AppColors.gris),
                  ),
                for (final p in _personas) _tarjeta(p),
              ],
            ),
    );
  }

  Widget _tarjeta(Map<String, dynamic> p) {
    final foto = p['foto_ine_url'] as String?;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              p['nombre'] as String? ?? '',
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            Text(
              p['parentesco'] as String? ?? '',
              style: GoogleFonts.poppins(color: AppColors.morado, fontWeight: FontWeight.w600),
            ),
            if ((p['telefono'] as String?)?.isNotEmpty == true)
              Text(p['telefono'] as String, style: GoogleFonts.poppins(fontSize: 13)),
            const SizedBox(height: 8),
            if (foto != null && foto.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(imageUrl: foto, height: 160, width: double.infinity, fit: BoxFit.cover),
              )
            else
              Text(
                'Sin foto de INE',
                style: GoogleFonts.poppins(fontSize: 12, color: AppColors.gris),
              ),
            if (widget.puedeEditar)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => _abrirFormulario(persona: p), child: const Text('Editar')),
                  TextButton(
                    onPressed: () => _eliminar(p['id'] as String),
                    child: const Text('Quitar'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
