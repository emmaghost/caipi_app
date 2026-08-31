import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../utils/constantes.dart';

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
  final _padre2EmailController = TextEditingController();
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
  int _planPagos = 12; // Plan kínder/maternal: 10, 11 o 12
  String? _planEstimulacion; // sesion | paquete_4 | paquete_6 | paquete_8
  int _becaPorcentaje = 0; // Porcentaje de beca (0-100)
  bool _cartillaCompleta = true; // Cartilla de vacunas completa por defecto
  String? _gradoSeleccionado;
  String? _generoSeleccionado;
  File? _fotoSeleccionada;
  bool _isLoading = false;
  List<Grado> _grados = [];

  Grado? get _gradoSeleccionadoObj {
    if (_gradoSeleccionado == null) return null;
    for (final g in _grados) {
      if (g.id == _gradoSeleccionado) return g;
    }
    return null;
  }

  bool get _esKinderSeleccionado => _gradoSeleccionadoObj?.esKinder ?? false;

  /// Sin grado o no-kínder (maternal / estimulación): cobro por clase.
  bool get _esCobroPorClase =>
      _gradoSeleccionado == null ||
      (_gradoSeleccionadoObj?.cobroPorClase ?? true);

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
        // Grado en blanco al alta: la maestra lo asigna despues.
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
          .maybeSingle();

      // El alumno ya fue eliminado (p. ej. tarjeta vieja en la lista):
      // avisar y volver para que la lista se refresque.
      if (response == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Este alumno ya fue eliminado. Actualizando lista…'),
              backgroundColor: Colors.orange,
            ),
          );
          context.pop();
        }
        return;
      }

      final alumno = Alumno.fromJson(response);
      
      setState(() {
        _nombreController.text = alumno.nombre;
        _apellidosController.text = alumno.apellidos;
        _fechaNacimiento = alumno.fechaNacimiento;
        _fechaIngreso = alumno.fechaIngreso;
        _planPagos = alumno.planPagos;
        _planEstimulacion = alumno.planEstimulacion;
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

      if (!mounted) return;
      // Cargar emails de papá/mamá (hasta 2)
      final emailsPadres =
          await context.read<SupabaseService>().emailsPadresDeAlumno(alumnoId);
      if (mounted) {
        setState(() {
          if (emailsPadres.isNotEmpty) {
            _padreEmailController.text = emailsPadres[0];
          }
          if (emailsPadres.length > 1) {
            _padre2EmailController.text = emailsPadres[1];
          }
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
    _padre2EmailController.dispose();
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

    final auth = context.read<AuthService>();
    if (!(auth.currentUser?.puedeEditarAlumnos ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Solo directora o profesora supervisora pueden crear/editar alumnos.',
          ),
          backgroundColor: AppColors.rojo,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final supabaseService = context.read<SupabaseService>();
      final storageService = context.read<StorageService>();

      // Papás opcionales (hasta 2, cada uno con su cuenta)
      final padreIds = <String>[];
      for (final email in [
        _padreEmailController.text.trim(),
        _padre2EmailController.text.trim(),
      ]) {
        if (email.isEmpty) continue;
        if (!mounted) {
          setState(() => _isLoading = false);
          return;
        }
        final id = await _resolverPadreId(email);
        if (email.isNotEmpty && id == null) {
          setState(() => _isLoading = false);
          return;
        }
        if (id != null && !padreIds.contains(id)) padreIds.add(id);
      }
      final padreId = padreIds.isEmpty ? null : padreIds.first;

      final esEdicion = widget.alumnoId != null;
      final alumnoId = esEdicion ? widget.alumnoId! : const Uuid().v4();

      String? fotoUrl;
      if (_fotoSeleccionada != null) {
        fotoUrl = await storageService.subirFotoAlumno(_fotoSeleccionada!, alumnoId);
      }

      final fechaNac = _fechaNacimiento ?? DateTime(2018, 1, 1);
      final incompleto = _fechaNacimiento == null ||
          _generoSeleccionado == null ||
          padreId == null ||
          _gradoSeleccionado == null ||
          _contactoEmergenciaController.text.trim().isEmpty;

      if (esEdicion) {
        final alumnoData = <String, dynamic>{
          'nombre': _nombreController.text.trim(),
          'apellidos': _apellidosController.text.trim(),
          'fecha_nacimiento': fechaNac.toIso8601String().split('T')[0],
          'genero': _generoSeleccionado,
          'grado_id': _gradoSeleccionado,
          'padre_id': padreId,
          'alergias': _alergiasController.text.trim().isEmpty
              ? null
              : _alergiasController.text.trim(),
          'contacto_emergencia_nombre':
              _contactoEmergenciaController.text.trim().isEmpty
                  ? null
                  : _contactoEmergenciaController.text.trim(),
          'contacto_emergencia_telefono':
              _telefonoEmergenciaController.text.trim().isEmpty
                  ? null
                  : _telefonoEmergenciaController.text.trim(),
          'calle': _calleController.text.trim().isEmpty
              ? null
              : _calleController.text.trim(),
          'colonia': _coloniaController.text.trim().isEmpty
              ? null
              : _coloniaController.text.trim(),
          'codigo_postal': _codigoPostalController.text.trim().isEmpty
              ? null
              : _codigoPostalController.text.trim(),
          'curp': _curpController.text.trim().isEmpty
              ? null
              : _curpController.text.trim().toUpperCase(),
          'cartilla_completa': _cartillaCompleta,
          'vacunas_faltantes': _vacunasFaltantesController.text.trim().isEmpty
              ? null
              : _vacunasFaltantesController.text.trim(),
          'plan_pagos': _planPagos,
          'plan_estimulacion': null,
          'fecha_ingreso': _fechaIngreso.toIso8601String().split('T')[0],
          'registro_incompleto': incompleto,
          'updated_at': DateTime.now().toIso8601String(),
        };

        if (auth.currentUser?.esDirectora ?? false) {
          alumnoData['beca_porcentaje'] = _becaPorcentaje;
        }

        if (fotoUrl != null) {
          alumnoData['foto_url'] = fotoUrl;
        }

        await Supabase.instance.client
            .from('alumnos')
            .update(alumnoData)
            .eq('id', alumnoId);
        await supabaseService.guardarPadresAlumno(alumnoId, padreIds);
        supabaseService.avisarAlumnosCambiaron();

        final alumnoEditado = Alumno(
          id: alumnoId,
          nombre: _nombreController.text.trim(),
          apellidos: _apellidosController.text.trim(),
          fechaNacimiento: fechaNac,
          genero: _generoSeleccionado,
          gradoId: _gradoSeleccionado,
          padreId: padreId,
          planPagos: _planPagos,
          planEstimulacion: null,
          fechaIngreso: _fechaIngreso,
          becaPorcentaje: _becaPorcentaje,
          registroIncompleto: incompleto,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        final avisoPagos =
            await supabaseService.sincronizarPagosTrasEditarAlumno(alumnoEditado);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                [
                  incompleto
                      ? '✅ Alumno actualizado (aún faltan datos por completar)'
                      : '✅ Alumno actualizado exitosamente!',
                  if (avisoPagos != null) avisoPagos,
                ].join('\n'),
              ),
              backgroundColor: AppColors.verde,
              duration: Duration(seconds: avisoPagos != null ? 6 : 3),
            ),
          );
          context.pop(true);
        }
      } else {
        final alumno = Alumno(
          id: alumnoId,
          nombre: _nombreController.text.trim(),
          apellidos: _apellidosController.text.trim(),
          fechaNacimiento: fechaNac,
          genero: _generoSeleccionado,
          gradoId: _gradoSeleccionado,
          padreId: padreId,
          fotoUrl: fotoUrl,
          fotoDefaultGenero: _generoSeleccionado == 'niña' ? 'nina' : 'nino',
          alergias: _alergiasController.text.trim().isEmpty
              ? null
              : _alergiasController.text.trim(),
          contactoEmergenciaNombre:
              _contactoEmergenciaController.text.trim().isEmpty
                  ? null
                  : _contactoEmergenciaController.text.trim(),
          contactoEmergenciaTelefono:
              _telefonoEmergenciaController.text.trim().isEmpty
                  ? null
                  : _telefonoEmergenciaController.text.trim(),
          calle: _calleController.text.trim().isEmpty
              ? null
              : _calleController.text.trim(),
          colonia: _coloniaController.text.trim().isEmpty
              ? null
              : _coloniaController.text.trim(),
          codigoPostal: _codigoPostalController.text.trim().isEmpty
              ? null
              : _codigoPostalController.text.trim(),
          curp: _curpController.text.trim().isEmpty
              ? null
              : _curpController.text.trim().toUpperCase(),
          cartillaCompleta: _cartillaCompleta,
          vacunasFaltantes: _vacunasFaltantesController.text.trim().isEmpty
              ? null
              : _vacunasFaltantesController.text.trim(),
          planPagos: _planPagos,
          planEstimulacion: null,
          fechaIngreso: _fechaIngreso,
          becaPorcentaje: _becaPorcentaje,
          registroIncompleto: incompleto,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await supabaseService.crearAlumno(
          alumno,
          verificarDuplicado: _fechaNacimiento != null,
        );
        await supabaseService.guardarPadresAlumno(alumnoId, padreIds);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                incompleto
                    ? '✅ Alumno creado (registro rápido). Completa datos después.'
                    : '✅ Alumno creado exitosamente!',
              ),
              backgroundColor: AppColors.verde,
            ),
          );
          // Ir a la lista ya refrescada (no solo pop: si vinieron del dashboard no se actualizaba).
          context.go('/directora/alumnos');
        }
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString();
        String amigable = msg;
        if (msg.contains('registro_incompleto')) {
          amigable =
              'Falta ejecutar el SQL de alta rápida (columna registro_incompleto).';
        } else if (msg.contains('plan_pagos') || msg.contains('check')) {
          amigable =
              'El plan de pagos no es válido en la BD. Ejecuta ADD_PLAN_11_Y_CUADRO_COLEGIATURAS.sql';
        } else if (msg.contains('JWT') || msg.contains('sesión')) {
          amigable =
              'Se perdió la sesión al crear el padre. Vuelve a iniciar sesión e intenta de nuevo.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $amigable'),
            backgroundColor: AppColors.rojo,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _confirmarEliminarAlumno() async {
    final alumnoId = widget.alumnoId;
    if (alumnoId == null || _isLoading) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Eliminar alumno?'),
        content: Text(
          'Se eliminará permanentemente a '
          '${_nombreController.text.trim()} ${_apellidosController.text.trim()} '
          'junto con sus pagos, abonos y registros relacionados.\n\n'
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.rojo),
            icon: const Icon(Icons.delete_forever),
            label: const Text('Eliminar definitivamente'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;
    setState(() => _isLoading = true);
    try {
      await context
          .read<SupabaseService>()
          .eliminarAlumnoDefinitivamente(alumnoId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Alumno y datos relacionados eliminados'),
          backgroundColor: AppColors.verde,
        ),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo eliminar el alumno: $e'),
          backgroundColor: AppColors.rojo,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<String?> _resolverPadreId(String emailRaw) async {
    final email = emailRaw.trim().toLowerCase();
    if (email.isEmpty || !email.contains('@')) return null;

    final padreResponse = await Supabase.instance.client
        .from('usuarios')
        .select('id')
        .eq('email', email)
        .eq('rol', 'padre')
        .maybeSingle();
    if (padreResponse != null) {
      return padreResponse['id'] as String;
    }
    if (!mounted) return null;
    return _mostrarDialogoCrearPadre(email);
  }

  Future<String?> _mostrarDialogoCrearPadre(String email) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Padre no encontrado'),
        content: Text(
          'El correo $email no está registrado.\n\n'
          '¿Deseas crear un usuario padre con este correo?\n'
          'Contraseña inicial: Caipi2026',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, null),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final id = await authService.crearUsuarioAuthComoStaff(
                  email: email,
                  password: 'Caipi2026',
                  rol: 'padre',
                  nombre: 'Padre de ${_nombreController.text.trim()}',
                );
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext, id);
                }
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Padre creado. Contraseña: Caipi2026. Puede cambiarla en el menú.',
                      ),
                      duration: Duration(seconds: 5),
                      backgroundColor: AppColors.verde,
                    ),
                  );
                }
              } catch (e) {
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext, null);
                }
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al crear padre: $e'),
                      backgroundColor: AppColors.rojo,
                    ),
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
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.naranja.withOpacity(0.4),
                        ),
                      ),
                      child: Text(
                        'Alta rápida: solo nombre y apellidos son obligatorios. '
                        'Grado puede quedar sin asignar. '
                        'Kínder = colegiaturas 10/11/12. Maternal = cobro por clase (sin colegiaturas auto).',
                        style: GoogleFonts.poppins(fontSize: 12),
                      ),
                    ),
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
                    ),
                    const SizedBox(height: 16),

                    // Fecha de nacimiento
                    InkWell(
                      onTap: _seleccionarFecha,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Fecha de nacimiento (opcional)',
                          prefixIcon: const Icon(Icons.cake, color: AppColors.naranja),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          helperText: 'Puedes completarla después',
                        ),
                        child: Text(
                          _fechaNacimiento != null
                              ? DateFormat('dd/MM/yyyy').format(_fechaNacimiento!)
                              : 'Seleccionar fecha',
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Grado (opcional al alta)
                    DropdownButtonFormField<String?>(
                      value: _gradoSeleccionado,
                      decoration: InputDecoration(
                        labelText: 'Grado (opcional)',
                        prefixIcon: const Icon(Icons.school, color: AppColors.azul),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        helperText: 'Puede quedar en blanco; la maestra lo asigna después',
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Sin asignar'),
                        ),
                        ..._grados
                            .where((grado) =>
                                !grado.esEstimulacion ||
                                grado.id == _gradoSeleccionado)
                            .map((grado) {
                          return DropdownMenuItem<String?>(
                            value: grado.id,
                            child: Text(grado.nombre),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _gradoSeleccionado = value;
                          _planEstimulacion = null;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Plan de pagos según tipo de grado
                    if (_esKinderSeleccionado)
                      DropdownButtonFormField<int>(
                        value: _planPagos,
                        decoration: InputDecoration(
                          labelText: 'Plan de Pagos (kínder)',
                          prefixIcon: const Icon(Icons.payments, color: AppColors.naranja),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          helperText: '10, 11 o 12 mensualidades (sí genera colegiaturas)',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 12,
                            child: Text('12 meses (Agosto - Julio)'),
                          ),
                          DropdownMenuItem(
                            value: 11,
                            child: Text('11 meses (Agosto - Junio)'),
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
                      )
                    else
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7ED),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.naranja.withValues(alpha: 0.45),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.info_outline, color: AppColors.naranja),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _gradoSeleccionado == null
                                        ? 'Sin grado: cobro por clase'
                                        : 'Maternal / por clase',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _gradoSeleccionado == null
                                  ? 'Asigna el grado para definir el plan. Mientras tanto no se generan colegiaturas automáticas.'
                                  : 'Este grado se cobra por clase. No se generan costos automáticos; los cargos se agregan manualmente en Pagos.',
                              style: GoogleFonts.poppins(fontSize: 12, height: 1.35),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),

                    if (Constantes.mostrarCampoBeca &&
                        (context.read<AuthService>().currentUser?.esDirectora ??
                            false)) ...[
                      DropdownButtonFormField<int>(
                        value: _becaPorcentaje,
                        decoration: InputDecoration(
                          labelText: 'Beca / Descuento',
                          prefixIcon: Icon(
                            Icons.school,
                            color: _becaPorcentaje > 0
                                ? AppColors.verde
                                : AppColors.gris,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          helperText: _becaPorcentaje > 0
                              ? 'Alumno con beca del $_becaPorcentaje%'
                              : 'Solo lo asigna la directora',
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: 0,
                            child: Text('Sin beca (0%)'),
                          ),
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
                    ],

                    // Emails de papá/mamá (hasta 2 cuentas)
                    TextFormField(
                      controller: _padreEmailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email papá/mamá 1 (opcional)',
                        prefixIcon: const Icon(Icons.email, color: AppColors.verde),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        helperText: 'Cualquier Gmail/Hotmail. Contraseña inicial: Caipi2026',
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        final t = v.trim();
                        if (t.contains(' ')) {
                          return 'Quita espacios del correo (ej. sin espacio antes de @)';
                        }
                        if (!t.contains('@')) return 'Email inválido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _padre2EmailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email papá/mamá 2 (opcional)',
                        prefixIcon: const Icon(Icons.email_outlined, color: AppColors.azul),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        helperText: 'Otro tutor del mismo niño, con su propio acceso',
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        final t = v.trim();
                        if (t.contains(' ')) {
                          return 'Quita espacios del correo (ej. sin espacio antes de @)';
                        }
                        if (!t.contains('@')) return 'Email inválido';
                        final uno = _padreEmailController.text.trim().toLowerCase();
                        if (uno.isNotEmpty && t.toLowerCase() == uno) {
                          return 'Usa un correo distinto al del papá/mamá 1';
                        }
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

                    // CURP (18 caracteres). Sin textCapitalization.characters:
                    // en Android el teclado a menudo corta el texto a la mitad.
                    TextFormField(
                      controller: _curpController,
                      maxLength: 18,
                      keyboardType: TextInputType.visiblePassword,
                      autocorrect: false,
                      enableSuggestions: false,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                        TextInputFormatter.withFunction((oldValue, newValue) {
                          return newValue.copyWith(
                            text: newValue.text.toUpperCase(),
                          );
                        }),
                      ],
                      decoration: InputDecoration(
                        labelText: 'CURP (opcional)',
                        prefixIcon: const Icon(Icons.badge, color: AppColors.purpura),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        hintText: '18 caracteres, ej: GAGA850101HDFRRN09',
                        helperText: 'Deben caber los 18. Se guarda en mayúsculas.',
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
                    if (widget.alumnoId != null &&
                        (context.read<AuthService>().currentUser?.esDirectora ??
                            false)) ...[
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed:
                            _isLoading ? null : _confirmarEliminarAlumno,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.rojo,
                          side: const BorderSide(color: AppColors.rojo),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        icon: const Icon(Icons.delete_forever),
                        label: const Text('Eliminar alumno'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}
