import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/app_colors.dart';
import '../../models/alumno.dart';
import '../../models/entrevista_padres.dart';
import '../../services/reportes_pdf_service.dart';
import '../../widgets/app_drawer.dart';

/// Lista de alumnos para ver / crear / descargar entrevista por hijo.
class EntrevistasListaScreen extends StatefulWidget {
  const EntrevistasListaScreen({super.key});

  @override
  State<EntrevistasListaScreen> createState() => _EntrevistasListaScreenState();
}

class _EntrevistasListaScreenState extends State<EntrevistasListaScreen> {
  bool _cargando = true;
  String _busqueda = '';
  List<Alumno> _alumnos = [];
  Map<String, EntrevistaPadres> _porAlumno = {};
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final client = Supabase.instance.client;
      final alumnosRes = await client
          .from('alumnos')
          .select()
          .eq('activo', true)
          .order('apellidos');
      final entrevistasRes = await client.from('entrevistas_padres').select();

      final alumnos =
          (alumnosRes as List).map((e) => Alumno.fromJson(e)).toList();
      final mapa = <String, EntrevistaPadres>{};
      for (final raw in entrevistasRes as List) {
        final e = EntrevistaPadres.fromJson(Map<String, dynamic>.from(raw));
        if (e.alumnoId != null && e.alumnoId!.isNotEmpty) {
          mapa[e.alumnoId!] = e;
        }
      }

      if (!mounted) return;
      setState(() {
        _alumnos = alumnos;
        _porAlumno = mapa;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _cargando = false;
      });
    }
  }

  Future<void> _abrirEntrevista(Alumno alumno) async {
    final existente = _porAlumno[alumno.id];
    final ruta = existente == null
        ? '/directora/entrevista/crear?alumnoId=${alumno.id}'
        : '/directora/entrevista/editar/${existente.id}?alumnoId=${alumno.id}';
    await context.push(ruta);
    if (mounted) await _cargar();
  }

  Future<void> _exportarPdf(Alumno alumno) async {
    final entrevista = _porAlumno[alumno.id];
    if (entrevista == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este alumno aún no tiene entrevista. Créala primero.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    try {
      await ReportesPdfService.compartirEntrevista(
        entrevista: entrevista,
        alumno: alumno,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo generar el PDF: $e'),
          backgroundColor: AppColors.rojo,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtrados = _busqueda.trim().isEmpty
        ? _alumnos
        : _alumnos
            .where((a) =>
                a.nombreCompleto.toLowerCase().contains(_busqueda.toLowerCase()))
            .toList();

    return Scaffold(
      backgroundColor: AppColors.grisClaro,
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Text(
          'Entrevistas por alumno',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargar,
          ),
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => context.go('/directora'),
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: _cargar,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Text(
                        'La entrevista va ligada a un hijo. Primero debe existir el alumno. '
                        'Puedes crearla, completarla después y descargarla en PDF.',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey[700],
                          height: 1.35,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        onChanged: (v) => setState(() => _busqueda = v),
                        decoration: InputDecoration(
                          hintText: 'Buscar alumno…',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: filtrados.isEmpty
                          ? Center(
                              child: Text(
                                _alumnos.isEmpty
                                    ? 'No hay alumnos. Crea uno antes de hacer la entrevista.'
                                    : 'Sin resultados',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _cargar,
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: filtrados.length,
                                itemBuilder: (context, index) {
                                  final alumno = filtrados[index];
                                  final entrevista = _porAlumno[alumno.id];
                                  final tiene = entrevista != null;
                                  final completa = entrevista?.completado == true;
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: AppColors.morado
                                            .withOpacity(0.15),
                                        child: Text(
                                          alumno.nombre.isNotEmpty
                                              ? alumno.nombre[0].toUpperCase()
                                              : '?',
                                          style: const TextStyle(
                                            color: AppColors.morado,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      title: Text(
                                        alumno.nombreCompleto,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      subtitle: Text(
                                        !tiene
                                            ? 'Sin entrevista'
                                            : completa
                                                ? 'Entrevista completa'
                                                : 'Entrevista en borrador',
                                        style: TextStyle(
                                          color: !tiene
                                              ? Colors.grey[600]
                                              : completa
                                                  ? AppColors.verde
                                                  : Colors.orange[800],
                                        ),
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (tiene)
                                            IconButton(
                                              tooltip: 'Descargar PDF',
                                              icon: const Icon(
                                                Icons.picture_as_pdf,
                                                color: Color(0xFF166534),
                                              ),
                                              onPressed: () =>
                                                  _exportarPdf(alumno),
                                            ),
                                          IconButton(
                                            tooltip: tiene
                                                ? 'Ver / editar'
                                                : 'Crear entrevista',
                                            icon: Icon(
                                              tiene
                                                  ? Icons.edit_note
                                                  : Icons.add_circle_outline,
                                              color: AppColors.morado,
                                            ),
                                            onPressed: () =>
                                                _abrirEntrevista(alumno),
                                          ),
                                        ],
                                      ),
                                      onTap: () => _abrirEntrevista(alumno),
                                    ),
                                  );
                                },
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }
}
