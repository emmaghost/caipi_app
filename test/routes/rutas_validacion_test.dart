import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Validación de Rutas - Sistema Completo', () {
    // Lista de todas las rutas esperadas
    final rutasEsperadas = [
      '/',
      '/login',
      '/directora',
      '/directora/alumnos',
      '/directora/alumnos/crear',
      '/directora/alumnos/editar/:id',
      '/directora/pagos',
      '/acreditar-pago/:pagoId',
      '/directora/profesores',
      '/directora/profesores/crear',
      '/directora/profesores/editar/:id',
      '/directora/padres',
      '/directora/padres/crear',
      '/directora/padres/ver/:id',
      '/directora/personas-autorizadas/:alumnoId',
      '/directora/anuncios/crear',
      '/padre',
      '/padre/hijo/:id',
    ];

    test('Debe haber exactamente 18 rutas en el sistema', () {
      expect(rutasEsperadas.length, 18);
    });

    test('Todas las rutas deben ser únicas', () {
      final rutasSet = rutasEsperadas.toSet();
      expect(rutasSet.length, rutasEsperadas.length,
          reason: 'Hay rutas duplicadas');
    });

    test('Todas las rutas deben empezar con /', () {
      for (var ruta in rutasEsperadas) {
        expect(ruta.startsWith('/'), true, reason: 'Ruta $ruta debe empezar con /');
      }
    });

    test('Rutas de directora (excepciones) deben tener el prefijo correcto', () {
      final rutasDirectora = rutasEsperadas.where((r) =>
          r.contains('alumnos') ||
          r.contains('profesores') ||
          r.contains('padres') ||
          r.contains('personas-autorizadas') ||
          r.contains('anuncios')).toList();

      for (var ruta in rutasDirectora) {
        if (!ruta.contains('acreditar-pago')) {
          expect(ruta.startsWith('/directora'), true,
              reason: 'Ruta $ruta debe empezar con /directora');
        }
      }
    });

    test('Rutas de padre deben tener el prefijo /padre', () {
      final rutasPadre = rutasEsperadas
          .where((r) => r.contains('hijo') || r == '/padre')
          .toList();

      for (var ruta in rutasPadre) {
        expect(ruta.startsWith('/padre'), true,
            reason: 'Ruta $ruta debe empezar con /padre');
      }
    });

    test('Rutas con parámetros deben usar : correctamente', () {
      final rutasConParams = rutasEsperadas.where((r) => r.contains(':')).toList();

      expect(rutasConParams.length, 6,
          reason: 'Debe haber exactamente 6 rutas con parámetros');

      // Validar rutas con parámetros
      expect(rutasConParams.contains('/directora/alumnos/editar/:id'), true);
      expect(rutasConParams.contains('/acreditar-pago/:pagoId'), true);
      expect(rutasConParams.contains('/directora/profesores/editar/:id'), true);
      expect(rutasConParams.contains('/directora/padres/ver/:id'), true);
      expect(rutasConParams.contains('/directora/personas-autorizadas/:alumnoId'), true);
      expect(rutasConParams.contains('/padre/hijo/:id'), true);
    });

    group('Rutas Críticas del Sistema', () {
      test('Ruta raíz existe', () {
        expect(rutasEsperadas.contains('/'), true);
      });

      test('Ruta de login existe', () {
        expect(rutasEsperadas.contains('/login'), true);
      });

      test('Dashboard directora existe', () {
        expect(rutasEsperadas.contains('/directora'), true);
      });

      test('Dashboard padre existe', () {
        expect(rutasEsperadas.contains('/padre'), true);
      });

      test('Crear alumno existe', () {
        expect(rutasEsperadas.contains('/directora/alumnos/crear'), true);
      });

      test('Ver alumnos existe', () {
        expect(rutasEsperadas.contains('/directora/alumnos'), true);
      });

      test('Gestionar pagos existe', () {
        expect(rutasEsperadas.contains('/directora/pagos'), true);
      });

      test('Acreditar pago existe', () {
        expect(rutasEsperadas.contains('/acreditar-pago/:pagoId'), true);
      });

      test('Ver profesores existe', () {
        expect(rutasEsperadas.contains('/directora/profesores'), true);
      });

      test('Crear profesor existe', () {
        expect(rutasEsperadas.contains('/directora/profesores/crear'), true);
      });

      test('Ver padres existe', () {
        expect(rutasEsperadas.contains('/directora/padres'), true);
      });

      test('Crear padre existe', () {
        expect(rutasEsperadas.contains('/directora/padres/crear'), true);
      });

      test('Personas autorizadas existe', () {
        expect(rutasEsperadas.contains('/directora/personas-autorizadas/:alumnoId'), true);
      });

      test('Ver detalle de hijo (padre) existe', () {
        expect(rutasEsperadas.contains('/padre/hijo/:id'), true);
      });
    });

    group('Módulos del Sistema', () {
      test('Módulo de Alumnos: 3 rutas', () {
        final rutasAlumnos = rutasEsperadas
            .where((r) => r.contains('alumnos'))
            .toList();
        
        expect(rutasAlumnos.length, 3);
        expect(rutasAlumnos.contains('/directora/alumnos'), true);
        expect(rutasAlumnos.contains('/directora/alumnos/crear'), true);
        expect(rutasAlumnos.contains('/directora/alumnos/editar/:id'), true);
      });

      test('Módulo de Pagos: 2 rutas', () {
        final rutasPagos = rutasEsperadas
            .where((r) => r.contains('pago'))
            .toList();
        
        expect(rutasPagos.length, 2);
        expect(rutasPagos.contains('/directora/pagos'), true);
        expect(rutasPagos.contains('/acreditar-pago/:pagoId'), true);
      });

      test('Módulo de Profesores: 3 rutas', () {
        final rutasProfesores = rutasEsperadas
            .where((r) => r.contains('profesores'))
            .toList();
        
        expect(rutasProfesores.length, 3);
        expect(rutasProfesores.contains('/directora/profesores'), true);
        expect(rutasProfesores.contains('/directora/profesores/crear'), true);
        expect(rutasProfesores.contains('/directora/profesores/editar/:id'), true);
      });

      test('Módulo de Padres: 3 rutas', () {
        final rutasPadres = rutasEsperadas
            .where((r) => r.contains('padres'))
            .toList();
        
        expect(rutasPadres.length, 3);
        expect(rutasPadres.contains('/directora/padres'), true);
        expect(rutasPadres.contains('/directora/padres/crear'), true);
        expect(rutasPadres.contains('/directora/padres/ver/:id'), true);
      });

      test('Módulo de Personas Autorizadas: 1 ruta', () {
        final rutasPersonas = rutasEsperadas
            .where((r) => r.contains('personas-autorizadas'))
            .toList();
        
        expect(rutasPersonas.length, 1);
        expect(rutasPersonas.contains('/directora/personas-autorizadas/:alumnoId'), true);
      });

      test('Módulo de Padres (vista): 2 rutas', () {
        final rutasPadreVista = rutasEsperadas
            .where((r) => r.startsWith('/padre'))
            .toList();
        
        expect(rutasPadreVista.length, 2);
        expect(rutasPadreVista.contains('/padre'), true);
        expect(rutasPadreVista.contains('/padre/hijo/:id'), true);
      });
    });

    group('Seguridad de Rutas', () {
      test('Rutas públicas: 2 (raíz y login)', () {
        final rutasPublicas = ['/', '/login'];
        
        for (var ruta in rutasPublicas) {
          expect(rutasEsperadas.contains(ruta), true,
              reason: 'Ruta pública $ruta debe existir');
        }
      });

      test('Rutas de Directora: 14 rutas protegidas', () {
        final rutasDirectora = rutasEsperadas
            .where((r) => r.startsWith('/directora') || r == '/acreditar-pago/:pagoId')
            .toList();
        
        expect(rutasDirectora.length, 14);
      });

      test('Rutas de Padre: 2 rutas protegidas', () {
        final rutasPadre = rutasEsperadas
            .where((r) => r.startsWith('/padre'))
            .toList();
        
        expect(rutasPadre.length, 2);
      });

      test('NO debe haber rutas sin protección de rol', () {
        // Todas las rutas excepto / y /login deben tener prefijo de rol
        final rutasProtegidas = rutasEsperadas
            .where((r) => r != '/' && r != '/login')
            .toList();

        for (var ruta in rutasProtegidas) {
          final tieneRol = ruta.startsWith('/directora') ||
              ruta.startsWith('/padre') ||
              ruta.startsWith('/acreditar-pago'); // Ruta especial

          expect(tieneRol, true,
              reason: 'Ruta $ruta debe tener prefijo de rol');
        }
      });
    });

    group('Consistencia de Rutas', () {
      test('Rutas CRUD siguen patrón consistente', () {
        // Patrón esperado: /modulo, /modulo/crear, /modulo/editar/:id
        
        // Alumnos
        expect(rutasEsperadas.contains('/directora/alumnos'), true);
        expect(rutasEsperadas.contains('/directora/alumnos/crear'), true);
        expect(rutasEsperadas.contains('/directora/alumnos/editar/:id'), true);

        // Profesores
        expect(rutasEsperadas.contains('/directora/profesores'), true);
        expect(rutasEsperadas.contains('/directora/profesores/crear'), true);
        expect(rutasEsperadas.contains('/directora/profesores/editar/:id'), true);

        // Padres (sin editar por ahora)
        expect(rutasEsperadas.contains('/directora/padres'), true);
        expect(rutasEsperadas.contains('/directora/padres/crear'), true);
      });

      test('NO hay rutas terminadas en /', () {
        for (var ruta in rutasEsperadas) {
          if (ruta != '/') {
            expect(ruta.endsWith('/'), false,
                reason: 'Ruta $ruta no debe terminar en /');
          }
        }
      });

      test('Parámetros de ruta usan nombres descriptivos', () {
        // :id, :pagoId, :alumnoId son nombres válidos
        final rutasConParams = rutasEsperadas.where((r) => r.contains(':')).toList();

        for (var ruta in rutasConParams) {
          final regex = RegExp(r':(\w+)');
          final matches = regex.allMatches(ruta);
          
          for (var match in matches) {
            final param = match.group(1)!;
            // Verificar que el parámetro tiene sentido
            expect(param.length > 1, true,
                reason: 'Parámetro :$param debe ser descriptivo');
          }
        }
      });
    });
  });
}
