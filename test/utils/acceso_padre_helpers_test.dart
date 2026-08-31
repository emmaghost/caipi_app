import 'package:flutter_test/flutter_test.dart';

import 'package:escuela_caipi/utils/pago_helpers.dart';

void main() {
  group('debeBloquearAccesoApp', () {
    final vencimiento = DateTime(2026, 3, 5);

    test('no bloquea si está pagado', () {
      expect(
        PagoHelpers.debeBloquearAccesoApp(
          fechaVencimiento: vencimiento,
          pagado: true,
          hoy: DateTime(2026, 3, 20),
        ),
        isFalse,
      );
    });

    test('no bloquea dentro de los 5 días de gracia', () {
      expect(
        PagoHelpers.debeBloquearAccesoApp(
          fechaVencimiento: vencimiento,
          pagado: false,
          hoy: DateTime(2026, 3, 10),
        ),
        isFalse,
      );
    });

    test('bloquea al día 11 (5 días después del 5 mar)', () {
      expect(
        PagoHelpers.debeBloquearAccesoApp(
          fechaVencimiento: vencimiento,
          pagado: false,
          hoy: DateTime(2026, 3, 11),
        ),
        isTrue,
      );
    });
  });
}
