import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/app_colors.dart';
import '../../models/pago.dart';
import '../../services/supabase_service.dart';
import '../../utils/pago_helpers.dart';

/// Solo colegiatura / otros (sin inscripción ni seguro en el cuadro).
enum _CatPadre { todas, colegiatura }

/// Solo consulta. Filtros: pendiente | pagado. Sin pagar desde la app.
class PagosPadreScreen extends StatefulWidget {
  final String alumnoId;
  final String alumnoNombre;

  const PagosPadreScreen({
    super.key,
    required this.alumnoId,
    required this.alumnoNombre,
  });

  @override
  State<PagosPadreScreen> createState() => _PagosPadreScreenState();
}

class _PagosPadreScreenState extends State<PagosPadreScreen> {
  /// true = pendiente, false = pagado
  bool _soloPendientes = true;
  _CatPadre _categoria = _CatPadre.todas;

  static _CatPadre? _categoriaDe(Pago p) {
    final t = (p.tipoPago ?? '').toLowerCase();
    final c = (p.concepto ?? '').toLowerCase();
    if (t == 'mensualidad' ||
        c.contains('colegiatura') ||
        c.contains('mensual')) {
      return _CatPadre.colegiatura;
    }
    return null;
  }

  static String _tituloCategoria(_CatPadre c) {
    switch (c) {
      case _CatPadre.colegiatura:
        return 'Colegiatura';
      case _CatPadre.todas:
        return 'Todas';
    }
  }

  List<Pago> _filtrar(List<Pago> todos) {
    return todos.where((p) {
      if (!PagoHelpers.esTipoCuadroPagos(p.tipoPago, concepto: p.concepto)) {
        return false;
      }
      final pend = !p.estaPagado;
      if (_soloPendientes && !pend) return false;
      if (!_soloPendientes && pend) return false;

      if (_categoria == _CatPadre.todas) return true;
      final cat = _categoriaDe(p);
      return cat == _categoria;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final service = context.read<SupabaseService>();

    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEC407A),
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Pagos',
              style: GoogleFonts.fredoka(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              widget.alumnoNombre,
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Bitácora',
            icon: const Icon(Icons.assignment_outlined),
            onPressed: () => context.push(
              '/padre/hijo/${widget.alumnoId}/bitacora',
              extra: {'alumnoNombre': widget.alumnoNombre},
            ),
          ),
          IconButton(
            tooltip: 'Ficha del hijo (autorizados, incidentes…)',
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push('/padre/hijo/${widget.alumnoId}'),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Colors.amber.shade100,
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.amber.shade900, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Solo consulta. El pago se hace en la escuela.',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey[900],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Text(
              'Estado',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.grey[700],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Pendientes'),
                    selected: _soloPendientes,
                    onSelected: (_) =>
                        setState(() => _soloPendientes = true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Pagados'),
                    selected: !_soloPendientes,
                    onSelected: (_) =>
                        setState(() => _soloPendientes = false),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
            child: Text(
              'Tipo',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.grey[700],
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: _CatPadre.values.map((c) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(_tituloCategoria(c)),
                    selected: _categoria == c,
                    onSelected: (_) => setState(() => _categoria = c),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<List<Pago>>(
              stream: service.getPagosPorAlumno(widget.alumnoId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final todos = snapshot.data ?? [];
                final filtrados = _filtrar(todos);

                if (filtrados.isEmpty) {
                  return ListView(children: [_vacio()]);
                }

                if (_categoria != _CatPadre.todas) {
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    children: filtrados.map((p) => _tarjetaPago(p)).toList(),
                  );
                }

                Widget seccion(String titulo, List<Pago> ps) {
                  if (ps.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 12, bottom: 8),
                        child: Text(
                          titulo,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppColors.morado,
                          ),
                        ),
                      ),
                      ...ps.map((p) => _tarjetaPago(p)),
                    ],
                  );
                }

                final coleg = filtrados
                    .where((p) => _categoriaDe(p) == _CatPadre.colegiatura)
                    .toList();
                final ot = filtrados.where((p) => _categoriaDe(p) == null).toList();

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  children: [
                    seccion('Colegiatura', coleg),
                    seccion('Otros', ot),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _vacio() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Text(
          _soloPendientes
              ? 'No hay pagos pendientes con estos filtros.'
              : 'No hay pagos pagados con estos filtros.',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[700]),
        ),
      ),
    );
  }

  Widget _tarjetaPago(Pago pago) {
    final venc = pago.fechaVencimiento;
    String? fechaTxt;
    if (venc != null) {
      fechaTxt = DateFormat('dd/MM/yyyy').format(venc);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          pago.concepto ?? 'Concepto',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (fechaTxt != null)
              Text(
                'Límite: $fechaTxt',
                style: GoogleFonts.poppins(fontSize: 12),
              ),
            if (pago.estaParcial)
              Text(
                'Pagado: ${pago.montoPagadoFormateado} de ${pago.montoFormateado}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.orange.shade800,
                ),
              ),
            if (pago.estaPagado &&
                pago.recibidoPorNombre != null &&
                pago.recibidoPorNombre!.trim().isNotEmpty)
              Text(
                'Cuenta: ${pago.recibidoPorNombre}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '\$${pago.monto.toStringAsFixed(0)}',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: pago.estaPagado
                    ? Colors.green.shade100
                    : Colors.orange.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                pago.estaPagado ? 'Pagado' : 'Pendiente',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: pago.estaPagado
                      ? Colors.green.shade800
                      : Colors.orange.shade900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
