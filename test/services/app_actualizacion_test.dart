import 'package:flutter_test/flutter_test.dart';
import 'package:escuela_caipi/services/app_actualizacion_service.dart';

void main() {
  test('no bloquea si está apagado o el build alcanza', () {
    expect(
      AppActualizacionService.debeBloquear(
        buildActual: 4017,
        buildMinimo: 4018,
        activo: false,
      ),
      isFalse,
    );
    expect(
      AppActualizacionService.debeBloquear(
        buildActual: 4018,
        buildMinimo: 4018,
        activo: true,
      ),
      isFalse,
    );
  });

  test('bloquea si el build instalado es menor', () {
    expect(
      AppActualizacionService.debeBloquear(
        buildActual: 4017,
        buildMinimo: 4018,
        activo: true,
      ),
      isTrue,
    );
  });
}
