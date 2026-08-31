import 'package:flutter_test/flutter_test.dart';
import 'package:escuela_caipi/models/pago.dart';
import 'package:escuela_caipi/utils/pago_helpers.dart';

void main() {
  group('PagoHelpers', () {
    test('etiquetaPeriodo usa mes en español y año', () {
      expect(
        PagoHelpers.etiquetaPeriodo(DateTime(2026, 3, 1)),
        'Marzo 2026',
      );
      expect(
        PagoHelpers.etiquetaPeriodo(DateTime(2025, 12, 15)),
        'Diciembre 2025',
      );
    });

    test('montoNeto resta descuento', () {
      expect(
        PagoHelpers.montoNeto(montoBruto: 1500, descuento: 200),
        1300,
      );
      expect(
        PagoHelpers.montoNeto(montoBruto: 800, descuento: 0),
        800,
      );
    });

    test('montoNeto rechaza descuento inválido', () {
      expect(
        () => PagoHelpers.montoNeto(montoBruto: 100, descuento: 150),
        throwsArgumentError,
      );
      expect(
        () => PagoHelpers.montoNeto(montoBruto: 100, descuento: -1),
        throwsArgumentError,
      );
    });

    test('notasConDescuento combina descuento y texto libre', () {
      final notas = PagoHelpers.notasConDescuento(
        montoBruto: 1500,
        descuento: 300,
        notasUsuario: 'Entró a mitad de mes',
      );
      expect(notas, contains('Descuento \$300.00'));
      expect(notas, contains('Entró a mitad de mes'));
    });

    test('puedeEliminarse solo pendientes sin abonos', () {
      final ahora = DateTime(2026, 7, 1);
      final pendiente = Pago(
        id: '1',
        alumnoId: 'a',
        monto: 1000,
        estatus: 'pendiente',
        createdAt: ahora,
        updatedAt: ahora,
      );
      final conAbono = pendiente.copyWith(montoPagado: 100, estatus: 'parcial');
      final pagado = pendiente.copyWith(
        montoPagado: 1000,
        estatus: 'pagado',
      );

      expect(PagoHelpers.puedeEliminarse(pendiente), isTrue);
      expect(pendiente.puedeEliminarse, isTrue);
      expect(PagoHelpers.puedeEliminarse(conAbono), isFalse);
      expect(PagoHelpers.puedeEliminarse(pagado), isFalse);
    });

    test('idsEliminables ignora pagos con abonos', () {
      final ahora = DateTime(2026, 7, 1);
      final p1 = Pago(
        id: 'p1',
        alumnoId: 'a',
        monto: 500,
        estatus: 'pendiente',
        createdAt: ahora,
        updatedAt: ahora,
      );
      final p2 = Pago(
        id: 'p2',
        alumnoId: 'a',
        monto: 500,
        montoPagado: 50,
        estatus: 'parcial',
        createdAt: ahora,
        updatedAt: ahora,
      );

      final ids = PagoHelpers.idsEliminables([p1, p2], ['p1', 'p2', 'p3']);
      expect(ids, ['p1']);
    });

    test('plan 11 va de agosto a junio', () {
      final fechas = PagoHelpers.fechasMensualidadesPlan(
        planPagos: 11,
        fechaIngreso: DateTime(2025, 8, 1),
      );
      expect(fechas.length, 11);
      expect(fechas.first, DateTime(2025, 8, 5));
      expect(fechas.last, DateTime(2026, 6, 5));
    });

    test('esTipoCuadroPagos excluye inscripción y seguro', () {
      expect(PagoHelpers.esTipoCuadroPagos('mensualidad'), isTrue);
      expect(PagoHelpers.esTipoCuadroPagos('otro'), isTrue);
      expect(PagoHelpers.esTipoCuadroPagos('inscripcion'), isFalse);
      expect(
        PagoHelpers.esTipoCuadroPagos(
          'inscripcion',
          concepto: 'Inscripción anual estimulación',
        ),
        isTrue,
      );
      expect(PagoHelpers.esTipoCuadroPagos('seguro'), isFalse);
    });
  });
}
