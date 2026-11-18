import 'package:escuela_caipi/utils/codigo_qr.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('acepta el código de 8 caracteres del QR', () {
    expect(codigoDesdeEscaneo(' a1b2c3d4 '), 'A1B2C3D4');
  });

  test('rechaza un QR que no es el código de CAIPI', () {
    expect(codigoDesdeEscaneo('https://caipi.example/pase'), isNull);
    expect(codigoDesdeEscaneo('ABC'), isNull);
    expect(codigoDesdeEscaneo(''), isNull);
  });
}
