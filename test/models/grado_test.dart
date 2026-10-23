import 'package:flutter_test/flutter_test.dart';
import 'package:escuela_caipi/models/grado.dart';

Grado _g(String nombre) {
  final f = DateTime(2026, 1, 1);
  return Grado(
    id: '1',
    nombre: nombre,
    cupoMaximo: 20,
    createdAt: f,
    updatedAt: f,
  );
}

void main() {
  test('kinder usa colegiatura; maternal y lactante usan paquete', () {
    expect(_g('Kínder 1').muestraModuloPagos, isTrue);
    expect(_g('Kinder 2').generaColegiaturaAutomatica, isTrue);
    expect(_g('Kinder 3').usaCostosMaternal, isFalse);
    expect(_g('Maternal 2 vespertino').generaColegiaturaAutomatica, isFalse);
    expect(_g('Maternal 2 vespertino').usaCostosMaternal, isTrue);
    expect(_g('LACTANTES Matutino').usaCostosMaternal, isTrue);
    expect(_g('LACTANTES Matutino').generaColegiaturaAutomatica, isFalse);
    expect(_g('Bebés').esLactanteOBebes, isTrue);
    expect(_g('Estimulación Temprana').usaCostosMaternal, isTrue);
    expect(_g('Estimulación Temprana').generaColegiaturaAutomatica, isFalse);
  });
}
