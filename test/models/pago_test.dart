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
        'monto_pagado': 0,
        'estatus': 'pendiente',
        'fecha_vencimiento': '2026-01-10',
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
      expect(pago.estaPagado, false);
    });

    test('Debe identificar pago pendiente correctamente', () {
      // Arrange - Pago con fecha límite futura
      final pagoPendiente = Pago(
        id: 'pago-1',
        alumnoId: 'alumno-1',
        mes: 'Diciembre 2026',
        monto: 1500.0,
        concepto: 'Colegiatura',
        estatus: 'pendiente',
        fechaVencimiento: DateTime.now().add(const Duration(days: 30)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Assert
      expect(pagoPendiente.estado, EstadoPago.pendiente);
    });

    test('Debe identificar pago vencido por fecha aunque estatus sea pendiente', () {
      final pagoVencido = Pago(
        id: 'pago-2',
        alumnoId: 'alumno-1',
        mes: 'Enero 2026',
        monto: 1500.0,
        concepto: 'Colegiatura',
        estatus: 'pendiente',
        fechaVencimiento: DateTime.now().subtract(const Duration(days: 10)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(pagoVencido.estaVencido, true);
      expect(pagoVencido.esFuturo, false);
      expect(pagoVencido.estado, EstadoPago.vencido);
    });

    test('Debe identificar pago futuro correctamente', () {
      final pagoFuturo = Pago(
        id: 'pago-f',
        alumnoId: 'alumno-1',
        mes: 'Diciembre 2026',
        monto: 1500.0,
        concepto: 'Colegiatura',
        estatus: 'pendiente',
        fechaVencimiento: DateTime.now().add(const Duration(days: 40)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(pagoFuturo.esFuturo, true);
      expect(pagoFuturo.estaVencido, false);
      expect(pagoFuturo.estado, EstadoPago.pendiente);
    });

    test('Debe identificar pago pagado correctamente', () {
      // Arrange
      final pagoPagado = Pago(
        id: 'pago-3',
        alumnoId: 'alumno-1',
        mes: 'Enero 2026',
        monto: 1500.0,
        concepto: 'Colegiatura',
        montoPagado: 1500,
        estatus: 'pagado',
        fechaVencimiento: DateTime.now(),
        fechaPago: DateTime.now(),
        formaPago: 'Efectivo',
        recibidoPorNombre: 'BBVA Instituto Brain',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Assert
      expect(pagoPagado.estado, EstadoPago.pagado);
      expect(pagoPagado.formaPago, 'Efectivo');
      expect(pagoPagado.recibidoPorNombre, 'BBVA Instituto Brain');
    });

    test('Debe conservar la cuenta receptora', () {
      final pago = Pago(
        id: 'pago-1',
        alumnoId: 'alumno-1',
        mes: 'Enero 2026',
        monto: 1500.0,
        concepto: 'Colegiatura',
        fechaVencimiento: DateTime.now(),
        recibidoPorNombre: 'Efectivo',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(pago.recibidoPorNombre, 'Efectivo');
    });
  });
}
