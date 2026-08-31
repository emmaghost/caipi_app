import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../config/app_colors.dart';
import '../../services/reportes_pdf_service.dart';
import '../../widgets/app_drawer.dart';

/// Pantalla solo directora: exportar reportes PDF con rango de fechas.
class ReportesPdfScreen extends StatefulWidget {
  const ReportesPdfScreen({super.key});

  @override
  State<ReportesPdfScreen> createState() => _ReportesPdfScreenState();
}

class _ReportesPdfScreenState extends State<ReportesPdfScreen> {
  DateTime _desde = DateTime.now().subtract(const Duration(days: 7));
  DateTime _hasta = DateTime.now();
  bool _generando = false;
  String? _generandoTipo;

  Future<void> _pickDesde() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _desde,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      locale: const Locale('es', 'MX'),
    );
    if (d != null) setState(() => _desde = d);
  }

  Future<void> _pickHasta() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _hasta,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      locale: const Locale('es', 'MX'),
    );
    if (d != null) setState(() => _hasta = d);
  }

  Future<void> _correr(String tipo, Future<void> Function() accion) async {
    if (_desde.isAfter(_hasta)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La fecha “desde” no puede ser mayor que “hasta”.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    setState(() {
      _generando = true;
      _generandoTipo = tipo;
    });
    try {
      await accion();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al generar PDF: $e'),
          backgroundColor: AppColors.rojo,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _generando = false;
          _generandoTipo = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy');
    return Scaffold(
      backgroundColor: AppColors.grisClaro,
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Text(
          'Reportes PDF',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => context.go('/directora'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Elige el rango de fechas y genera el PDF. Se abre el menú del '
            'teléfono para compartir (WhatsApp, Drive, correo…).',
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700]),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Rango de fechas',
                    style: GoogleFonts.fredoka(
                      fontSize: 18,
                      color: AppColors.morado,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _generando ? null : _pickDesde,
                          icon: const Icon(Icons.calendar_today, size: 18),
                          label: Text('Desde ${fmt.format(_desde)}'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _generando ? null : _pickHasta,
                          icon: const Icon(Icons.event, size: 18),
                          label: Text('Hasta ${fmt.format(_hasta)}'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: [
                      ActionChip(
                        label: const Text('Hoy'),
                        onPressed: _generando
                            ? null
                            : () => setState(() {
                                  _desde = DateTime.now();
                                  _hasta = DateTime.now();
                                }),
                      ),
                      ActionChip(
                        label: const Text('7 días'),
                        onPressed: _generando
                            ? null
                            : () => setState(() {
                                  _hasta = DateTime.now();
                                  _desde = DateTime.now()
                                      .subtract(const Duration(days: 7));
                                }),
                      ),
                      ActionChip(
                        label: const Text('30 días'),
                        onPressed: _generando
                            ? null
                            : () => setState(() {
                                  _hasta = DateTime.now();
                                  _desde = DateTime.now()
                                      .subtract(const Duration(days: 30));
                                }),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _tarjetaReporte(
            icono: Icons.assignment,
            titulo: 'Bitácora diaria',
            descripcion: 'Comidas, ánimo y observaciones por alumno.',
            tipo: 'bitacora',
            onTap: () => _correr(
              'bitacora',
              () => ReportesPdfService.compartirBitacoraDiaria(
                desde: _desde,
                hasta: _hasta,
              ),
            ),
          ),
          _tarjetaReporte(
            icono: Icons.receipt_long,
            titulo: 'Bitácora de gastos',
            descripcion: 'Gastos del periodo con total.',
            tipo: 'gastos',
            onTap: () => _correr(
              'gastos',
              () => ReportesPdfService.compartirBitacoraGastos(
                desde: _desde,
                hasta: _hasta,
              ),
            ),
          ),
          _tarjetaReporte(
            icono: Icons.access_time,
            titulo: 'Control entrada / salida',
            descripcion: 'Quién trajo y recogió a cada niño.',
            tipo: 'control',
            onTap: () => _correr(
              'control',
              () => ReportesPdfService.compartirControlSalidas(
                desde: _desde,
                hasta: _hasta,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Las entrevistas por alumno se descargan desde '
            'Entrevista a Padres → ícono PDF de cada niño.',
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _tarjetaReporte({
    required IconData icono,
    required String titulo,
    required String descripcion,
    required String tipo,
    required VoidCallback onTap,
  }) {
    final cargandoEste = _generando && _generandoTipo == tipo;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: CircleAvatar(
          backgroundColor: AppColors.morado.withOpacity(0.12),
          child: Icon(icono, color: AppColors.morado),
        ),
        title: Text(
          titulo,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(descripcion),
        trailing: cargandoEste
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : FilledButton.icon(
                onPressed: _generando ? null : onTap,
                icon: const Icon(Icons.picture_as_pdf, size: 18),
                label: const Text('PDF'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF166534),
                ),
              ),
      ),
    );
  }
}
