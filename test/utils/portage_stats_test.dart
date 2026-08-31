import 'package:flutter_test/flutter_test.dart';
import 'package:escuela_caipi/models/portage.dart';
import 'package:escuela_caipi/utils/portage_stats.dart';

void main() {
  group('PortageStats', () {
    final ahora = DateTime(2026, 7, 27);

    PortageResultado resultado({
      required String id,
      required String evalId,
      String? estado,
    }) {
      return PortageResultado(
        id: id,
        evaluacionId: evalId,
        alumnoId: 'alumno-1',
        indicadorId: 'ind-$id',
        estado: estado,
        updatedAt: ahora,
      );
    }

    test('contarPorEstado cuenta logrados, en proceso y sin calificar', () {
      final conteo = PortageStats.contarPorEstado(
        resultados: [
          resultado(id: '1', evalId: 'e1', estado: PortageEstado.logrado),
          resultado(id: '2', evalId: 'e1', estado: PortageEstado.logrado),
          resultado(id: '3', evalId: 'e1', estado: PortageEstado.enProceso),
        ],
        totalIndicadores: 5,
      );

      expect(conteo.logrados, 2);
      expect(conteo.enProceso, 1);
      expect(conteo.sinCalificar, 2);
      expect(conteo.total, 5);
    });

    test('seriePorVentanaMeses filtra por fecha_inicio >= now - N meses', () {
      final evaluaciones = [
        PortageEvaluacion(
          id: 'vieja',
          listaId: 'l1',
          gradoId: 'g1',
          fechaInicio: DateTime(2026, 1, 15),
          createdAt: ahora,
        ),
        PortageEvaluacion(
          id: 'reciente',
          listaId: 'l1',
          gradoId: 'g1',
          fechaInicio: DateTime(2026, 7, 1),
          createdAt: ahora,
        ),
      ];

      final serie = PortageStats.seriePorVentanaMeses(
        evaluaciones: evaluaciones,
        resultadosPorEvaluacion: {
          'reciente': [
            resultado(id: 'a', evalId: 'reciente', estado: PortageEstado.logrado),
          ],
        },
        totalIndicadoresPorEvaluacion: {
          'vieja': 3,
          'reciente': 2,
        },
        meses: 3,
        ahora: ahora,
      );

      expect(serie.length, 1);
      expect(serie.first.fecha, DateTime(2026, 7, 1));
      expect(serie.first.logrados, 1);
      expect(serie.first.sinCalificar, 1);
    });

    test('seriePorVentanaMeses ordena por fecha ascendente', () {
      final evaluaciones = [
        PortageEvaluacion(
          id: 'e2',
          listaId: 'l1',
          gradoId: 'g1',
          fechaInicio: DateTime(2026, 7, 10),
          createdAt: ahora,
        ),
        PortageEvaluacion(
          id: 'e1',
          listaId: 'l1',
          gradoId: 'g1',
          fechaInicio: DateTime(2026, 6, 5),
          createdAt: ahora,
        ),
      ];

      final serie = PortageStats.seriePorVentanaMeses(
        evaluaciones: evaluaciones,
        resultadosPorEvaluacion: const {},
        totalIndicadoresPorEvaluacion: {'e1': 1, 'e2': 1},
        meses: 6,
        ahora: ahora,
      );

      expect(serie.map((p) => p.fecha), [
        DateTime(2026, 6, 5),
        DateTime(2026, 7, 10),
      ]);
    });

    test('barrasAscii genera texto proporcional', () {
      const conteo = PortageConteoEstado(
        logrados: 2,
        enProceso: 1,
        sinCalificar: 1,
        total: 4,
      );
      final barra = PortageStats.barrasAscii(conteo, ancho: 8);
      expect(barra, contains('2L'));
      expect(barra, contains('1EP'));
    });
  });
}
