import 'package:escuela_caipi/models/abono.dart';
import 'package:escuela_caipi/models/alumno.dart';
import 'package:escuela_caipi/models/pago.dart';
import 'package:escuela_caipi/services/recibo_pago_pdf.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('genera un recibo PDF válido', () async {
    final ahora = DateTime(2026, 7, 21, 9, 30);
    final alumno = Alumno(
      id: 'alumno-1',
      nombre: 'María',
      apellidos: 'López',
      fechaNacimiento: DateTime(2021, 3, 4),
      padreId: 'padre-1',
      fechaIngreso: DateTime(2026, 8, 1),
      createdAt: ahora,
      updatedAt: ahora,
    );
    final pago = Pago(
      id: 'pago-1',
      alumnoId: alumno.id,
      concepto: 'Colegiatura',
      mes: 'Agosto 2026',
      monto: 1500,
      fechaVencimiento: DateTime(2026, 8, 10),
      createdAt: ahora,
      updatedAt: ahora,
    );
    final abono = Abono(
      id: 'abono-1',
      pagoId: pago.id,
      monto: 1500,
      fechaAbono: ahora,
      formaPago: 'Transferencia',
      referencia: 'TEST-123',
      recibidoPorNombre: 'BBVA Instituto Brain',
      reciboFolio: 'REC-2026-0001',
      createdAt: ahora,
    );

    final bytes = await ReciboPagoPdf.generar(
      abono: abono,
      pago: pago,
      alumno: alumno,
    );

    expect(bytes.length, greaterThan(1000));
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });
}
