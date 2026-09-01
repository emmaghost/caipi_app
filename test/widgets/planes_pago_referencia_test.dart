import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:escuela_caipi/models/configuracion_costos.dart';
import 'package:escuela_caipi/widgets/planes_pago_referencia.dart';

void main() {
  final ahora = DateTime(2026, 9, 1);

  ConfiguracionCostos costos({
    double mensualidad12 = 2000,
    double? anticipado12,
    double? recargo12,
  }) {
    return ConfiguracionCostos(
      id: 'cfg',
      costoInscripcion: 1500,
      costoSeguroCredencial: 300,
      costoMensualidad12: mensualidad12,
      costoMensualidad11: 2200,
      costoMensualidad10: 2400,
      costoAnticipado12: anticipado12,
      costoRecargo12: recargo12,
      vigente: true,
      vigenciaDesde: ahora,
      createdAt: ahora,
      updatedAt: ahora,
    );
  }

  testWidgets('muestra anticipado y recargo calculados', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlanesPagoReferencia(config: costos()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Planes para cotizar'), findsOneWidget);
    expect(find.text('Pago anticipado'), findsOneWidget);
    expect(find.text('Pago con recargo'), findsOneWidget);
    expect(find.textContaining('24,000.00'), findsWidgets);
  });

  testWidgets('usa montos configurados si existen', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlanesPagoReferencia(
            config: costos(anticipado12: 18000, recargo12: 26000),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('18,000.00'), findsOneWidget);
    expect(find.textContaining('26,000.00'), findsOneWidget);
  });
}
