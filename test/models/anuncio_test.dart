import 'package:flutter_test/flutter_test.dart';
import 'package:escuela_caipi/models/anuncio.dart';

void main() {
  group('Anuncio.leidoPor', () {
    test('parsea lista, texto postgres y JSON', () {
      expect(Anuncio.parseLeidoPor(null), isEmpty);
      expect(Anuncio.parseLeidoPor(['a', 'b']), ['a', 'b']);
      expect(
        Anuncio.parseLeidoPor('{uuid-1,uuid-2}'),
        ['uuid-1', 'uuid-2'],
      );
      expect(Anuncio.parseLeidoPor('["padre-1"]'), ['padre-1']);
    });

    test('visibleParaPadre respeta paraTodos y grados', () {
      final todos = Anuncio(
        id: '1',
        titulo: 'T',
        mensaje: 'M',
        fechaPublicacion: DateTime(2026, 10, 1),
        paraTodos: true,
      );
      final deK1 = Anuncio(
        id: '2',
        titulo: 'T',
        mensaje: 'M',
        fechaPublicacion: DateTime(2026, 10, 1),
        paraTodos: false,
        paraGrados: const ['k1'],
      );
      expect(todos.visibleParaPadre({'k3'}), isTrue);
      expect(deK1.visibleParaPadre({'k1'}), isTrue);
      expect(deK1.visibleParaPadre({'k3'}), isFalse);
    });

    test('fueLeidoPor ignora espacios', () {
      final a = Anuncio(
        id: '1',
        titulo: 'Tarea',
        mensaje: 'Hola',
        fechaPublicacion: DateTime(2026, 10, 1),
        leidoPor: const [' padre-1 '],
      );
      expect(a.fueLeidoPor('padre-1'), isTrue);
      expect(a.fueLeidoPor('otro'), isFalse);
    });
  });
}
