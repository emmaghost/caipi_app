import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../services/auth_service.dart';
import '../../services/supabase_service.dart';
import '../../services/storage_service.dart';
import '../../models/alumno.dart';
import '../../models/grado.dart';
import '../../config/app_colors.dart';

class CrearAlumnoScreen extends StatefulWidget {
  final String? alumnoId;

  const CrearAlumnoScreen({super.key, this.alumnoId});

  @override
  State<CrearAlumnoScreen> createState() => _CrearAlumnoScreenState();
}

class _CrearAlumnoScreenState extends State<CrearAlumnoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _apellidosController = TextEditingController();
  final _padreEmailController = TextEditingController();
  final _alergiasController = TextEditingController();
  final _contactoEmergenciaController = TextEditingController();
  final _telefonoEmergenciaController = TextEditingController();
  // Dirección
  final _calleController = TextEditingController();
  final _coloniaController = TextEditingController();
  final _codigoPostalController = TextEditingController();
  // CURP y vacunas
  final _curpController = TextEditingController();
  final _vacunasFaltantesController = TextEditingController();
  
  DateTime? _fechaNacimiento;
  DateTime _fechaIngreso = DateTime.now(); // Fecha de ingreso (hoy por defecto)
  int _planPagos = 12; // Plan de pagos: 10 o 12 meses (12 por defecto)
  int _becaPorcentaje = 0; // Porcentaje de beca (0-100)
  bool _cartillaCompleta = true; // Cartilla de vacunas completa por defecto
  String? _gradoSeleccionado;
  String? _generoSeleccionado;
  File? _fotoSeleccionada;
  bool _isLoading = false;
  List<Grado> _grados = [];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    await _cargarGrados();
    
    // Si es edición, cargar datos del alumno
    if (widget.alumnoId != null) {
      await _cargarAlumno(widget.alumnoId!);
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
        if (_grados.isNotEmpty && widget.alumnoId == null) {
          _gradoSeleccionado = _grados[0].id;
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar grados: $e')),
        );
      }
    }
  }

  Future<void> _cargarAlumno(String alumnoId) async {
    try {
      final response = await Supabase.instance.client
          .from('alumnos')
          .select()
          .eq('id', alumnoId)
          .single();
      
      final alumno = Alumno.fromJson(response);
      
      setState(() {
        _nombreController.text = alumno.nombre;
        _apellidosController.text = alumno.apellidos;
        _fechaNacimiento = alumno.fechaNacimiento;
        _fechaIngreso = alumno.fechaIngreso;
        _planPagos = alumno.planPagos;
        _becaPorcentaje = alumno.becaPorcentaje;
        _gradoSeleccionado = alumno.gradoId;
        _generoSeleccionado = alumno.genero;
        _alergiasController.text = alumno.alergias ?? '';
        _contactoEmergenciaController.text = alumno.contactoEmergenciaNombre ?? '';
        _telefonoEmergenciaController.text = alumno.contactoEmergenciaTelefono ?? '';
        // Nuevos campos
        _calleController.text = alumno.calle ?? '';
        _coloniaController.text = alumno.colonia ?? '';
        _codigoPostalController.text = alumno.codigoPostal ?? '';
        _curpController.text = alumno.curp ?? '';
        _cartillaCompleta = alumno.cartillaCompleta;
        _vacunasFaltantesController.text = alumno.vacunasFaltantes ?? '';
      });

      // Cargar email del padre
      if (alumno.padreId != null) {
        final padreResponse = await Supabase.instance.client
            .from('usuarios')
            .select('email')
            .eq('id', alumno.padreId!)
            .single();
        
        setState(() {
          _padreEmailController.text = padreResponse['email'] ?? '';
        });
      }
    } catch (e) {
      print('Error cargando alumno: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar alumno: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidosController.dispose();
    _padreEmailController.dispose();
    _alergiasController.dispose();
    _contactoEmergenciaController.dispose();
    _telefonoEmergenciaController.dispose();
    _calleController.dispose();
    _coloniaController.dispose();
    _codigoPostalController.dispose();
    _curpController.dispose();
    _vacunasFaltantesController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: DateTime(2020),
      firstDate: DateTime(2015),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'MX'),
    );

    if (fecha != null) {
      setState(() {
        _fechaNacimiento = fecha;
      });
    }
  }

  Future<void> _guardarAlumno() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fechaNacimiento == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona la fecha de nacimiento')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final supabaseService = context.read<SupabaseService>();
      final storageService = context.read<StorageService>();

      // 1. Buscar padre por email
      String? padreId;
      final padreResponse = await Supabase.instance.client
          .from('usuarios')
          .select('id')
          .eq('email', _padreEmailController.text.trim())
          .eq('rol', 'padre')
          .maybeSingle();
      
      if (padreResponse != null) {
        padreId = padreResponse['id'] as String;
      } else {
        // Padre no existe, preguntar si crear uno nuevo
        if (mounted) {
          padreId = await _mostrarDialogoCrearPadre();
          if (padreId == null) {
            setState(() => _isLoading = false);
            return;
          }
        }
      }

      // 2. Determinar si es creación o edición
      final esEdicion = widget.alumnoId != null;
      final alumnoId = esEdicion ? widget.alumnoId! : const Uuid().v4();

      // 3. Subir foto si existe
      String? fotoUrl;
      if (_fotoSeleccionada != null) {
        fotoUrl = await storageService.subirFotoAlumno(_fotoSeleccionada!, alumnoId);
      }

      // 4. Crear o actualizar alumno
      if (esEdicion) {
        // ACTUALIZAR alumno existente
        final alumnoData = {
          'nombre': _nombreController.text.trim(),
          'apellidos': _apellidosController.text.trim(),
          'fecha_nacimiento': _fechaNacimiento!.toIso8601String(),
          'genero': _generoSeleccionado,
          'grado_id': _gradoSeleccionado,
          'padre_id': padreId ?? 'sin-padre',
          'alergias': _alergiasController.text.trim().isEmpty 
              ? null 
              : _alergiasController.text.trim(),
          'contacto_emergencia_nombre': _contactoEmergenciaController.text.trim().isEmpty
              ? null
              : _contactoEmergenciaController.text.trim(),
          'contacto_emergencia_telefono': _telefonoEmergenciaController.text.trim().isEmpty
              ? null
              : _telefonoEmergenciaController.text.trim(),
          // Dirección
          'calle': _calleController.text.trim().isEmpty ? null : _calleController.text.trim(),
          'colonia': _coloniaController.text.trim().isEmpty ? null : _coloniaController.text.trim(),
          'codigo_postal': _codigoPostalController.text.trim().isEmpty ? null : _codigoPostalController.text.trim(),
          // CURP y vacunas
          'curp': _curpController.text.trim().isEmpty ? null : _curpController.text.trim().toUpperCase(),
          'cartilla_completa': _cartillaCompleta,
          'vacunas_faltantes': _vacunasFaltantesController.text.trim().isEmpty 
              ? null 
              : _vacunasFaltantesController.text.trim(),
          // Planes y becas
          'plan_pagos': _planPagos,
          'fecha_ingreso': _fechaIngreso.toIso8601String().split('T')[0],
          'beca_porcentaje': _becaPorcentaje,
          'updated_at': DateTime.now().toIso8601String(),
        };

        if (fotoUrl != null) {
          alumnoData['foto_url'] = fotoUrl;
        }

        await Supabase.instance.client
            .from('alumnos')
            .update(alumnoData)
            .eq('id', alumnoId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Alumno actualizado exitosamente!'),
              backgroundColor: AppColors.verde,
            ),
          );
          context.pop();
        }
      } else {
        // CREAR alumno nuevo
        final alumno = Alumno(
          id: alumnoId,
          nombre: _nombreController.text.trim(),
          apellidos: _apellidosController.text.trim(),
          fechaNacimiento: _fechaNacimiento!,
          genero: _generoSeleccionado,
          gradoId: _gradoSeleccionado,
          padreId: padreId ?? 'sin-padre',
          fotoUrl: fotoUrl,
          fotoDefaultGenero: _generoSeleccionado == 'niña' ? 'nina' : 'nino',
          alergias: _alergiasController.text.trim().isEmpty 
              ? null 
              : _alergiasController.text.trim(),
          contactoEmergenciaNombre: _contactoEmergenciaController.text.trim().isEmpty
              ? null
              : _contactoEmergenciaController.text.trim(),
          contactoEmergenciaTelefono: _telefonoEmergenciaController.text.trim().isEmpty
              ? null
              : _telefonoEmergenciaController.text.trim(),
          // Dirección
          calle: _calleController.text.trim().isEmpty ? null : _calleController.text.trim(),
          colonia: _coloniaController.text.trim().isEmpty ? null : _coloniaController.text.trim(),
          codigoPostal: _codigoPostalController.text.trim().isEmpty ? null : _codigoPostalController.text.trim(),
          // CURP y vacunas
          curp: _curpController.text.trim().isEmpty ? null : _curpController.text.trim().toUpperCase(),
          cartillaCompleta: _cartillaCompleta,
          vacunasFaltantes: _vacunasFaltantesController.text.trim().isEmpty 
              ? null 
              : _vacunasFaltantesController.text.trim(),
          // Planes y becas
          planPagos: _planPagos,
          fechaIngreso: _fechaIngreso,
          becaPorcentaje: _becaPorcentaje,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await supabaseService.crearAlumno(alumno);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Alumno creado exitosamente!'),
              backgroundColor: AppColors.verde,
            ),
          );
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
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

  Future<String?> _mostrarDialogoCrearPadre() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Padre no encontrado'),
        content: Text(
          'El correo ${_padreEmailController.text} no está registrado.\n\n'
          '¿Deseas crear un usuario padre con este correo?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, null),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final client = Supabase.instance.client;
                final prevId = client.auth.currentUser?.id;
                final prevRefresh = client.auth.currentSession?.refreshToken;
                if (prevId == null ||
                    prevRefresh == null ||
                    prevRefresh.isEmpty) {
                  throw Exception('Sesión inválida');
                }
                final response = await client.auth.signUp(
                  email: _padreEmailController.text.trim(),
                  password: 'Caipi2026',
                );
                if (response.user == null) {
                  throw Exception('No se pudo crear el usuario');
                }
                await authService.restaurarSesionTrasSignUpDesdeDirectora(
                  userIdAntes: prevId,
                  refreshAntes: prevRefresh,
                );
                await client
                    .from('usuarios')
                    .insert({
                      'id': response.user!.id,
                      'email': _padreEmailController.text.trim(),
                      'rol': 'padre',
                      'nombre': 'Padre de ${_nombreController.text}',
                    })
                    .setHeader('Prefer', 'return=minimal');
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext, response.user!.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Padre creado. Contraseña: Caipi2026. Puede cambiarla en el menú.',
                      ),
                      duration: Duration(seconds: 5),
                    ),
                  );
                }
              } catch (e) {
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext, null);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Crear Padre'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grisClaro,
      appBar: AppBar(
        title: Text(
          widget.alumnoId == null ? 'Nuevo Alumno' : 'Editar Alumno',
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
      body: _grados.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Foto del alumno
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          // TODO: Seleccionar foto
                        },
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: AppColors.grisClaro,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.rosa, width: 3),
                          ),
                          child: _fotoSeleccionada != null
                              ? ClipOval(
                                  child: Image.file(_fotoSeleccionada!, fit: BoxFit.cover),
                                )
                              : const Icon(Icons.camera_alt, size: 40, color: AppColors.gris),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Nombre
                    TextFormField(
                      controller: _nombreController,
                      decoration: InputDecoration(
                        labelText: 'Nombre(s)',
                        prefixIcon: const Icon(Icons.person, color: AppColors.rosa),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
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
                      ),
                      validator: (v) => v?.isEmpty ?? true ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 16),

                    // Género
                    DropdownButtonFormField<String>(
                      value: _generoSeleccionado,
                      decoration: InputDecoration(
                        labelText: 'Género',
                        prefixIcon: const Icon(Icons.wc, color: AppColors.purpura),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'niño', child: Text('Niño')),
                        DropdownMenuItem(value: 'niña', child: Text('Niña')),
                      ],
                      onChanged: (value) {
                        setState(() => _generoSeleccionado = value);
                      },
                      validator: (v) => v == null ? 'Selecciona el género' : null,
                    ),
                    const SizedBox(height: 16),

                    // Fecha de nacimiento
                    InkWell(
                      onTap: _seleccionarFecha,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Fecha de nacimiento',
                          prefixIcon: const Icon(Icons.cake, color: AppColors.naranja),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          _fechaNacimiento != null
                              ? DateFormat('dd/MM/yyyy').format(_fechaNacimiento!)
                              : 'Seleccionar fecha',
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Grado
                    DropdownButtonFormField<String>(
                      value: _gradoSeleccionado,
                      decoration: InputDecoration(
                        labelText: 'Grado',
                        prefixIcon: const Icon(Icons.school, color: AppColors.azul),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      items: _grados.map((grado) {
                        return DropdownMenuItem(
                          value: grado.id,
                          child: Text(grado.nombre),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _gradoSeleccionado = value);
                      },
                      validator: (v) => v == null ? 'Selecciona el grado' : null,
                    ),
                    const SizedBox(height: 16),

                    // Fecha de ingreso
                    InkWell(
                      onTap: () async {
                        final fecha = await showDatePicker(
                          context: context,
                          initialDate: _fechaIngreso,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                          locale: const Locale('es', 'MX'),
                        );
                        if (fecha != null) {
                          setState(() => _fechaIngreso = fecha);
                        }
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Fecha de ingreso',
                          prefixIcon: const Icon(Icons.calendar_today, color: AppColors.morado),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          DateFormat('dd/MM/yyyy').format(_fechaIngreso),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Plan de pagos
                    DropdownButtonFormField<int>(
                      value: _planPagos,
                      decoration: InputDecoration(
                        labelText: 'Plan de Pagos',
                        prefixIcon: const Icon(Icons.payments, color: AppColors.naranja),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        helperText: 'Selecciona entre 10 o 12 mensualidades',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 12,
                          child: Text('12 meses (Agosto - Julio)'),
                        ),
                        DropdownMenuItem(
                          value: 10,
                          child: Text('10 meses (Agosto - Mayo)'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _planPagos = value);
                        }
                      },
                      validator: (v) => v == null ? 'Selecciona el plan' : null,
                    ),
                    const SizedBox(height: 16),

                    // Beca (porcentaje de descuento)
                    DropdownButtonFormField<int>(
                      value: _becaPorcentaje,
                      decoration: InputDecoration(
                        labelText: 'Beca / Descuento',
                        prefixIcon: Icon(Icons.school, color: _becaPorcentaje > 0 ? AppColors.verde : AppColors.gris),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        helperText: _becaPorcentaje > 0 
                            ? '✅ Alumno con beca del $_becaPorcentaje%'
                            : 'Selecciona si el alumno tiene beca',
                      ),
                      items: [
                        const DropdownMenuItem(value: 0, child: Text('Sin beca (0%)')),
                        for (int i = 10; i <= 100; i += 10)
                          DropdownMenuItem(
                            value: i,
                            child: Text('$i% de descuento'),
                          ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _becaPorcentaje = value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Email del padre
                    TextFormField(
                      controller: _padreEmailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email del padre/madre',
                        prefixIcon: const Icon(Icons.email, color: AppColors.verde),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        helperText: 'Se buscará o creará un usuario padre',
                      ),
                      validator: (v) {
                        if (v?.isEmpty ?? true) return 'Requerido';
                        if (!v!.contains('@')) return 'Email inválido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Alergias
                    TextFormField(
                      controller: _alergiasController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Alergias (opcional)',
                        prefixIcon: const Icon(Icons.warning_amber, color: AppColors.amarillo),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Contacto de emergencia
                    TextFormField(
                      controller: _contactoEmergenciaController,
                      decoration: InputDecoration(
                        labelText: 'Contacto de emergencia (opcional)',
                        prefixIcon: const Icon(Icons.contact_phone, color: AppColors.turquesa),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Teléfono de emergencia
                    TextFormField(
                      controller: _telefonoEmergenciaController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Teléfono de emergencia (opcional)',
                        prefixIcon: const Icon(Icons.phone, color: AppColors.turquesa),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // SECCIÓN: DIRECCIÓN
                    Text(
                      '📍 Dirección del Alumno',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.negro,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Calle y número
                    TextFormField(
                      controller: _calleController,
                      decoration: InputDecoration(
                        labelText: 'Calle y número (opcional)',
                        prefixIcon: const Icon(Icons.home, color: AppColors.azul),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        hintText: 'Ej: Av. Juárez 123',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Colonia
                    TextFormField(
                      controller: _coloniaController,
                      decoration: InputDecoration(
                        labelText: 'Colonia (opcional)',
                        prefixIcon: const Icon(Icons.location_city, color: AppColors.azul),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Código Postal
                    TextFormField(
                      controller: _codigoPostalController,
                      keyboardType: TextInputType.number,
                      maxLength: 5,
                      decoration: InputDecoration(
                        labelText: 'Código Postal (opcional)',
                        prefixIcon: const Icon(Icons.pin_drop, color: AppColors.azul),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        counterText: '',
                      ),
                    ),
                    const SizedBox(height: 24),

                    // SECCIÓN: CURP
                    Text(
                      '🆔 CURP y Vacunas',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.negro,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // CURP
                    TextFormField(
                      controller: _curpController,
                      maxLength: 18,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        labelText: 'CURP (opcional)',
                        prefixIcon: const Icon(Icons.badge, color: AppColors.purpura),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        hintText: 'Ej: XXXX000000XXXXXX00',
                        counterText: '',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Cartilla de vacunas completa
                    SwitchListTile(
                      title: Text(
                        'Cartilla de vacunas completa',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        _cartillaCompleta 
                            ? '✅ Todas las vacunas al día'
                            : '⚠️ Faltan vacunas',
                        style: TextStyle(
                          color: _cartillaCompleta ? AppColors.verde : AppColors.naranja,
                        ),
                      ),
                      value: _cartillaCompleta,
                      activeColor: AppColors.verde,
                      onChanged: (value) {
                        setState(() => _cartillaCompleta = value);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Vacunas faltantes (solo si cartilla NO completa)
                    if (!_cartillaCompleta) ...[
                      TextFormField(
                        controller: _vacunasFaltantesController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Vacunas faltantes',
                          prefixIcon: const Icon(Icons.medical_services, color: AppColors.rojo),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          hintText: 'Ej: BCG, Hepatitis B, Triple viral...',
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

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
                        onPressed: _isLoading ? null : _guardarAlumno,
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
                                'Guardar Alumno',
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
