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
  test('kinder genera colegiatura; maternal y estimulacion no', () {
    expect(_g('Kínder 1').generaColegiaturaAutomatica, isTrue);
    expect(_g('Maternal').generaColegiaturaAutomatica, isFalse);
    expect(_g('Estimulación Temprana').generaColegiaturaAutomatica, isFalse);
    expect(_g('Estimulación Temprana').cobroPorClase, isTrue);
    expect(_g('Maternal').esMaternalOBebes, isTrue);
    expect(_g('Estimulación Temprana').esMaternalOBebes, isTrue);
  });
}
