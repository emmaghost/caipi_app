import 'package:flutter_test/flutter_test.dart';
import 'package:escuela_caipi/utils/push_payload_routes.dart';

void main() {
  group('rutaDesdePayloadPush', () {
    test('deja pasar rutas reales', () {
      expect(
        rutaDesdePayloadPush('/directora/entrega-afuera'),
        '/directora/entrega-afuera',
      );
      expect(rutaDesdePayloadPush('/padre/chat'), '/padre/chat');
    });

    test('mapea payloads legacy a rutas', () {
      expect(
        rutaDesdePayloadPush('solicitud_recogida'),
        '/directora/entrega-afuera',
      );
      expect(rutaDesdePayloadPush('chat'), '/directora/chat');
      expect(rutaDesdePayloadPush('pagos'), '/directora/pagos');
    });

    test('desconocido cae en entrega-afuera', () {
      expect(rutaDesdePayloadPush('foo'), '/directora/entrega-afuera');
      expect(rutaDesdePayloadPush('  '), '/directora/entrega-afuera');
    });
  });
}
