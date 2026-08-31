import 'package:flutter_test/flutter_test.dart';
import 'package:escuela_caipi/models/usuario.dart';

Usuario _u({String rol = 'profesor', String? especialidad}) {
  final fecha = DateTime(2026, 1, 1);
  return Usuario(
    id: 'u1',
    email: 'a@b.com',
    rol: rol,
    nombre: 'Ana',
    createdAt: fecha,
    updatedAt: fecha,
  ).conPerfilProfesor(especialidad: especialidad, gradoId: 'g1');
}

void main() {
  test('titular no es maestra de ingles', () {
    expect(_u(especialidad: 'titular').esMaestraIngles, isFalse);
    expect(_u(especialidad: null).esMaestraIngles, isFalse);
  });

  test('especialidad ingles marca maestra de ingles', () {
    expect(_u(especialidad: 'ingles').esMaestraIngles, isTrue);
    expect(_u(especialidad: 'Ingles').esMaestraIngles, isTrue);
    expect(_u(especialidad: 'Ingl\u00e9s').esMaestraIngles, isTrue);
  });

  test('maestra de ingles no edita fichas de alumnos', () {
    expect(_u(especialidad: 'ingles').puedeEditarAlumnos, isFalse);
  });
}
