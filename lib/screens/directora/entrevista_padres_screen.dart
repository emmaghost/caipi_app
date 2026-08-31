import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../config/app_colors.dart';
import '../../models/entrevista_padres.dart';

class EntrevistaPadresScreen extends StatefulWidget {
  final String? alumnoId;
  final String? entrevistaId;

  const EntrevistaPadresScreen({
    super.key,
    this.alumnoId,
    this.entrevistaId,
  });

  @override
  State<EntrevistaPadresScreen> createState() => _EntrevistaPadresScreenState();
}

class _EntrevistaPadresScreenState extends State<EntrevistaPadresScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  int _currentStep = 0;

  // SECCIÓN 1: DATOS DE LA MADRE
  final _madreNombreController = TextEditingController();
  final _madreEdadController = TextEditingController();
  final _madreOcupacionController = TextEditingController();
  final _madreDireccionController = TextEditingController();
  final _madreGradoEstudiosController = TextEditingController();
  final _madreTelefonoController = TextEditingController();

  // SECCIÓN 2: DATOS DEL PADRE
  final _padreNombreController = TextEditingController();
  final _padreEdadController = TextEditingController();
  final _padreOcupacionController = TextEditingController();
  final _padreDireccionController = TextEditingController();
  final _padreGradoEstudiosController = TextEditingController();
  final _padreTelefonoController = TextEditingController();

  // SECCIÓN 3: DIRECCIÓN
  final _viveCalleController = TextEditingController();
  final _viveColoniaController = TextEditingController();
  final _viveNumeroController = TextEditingController();
  final _viveReferenciaController = TextEditingController();
  String _viveTipo = 'Casa';
  String _viveCondicion = 'Propia';

  // SECCIÓN 4: INFORMACIÓN DEL HOGAR
  final _personasVivenConController = TextEditingController();
  final _quienCuidaController = TextEditingController();
  final _enfermedadesController = TextEditingController();
  final _alergiasController = TextEditingController();
  bool _controlEsfinteres = true;
  final _controlEsfinteresEdadController = TextEditingController();
  final _necesidadesEducativasController = TextEditingController();
  final _dificultadesController = TextEditingController();
  final _motivoInasistenciasController = TextEditingController();

  // SECCIÓN 5: ANTECEDENTES
  String _embarazoPlaneado = 'Sí';
  final _tiempoEmbarazoController = TextEditingController();
  final _dificultadesEmbarazoController = TextEditingController();
  final _edadCaminoController = TextEditingController();
  final _edadHabloController = TextEditingController();

  // SECCIÓN 6: PADRES SEPARADOS
  bool _padresSeparados = false;
  final _quienPatriaPotestadController = TextEditingController();
  final _conviveOtraParteController = TextEditingController();
  final _tienePadrastroController = TextEditingController();
  final _relacionPadrastroController = TextEditingController();
  final _comoSeRefiereController = TextEditingController();
  final _tieneHermanastrosController = TextEditingController();
  final _relacionHermanastrosController = TextEditingController();

  // SECCIÓN 7: ASPECTO SOCIAL DEL HIJO
  final _caracterHijoController = TextEditingController();
  final _queHaceEnojarController = TextEditingController();
  final _quePoneTristeController = TextEditingController();
  final _comoActuaController = TextEditingController();
  final _queMasGustaController = TextEditingController();
  bool _seVisteSola = false;
  final _seAtaCordonesController = TextEditingController();
  final _habitosHigieneController = TextEditingController();
  final _rutinaDespuesController = TextEditingController();
  final _horaDuermeController = TextEditingController();
  final _horaDespiertaController = TextEditingController();

  // SECCIÓN 8: ASPECTO SOCIAL (FAMILIA)
  bool _saleFinesSemana = false;
  final _saleADondeController = TextEditingController();
  final _actividadesFamiliaController = TextEditingController();
  bool _haceAmigosFacilidad = true;
  final _nombresAmigosController = TextEditingController();
  bool _tieneMascotas = false;
  final _mascotasCualesController = TextEditingController();
  bool _ayudaQuehaceres = false;
  final _cuandoPortaMalController = TextEditingController();
  final _hayCastigosController = TextEditingController();
  final _cuandoPortaBienController = TextEditingController();
  final _dicenGroceriasController = TextEditingController();
  final _juguetesFrecuenciaController = TextEditingController();

  // SECCIÓN 9: SOBRE NOSOTROS
  final _queEsperaMaestraController = TextEditingController();
  final _queEsperaEscuelaController = TextEditingController();
  bool _dispuestoApoyar = true;

  @override
  void initState() {
    super.initState();
    if (widget.entrevistaId != null) {
      _cargarEntrevista();
    }
  }

  Future<void> _cargarEntrevista() async {
    if (widget.entrevistaId == null) return;
    try {
      final response = await Supabase.instance.client
          .from('entrevistas_padres')
          .select()
          .eq('id', widget.entrevistaId!)
          .maybeSingle();
      if (response == null || !mounted) return;
      final e = EntrevistaPadres.fromJson(response);
      setState(() {
        _madreNombreController.text = e.madreNombre ?? '';
        _madreEdadController.text = e.madreEdad?.toString() ?? '';
        _madreOcupacionController.text = e.madreOcupacion ?? '';
        _madreDireccionController.text = e.madreDireccion ?? '';
        _madreGradoEstudiosController.text = e.madreGradoEstudios ?? '';
        _madreTelefonoController.text = e.madreTelefono ?? '';
        _padreNombreController.text = e.padreNombre ?? '';
        _padreEdadController.text = e.padreEdad?.toString() ?? '';
        _padreOcupacionController.text = e.padreOcupacion ?? '';
        _padreDireccionController.text = e.padreDireccion ?? '';
        _padreGradoEstudiosController.text = e.padreGradoEstudios ?? '';
        _padreTelefonoController.text = e.padreTelefono ?? '';
        _viveCalleController.text = e.viveCalle ?? '';
        _viveColoniaController.text = e.viveColonia ?? '';
        _viveNumeroController.text = e.viveNumero ?? '';
        _viveReferenciaController.text = e.viveReferencia ?? '';
        _viveTipo = e.viveTipo ?? 'Casa';
        _viveCondicion = e.viveCondicion ?? 'Propia';
        _personasVivenConController.text = e.personasVivenCon ?? '';
        _quienCuidaController.text = e.quienCuidaCuandoNoEscuela ?? '';
        _enfermedadesController.text = e.enfermedadesPadecimientos ?? '';
        _alergiasController.text = e.alergiasCuidados ?? '';
        _controlEsfinteres = e.controlEsfinteres ?? false;
        _controlEsfinteresEdadController.text = e.controlEsfinteresEdad ?? '';
        _necesidadesEducativasController.text =
            e.necesidadesEducativasEspeciales ?? '';
        _dificultadesController.text = e.dificultadesRealizar ?? '';
        _motivoInasistenciasController.text = e.motivoInasistencias ?? '';
        _embarazoPlaneado = e.embarazoPlaneado ?? 'Sí';
        _tiempoEmbarazoController.text = e.tiempoEmbarazo ?? '';
        _dificultadesEmbarazoController.text = e.dificultadesEmbarazo ?? '';
        _edadCaminoController.text = e.edadCamino ?? '';
        _edadHabloController.text = e.edadHablo ?? '';
        _padresSeparados = e.padresSeparados;
        _quienPatriaPotestadController.text = e.quienPatriaPotestad ?? '';
        _conviveOtraParteController.text = e.conviveOtraParte ?? '';
        _tienePadrastroController.text = e.tienePadrastroMadrastra ?? '';
        _relacionPadrastroController.text = e.relacionPadrastroMadrastra ?? '';
        _comoSeRefiereController.text = e.comoSeRefiereAEl ?? '';
        _tieneHermanastrosController.text = e.tieneHermanastros ?? '';
        _relacionHermanastrosController.text = e.relacionHermanastros ?? '';
        _caracterHijoController.text = e.caracterHijo ?? '';
        _queHaceEnojarController.text = e.queLaHaceEnojar ?? '';
        _quePoneTristeController.text = e.queLaPoneTriste ?? '';
        _comoActuaController.text = e.comoActuaCuandoAsi ?? '';
        _queMasGustaController.text = e.queMasLeGustaHacer ?? '';
        _seVisteSola = e.seVisteSola ?? false;
        _seAtaCordonesController.text = e.seAtaCordonesSola ?? '';
        _habitosHigieneController.text = e.habitosHigiene ?? '';
        _rutinaDespuesController.text = e.rutinaDespuesEscuela ?? '';
        _horaDuermeController.text = e.horaDuerme ?? '';
        _horaDespiertaController.text = e.horaDespierta ?? '';
        _saleFinesSemana = e.saleFineSemana ?? false;
        _saleADondeController.text = e.saleADonde ?? '';
        _actividadesFamiliaController.text = e.actividadesFamilia ?? '';
        _haceAmigosFacilidad = e.haceAmigosFacilidad ?? false;
        _nombresAmigosController.text = e.nombresAmigos ?? '';
        _tieneMascotas = e.tieneMascotas ?? false;
        _mascotasCualesController.text = e.mascotasCuales ?? '';
        _ayudaQuehaceres = e.ayudaQuehaceres ?? false;
        _cuandoPortaMalController.text = e.cuandoPortaMalActua ?? '';
        _hayCastigosController.text = e.hayCastigosCuales ?? '';
        _cuandoPortaBienController.text = e.cuandoPortaBienActua ?? '';
        _dicenGroceriasController.text = e.dicenGroceriasQuien ?? '';
        _juguetesFrecuenciaController.text = e.juguetesUsaFrecuencia ?? '';
        _queEsperaMaestraController.text = e.queEsperaMaestra ?? '';
        _queEsperaEscuelaController.text = e.queEsperaEscuela ?? '';
        _dispuestoApoyar = e.dispuestoApoyarEscuela ?? true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo cargar la entrevista: $e'),
            backgroundColor: AppColors.rojo,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    // Dispose all controllers
    _madreNombreController.dispose();
    _madreEdadController.dispose();
    _madreOcupacionController.dispose();
    _madreDireccionController.dispose();
    _madreGradoEstudiosController.dispose();
    _madreTelefonoController.dispose();
    _padreNombreController.dispose();
    _padreEdadController.dispose();
    _padreOcupacionController.dispose();
    _padreDireccionController.dispose();
    _padreGradoEstudiosController.dispose();
    _padreTelefonoController.dispose();
    _viveCalleController.dispose();
    _viveColoniaController.dispose();
    _viveNumeroController.dispose();
    _viveReferenciaController.dispose();
    _personasVivenConController.dispose();
    _quienCuidaController.dispose();
    _enfermedadesController.dispose();
    _alergiasController.dispose();
    _controlEsfinteresEdadController.dispose();
    _necesidadesEducativasController.dispose();
    _dificultadesController.dispose();
    _motivoInasistenciasController.dispose();
    _tiempoEmbarazoController.dispose();
    _dificultadesEmbarazoController.dispose();
    _edadCaminoController.dispose();
    _edadHabloController.dispose();
    _quienPatriaPotestadController.dispose();
    _conviveOtraParteController.dispose();
    _tienePadrastroController.dispose();
    _relacionPadrastroController.dispose();
    _comoSeRefiereController.dispose();
    _tieneHermanastrosController.dispose();
    _relacionHermanastrosController.dispose();
    _caracterHijoController.dispose();
    _queHaceEnojarController.dispose();
    _quePoneTristeController.dispose();
    _comoActuaController.dispose();
    _queMasGustaController.dispose();
    _seAtaCordonesController.dispose();
    _habitosHigieneController.dispose();
    _rutinaDespuesController.dispose();
    _horaDuermeController.dispose();
    _horaDespiertaController.dispose();
    _saleADondeController.dispose();
    _actividadesFamiliaController.dispose();
    _nombresAmigosController.dispose();
    _mascotasCualesController.dispose();
    _cuandoPortaMalController.dispose();
    _hayCastigosController.dispose();
    _cuandoPortaBienController.dispose();
    _dicenGroceriasController.dispose();
    _juguetesFrecuenciaController.dispose();
    _queEsperaMaestraController.dispose();
    _queEsperaEscuelaController.dispose();
    super.dispose();
  }

  Future<void> _guardarEntrevista({bool marcarCompleta = true}) async {
    final alumnoId = widget.alumnoId;
    if (alumnoId == null || alumnoId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Debes seleccionar un alumno. Ve a Entrevistas y elige el hijo.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final entrevistaId = widget.entrevistaId ?? const Uuid().v4();
      final userId = Supabase.instance.client.auth.currentUser!.id;

      String? padreUsuarioId;
      final alumnoRow = await Supabase.instance.client
          .from('alumnos')
          .select('padre_id')
          .eq('id', alumnoId)
          .maybeSingle();
      padreUsuarioId = alumnoRow?['padre_id'] as String?;

      final entrevistaData = {
        'id': entrevistaId,
        'alumno_id': alumnoId,
        'padre_usuario_id': padreUsuarioId,
        // Madre
        'madre_nombre': _madreNombreController.text.trim(),
        'madre_edad': int.tryParse(_madreEdadController.text.trim()),
        'madre_ocupacion': _madreOcupacionController.text.trim(),
        'madre_direccion': _madreDireccionController.text.trim(),
        'madre_grado_estudios': _madreGradoEstudiosController.text.trim(),
        'madre_telefono': _madreTelefonoController.text.trim(),
        // Padre
        'padre_nombre': _padreNombreController.text.trim(),
        'padre_edad': int.tryParse(_padreEdadController.text.trim()),
        'padre_ocupacion': _padreOcupacionController.text.trim(),
        'padre_direccion': _padreDireccionController.text.trim(),
        'padre_grado_estudios': _padreGradoEstudiosController.text.trim(),
        'padre_telefono': _padreTelefonoController.text.trim(),
        // Dirección
        'vive_calle': _viveCalleController.text.trim(),
        'vive_colonia': _viveColoniaController.text.trim(),
        'vive_numero': _viveNumeroController.text.trim(),
        'vive_referencia': _viveReferenciaController.text.trim(),
        'vive_tipo': _viveTipo,
        'vive_condicion': _viveCondicion,
        // Hogar
        'personas_viven_con': _personasVivenConController.text.trim(),
        'quien_cuida_cuando_no_escuela': _quienCuidaController.text.trim(),
        'enfermedades_padecimientos': _enfermedadesController.text.trim(),
        'alergias_cuidados': _alergiasController.text.trim(),
        'control_esfinteres': _controlEsfinteres,
        'control_esfinteres_edad': _controlEsfinteresEdadController.text.trim(),
        'necesidades_educativas_especiales': _necesidadesEducativasController.text.trim(),
        'dificultades_realizar': _dificultadesController.text.trim(),
        'motivo_inasistencias': _motivoInasistenciasController.text.trim(),
        // Antecedentes
        'embarazo_planeado': _embarazoPlaneado,
        'tiempo_embarazo': _tiempoEmbarazoController.text.trim(),
        'dificultades_embarazo': _dificultadesEmbarazoController.text.trim(),
        'edad_camino': _edadCaminoController.text.trim(),
        'edad_hablo': _edadHabloController.text.trim(),
        // Padres separados
        'padres_separados': _padresSeparados,
        'quien_patria_potestad': _quienPatriaPotestadController.text.trim(),
        'convive_otra_parte': _conviveOtraParteController.text.trim(),
        'tiene_padrastro_madrastra': _tienePadrastroController.text.trim(),
        'relacion_padrastro_madrastra': _relacionPadrastroController.text.trim(),
        'como_se_refiere_a_el': _comoSeRefiereController.text.trim(),
        'tiene_hermanastros': _tieneHermanastrosController.text.trim(),
        'relacion_hermanastros': _relacionHermanastrosController.text.trim(),
        // Aspecto social hijo
        'caracter_hijo': _caracterHijoController.text.trim(),
        'que_la_hace_enojar': _queHaceEnojarController.text.trim(),
        'que_la_pone_triste': _quePoneTristeController.text.trim(),
        'como_actua_cuando_asi': _comoActuaController.text.trim(),
        'que_mas_le_gusta_hacer': _queMasGustaController.text.trim(),
        'se_viste_sola': _seVisteSola,
        'se_ata_cordones_sola': _seAtaCordonesController.text.trim(),
        'habitos_higiene': _habitosHigieneController.text.trim(),
        'rutina_despues_escuela': _rutinaDespuesController.text.trim(),
        'hora_duerme': _horaDuermeController.text.trim(),
        'hora_despierta': _horaDespiertaController.text.trim(),
        // Aspecto social familia
        'sale_fines_semana': _saleFinesSemana,
        'sale_a_donde': _saleADondeController.text.trim(),
        'actividades_familia': _actividadesFamiliaController.text.trim(),
        'hace_amigos_facilidad': _haceAmigosFacilidad,
        'nombres_amigos': _nombresAmigosController.text.trim(),
        'tiene_mascotas': _tieneMascotas,
        'mascotas_cuales': _mascotasCualesController.text.trim(),
        'ayuda_quehaceres': _ayudaQuehaceres,
        'cuando_porta_mal_actua': _cuandoPortaMalController.text.trim(),
        'hay_castigos_cuales': _hayCastigosController.text.trim(),
        'cuando_porta_bien_actua': _cuandoPortaBienController.text.trim(),
        'dicen_grocerias_quien': _dicenGroceriasController.text.trim(),
        'juguetes_usa_frecuencia': _juguetesFrecuenciaController.text.trim(),
        // Expectativas
        'que_espera_maestra': _queEsperaMaestraController.text.trim(),
        'que_espera_escuela': _queEsperaEscuelaController.text.trim(),
        'dispuesto_apoyar_escuela': _dispuestoApoyar,
        // Metadatos
        'completado': marcarCompleta,
        'created_by': userId,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (widget.entrevistaId != null) {
        // Actualizar
        await Supabase.instance.client
            .from('entrevistas_padres')
            .update(entrevistaData)
            .eq('id', entrevistaId);
      } else {
        // Crear
        await Supabase.instance.client
            .from('entrevistas_padres')
            .insert(entrevistaData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              marcarCompleta
                  ? 'Entrevista guardada como completa'
                  : 'Avance guardado. Puedes continuar después.',
            ),
            backgroundColor: AppColors.verde,
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
          'Entrevista a Padres',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isLoading
                ? null
                : () => _guardarEntrevista(marcarCompleta: false),
            child: const Text('Guardar avance'),
          ),
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => context.go('/directora'),
            tooltip: 'Ir al inicio',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Stepper(
          type: StepperType.vertical,
          currentStep: _currentStep,
          onStepContinue: () {
            if (_currentStep < 8) {
              setState(() => _currentStep++);
            } else {
              _guardarEntrevista(marcarCompleta: true);
            }
          },
          onStepCancel: () {
            if (_currentStep > 0) {
              setState(() => _currentStep--);
            }
          },
          controlsBuilder: (context, details) {
            return Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  ElevatedButton(
                    onPressed: _isLoading ? null : details.onStepContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.purpura,
                      foregroundColor: Colors.white,
                      disabledForegroundColor: Colors.white70,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _currentStep == 8
                                ? 'Guardar completa'
                                : 'Siguiente',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                  if (_currentStep > 0)
                    OutlinedButton(
                      onPressed: details.onStepCancel,
                      child: const Text('Atrás'),
                    ),
                ],
              ),
            );
          },
          steps: [
            _buildStep1DatosMadre(),
            _buildStep2DatosPadre(),
            _buildStep3Direccion(),
            _buildStep4InformacionHogar(),
            _buildStep5Antecedentes(),
            _buildStep6PadresSeparados(),
            _buildStep7AspectoSocialHijo(),
            _buildStep8AspectoSocialFamilia(),
            _buildStep9Expectativas(),
          ],
        ),
      ),
    );
  }

  // CONTINÚA EN EL SIGUIENTE ARCHIVO (es muy largo)
  Step _buildStep1DatosMadre() {
    return Step(
      title: const Text('Datos de la Madre'),
      isActive: _currentStep >= 0,
      state: _currentStep > 0 ? StepState.complete : StepState.indexed,
      content: Column(
        children: [
          _buildTextField(_madreNombreController, 'Nombre completo', Icons.person),
          const SizedBox(height: 12),
          _buildTextField(_madreEdadController, 'Edad', Icons.cake, keyboardType: TextInputType.number),
          const SizedBox(height: 12),
          _buildTextField(_madreOcupacionController, 'Ocupación', Icons.work),
          const SizedBox(height: 12),
          _buildTextField(_madreDireccionController, 'Dirección', Icons.home, maxLines: 2),
          const SizedBox(height: 12),
          _buildTextField(_madreGradoEstudiosController, 'Máximo grado de estudios', Icons.school),
          const SizedBox(height: 12),
          _buildTextField(_madreTelefonoController, 'Teléfono', Icons.phone, keyboardType: TextInputType.phone),
        ],
      ),
    );
  }

  Step _buildStep2DatosPadre() {
    return Step(
      title: const Text('Datos del Padre'),
      isActive: _currentStep >= 1,
      state: _currentStep > 1 ? StepState.complete : StepState.indexed,
      content: Column(
        children: [
          _buildTextField(_padreNombreController, 'Nombre completo', Icons.person),
          const SizedBox(height: 12),
          _buildTextField(_padreEdadController, 'Edad', Icons.cake, keyboardType: TextInputType.number),
          const SizedBox(height: 12),
          _buildTextField(_padreOcupacionController, 'Ocupación', Icons.work),
          const SizedBox(height: 12),
          _buildTextField(_padreDireccionController, 'Dirección', Icons.home, maxLines: 2),
          const SizedBox(height: 12),
          _buildTextField(_padreGradoEstudiosController, 'Máximo grado de estudios', Icons.school),
          const SizedBox(height: 12),
          _buildTextField(_padreTelefonoController, 'Teléfono', Icons.phone, keyboardType: TextInputType.phone),
        ],
      ),
    );
  }

  Step _buildStep3Direccion() {
    return Step(
      title: const Text('Dirección del Alumno'),
      isActive: _currentStep >= 2,
      state: _currentStep > 2 ? StepState.complete : StepState.indexed,
      content: Column(
        children: [
          _buildTextField(_viveCalleController, 'Calle', Icons.location_on),
          const SizedBox(height: 12),
          _buildTextField(_viveColoniaController, 'Colonia', Icons.location_city),
          const SizedBox(height: 12),
          _buildTextField(_viveNumeroController, 'Número', Icons.home_work, keyboardType: TextInputType.number),
          const SizedBox(height: 12),
          _buildTextField(_viveReferenciaController, 'Referencia', Icons.info, maxLines: 2),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _viveTipo,
            decoration: InputDecoration(
              labelText: 'Tipo de vivienda',
              prefixIcon: const Icon(Icons.apartment, color: AppColors.azul),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: const [
              DropdownMenuItem(value: 'Casa', child: Text('Casa')),
              DropdownMenuItem(value: 'Departamento', child: Text('Departamento')),
              DropdownMenuItem(value: 'Otro', child: Text('Otro')),
            ],
            onChanged: (value) => setState(() => _viveTipo = value!),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _viveCondicion,
            decoration: InputDecoration(
              labelText: 'Condición de vivienda',
              prefixIcon: const Icon(Icons.key, color: AppColors.verde),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: const [
              DropdownMenuItem(value: 'Propia', child: Text('Propia')),
              DropdownMenuItem(value: 'Rentada', child: Text('Rentada')),
              DropdownMenuItem(value: 'De un familiar', child: Text('De un familiar')),
            ],
            onChanged: (value) => setState(() => _viveCondicion = value!),
          ),
        ],
      ),
    );
  }

  Step _buildStep4InformacionHogar() {
    return Step(
      title: const Text('Información del Hogar'),
      isActive: _currentStep >= 3,
      state: _currentStep > 3 ? StepState.complete : StepState.indexed,
      content: Column(
        children: [
          _buildTextField(_personasVivenConController, 'Personas que viven con el alumno', Icons.people, maxLines: 2),
          const SizedBox(height: 12),
          _buildTextField(_quienCuidaController, 'Quién cuida cuando no va a la escuela', Icons.child_care, maxLines: 2),
          const SizedBox(height: 12),
          _buildTextField(_enfermedadesController, 'Enfermedades/padecimientos/tratamientos', Icons.medical_services, maxLines: 3),
          const SizedBox(height: 12),
          _buildTextField(_alergiasController, 'Alergias o cuidados especiales', Icons.warning_amber, maxLines: 2),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Control de esfínteres'),
            subtitle: Text(_controlEsfinteres ? 'Sí' : 'No'),
            value: _controlEsfinteres,
            activeColor: AppColors.verde,
            onChanged: (value) => setState(() => _controlEsfinteres = value),
          ),
          if (_controlEsfinteres) ...[
            const SizedBox(height: 12),
            _buildTextField(_controlEsfinteresEdadController, '¿A qué edad?', Icons.child_friendly),
          ],
          const SizedBox(height: 12),
          _buildTextField(_necesidadesEducativasController, 'Necesidades educativas especiales', Icons.accessibility_new, maxLines: 3),
          const SizedBox(height: 12),
          _buildTextField(_dificultadesController, 'Dificultades que han notado', Icons.report_problem, maxLines: 3),
          const SizedBox(height: 12),
          _buildTextField(_motivoInasistenciasController, 'Posibles motivos de inasistencias', Icons.event_busy, maxLines: 2),
        ],
      ),
    );
  }

  Step _buildStep5Antecedentes() {
    return Step(
      title: const Text('Antecedentes'),
      isActive: _currentStep >= 4,
      state: _currentStep > 4 ? StepState.complete : StepState.indexed,
      content: Column(
        children: [
          DropdownButtonFormField<String>(
            value: _embarazoPlaneado,
            decoration: InputDecoration(
              labelText: '¿Fue un embarazo planeado?',
              prefixIcon: const Icon(Icons.family_restroom, color: AppColors.rosa),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: const [
              DropdownMenuItem(value: 'Sí', child: Text('Sí')),
              DropdownMenuItem(value: 'No', child: Text('No')),
            ],
            onChanged: (value) => setState(() => _embarazoPlaneado = value!),
          ),
          const SizedBox(height: 12),
          _buildTextField(_tiempoEmbarazoController, 'Tiempo del embarazo', Icons.timer),
          const SizedBox(height: 12),
          _buildTextField(_dificultadesEmbarazoController, 'Dificultades durante el embarazo', Icons.healing, maxLines: 3),
          const SizedBox(height: 12),
          _buildTextField(_edadCaminoController, 'Edad en la que caminó', Icons.directions_walk),
          const SizedBox(height: 12),
          _buildTextField(_edadHabloController, 'Edad en la que habló', Icons.record_voice_over),
        ],
      ),
    );
  }

  Step _buildStep6PadresSeparados() {
    return Step(
      title: const Text('Padres Separados (Opcional)'),
      isActive: _currentStep >= 5,
      state: _currentStep > 5 ? StepState.complete : StepState.indexed,
      content: Column(
        children: [
          SwitchListTile(
            title: const Text('¿Los padres están separados?'),
            subtitle: Text(_padresSeparados ? 'Sí' : 'No'),
            value: _padresSeparados,
            activeColor: AppColors.naranja,
            onChanged: (value) => setState(() => _padresSeparados = value),
          ),
          if (_padresSeparados) ...[
            const SizedBox(height: 12),
            _buildTextField(_quienPatriaPotestadController, 'Quién tiene la patria potestad', Icons.gavel),
            const SizedBox(height: 12),
            _buildTextField(_conviveOtraParteController, 'Convive con la otra parte? Explicar', Icons.people_outline, maxLines: 2),
            const SizedBox(height: 12),
            _buildTextField(_tienePadrastroController, 'Tiene padrastro/madrastra?', Icons.person_add, maxLines: 2),
            const SizedBox(height: 12),
            _buildTextField(_relacionPadrastroController, 'Cómo es su relación', Icons.thumb_up, maxLines: 2),
            const SizedBox(height: 12),
            _buildTextField(_comoSeRefiereController, 'De qué forma lo llama/se refiere a él', Icons.chat),
            const SizedBox(height: 12),
            _buildTextField(_tieneHermanastrosController, 'Tiene hermanastros?', Icons.group, maxLines: 2),
            const SizedBox(height: 12),
            _buildTextField(_relacionHermanastrosController, 'Cómo es su relación con ellos', Icons.sentiment_satisfied, maxLines: 2),
          ],
        ],
      ),
    );
  }

  Step _buildStep7AspectoSocialHijo() {
    return Step(
      title: const Text('Aspecto Social del Hijo'),
      isActive: _currentStep >= 6,
      state: _currentStep > 6 ? StepState.complete : StepState.indexed,
      content: Column(
        children: [
          _buildTextField(_caracterHijoController, 'Describa el carácter de su hijo', Icons.psychology, maxLines: 3),
          const SizedBox(height: 12),
          _buildTextField(_queHaceEnojarController, 'Qué lo hace enojar', Icons.mood_bad, maxLines: 2),
          const SizedBox(height: 12),
          _buildTextField(_quePoneTristeController, 'Qué lo pone triste', Icons.sentiment_dissatisfied, maxLines: 2),
          const SizedBox(height: 12),
          _buildTextField(_comoActuaController, 'Cómo actúa cuando está así', Icons.emoji_emotions, maxLines: 2),
          const SizedBox(height: 12),
          _buildTextField(_queMasGustaController, 'Qué es lo que más le gusta hacer', Icons.favorite, maxLines: 2),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Se viste sola'),
            value: _seVisteSola,
            activeColor: AppColors.verde,
            onChanged: (value) => setState(() => _seVisteSola = value),
          ),
          const SizedBox(height: 12),
          _buildTextField(_seAtaCordonesController, 'Se ata los cordones sola? (Sí/No/A veces)', Icons.local_laundry_service),
          const SizedBox(height: 12),
          _buildTextField(_habitosHigieneController, 'Hábitos de higiene que practica en casa', Icons.wash, maxLines: 3),
          const SizedBox(height: 12),
          _buildTextField(_rutinaDespuesController, 'Rutina después de la escuela', Icons.schedule, maxLines: 3),
          const SizedBox(height: 12),
          _buildTextField(_horaDuermeController, 'A qué hora se duerme', Icons.bedtime),
          const SizedBox(height: 12),
          _buildTextField(_horaDespiertaController, 'A qué hora se despierta', Icons.alarm),
        ],
      ),
    );
  }

  Step _buildStep8AspectoSocialFamilia() {
    return Step(
      title: const Text('Aspecto Social (Familia)'),
      isActive: _currentStep >= 7,
      state: _currentStep > 7 ? StepState.complete : StepState.indexed,
      content: Column(
        children: [
          SwitchListTile(
            title: const Text('Acostumbra salir los fines de semana'),
            value: _saleFinesSemana,
            activeColor: AppColors.azul,
            onChanged: (value) => setState(() => _saleFinesSemana = value),
          ),
          if (_saleFinesSemana) ...[
            const SizedBox(height: 12),
            _buildTextField(_saleADondeController, 'A dónde salen', Icons.map, maxLines: 2),
          ],
          const SizedBox(height: 12),
          _buildTextField(_actividadesFamiliaController, 'Actividades que realizan en familia', Icons.family_restroom, maxLines: 3),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Hace amigos con facilidad'),
            value: _haceAmigosFacilidad,
            activeColor: AppColors.verde,
            onChanged: (value) => setState(() => _haceAmigosFacilidad = value),
          ),
          const SizedBox(height: 12),
          _buildTextField(_nombresAmigosController, 'Nombres de sus amigos', Icons.people, maxLines: 2),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Tiene mascotas'),
            value: _tieneMascotas,
            activeColor: AppColors.naranja,
            onChanged: (value) => setState(() => _tieneMascotas = value),
          ),
          if (_tieneMascotas) ...[
            const SizedBox(height: 12),
            _buildTextField(_mascotasCualesController, 'Qué y cómo se llaman', Icons.pets, maxLines: 2),
          ],
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Ayuda a los quehaceres de la casa'),
            value: _ayudaQuehaceres,
            activeColor: AppColors.purpura,
            onChanged: (value) => setState(() => _ayudaQuehaceres = value),
          ),
          const SizedBox(height: 12),
          _buildTextField(_cuandoPortaMalController, 'Cuando se porta mal, cómo actúa usted', Icons.report, maxLines: 3),
          const SizedBox(height: 12),
          _buildTextField(_hayCastigosController, 'Hay castigos? Cuáles', Icons.block, maxLines: 2),
          const SizedBox(height: 12),
          _buildTextField(_cuandoPortaBienController, 'Cuando se porta bien, cómo se actúa', Icons.star, maxLines: 2),
          const SizedBox(height: 12),
          _buildTextField(_dicenGroceriasController, 'En casa dicen groserías? Quién?', Icons.warning, maxLines: 2),
          const SizedBox(height: 12),
          _buildTextField(_juguetesFrecuenciaController, 'Juguetes que usa con mayor frecuencia', Icons.toys, maxLines: 2),
        ],
      ),
    );
  }

  Step _buildStep9Expectativas() {
    return Step(
      title: const Text('Sobre Nosotros'),
      isActive: _currentStep >= 8,
      state: _currentStep > 8 ? StepState.complete : StepState.indexed,
      content: Column(
        children: [
          _buildTextField(_queEsperaMaestraController, 'Qué espera de la maestra', Icons.school, maxLines: 3),
          const SizedBox(height: 12),
          _buildTextField(_queEsperaEscuelaController, 'Qué espera de la escuela', Icons.business, maxLines: 3),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Está dispuesto a apoyar a su hijo en todo lo que se refiere a la escuela'),
            subtitle: Text(_dispuestoApoyar ? 'Sí' : 'No'),
            value: _dispuestoApoyar,
            activeColor: AppColors.verde,
            onChanged: (value) => setState(() => _dispuestoApoyar = value),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.purpura),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}
