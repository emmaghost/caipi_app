import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'package:provider/provider.dart';

import '../../config/app_colors.dart';
import '../../models/grado.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../widgets/app_drawer.dart';

class CrearAnuncioScreen extends StatefulWidget {
  final String? anuncioId;

  const CrearAnuncioScreen({super.key, this.anuncioId});

  @override
  State<CrearAnuncioScreen> createState() => _CrearAnuncioScreenState();
}

class _CrearAnuncioScreenState extends State<CrearAnuncioScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _mensajeController = TextEditingController();

  DateTime _fecha = DateTime.now();
  bool _paraTodos = true;
  bool _urgente = false;
  bool _enviarComoChat = true;
  List<String> _gradosSeleccionados = [];

  bool _cargando = false;
  bool _esEdicion = false;

  @override
  void initState() {
    super.initState();
    if (widget.anuncioId != null) {
      _esEdicion = true;
      _cargarDatosAnuncio();
    }
  }

  Future<void> _cargarDatosAnuncio() async {
    try {
      setState(() => _cargando = true);

      final response = await Supabase.instance.client
          .from('anuncios')
          .select()
          .eq('id', widget.anuncioId!)
          .single();

      if (!mounted) return;

      final fechaRaw =
          response['fecha_publicacion'] ?? response['fecha'];
      final gradosRaw =
          response['para_grados'] ?? response['grados'];

      setState(() {
        _tituloController.text = response['titulo'] as String? ?? '';
        _mensajeController.text = response['mensaje'] as String? ?? '';
        _fecha = fechaRaw != null
            ? (DateTime.tryParse(fechaRaw.toString()) ?? DateTime.now())
            : DateTime.now();
        _paraTodos = response['para_todos'] as bool? ?? true;
        _urgente = response['prioridad']?.toString() == 'alta';
        _gradosSeleccionados = gradosRaw is List
            ? gradosRaw.map((e) => e.toString()).toList()
            : <String>[];
        _cargando = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar anuncio: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _cargando = false);
      }
    }
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _mensajeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.campaign, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              _esEdicion ? 'Editar Anuncio' : 'Nuevo Anuncio',
              style: GoogleFonts.fredoka(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.azulOscuro,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => GoRouter.of(context).pop(),
        ),
      ),
      drawer: const AppDrawer(),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Encabezado
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.rosaClaro, AppColors.moradoClaro],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.campaign, color: Colors.white, size: 40),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _esEdicion ? 'Modificar Anuncio' : 'Crear Anuncio',
                                  style: GoogleFonts.fredoka(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Comunicación con padres de familia',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Información del Anuncio
                    _buildSeccionTitulo('Información del Anuncio'),
                    const SizedBox(height: 12),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _tituloController,
                              decoration: InputDecoration(
                                labelText: 'Título *',
                                hintText: 'Ej: Reunión de padres',
                                prefixIcon: const Icon(Icons.title),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'El título es obligatorio';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _mensajeController,
                              decoration: InputDecoration(
                                labelText: 'Mensaje *',
                                hintText: 'Escribe el mensaje del anuncio...',
                                prefixIcon: const Icon(Icons.message),
                                alignLabelWithHint: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              maxLines: 5,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'El mensaje es obligatorio';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            InkWell(
                              onTap: _seleccionarFecha,
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Fecha *',
                                  prefixIcon: const Icon(Icons.calendar_today),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  DateFormat('dd/MM/yyyy').format(_fecha),
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              value: _urgente,
                              onChanged: (v) => setState(() => _urgente = v),
                              title: Text(
                                'Marcar como urgente',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              secondary: Icon(
                                Icons.priority_high,
                                color: _urgente ? Colors.red : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Destinatarios
                    _buildSeccionTitulo('Destinatarios'),
                    const SizedBox(height: 12),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            SwitchListTile(
                              value: _paraTodos,
                              onChanged: (value) {
                                setState(() {
                                  _paraTodos = value;
                                  if (value) {
                                    _gradosSeleccionados.clear();
                                  }
                                });
                              },
                              title: Text(
                                'Enviar a todos los padres',
                                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                            _paraTodos
                                ? 'El anuncio será visible para todos. El chat llegará a todos los papás activos.'
                                : 'Solo padres de los grados seleccionados recibirán el chat',
                            style: GoogleFonts.poppins(fontSize: 12),
                          ),
                              secondary: Icon(
                                Icons.public,
                                color: _paraTodos ? Colors.green : Colors.grey,
                              ),
                            ),
                            if (!_paraTodos) ...[
                              const Divider(),
                              const SizedBox(height: 8),
                              Text(
                                'Selecciona los grados:',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              StreamBuilder<List<Map<String, dynamic>>>(
                                stream: Supabase.instance.client
                                    .from('grados')
                                    .stream(primaryKey: ['id'])
                                    .eq('activo', true)
                                    .order('nombre', ascending: true),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData) {
                                    return const CircularProgressIndicator();
                                  }

                                  final grados = snapshot.data!
                                      .map((json) => Grado.fromJson(json))
                                      .toList();

                                  return Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: grados.map((grado) {
                                      final seleccionado =
                                          _gradosSeleccionados.contains(grado.id);
                                      return FilterChip(
                                        selected: seleccionado,
                                        label: Text(grado.nombre),
                                        onSelected: (selected) {
                                          setState(() {
                                            if (selected) {
                                              _gradosSeleccionados.add(grado.id);
                                            } else {
                                              _gradosSeleccionados.remove(grado.id);
                                            }
                                          });
                                        },
                                        avatar: Icon(
                                          Icons.school,
                                          size: 18,
                                          color: seleccionado
                                              ? Colors.white
                                              : Colors.grey,
                                        ),
                                      );
                                    }).toList(),
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    if (!_esEdicion) ...[
                      const SizedBox(height: 16),
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: SwitchListTile(
                          value: _enviarComoChat,
                          onChanged: (v) =>
                              setState(() => _enviarComoChat = v),
                          title: Text(
                            'Enviar también como mensaje de chat',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            'Cada papá lo verá en Chat con la escuela (mismo texto para todos los destinatarios)',
                            style: GoogleFonts.poppins(fontSize: 12),
                          ),
                          secondary: Icon(
                            Icons.chat_bubble_outline,
                            color: _enviarComoChat
                                ? AppColors.azulOscuro
                                : Colors.grey,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),

                    // Botón guardar
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _guardarAnuncio,
                        icon: const Icon(Icons.send, color: Colors.white),
                        label: Text(
                          _esEdicion ? 'Actualizar Anuncio' : 'Publicar Anuncio',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.verdeClaro,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),

                    // Botón eliminar (solo en edición)
                    if (_esEdicion) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton.icon(
                          onPressed: _confirmarEliminar,
                          icon: const Icon(Icons.delete, color: Colors.red),
                          label: Text(
                            'Eliminar Anuncio',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red, width: 2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSeccionTitulo(String titulo) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: AppColors.azulOscuro,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          titulo,
          style: GoogleFonts.fredoka(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.azulOscuro,
          ),
        ),
      ],
    );
  }

  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('es', 'MX'),
    );

    if (fecha != null) {
      setState(() {
        _fecha = fecha;
      });
    }
  }

  Future<void> _guardarAnuncio() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_paraTodos && _gradosSeleccionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona al menos un grado'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _cargando = true);

    try {
      final usuario = context.read<AuthService>().currentUser;
      final titulo = _tituloController.text.trim();
      final mensaje = _mensajeController.text.trim();
      final fechaIso = DateTime(
        _fecha.year,
        _fecha.month,
        _fecha.day,
        DateTime.now().hour,
        DateTime.now().minute,
      ).toIso8601String();

      // Columnas canónicas (SQL_MAESTRO). No usar fecha/grados legacy.
      final Map<String, dynamic> anuncioData = {
        'titulo': titulo,
        'mensaje': mensaje,
        'fecha_publicacion': fechaIso,
        'para_todos': _paraTodos,
        'para_grados':
            _paraTodos ? <String>[] : List<String>.from(_gradosSeleccionados),
        'prioridad': _urgente ? 'alta' : 'normal',
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (_esEdicion) {
        await Supabase.instance.client
            .from('anuncios')
            .update(anuncioData)
            .eq('id', widget.anuncioId!);
      } else {
        anuncioData['id'] = const Uuid().v4();
        anuncioData['created_at'] = DateTime.now().toIso8601String();
        anuncioData['leido_por'] = <String>[];
        if (usuario != null) {
          anuncioData['creado_por'] = usuario.id;
        }

        await Supabase.instance.client.from('anuncios').insert(anuncioData);

        var chatEnviados = 0;
        if (_enviarComoChat && usuario != null) {
          final prefijo = _urgente ? '📢 Anuncio urgente' : '📢 Anuncio';
          chatEnviados = await ChatService().enviarMensajeMasivoAPadres(
            remitenteId: usuario.id,
            contenido: '$prefijo: $titulo\n\n$mensaje',
            paraTodos: _paraTodos,
            gradoIds: _gradosSeleccionados,
            omitirHorario: true,
          );
        }

        if (mounted) {
          final extraChat = _enviarComoChat
              ? ' · Chat: $chatEnviados papá(s)'
              : '';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✓ Anuncio publicado$extraChat'),
              backgroundColor: Colors.green,
            ),
          );
          GoRouter.of(context).go('/directora/anuncios');
        }
        return;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Anuncio actualizado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        GoRouter.of(context).go('/directora/anuncios');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _cargando = false);
      }
    }
  }

  Future<void> _confirmarEliminar() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning, color: Colors.red),
            const SizedBox(width: 8),
            Text(
              '¿Eliminar Anuncio?',
              style: GoogleFonts.fredoka(),
            ),
          ],
        ),
        content: Text(
          'Esta acción no se puede deshacer. ¿Estás segura de eliminar este anuncio?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await _eliminarAnuncio();
    }
  }

  Future<void> _eliminarAnuncio() async {
    setState(() => _cargando = true);

    try {
      await Supabase.instance.client
          .from('anuncios')
          .delete()
          .eq('id', widget.anuncioId!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Anuncio eliminado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        GoRouter.of(context).go('/directora/anuncios');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _cargando = false);
      }
    }
  }
}
