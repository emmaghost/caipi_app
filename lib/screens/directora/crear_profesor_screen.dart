import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../services/auth_service.dart';
import '../../services/profesor_grupos_service.dart';
import '../../models/grado.dart';
import '../../config/app_colors.dart';
import '../../utils/constantes.dart';
import '../../widgets/caipi_app_bar_leading.dart';

class CrearProfesorScreen extends StatefulWidget {
  final String? profesorId;

  const CrearProfesorScreen({super.key, this.profesorId});

  @override
  State<CrearProfesorScreen> createState() => _CrearProfesorScreenState();
}

bool _esErrorRlsProfesores(Object e) {
  final t = e.toString().toLowerCase();
  return t.contains('profesores') &&
      (t.contains('42501') || t.contains('row-level security'));
}

class _CrearProfesorScreenState extends State<CrearProfesorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _gruposService = ProfesorGruposService();

  /// Multi-grupo (inglés / música / titular en varios).
  final Set<String> _gruposSeleccionados = {};
  /// 'profesor' | 'profesor_admin' | 'secretaria' | 'caja'
  String _rol = 'profesor';
  /// titular | ingles | musica
  String _especialidad = Constantes.especialidadTitular;
  bool _accesoActivo = true;
  bool _isLoading = false;
  List<Grado> _grados = [];
  /// Si editamos un usuario caja/secretaria sin fila en profesores.
  String? _usuarioIdSoloStaff;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    await _cargarGrados();
    
    // Si es edición, cargar datos del profesor
    if (widget.profesorId != null) {
      await _cargarProfesor(widget.profesorId!);
    }
  }

  Future<void> _cargarGrados() async {
    try {
      final response = await Supabase.instance.client
          .from('grados')
          .select()
          .eq('activo', true)
          .order('nombre');
      
      setState(() {
        _grados = response.map((json) => Grado.fromJson(json)).toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar grados: $e')),
        );
      }
    }
  }

  Future<void> _cargarProfesor(String profesorId) async {
    try {
      // Edición de caja/secretaria (sin fila profesores): id "usuario:<uuid>"
      if (profesorId.startsWith('usuario:')) {
        final uid = profesorId.substring('usuario:'.length);
        final u = await Supabase.instance.client
            .from('usuarios')
            .select()
            .eq('id', uid)
            .single();
        setState(() {
          _usuarioIdSoloStaff = uid;
          _nombreController.text = u['nombre'] ?? '';
          _emailController.text = u['email'] ?? '';
          _telefonoController.text = u['telefono'] ?? '';
          _rol = (u['rol'] as String?) ?? 'caja';
          _accesoActivo = (u['activo'] as bool?) ?? true;
        });
        return;
      }

      final response = await Supabase.instance.client
          .from('profesores')
          .select('*, usuarios!inner(*)')
          .eq('id', profesorId)
          .single();

      final usuarioData = response['usuarios'];
      final gradoIds = await _gruposService.gradoIdsDeProfesorRow(profesorId);

      setState(() {
        _nombreController.text = usuarioData['nombre'] ?? '';
        _emailController.text = usuarioData['email'] ?? '';
        _telefonoController.text = usuarioData['telefono'] ?? '';
        _gruposSeleccionados
          ..clear()
          ..addAll(gradoIds);
        if (_gruposSeleccionados.isEmpty && response['grado_id'] != null) {
          _gruposSeleccionados.add(response['grado_id'] as String);
        }
        final rol = usuarioData['rol'] as String? ?? 'profesor';
        if (rol == 'secretaria') {
          _rol = 'secretaria';
        } else if (rol == 'caja') {
          _rol = 'caja';
        } else if (rol == 'profesor_admin') {
          _rol = 'profesor_admin';
        } else {
          _rol = 'profesor';
        }
        final esp = (response['especialidad'] as String? ?? '').toLowerCase();
        if (esp.contains('ingles') || esp.contains('inglés')) {
          _especialidad = Constantes.especialidadIngles;
        } else if (esp.contains('musica') || esp.contains('música')) {
          _especialidad = Constantes.especialidadMusica;
        } else {
          _especialidad = Constantes.especialidadTitular;
        }
        _accesoActivo = (usuarioData['activo'] as bool?) ??
            (response['activo'] as bool? ?? true);
      });
    } catch (e) {
      print('Error cargando profesor: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  Future<void> _guardarProfesor() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final esEdicion = widget.profesorId != null;
      final client = Supabase.instance.client;
      final gradoIds = _gruposSeleccionados.toList();
      final gradoPrincipal = gradoIds.isEmpty ? null : gradoIds.first;

      if (esEdicion && _usuarioIdSoloStaff != null) {
        await client.from('usuarios').update({
          'nombre': _nombreController.text.trim(),
          'telefono': _telefonoController.text.trim().isEmpty
              ? null
              : _telefonoController.text.trim(),
          'rol': _rol,
          'activo': _accesoActivo,
        }).eq('id', _usuarioIdSoloStaff!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Usuario actualizado'),
              backgroundColor: AppColors.verde,
            ),
          );
          context.pop(true);
        }
        return;
      }

      if (esEdicion) {
        final profesorResponse = await client
            .from('profesores')
            .select('usuario_id')
            .eq('id', widget.profesorId!)
            .single();
        final usuarioId = profesorResponse['usuario_id'] as String;

        await client.from('usuarios').update({
          'nombre': _nombreController.text.trim(),
          'telefono': _telefonoController.text.trim().isEmpty
              ? null
              : _telefonoController.text.trim(),
          'rol': _rol,
          'activo': _accesoActivo,
        }).eq('id', usuarioId);

        await client.from('profesores').update({
          'grado_id': gradoPrincipal,
          'especialidad': _rol == 'profesor'
              ? _especialidad
              : Constantes.especialidadTitular,
          'activo': _accesoActivo,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', widget.profesorId!);

        try {
          await _gruposService.guardarGrados(
            profesorId: widget.profesorId!,
            gradoIds: gradoIds,
          );
        } catch (_) {}

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Docente actualizado'),
              backgroundColor: AppColors.verde,
            ),
          );
          context.pop(true);
        }
      } else {
        final auth = Provider.of<AuthService>(context, listen: false);
        final newUserId = await auth.crearUsuarioAuthComoStaff(
          email: _emailController.text.trim(),
          password: Constantes.passwordInicial,
          rol: _rol,
          nombre: _nombreController.text.trim(),
          telefono: _telefonoController.text.trim().isEmpty
              ? null
              : _telefonoController.text.trim(),
        );

        await client
            .from('usuarios')
            .update({'activo': _accesoActivo})
            .eq('id', newUserId);

        if (_rol == 'secretaria' || _rol == 'caja') {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  _rol == 'caja'
                      ? 'Usuario de caja creado. Pass: ${Constantes.passwordInicial}\nVe todos los grupos y pagos.'
                      : 'Secretaria creada. Pass: ${Constantes.passwordInicial}',
                  style: GoogleFonts.poppins(fontSize: 13),
                ),
                backgroundColor: AppColors.verde,
                duration: const Duration(seconds: 7),
              ),
            );
            context.pop(true);
          }
          return;
        }

        final profesorId = const Uuid().v4();
        try {
          await client.from('profesores').insert({
            'id': profesorId,
            'usuario_id': newUserId,
            'grado_id': gradoPrincipal,
            'especialidad': _rol == 'profesor'
                ? _especialidad
                : Constantes.especialidadTitular,
            'activo': _accesoActivo,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          }).setHeader('Prefer', 'return=minimal');
        } catch (e) {
          if (_esErrorRlsProfesores(e)) {
            final existe = await client
                .from('profesores')
                .select('id')
                .eq('usuario_id', newUserId)
                .maybeSingle();
            if (existe != null) {
              try {
                await _gruposService.guardarGrados(
                  profesorId: existe['id'] as String,
                  gradoIds: gradoIds,
                );
              } catch (_) {}
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Docente registrado'),
                    backgroundColor: AppColors.verde,
                  ),
                );
                context.pop(true);
              }
              return;
            }
          }
          rethrow;
        }

        try {
          await _gruposService.guardarGrados(
            profesorId: profesorId,
            gradoIds: gradoIds,
          );
        } catch (_) {}

        if (mounted) {
          final extra = gradoIds.length > 1
              ? 'Asignada a ${gradoIds.length} grupos.\n'
              : '';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Docente creado. Pass: ${Constantes.passwordInicial}\n$extra',
                style: GoogleFonts.poppins(fontSize: 13),
              ),
              backgroundColor: AppColors.verde,
              duration: const Duration(seconds: 6),
            ),
          );
          context.pop(true);
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.message}'),
            backgroundColor: AppColors.rojo,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.rojo,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grisClaro,
      appBar: AppBar(
        leading: const CaipiAppBarLeading(),
        title: Text(
          widget.profesorId == null ? 'Nuevo docente' : 'Editar docente',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => context.go('/directora'),
            tooltip: 'Ir al inicio',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Icono
              Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.purpura, AppColors.rosa],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Nombre
              TextFormField(
                controller: _nombreController,
                decoration: InputDecoration(
                  labelText: 'Nombre completo',
                  prefixIcon: const Icon(Icons.person, color: AppColors.purpura),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (v) => v?.isEmpty ?? true ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),

              // Email
              TextFormField(
                controller: _emailController,
                enabled: widget.profesorId == null,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email, color: AppColors.azul),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  helperText: widget.profesorId == null
                      ? 'Contraseña inicial: Caipi2026 (puede cambiarla después en el menú)'
                      : 'El correo no se puede cambiar aquí',
                ),
                validator: (v) {
                  if (v?.isEmpty ?? true) return 'Requerido';
                  if (!v!.contains('@')) return 'Email inválido';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              Text(
                'Tipo de acceso',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              RadioListTile<String>(
                contentPadding: EdgeInsets.zero,
                title: const Text('Docente'),
                subtitle: const Text(
                  'Titular del grupo o maestra de inglés/música (elige abajo)',
                ),
                value: 'profesor',
                groupValue: _rol,
                onChanged: (v) => setState(() {
                  _rol = v!;
                }),
              ),
              if (_rol == 'profesor')
                Padding(
                  padding: const EdgeInsets.only(left: 16, bottom: 8),
                  child: Column(
                    children: [
                      RadioListTile<String>(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        title: const Text('Grupo (titular)'),
                        subtitle: const Text(
                          'Puede haber otra de inglés/música en el mismo grupo',
                        ),
                        value: Constantes.especialidadTitular,
                        groupValue: _especialidad,
                        onChanged: (v) =>
                            setState(() => _especialidad = v!),
                      ),
                      RadioListTile<String>(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        title: const Text('Inglés / especial'),
                        subtitle: const Text(
                          'Puede tener varios grupos; ve chats y alumnos de esos grupos',
                        ),
                        value: Constantes.especialidadIngles,
                        groupValue: _especialidad,
                        onChanged: (v) =>
                            setState(() => _especialidad = v!),
                      ),
                      RadioListTile<String>(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        title: const Text('Música'),
                        subtitle: const Text(
                          'Igual: varios grupos, mismos menús que docente',
                        ),
                        value: Constantes.especialidadMusica,
                        groupValue: _especialidad,
                        onChanged: (v) =>
                            setState(() => _especialidad = v!),
                      ),
                    ],
                  ),
                ),
              RadioListTile<String>(
                contentPadding: EdgeInsets.zero,
                title: const Text('Docente admin'),
                subtitle: const Text(
                  'Como directora en casi todo, excepto pagos',
                ),
                value: 'profesor_admin',
                groupValue: _rol,
                onChanged: (v) => setState(() => _rol = v!),
              ),
              RadioListTile<String>(
                contentPadding: EdgeInsets.zero,
                title: const Text('Secretaria (altas en junta)'),
                subtitle: const Text(
                  'Solo registrar alumnos y papás. Sin beca, sin pagos.',
                ),
                value: 'secretaria',
                groupValue: _rol,
                onChanged: (v) => setState(() => _rol = v!),
              ),
              RadioListTile<String>(
                contentPadding: EdgeInsets.zero,
                title: const Text('Caja / Pagos'),
                subtitle: const Text(
                  'Solo administrar cobros y acreditar pagos. Sin alumnos.',
                ),
                value: 'caja',
                groupValue: _rol,
                onChanged: (v) => setState(() => _rol = v!),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Acceso activo'),
                subtitle: Text(
                  _accesoActivo
                      ? 'Puede iniciar sesión en la app'
                      : 'Sin acceso (no podrá entrar)',
                  style: GoogleFonts.poppins(fontSize: 12),
                ),
                value: _accesoActivo,
                activeColor: AppColors.verde,
                onChanged: (v) => setState(() => _accesoActivo = v),
              ),
              const SizedBox(height: 8),

              // Teléfono
              TextFormField(
                controller: _telefonoController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Teléfono (opcional)',
                  prefixIcon: const Icon(Icons.phone, color: AppColors.verde),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),

              if (_rol != 'secretaria' && _rol != 'caja') ...[
                Text(
                  'Grupos asignados (puede ser más de uno)',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _grados.map((g) {
                    final sel = _gruposSeleccionados.contains(g.id);
                    return FilterChip(
                      label: Text(g.nombre),
                      selected: sel,
                      onSelected: (v) {
                        setState(() {
                          if (v) {
                            _gruposSeleccionados.add(g.id);
                          } else {
                            _gruposSeleccionados.remove(g.id);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                if (_gruposSeleccionados.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'Sin grupo aún: puedes asignarlos después. '
                      'Inglés/música suele marcar varios.',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.gris,
                      ),
                    ),
                  ),
                const SizedBox(height: 32),
              ],

              // Botón guardar
              Container(
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.purpura, AppColors.rosa],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.purpura.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _guardarProfesor,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Guardar docente',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
