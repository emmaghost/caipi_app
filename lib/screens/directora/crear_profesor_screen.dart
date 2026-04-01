import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../services/auth_service.dart';
import '../../models/grado.dart';
import '../../config/app_colors.dart';

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
  
  String? _grupoSeleccionado;
  bool _isLoading = false;
  List<Grado> _grados = [];

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
      final response = await Supabase.instance.client
          .from('profesores')
          .select('*, usuarios!inner(*)')
          .eq('id', profesorId)
          .single();
      
      final usuarioData = response['usuarios'];
      
      setState(() {
        _nombreController.text = usuarioData['nombre'] ?? '';
        _emailController.text = usuarioData['email'] ?? '';
        _telefonoController.text = usuarioData['telefono'] ?? '';
        _grupoSeleccionado = response['grado_id'];  // Corregido: era 'grupo_asignado'
      });
    } catch (e) {
      print('Error cargando profesor: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar profesor: $e'),
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

      if (esEdicion) {
        // EDITAR profesor existente
        
        // 1. Obtener usuario_id del profesor
        final profesorResponse = await Supabase.instance.client
            .from('profesores')
            .select('usuario_id')
            .eq('id', widget.profesorId!)
            .single();
        
        final usuarioId = profesorResponse['usuario_id'] as String;

        // 2. Actualizar usuario
        await Supabase.instance.client
            .from('usuarios')
            .update({
              'nombre': _nombreController.text.trim(),
              'telefono': _telefonoController.text.trim().isEmpty 
                  ? null 
                  : _telefonoController.text.trim(),
            })
            .eq('id', usuarioId);

        // 3. Actualizar profesor
        await Supabase.instance.client
            .from('profesores')
            .update({
              'grado_id': _grupoSeleccionado,  // Corregido: era 'grupo_asignado'
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', widget.profesorId!);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Profesora actualizada exitosamente!'),
              backgroundColor: AppColors.verde,
            ),
          );
          context.pop(true);
        }
      } else {
        // CREAR profesor nuevo
        final auth = Provider.of<AuthService>(context, listen: false);
        final client = Supabase.instance.client;
        final prevId = client.auth.currentUser?.id;
        final prevRefresh = client.auth.currentSession?.refreshToken;
        if (prevId == null ||
            prevRefresh == null ||
            prevRefresh.isEmpty) {
          throw Exception(
            'Sesión inválida. Cierra sesión y vuelve a entrar como directora.',
          );
        }

        // 1. Auth: signUp puede dejar la sesión en la profesora nueva → fallan los INSERT
        final response = await client.auth.signUp(
          email: _emailController.text.trim(),
          password: 'Caipi2026', // Password temporal
        );

        if (response.user == null) {
          throw Exception('No se pudo crear el usuario');
        }

        await auth.restaurarSesionTrasSignUpDesdeDirectora(
          userIdAntes: prevId,
          refreshAntes: prevRefresh,
        );

        final newUserId = response.user!.id;

        // return=minimal evita que PostgREST devuelva la fila (a veces falla RLS al "leer" el RETURNING aunque el INSERT sí guardó).
        await client
            .from('usuarios')
            .insert({
              'id': newUserId,
              'email': _emailController.text.trim(),
              'rol': 'profesor',
              'nombre': _nombreController.text.trim(),
              'telefono': _telefonoController.text.trim().isEmpty
                  ? null
                  : _telefonoController.text.trim(),
            })
            .setHeader('Prefer', 'return=minimal');

        try {
          await client
              .from('profesores')
              .insert({
                'id': const Uuid().v4(),
                'usuario_id': newUserId,
                'grado_id': _grupoSeleccionado,
                'activo': true,
                'created_at': DateTime.now().toIso8601String(),
                'updated_at': DateTime.now().toIso8601String(),
              })
              .setHeader('Prefer', 'return=minimal');
        } catch (e) {
          if (_esErrorRlsProfesores(e)) {
            final existe = await client
                .from('profesores')
                .select('id')
                .eq('usuario_id', newUserId)
                .maybeSingle();
            if (existe != null) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '✅ Profesora registrada correctamente.\n'
                      '(La app mostró un aviso de permisos pero el alta quedó guardada.)',
                      style: GoogleFonts.poppins(fontSize: 13),
                    ),
                    backgroundColor: AppColors.verde,
                    duration: const Duration(seconds: 6),
                  ),
                );
                context.pop(true);
              }
              return;
            }
          }
          rethrow;
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '✅ Profesora creada. Contraseña inicial: Caipi2026\n'
                'Puede cambiarla en el menú → Cambiar contraseña.',
                style: GoogleFonts.poppins(fontSize: 13),
              ),
              backgroundColor: AppColors.verde,
              duration: const Duration(seconds: 7),
            ),
          );
          context.pop(true);
        }
      }
    } on AuthException catch (e) {
      // Manejo específico de errores de autenticación
      if (mounted) {
        String mensaje = '❌ Error al crear usuario';
        
        if (e.message.contains('already registered') || e.statusCode == '422') {
          mensaje = '❌ Este email ya está registrado.\nUsa otro email o elimina el usuario existente.';
        } else if (e.message.contains('invalid email')) {
          mensaje = '❌ El email no es válido';
        } else if (e.message.contains('password')) {
          mensaje = '❌ Error con la contraseña: ${e.message}';
        } else {
          mensaje = '❌ Error: ${e.message}';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensaje),
            backgroundColor: AppColors.rojo,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final t = e.toString().toLowerCase();
        String msg = '❌ $e';
        if (t.contains('duplicate') ||
            t.contains('unique') ||
            t.contains('23505')) {
          msg =
              '❌ Ese correo o usuario ya existe. Usa otro email o revisa en Supabase.';
        } else if (t.contains('profesores') &&
            (t.contains('row-level') || t.contains('42501'))) {
          msg =
              '❌ La base de datos no permite dar de alta profesoras (RLS).\n'
              'En Supabase → SQL Editor ejecuta el archivo:\n'
              'FIX_PROFESORES_RLS_INSERT.sql';
        } else if (t.contains('permission') ||
            t.contains('row-level') ||
            t.contains('rls') ||
            t.contains('42501')) {
          msg =
              '❌ Sin permiso (RLS). Si es tabla profesores, ejecuta FIX_PROFESORES_RLS_INSERT.sql en Supabase.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: AppColors.rojo,
            duration: const Duration(seconds: 7),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grisClaro,
      appBar: AppBar(
        title: Text(
          widget.profesorId == null ? 'Nueva Profesora' : 'Editar Profesora',
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
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email, color: AppColors.azul),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  helperText:
                      'Contraseña inicial: Caipi2026 (puede cambiarla después en el menú)',
                ),
                validator: (v) {
                  if (v?.isEmpty ?? true) return 'Requerido';
                  if (!v!.contains('@')) return 'Email inválido';
                  return null;
                },
              ),
              const SizedBox(height: 16),

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

              // Grupo asignado
              DropdownButtonFormField<String>(
                value: _grupoSeleccionado,
                decoration: InputDecoration(
                  labelText: 'Grupo a asignar',
                  prefixIcon: const Icon(Icons.school, color: AppColors.naranja),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  helperText: 'Puedes dejarlo sin grupo y asignarlo después',
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Sin grupo asignado'),
                  ),
                  ..._grados.map((grado) {
                    return DropdownMenuItem(
                      value: grado.id,
                      child: Text(grado.nombre),
                    );
                  }),
                ],
                onChanged: (value) {
                  setState(() => _grupoSeleccionado = value);
                },
              ),
              const SizedBox(height: 32),

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
                          'Guardar Profesora',
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
