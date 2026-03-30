import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/app_colors.dart';
import '../../services/auth_service.dart';

class CrearPadreScreen extends StatefulWidget {
  const CrearPadreScreen({super.key});

  @override
  State<CrearPadreScreen> createState() => _CrearPadreScreenState();
}

class _CrearPadreScreenState extends State<CrearPadreScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _apellidosController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _whatsappController = TextEditingController();
  
  bool _isLoading = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidosController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    _whatsappController.dispose();
    super.dispose();
  }

  Future<void> _guardarPadre() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final client = Supabase.instance.client;
      final prevId = client.auth.currentUser?.id;
      final prevRefresh = client.auth.currentSession?.refreshToken;
      if (prevId == null ||
          prevRefresh == null ||
          prevRefresh.isEmpty) {
        throw Exception(
          'Sesión inválida. Vuelve a iniciar sesión como directora.',
        );
      }

      final response = await client.auth.signUp(
        email: _emailController.text.trim(),
        password: 'Caipi2026',
      );

      if (response.user == null) {
        throw Exception('No se pudo crear el usuario');
      }

      await auth.restaurarSesionTrasSignUpDesdeDirectora(
        userIdAntes: prevId,
        refreshAntes: prevRefresh,
      );

      await client.from('usuarios').insert({
        'id': response.user!.id,
        'email': _emailController.text.trim(),
        'rol': 'padre',
        'nombre': '${_nombreController.text.trim()} ${_apellidosController.text.trim()}',
        'telefono': _telefonoController.text.trim().isEmpty 
            ? null 
            : _telefonoController.text.trim(),
        'whatsapp': _whatsappController.text.trim().isEmpty
            ? null
            : _whatsappController.text.trim(),
        'apellidos': _apellidosController.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '¡Padre creado! Contraseña inicial: Caipi2026. '
              'Puede cambiarla en Menú → Cambiar contraseña.',
            ),
            backgroundColor: AppColors.verde,
            duration: Duration(seconds: 5),
          ),
        );
        context.pop();
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
          'Nuevo Padre/Madre',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
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
                      colors: [AppColors.rosa, AppColors.naranja],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.family_restroom,
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
                  labelText: 'Nombre(s)',
                  prefixIcon: const Icon(Icons.person, color: AppColors.rosa),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (v) => v?.isEmpty ?? true ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),

              // Apellidos
              TextFormField(
                controller: _apellidosController,
                decoration: InputDecoration(
                  labelText: 'Apellidos',
                  prefixIcon: const Icon(Icons.person_outline, color: AppColors.rosa),
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
                  helperText: 'Se creará un usuario con password: Caipi2026',
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

              // WhatsApp
              TextFormField(
                controller: _whatsappController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'WhatsApp (opcional)',
                  prefixIcon: const Icon(Icons.message, color: AppColors.turquesa),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  helperText: 'Para enviar notificaciones',
                ),
              ),
              const SizedBox(height: 32),

              // Botón guardar
              Container(
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.rosa, AppColors.naranja],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.rosa.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _guardarPadre,
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
                          'Guardar Padre',
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
