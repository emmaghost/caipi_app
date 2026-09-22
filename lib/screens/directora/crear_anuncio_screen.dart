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
import '../../services/profesor_grupos_service.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/caipi_app_bar_leading.dart';

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

  /// Si no es null, la maestra solo puede anunciar a estos grados.
  List<String>? _gradosPermitidos;
  bool _cargandoAlcance = false;

  bool _cargando = false;
  bool _esEdicion = false;

  bool get _alcanceAcotado =>
      _gradosPermitidos != null && _gradosPermitidos!.isNotEmpty;

  @override
  void initState() {
    super.initState();
    if (widget.anuncioId != null) {
      _esEdicion = true;
    }
    _iniciar();
  }

  bool get _puedeEnviarGeneral {
    final u = context.read<AuthService>().currentUser;
    return u?.esDirectora == true;
  }

  Future<void> _iniciar() async {
    await _prepararAlcance();
    if (_esEdicion) {
      await _cargarDatosAnuncio();
    }
  }

  Future<void> _prepararAlcance() async {
    final usuario = context.read<AuthService>().currentUser;
    if (usuario == null) return;

    // Solo directora puede anunciar a toda la escuela.
    if (!usuario.esDirectora) {
      _paraTodos = false;
    }

    if (!usuario.esMaestraAula) {
      if (mounted) setState(() {});
      return;
    }

    setState(() => _cargandoAlcance = true);
    try {
      final ids = await ProfesorGruposService().gradoIdsDeUsuario(usuario.id);
      if (!mounted) return;
      setState(() {
        _gradosPermitidos = ids;
        _paraTodos = false;
        if (!_esEdicion && ids.isNotEmpty) {
          _gradosSeleccionados = List<String>.from(ids);
        }
        _cargandoAlcance = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _gradosPermitidos = [];
        _paraTodos = false;
        _cargandoAlcance = false;
      });
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

      var gradosSel = gradosRaw is List
          ? gradosRaw.map((e) => e.toString()).toList()
          : <String>[];
      var paraTodos = response['para_todos'] as bool? ?? true;
      if (_alcanceAcotado) {
        paraTodos = false;
        gradosSel = gradosSel
            .where((id) => _gradosPermitidos!.contains(id))
            .toList();
        if (gradosSel.isEmpty) {
          gradosSel = List<String>.from(_gradosPermitidos!);
        }
      }

      setState(() {
        _tituloController.text = response['titulo'] as String? ?? '';
        _mensajeController.text = response['mensaje'] as String? ?? '';
        _fecha = fechaRaw != null
            ? (DateTime.tryParse(fechaRaw.toString()) ?? DateTime.now())
            : DateTime.now();
        _paraTodos = paraTodos;
        _urgente = response['prioridad']?.toString() == 'alta';
        _gradosSeleccionados = gradosSel;
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
        leading: const CaipiAppBarLeading(),
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
                    // Encabezado (colores sólidos: texto blanco legible)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.rosa, AppColors.morado],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.rosa.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
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
                                    color: Colors.white,
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
                    if (_cargandoAlcance)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_gradosPermitidos != null &&
                        _gradosPermitidos!.isEmpty)
                      Card(
                        color: Colors.orange.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'No tienes grupos asignados. Pide a dirección que te asigne grado(s) para poder anunciar.',
                            style: GoogleFonts.poppins(fontSize: 13),
                          ),
                        ),
                      )
                    else
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            if (_puedeEnviarGeneral)
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
                                  style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600),
                                ),
                                subtitle: Text(
                                  _paraTodos
                                      ? 'El anuncio será visible para todos. El chat llegará a todos los papás activos.'
                                      : 'Solo padres de los grados seleccionados recibirán el chat',
                                  style: GoogleFonts.poppins(fontSize: 12),
                                ),
                                secondary: Icon(
                                  Icons.public,
                                  color:
                                      _paraTodos ? Colors.green : Colors.grey,
                                ),
                              )
                            else if (_alcanceAcotado)
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(Icons.groups,
                                    color: AppColors.azulOscuro),
                                title: Text(
                                  _gradosPermitidos!.length == 1
                                      ? 'Anuncio solo a tu grupo'
                                      : 'Anuncio a tus grupos asignados',
                                  style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600),
                                ),
                                subtitle: Text(
                                  'Solo papás de los grados que tienes asignados.',
                                  style: GoogleFonts.poppins(fontSize: 12),
                                ),
                              ),
                            if (!_paraTodos) ...[
                              if (!_alcanceAcotado) const Divider(),
                              const SizedBox(height: 8),
                              Text(
                                _alcanceAcotado &&
                                        _gradosPermitidos!.length == 1
                                    ? 'Tu grupo:'
                                    : 'Selecciona los grados:',
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

                                  var grados = snapshot.data!
                                      .map((json) => Grado.fromJson(json))
                                      .toList();
                                  if (_alcanceAcotado) {
                                    grados = grados
                                        .where((g) =>
                                            _gradosPermitidos!.contains(g.id))
                                        .toList();
                                  }

                                  final soloUno =
                                      _alcanceAcotado && grados.length == 1;

                                  return Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: grados.map((grado) {
                                      final seleccionado =
                                          _gradosSeleccionados.contains(grado.id);
                                      return FilterChip(
                                        selected: seleccionado,
                                        label: Text(grado.nombre),
                                        onSelected: soloUno
                                            ? null
                                            : (selected) {
                                                setState(() {
                                                  if (selected) {
                                                    _gradosSeleccionados
                                                        .add(grado.id);
                                                  } else {
                                                    _gradosSeleccionados
                                                        .remove(grado.id);
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
                          backgroundColor: const Color(0xFF059669),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              const Color(0xFF059669).withValues(alpha: 0.5),
                          elevation: 3,
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

    if (_alcanceAcotado) {
      _paraTodos = false;
      _gradosSeleccionados = _gradosSeleccionados
          .where((id) => _gradosPermitidos!.contains(id))
          .toList();
      if (_gradosSeleccionados.isEmpty) {
        _gradosSeleccionados = List<String>.from(_gradosPermitidos!);
      }
    } else if (!_puedeEnviarGeneral) {
      _paraTodos = false;
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

    if (_gradosPermitidos != null && _gradosPermitidos!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No tienes grupos asignados'),
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
          // Nunca ampliar alcance: maestra solo a sus grados.
          final paraTodosChat =
              _paraTodos && _puedeEnviarGeneral;
          final gradosChat = paraTodosChat
              ? <String>[]
              : (_gradosPermitidos == null
                  ? List<String>.from(_gradosSeleccionados)
                  : _gradosSeleccionados
                      .where(_gradosPermitidos!.contains)
                      .toList());
          if (!paraTodosChat && gradosChat.isEmpty) {
            throw Exception(
              'Sin grados destino para el chat. Revisa tus grupos asignados.',
            );
          }
          chatEnviados = await ChatService().enviarMensajeMasivoAPadres(
            remitenteId: usuario.id,
            contenido: ChatService.textoChatDesdeAnuncio(
              titulo: titulo,
              mensaje: mensaje,
              urgente: _urgente,
            ),
            paraTodos: paraTodosChat,
            gradoIds: gradosChat,
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
          _volverALista(refresco: true);
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
        _volverALista(refresco: true);
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
          'Esta acción no se puede deshacer. Se elimina del megáfono y, '
          'si también se mandó por chat, se borra de esos chats.',
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
      final titulo = _tituloController.text.trim();
      final mensaje = _mensajeController.text.trim();
      final chatBorrados = await ChatService().eliminarMensajesDeAnuncio(
        titulo: titulo,
        mensaje: mensaje,
        urgente: _urgente,
      );

      await Supabase.instance.client
          .from('anuncios')
          .delete()
          .eq('id', widget.anuncioId!);

      if (mounted) {
        final extra = chatBorrados > 0
            ? ' · También se quitó del chat ($chatBorrados)'
            : '';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Anuncio eliminado$extra'),
            backgroundColor: Colors.green,
          ),
        );
        _volverALista(refresco: true);
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
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _volverALista({bool refresco = false}) {
    if (!mounted) return;
    final router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop(refresco);
    } else {
      router.go('/directora/anuncios');
    }
  }
}
