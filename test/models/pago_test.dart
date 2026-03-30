import 'package:flutter_test/flutter_test.dart';
import 'package:escuela_caipi/models/pago.dart';

void main() {
  group('Pago Model Tests', () {
    test('Debe crear un pago desde JSON', () {
      // Arrange
      final json = {
        'id': 'pago-123',
        'alumno_id': 'alumno-123',
        'mes': 'Enero 2026',
        'monto': 1500.0,
        'concepto': 'Colegiatura',
        'pagado': false,
        'fecha_limite': '2026-01-10',
        'created_at': '2024-01-01T00:00:00Z',
        'updated_at': '2024-01-01T00:00:00Z',
      };

      // Act
      final pago = Pago.fromJson(json);

      // Assert
      expect(pago.id, 'pago-123');
      expect(pago.alumnoId, 'alumno-123');
      expect(pago.mes, 'Enero 2026');
      expect(pago.monto, 1500.0);
      expect(pago.concepto, 'Colegiatura');
      expect(pago.pagado, false);
    });

    test('Debe identificar pago pendiente correctamente', () {
      // Arrange - Pago con fecha límite futura
      final pagoPendiente = Pago(
        id: 'pago-1',
        alumnoId: 'alumno-1',
        mes: 'Diciembre 2026',
        monto: 1500.0,
        concepto: 'Colegiatura',
        pagado: false,
        fechaLimite: DateTime.now().add(const Duration(days: 30)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Assert
      expect(pagoPendiente.estado, EstadoPago.pendiente);
    });

    test('Debe identificar pago vencido correctamente', () {
      // Arrange - Pago con fecha límite pasada
      final pagoVencido = Pago(
        id: 'pago-2',
        alumnoId: 'alumno-1',
        mes: 'Enero 2026',
        monto: 1500.0,
        concepto: 'Colegiatura',
        pagado: false,
        fechaLimite: DateTime.now().subtract(const Duration(days: 10)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Assert
      expect(pagoVencido.estado, EstadoPago.vencido);
    });

    test('Debe identificar pago pagado correctamente', () {
      // Arrange
      final pagoPagado = Pago(
        id: 'pago-3',
        alumnoId: 'alumno-1',
        mes: 'Enero 2026',
        monto: 1500.0,
        concepto: 'Colegiatura',
        pagado: true,
        fechaLimite: DateTime.now(),
        fechaPago: DateTime.now(),
        metodoPago: 'Efectivo',
        recibidoPor: 'directora',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Assert
      expect(pagoPagado.estado, EstadoPago.pagado);
      expect(pagoPagado.metodoPago, 'Efectivo');
      expect(pagoPagado.recibidoPor, 'directora');
      expect(pagoPagado.nombreQuienRecibio, 'Directora');
    });

    test('Debe convertir quien recibió correctamente', () {
      // Arrange
      final pagoDirectora = Pago(
        id: 'pago-1',
        alumnoId: 'alumno-1',
        mes: 'Enero 2026',
        monto: 1500.0,
        concepto: 'Colegiatura',
        fechaLimite: DateTime.now(),
        recibidoPor: 'directora',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final pagoJoss = Pago(
        id: 'pago-2',
        alumnoId: 'alumno-1',
        mes: 'Febrero 2026',
        monto: 1500.0,
        concepto: 'Colegiatura',
        fechaLimite: DateTime.now(),
        recibidoPor: 'joss',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Assert
      expect(pagoDirectora.nombreQuienRecibio, 'Directora');
      expect(pagoJoss.nombreQuienRecibio, 'Joss');
    });
  });
}
