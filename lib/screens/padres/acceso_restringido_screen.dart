import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../config/app_colors.dart';
import '../../models/acceso_padre_estado.dart';
import '../../services/acceso_padre_service.dart';
import '../../services/auth_service.dart';

/// Pantalla única cuando hay adeudo: estilo "Google sin pagar".
/// Solo desde aquí puede ir a Chat con la escuela.
class AccesoRestringidoScreen extends StatefulWidget {
  const AccesoRestringidoScreen({super.key});

  @override
  State<AccesoRestringidoScreen> createState() =>
      _AccesoRestringidoScreenState();
}

class _AccesoRestringidoScreenState extends State<AccesoRestringidoScreen> {
  bool _actualizando = false;

  Future<void> _refrescar() async {
    final uid = context.read<AuthService>().currentUser?.id;
    if (uid == null) return;
    setState(() => _actualizando = true);
    await context.read<AccesoPadreService>().consultar(uid, forzar: true);
    if (!mounted) return;
    setState(() => _actualizando = false);
    final estado = context.read<AccesoPadreService>().estado;
    if (estado != null && !estado.restringido) {
      context.go('/padre');
    }
  }

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<AccesoPadreService>().estado;
    final auth = context.watch<AuthService>();

    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F8),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'CAIPI',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFEC407A),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _actualizando ? null : _refrescar,
            tooltip: 'Actualizar estado de pago',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await auth.logout();
              context.read<AccesoPadreService>().limpiar();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refrescar,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _Encabezado(motivo: estado?.motivo),
            const SizedBox(height: 20),
            if (estado != null && estado.adeudos.isNotEmpty)
              _ListaAdeudos(estado: estado)
            else if (_actualizando)
              const Center(child: CircularProgressIndicator())
            else
              _SinDetalle(modo: estado?.modo),
            const SizedBox(height: 24),
            _Acciones(onChat: () => context.go('/padre/chat')),
            const SizedBox(height: 16),
            Text(
              'Si ya realizaste tu pago, toca actualizar arriba. '
              'También puedes escribir a la directora por chat.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Encabezado extends StatelessWidget {
  final String? motivo;

  const _Encabezado({this.motivo});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.errorPago.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_clock,
                size: 48,
                color: AppColors.errorPago,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Acceso limitado',
              style: GoogleFonts.fredoka(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.azulOscuro,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              motivo ??
                  'Tienes colegiaturas pendientes. Regulariza tu pago en la escuela para recuperar el acceso completo a la app.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListaAdeudos extends StatelessWidget {
  final AccesoPadreEstado estado;

  const _ListaAdeudos({required this.estado});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'es_MX', symbol: '\$');
    final fechaFmt = DateFormat('dd/MM/yyyy', 'es_MX');

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Adeudos pendientes',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Bloqueo automático ${estado.diasGracia} días después del vencimiento',
              style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600]),
            ),
            const Divider(height: 24),
            ...estado.adeudos.map((a) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.school, size: 20, color: AppColors.morado),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            a.alumnoNombre.trim(),
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            a.mes ?? 'Colegiatura',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                          ),
                          if (a.fechaVencimiento != null)
                            Text(
                              'Venció: ${fechaFmt.format(a.fechaVencimiento!.toLocal())}',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: AppColors.errorPago,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      fmt.format(a.saldo),
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: AppColors.errorPago,
                      ),
                    ),
                  ],
                ),
              );
            }),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total pendiente',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),
                Text(
                  fmt.format(estado.totalSaldo),
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppColors.errorPago,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SinDetalle extends StatelessWidget {
  final String? modo;

  const _SinDetalle({this.modo});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          modo == 'bloqueado'
              ? 'La escuela restringió el acceso a tu cuenta. Usa el chat para contactar a la directora.'
              : 'Consultando adeudos…',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(color: Colors.grey[700]),
        ),
      ),
    );
  }
}

class _Acciones extends StatelessWidget {
  final VoidCallback onChat;

  const _Acciones({required this.onChat});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onChat,
        icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
        label: Text(
          'Chat con la Directora',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFEC407A),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
