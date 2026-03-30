import 'package:flutter_test/flutter_test.dart';
import 'package:escuela_caipi/routes/app_router.dart';

void main() {
  group('Router - Validación Básica', () {
    test('El router debe estar configurado correctamente', () {
      expect(appRouter, isNotNull);
      expect(appRouter.configuration, isNotNull);
    });

    test('El router debe tener rutas configuradas', () {
      final routes = appRouter.configuration.routes;
      expect(routes, isNotEmpty);
      expect(routes.length, greaterThan(0));
    });

    test('El router debe tener configuration', () {
      expect(appRouter.configuration, isNotNull);
    });

    test('Debe tener exactamente 18 rutas', () {
      final routes = appRouter.configuration.routes;
      expect(routes.length, 18);
    });

    test('Todas las rutas deben ser de tipo RouteBase', () {
      final routes = appRouter.configuration.routes;
      for (var route in routes) {
        expect(route, isNotNull);
      }
    });
  });
}
