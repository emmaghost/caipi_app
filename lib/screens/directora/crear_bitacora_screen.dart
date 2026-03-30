import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../config/app_colors.dart';
import '../../models/alumno.dart';
import '../../models/bitacora.dart';
import '../../models/grado.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_drawer.dart';

class CrearBitacoraScreen extends StatefulWidget {
  final String? bitacoraId;
  final DateTime? fechaInicial;

  const CrearBitacoraScreen({
    super.key,
    this.bitacoraId,
    this.fechaInicial,
  });

  @override
  State<CrearBitacoraScreen> createState() => _CrearBitacoraScreenState();
}

class _CrearBitacoraScreenState extends State<CrearBitacoraScreen> {
  final _formKey = GlobalKey<FormState>();
  final _observacionesController = TextEditingController();

  String? _alumnoSeleccionadoId;
  DateTime _fecha = DateTime.now();
  String _estadoAnimo = 'Feliz';
  String _comio = 'si'; // UI: 'si', 'no', 'mas_o_menos' (BD acepta 'medio' = más o menos)
  bool _tomoAgua = false;
  bool _pipi = false;
  bool _popo = false;
  bool _lavoDientes = false;
  bool _respetoDemas = false;
  bool _realizoActividades = false;
  bool _siesta = false;
  
  bool _cargando = false;
  bool _esEdicion = false;
  bool _esDirectora = false;
  String? _miProfesorId;
  String? _miGradoId;
  List<Grado> _grados = [];
  String? _gradoDirectorId;
  List<Alumno> _alumnosLista = [];
  bool _profesoraSinGrupo = false;
  bool _profesoraBitacoraAjena = false;

  final List<String> _estadosAnimo = ['Feliz', 'Tranquilo', 'Triste', 'Irritable'];

  bool get _alumnoValidoEnLista =>
      _alumnoSeleccionadoId != null &&
      _alumnosLista.any((a) => a.id == _alumnoSeleccionadoId);

  @override
  void initState() {
    super.initState();
    if (widget.fechaInicial != null) {
      _fecha = _soloFecha(widget.fechaInicial!);
    }
    if (widget.bitacoraId != null) {
      _esEdicion = true;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _boot());
  }

  DateTime _soloFecha(DateTime d) => DateTime(d.year, d.month, d.day);

  DateTime get _hoy => _soloFecha(DateTime.now());

