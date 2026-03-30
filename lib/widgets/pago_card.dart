import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/pago.dart';

class PagoCard extends StatelessWidget {
  final Pago pago;
  final VoidCallback? onMarcarPagado;

  const PagoCard({
    super.key,
    required this.pago,
    this.onMarcarPagado,
  });

  @override
  Widget build(BuildContext context) {
    final estado = pago.estado;
    final Color estadoColor;
    final String estadoTexto;

    switch (estado) {
      case EstadoPago.pagado:
        estadoColor = Colors.green;
        estadoTexto = 'Pagado';
        break;
      case EstadoPago.parcial:
        estadoColor = Colors.blue;
        estadoTexto = 'Parcial';
        break;
      case EstadoPago.vencido:
        estadoColor = Colors.red;
        estadoTexto = 'Vencido';
        break;
      case EstadoPago.cancelado:
        estadoColor = Colors.grey;
        estadoTexto = 'Cancelado';
        break;
      case EstadoPago.pendiente:
        estadoColor = Colors.orange;
        estadoTexto = 'Pendiente';
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: estadoColor.withOpacity(0.2),
          child: Icon(
            estado == EstadoPago.pagado
                ? Icons.check_circle
                : Icons.payment,
            color: estadoColor,
          ),
        ),
        title: Text(pago.concepto ?? 'Sin concepto'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(pago.montoFormateado),
            Text(
              pago.fechaVencimiento != null
                  ? 'Vence: ${DateFormat('dd/MMM/yyyy').format(pago.fechaVencimiento!)}'
                  : 'Sin fecha límite',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '\$${pago.monto.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: estadoColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                estadoTexto,
                style: TextStyle(
                  fontSize: 11,
                  color: estadoColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        isThreeLine: true,
        onTap: !pago.estaPagado ? onMarcarPagado : null,
      ),
    );
  }
}
