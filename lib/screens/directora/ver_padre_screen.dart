import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/app_colors.dart';
import '../../widgets/app_drawer.dart';

class VerPadreScreen extends StatefulWidget {
  final String padreId;

  const VerPadreScreen({super.key, required this.padreId});

  @override
  State<VerPadreScreen> createState() => _VerPadreScreenState();
}

class _VerPadreScreenState extends State<VerPadreScreen> {
  Map<String, dynamic>? _padre;
  List<Map<String, dynamic>> _hijos = [];
  bool _isLoading = true;
  bool _guardandoAccesoApp = false;

  String get _modoAccesoApp =>
      (_padre?['acceso_app_modo'] as String?) ?? 'automatico';

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    try {
      // Cargar datos del padre
      final padreData = await Supabase.instance.client
          .from('usuarios')
          .select()
          .eq('id', widget.padreId)
          .single();

      // Cargar hijos del padre (principal o segundo tutor)
      List<Map<String, dynamic>> hijosData = [];
      try {
        final idsResp = await Supabase.instance.client
            .from('alumnos_padres')
            .select('alumno_id')
            .eq('padre_id', widget.padreId);
        final ids = (idsResp as List)
            .map((e) => e['alumno_id'] as String)
            .toSet();
        if (ids.isNotEmpty) {
          final porVinculo = await Supabase.instance.client
              .from('alumnos')
              .select('*, grados(nombre)')
              .inFilter('id', ids.toList())
              .eq('activo', true);
          hijosData = List<Map<String, dynamic>>.from(porVinculo);
        }
      } catch (_) {}
      if (hijosData.isEmpty) {
        final porColumna = await Supabase.instance.client
            .from('alumnos')
            .select('*, grados(nombre)')
            .eq('padre_id', widget.padreId)
            .eq('activo', true);
        hijosData = List<Map<String, dynamic>>.from(porColumna);
      }

      setState(() {
        _padre = padreData;
        _hijos = List<Map<String, dynamic>>.from(hijosData);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar datos: $e')),
        );
      }
    }
  }

  Future<void> _cambiarAcceso(bool activo) async {
    try {
      await Supabase.instance.client
          .from('usuarios')
          .update({'activo': activo})
          .eq('id', widget.padreId);

      setState(() {
        _padre = {...?_padre, 'activo': activo};
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            activo
                ? 'Acceso habilitado: puede entrar a la app'
                : 'Acceso deshabilitado: no podrá iniciar sesión',
          ),
          backgroundColor: activo ? AppColors.verde : AppColors.naranja,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo actualizar el acceso: $e'),
          backgroundColor: AppColors.rojo,
        ),
      );
    }
  }

  Future<void> _guardarModoAccesoApp(String modo, {String? nota}) async {
    setState(() => _guardandoAccesoApp = true);
    try {
      final payload = <String, dynamic>{
        'acceso_app_modo': modo,
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (nota != null) payload['acceso_app_nota'] = nota.trim().isEmpty ? null : nota.trim();
      if (modo != 'desbloqueado') payload['acceso_app_hasta'] = null;

      await Supabase.instance.client
          .from('usuarios')
          .update(payload)
          .eq('id', widget.padreId);

      setState(() {
        _padre = {...?_padre, ...payload};
        _guardandoAccesoApp = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_etiquetaModoAcceso(modo)),
          backgroundColor: AppColors.verde,
        ),
      );
    } catch (e) {
      setState(() => _guardandoAccesoApp = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo guardar: $e'),
          backgroundColor: AppColors.rojo,
        ),
      );
    }
  }

  String _etiquetaModoAcceso(String modo) {
    switch (modo) {
      case 'desbloqueado':
        return 'Acceso app desbloqueado (aunque deba)';
      case 'bloqueado':
        return 'Acceso app bloqueado manualmente';
      default:
        return 'Acceso app en automático (por adeudo)';
    }
  }

  Future<void> _editarNotaAccesoApp() async {
    final ctrl = TextEditingController(
      text: _padre?['acceso_app_nota'] as String? ?? '',
    );
    final nota = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Nota de acceso', style: GoogleFonts.fredoka()),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Ej: Convenio de pago hasta el 30…',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (nota == null) return;
    await _guardarModoAccesoApp(_modoAccesoApp, nota: nota);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grisClaro,
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Text(
          'Detalles del Padre',
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _padre == null
              ? const Center(child: Text('Padre no encontrado'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoCard(),
                      const SizedBox(height: 20),
                      _buildHijosSection(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.rosa, AppColors.naranja],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _padre!['nombre'] ?? 'Sin nombre',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_padre!['apellidos'] != null)
                        Text(
                          _padre!['apellidos'],
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: AppColors.gris,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            _buildInfoRow(Icons.email, 'Email', _padre!['email'] ?? 'No registrado'),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.phone, 'Teléfono', _padre!['telefono'] ?? 'No registrado'),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.phone_android, 'WhatsApp', _padre!['whatsapp'] ?? 'No registrado'),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Acceso a la app',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                _padre!['activo'] == true
                    ? 'Puede iniciar sesión'
                    : 'Sin acceso (inhabilitado)',
                style: GoogleFonts.poppins(fontSize: 12, color: AppColors.gris),
              ),
              value: _padre!['activo'] == true,
              activeColor: AppColors.verde,
              onChanged: _cambiarAcceso,
            ),
            const Divider(height: 24),
            Text(
              'Acceso por adeudo (app padres)',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Automático: se restringe 5 días después del vencimiento de colegiatura de cualquier hijo vinculado.',
              style: GoogleFonts.poppins(fontSize: 11, color: AppColors.gris),
            ),
            const SizedBox(height: 8),
            if (_guardandoAccesoApp)
              const LinearProgressIndicator()
            else
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'automatico',
                    label: Text('Auto'),
                    icon: Icon(Icons.autorenew, size: 16),
                  ),
                  ButtonSegment(
                    value: 'desbloqueado',
                    label: Text('Libre'),
                    icon: Icon(Icons.lock_open, size: 16),
                  ),
                  ButtonSegment(
                    value: 'bloqueado',
                    label: Text('Bloq.'),
                    icon: Icon(Icons.lock, size: 16),
                  ),
                ],
                selected: {_modoAccesoApp},
                onSelectionChanged: (s) =>
                    _guardarModoAccesoApp(s.first),
              ),
            if (_padre?['acceso_app_nota'] != null &&
                (_padre!['acceso_app_nota'] as String).trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                _padre!['acceso_app_nota'] as String,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: AppColors.gris,
                ),
              ),
            ],
            TextButton.icon(
              onPressed: _guardandoAccesoApp ? null : _editarNotaAccesoApp,
              icon: const Icon(Icons.note_alt_outlined, size: 18),
              label: const Text('Nota interna'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color ?? AppColors.gris),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.gris,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHijosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Hijos (${_hijos.length})',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton.icon(
              onPressed: () => context.push('/directora/alumnos/crear'),
              icon: const Icon(Icons.add),
              label: const Text('Agregar'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_hijos.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.child_care,
                      size: 60,
                      color: AppColors.gris.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Este padre no tiene hijos registrados',
                      style: GoogleFonts.poppins(
                        color: AppColors.gris,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ..._hijos.map((hijo) => _buildHijoCard(hijo)),
      ],
    );
  }

  Widget _buildHijoCard(Map<String, dynamic> hijo) {
    final grado = hijo['grados'] != null ? hijo['grados']['nombre'] : 'Sin grado';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => context.push('/directora/alumnos/editar/${hijo['id']}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: hijo['genero'] == 'niña' 
                    ? AppColors.rosa.withOpacity(0.2) 
                    : AppColors.azul.withOpacity(0.2),
                child: Icon(
                  hijo['genero'] == 'niña' ? Icons.girl : Icons.boy,
                  color: hijo['genero'] == 'niña' ? AppColors.rosa : AppColors.azul,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${hijo['nombre']} ${hijo['apellidos'] ?? ''}',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.school,
                          size: 14,
                          color: AppColors.gris,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          grado,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.gris,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.gris,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