  Future<void> _boot() async {
    setState(() => _cargando = true);
    try {
      final auth = context.read<AuthService>();
      _esDirectora = auth.isDirectora;
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (!_esDirectora && uid != null) {
        final pr = await Supabase.instance.client
            .from('profesores')
            .select('id, grado_id')
            .eq('usuario_id', uid)
            .eq('activo', true)
            .maybeSingle();
        if (pr != null) {
          _miProfesorId = pr['id'] as String;
          _miGradoId = pr['grado_id'] as String?;
        }
        if (_miGradoId == null || _miGradoId!.isEmpty) {
          _profesoraSinGrupo = true;
        } else {
          await _refrescarAlumnosPorGrado(_miGradoId!);
        }
      }
      if (_esDirectora) {
        final gr = await Supabase.instance.client
            .from('grados')
            .select()
            .eq('activo', true)
            .order('nombre');
        _grados = (gr as List)
            .map((j) => Grado.fromJson(Map<String, dynamic>.from(j as Map)))
            .toList();
      }
      if (widget.bitacoraId != null) {
        await _cargarDatosBitacora();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
    if (mounted) setState(() => _cargando = false);
  }

  Future<void> _refrescarAlumnosPorGrado(String gradoId) async {
    final al = await Supabase.instance.client
        .from('alumnos')
        .select()
        .eq('grado_id', gradoId)
        .eq('activo', true)
        .order('nombre');
    _alumnosLista = (al as List)
        .map((j) => Alumno.fromJson(Map<String, dynamic>.from(j as Map)))
        .toList();
  }

  Future<void> _cargarDatosBitacora() async {
    final response = await Supabase.instance.client
        .from('bitacora_diaria')
        .select()
        .eq('id', widget.bitacoraId!)
        .single();
    if (!mounted) return;
    final bitacora = Bitacora.fromJson(response);
    _alumnoSeleccionadoId = bitacora.alumnoId;
    _fecha = _soloFecha(bitacora.fecha);
    if (_fecha.isAfter(_hoy)) {
      _fecha = _hoy;
    }
    _estadoAnimo = bitacora.estadoAnimo ?? 'Feliz';
    final c = bitacora.comio ?? 'si';
    _comio = (c == 'medio' || c == 'mas_o_menos') ? 'mas_o_menos' : c;
    _tomoAgua = bitacora.tomoAgua;
    _pipi = bitacora.pipi;
    _popo = bitacora.popo;
    _lavoDientes = bitacora.lavoDientes;
    _respetoDemas = bitacora.respetoDemas;
    _realizoActividades = bitacora.realizoActividades;
    _siesta = bitacora.siesta;
    _observacionesController.text = bitacora.observaciones ?? '';

    if (_esDirectora) {
      final al = await Supabase.instance.client
          .from('alumnos')
          .select('grado_id')
          .eq('id', bitacora.alumnoId)
          .maybeSingle();
      final gid = al?['grado_id'] as String?;
      if (gid != null) {
        _gradoDirectorId = gid;
        await _refrescarAlumnosPorGrado(gid);
      }
    } else if (_miGradoId != null) {
      final ok = _alumnosLista.any((a) => a.id == bitacora.alumnoId);
      if (!ok) {
        _profesoraBitacoraAjena = true;
      }
    }
  }

  @override
  void dispose() {
    _observacionesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.morado,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            const Icon(Icons.assignment, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _esEdicion ? 'Editar Bitácora' : 'Nueva Bitácora',
                style: GoogleFonts.fredoka(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
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
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.rosa.withOpacity(0.45)),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.morado.withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.rosaClaro,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.child_care, color: AppColors.morado, size: 32),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _esEdicion ? 'Modificar bitácora' : 'Registrar bitácora',
                                  style: GoogleFonts.fredoka(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF4A3F55),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Actividades y bienestar del día',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    _buildSeccionTitulo('Información básica'),
                    const SizedBox(height: 12),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_esDirectora) ...[
                              DropdownButtonFormField<String>(
                                value: _gradoDirectorId,
                                decoration: InputDecoration(
                                  labelText: 'Grado / grupo *',
                                  prefixIcon: Icon(Icons.school, color: AppColors.morado),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                items: _grados
                                    .map((g) => DropdownMenuItem(
                                          value: g.id,
                                          child: Text(g.nombre),
                                        ))
                                    .toList(),
                                onChanged: (v) async {
                                  setState(() {
                                    _gradoDirectorId = v;
                                    _alumnoSeleccionadoId = null;
                                  });
                                  if (v != null) {
                                    await _refrescarAlumnosPorGrado(v);
                                    setState(() {});
                                  }
                                },
                              ),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<String>(
                                value: _alumnoValidoEnLista ? _alumnoSeleccionadoId : null,
                                decoration: InputDecoration(
                                  labelText: 'Alumno *',
                                  prefixIcon: Icon(Icons.person, color: AppColors.morado),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                items: _alumnosLista
                                    .map((a) => DropdownMenuItem(
                                          value: a.id,
                                          child: Text(a.nombreCompleto),
                                        ))
                                    .toList(),
                                onChanged: (value) {
                                  setState(() => _alumnoSeleccionadoId = value);
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Selecciona grado y alumno';
                                  }
                                  return null;
                                },
                              ),
                            ] else if (_profesoraBitacoraAjena) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Esta bitácora es de un alumno que no está en tu grupo. Solo la directora puede modificarla.',
                                  style: GoogleFonts.poppins(fontSize: 14),
                                ),
                              ),
                            ] else if (_profesoraSinGrupo) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.info_outline, color: Colors.orange.shade800),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'No tienes un grupo asignado. Pide a la directora que te asigne un grado en tu perfil de profesora.',
                                        style: GoogleFonts.poppins(fontSize: 14),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ] else ...[
                              DropdownButtonFormField<String>(
                                value: _alumnoValidoEnLista ? _alumnoSeleccionadoId : null,
                                decoration: InputDecoration(
                                  labelText: 'Alumno de tu grupo *',
                                  prefixIcon: Icon(Icons.groups, color: AppColors.morado),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                items: _alumnosLista
                                    .map((a) => DropdownMenuItem(
                                          value: a.id,
                                          child: Text(a.nombreCompleto),
                                        ))
                                    .toList(),
                                onChanged: (value) {
                                  setState(() => _alumnoSeleccionadoId = value);
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Selecciona un alumno';
                                  }
                                  return null;
                                },
                              ),
                            ],
                            const SizedBox(height: 16),
                            InkWell(
                              onTap: _profesoraSinGrupo ? null : _seleccionarFecha,
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Fecha * (hoy o días pasados)',
                                  prefixIcon: Icon(Icons.calendar_today, color: AppColors.morado),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  DateFormat('dd/MM/yyyy', 'es_MX').format(_fecha),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Estado de Ánimo
                    _buildSeccionTitulo('Estado de Ánimo'),
                    const SizedBox(height: 12),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: _estadosAnimo.map((estado) {
                            return Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _estadoAnimo = estado;
                                  });
                                },
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: _estadoAnimo == estado
                                        ? _getColorEstadoAnimo(estado)
                                        : Colors.grey[100],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _estadoAnimo == estado
                                          ? _getColorEstadoAnimo(estado)
                                          : Colors.grey[300]!,
                                      width: 2,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        _getEmojiEstadoAnimo(estado),
                                        style: const TextStyle(fontSize: 32),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        estado,
                                        style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          fontWeight: _estadoAnimo == estado
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    _buildSeccionTitulo('Actividades del día'),
                    const SizedBox(height: 12),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.restaurant, color: AppColors.morado, size: 28),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Comió *',
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      DropdownButtonFormField<String>(
                                        value: _comio,
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor: AppColors.rosaClaro.withOpacity(0.6),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                        ),
                                        items: const [
                                          DropdownMenuItem(value: 'si', child: Text('Sí')),
                                          DropdownMenuItem(value: 'no', child: Text('No')),
                                          DropdownMenuItem(
                                            value: 'mas_o_menos',
                                            child: Text('Más o menos'),
                                          ),
                                        ],
                                        onChanged: (value) {
                                          if (value != null) {
                                            setState(() => _comio = value);
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            _buildSwitchItem(
                              icon: Icons.local_drink,
                              label: 'Tomó agua',
                              valor: _tomoAgua,
                              onChanged: (v) => setState(() => _tomoAgua = v),
                            ),
                            const Divider(height: 20),
                            _buildSwitchItem(
                              icon: Icons.water_drop,
                              label: 'Pipí',
                              valor: _pipi,
                              onChanged: (v) => setState(() => _pipi = v),
                            ),
                            const Divider(height: 20),
                            _buildSwitchItem(
                              icon: Icons.radio_button_checked,
                              label: 'Popó',
                              valor: _popo,
                              onChanged: (v) => setState(() => _popo = v),
                            ),
                            const Divider(height: 20),
                            _buildSwitchItem(
                              icon: Icons.groups,
                              label: 'Respetó a los demás',
                              valor: _respetoDemas,
                              onChanged: (v) => setState(() => _respetoDemas = v),
                            ),
                            const Divider(height: 20),
                            _buildSwitchItem(
                              icon: Icons.draw,
                              label: 'Realizó sus actividades',
                              valor: _realizoActividades,
                              onChanged: (v) => setState(() => _realizoActividades = v),
                            ),
                            const Divider(height: 20),
                            _buildSwitchItem(
                              icon: Icons.sentiment_very_satisfied,
                              label: 'Se lavó los dientes',
                              valor: _lavoDientes,
                              onChanged: (v) => setState(() => _lavoDientes = v),
                            ),
                            const Divider(height: 20),
                            _buildSwitchItem(
                              icon: Icons.bed,
                              label: 'Siesta',
                              valor: _siesta,
                              onChanged: (v) => setState(() => _siesta = v),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Observaciones
                    _buildSeccionTitulo('Observaciones'),
                    const SizedBox(height: 12),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: TextFormField(
                          controller: _observacionesController,
                          decoration: InputDecoration(
                            labelText: 'Observaciones adicionales',
                            hintText: 'Notas importantes sobre el día...',
                            prefixIcon: const Icon(Icons.notes),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          maxLines: 4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Botón guardar
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _guardarBitacora,
                        icon: const Icon(Icons.save, color: Colors.white),
                        label: Text(
                          _esEdicion ? 'Actualizar Bitácora' : 'Guardar Bitácora',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF166534),
                          foregroundColor: Colors.white,
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
                            'Eliminar Bitácora',
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
            color: AppColors.morado,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          titulo,
          style: GoogleFonts.fredoka(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF5C4D6B),
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchItem({
    required IconData icon,
    required String label,
    required bool valor,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppColors.morado),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Switch(
          value: valor,
          onChanged: onChanged,
          activeColor: AppColors.morado,
          activeTrackColor: AppColors.morado.withOpacity(0.45),
        ),
      ],
    );
  }

  Color _getColorEstadoAnimo(String estadoAnimo) {
    switch (estadoAnimo.toLowerCase()) {
      case 'feliz':
        return Colors.green[300]!;
      case 'tranquilo':
        return Colors.blue[300]!;
      case 'triste':
        return Colors.orange[300]!;
      case 'irritable':
        return Colors.red[300]!;
      default:
        return Colors.grey[300]!;
    }
  }

  String _getEmojiEstadoAnimo(String estadoAnimo) {
    switch (estadoAnimo.toLowerCase()) {
      case 'feliz':
        return '😊';
      case 'tranquilo':
        return '😌';
      case 'triste':
        return '😢';
      case 'irritable':
        return '😠';
      default:
        return '😐';
    }
  }

  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fecha.isAfter(_hoy) ? _hoy : _fecha,
      firstDate: DateTime(2020),
      lastDate: _hoy,
      locale: const Locale('es', 'MX'),
    );

    if (fecha != null) {
      setState(() {
        _fecha = _soloFecha(fecha);
      });
    }
  }

  Future<void> _guardarBitacora() async {
    if (_profesoraSinGrupo || _profesoraBitacoraAjena) {
      return;
    }
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_alumnoSeleccionadoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona un alumno'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_esDirectora && !_esEdicion && _gradoDirectorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona el grado'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!_esDirectora && _miProfesorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Tu usuario no está registrado como profesora en el sistema. Contacta a la directora.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _cargando = true);

    try {
      final Map<String, dynamic> bitacoraData = {
        'alumno_id': _alumnoSeleccionadoId,
        'fecha': DateFormat('yyyy-MM-dd').format(_fecha),
        // BD: constraint suele ser si|no|medio — 'mas_o_menos' se guarda como 'medio'
        'comio': _comio == 'mas_o_menos' ? 'medio' : _comio,
        'tomo_agua': _tomoAgua,
        'pipi': _pipi,
        'popo': _popo,
        'lavo_dientes': _lavoDientes,
        'respeto_demas': _respetoDemas,
        'realizo_actividades': _realizoActividades,
        'siesta': _siesta,
        'estado_animo': _estadoAnimo,
        'observaciones': _observacionesController.text.trim().isEmpty
            ? null
            : _observacionesController.text.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (!_esEdicion) {
        bitacoraData['profesor_id'] = _esDirectora ? null : _miProfesorId;
      }

      if (_esEdicion) {
        await Supabase.instance.client
            .from('bitacora_diaria')
            .update(bitacoraData)
            .eq('id', widget.bitacoraId!);
      } else {
        bitacoraData['id'] = const Uuid().v4();
        bitacoraData['created_at'] = DateTime.now().toIso8601String();

        await Supabase.instance.client
            .from('bitacora_diaria')
            .insert(bitacoraData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _esEdicion
                  ? '✓ Bitácora actualizada correctamente'
                  : '✓ Bitácora creada correctamente',
            ),
            backgroundColor: Colors.green,
          ),
        );
        GoRouter.of(context).go('/directora/bitacoras');
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString().toLowerCase();
        final esDuplicado = msg.contains('duplicate') ||
            msg.contains('23505') ||
            msg.contains('unique constraint') ||
            msg.contains('violates unique') ||
            msg.contains('already exists');
        if (esDuplicado) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Ya existe una bitácora para este alumno en el día seleccionado. '
                'Ve a la lista de bitácoras, filtra por fecha y alumno, y edítala desde ahí.',
                style: GoogleFonts.poppins(fontSize: 14),
              ),
              backgroundColor: Colors.deepOrange.shade800,
              duration: const Duration(seconds: 7),
            ),
          );
        } else {
          final hint = msg.contains('profesor_id') || msg.contains('23503')
              ? ' Si eres directora, ejecuta en Supabase el script FIX_BITACORA_PROFESOR_ID.sql'
              : '';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al guardar: $e$hint'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 8),
            ),
          );
        }
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
              '¿Eliminar Bitácora?',
              style: GoogleFonts.fredoka(),
            ),
          ],
        ),
        content: Text(
          'Esta acción no se puede deshacer. ¿Estás segura de eliminar esta bitácora?',
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
      await _eliminarBitacora();
    }
  }

  Future<void> _eliminarBitacora() async {
    setState(() => _cargando = true);

    try {
      await Supabase.instance.client
          .from('bitacora_diaria')
          .delete()
          .eq('id', widget.bitacoraId!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Bitácora eliminada correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        GoRouter.of(context).go('/directora/bitacoras');
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
