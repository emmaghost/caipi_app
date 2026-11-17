import 'package:flutter_test/flutter_test.dart';
import 'package:escuela_caipi/models/acceso_padre_estado.dart';

void main() {
  test('lee adeudos aunque el mapa venga como Map<String, dynamic>', () {
    final estado = AccesoPadreEstado.fromJson(<String, dynamic>{
      'restringido': true,
      'modo': 'automatico',
      'motivo': 'Colegiatura(s) pendiente(s) de pago',
      'adeudos': <dynamic>[
        <String, dynamic>{
          'alumno_id': '1',
          'alumno_nombre': 'Ian Dimitri Ortega',
          'mes': 'November 2026',
          'monto': 2530,
          'saldo': 2530,
          'fecha_vencimiento': '2026-11-05',
        },
      ],
    });

    expect(estado.restringido, isTrue);
    expect(estado.adeudos, hasLength(1));
    expect(estado.adeudos.first.alumnoNombre, 'Ian Dimitri Ortega');
    expect(estado.adeudos.first.saldo, 2530);
  });
}
