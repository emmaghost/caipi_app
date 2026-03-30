import 'package:flutter_test/flutter_test.dart';
import 'package:escuela_caipi/models/alumno.dart';

void main() {
  group('Alumno Model Tests', () {
    test('Debe crear un alumno correctamente desde JSON', () {
      // Arrange
      final json = {
        'id': '123',
        'nombre': 'Juan',
        'apellidos': 'Pérez',
        'fecha_nacimiento': '2020-01-01',
        'genero': 'niño',
        'grado_id': 'maternal-1',
        'padre_id': 'padre-123',
        'activo': true,
        'created_at': '2024-01-01T00:00:00Z',
        'updated_at': '2024-01-01T00:00:00Z',
      };

      // Act
      final alumno = Alumno.fromJson(json);

      // Assert
      expect(alumno.id, '123');
      expect(alumno.nombre, 'Juan');
      expect(alumno.apellidos, 'Pérez');
      expect(alumno.nombreCompleto, 'Juan Pérez');
      expect(alumno.genero, 'niño');
      expect(alumno.gradoId, 'maternal-1');
      expect(alumno.activo, true);
    });

    test('Debe calcular la edad correctamente', () {
      // Arrange
      final fechaNacimiento = DateTime(2020, 1, 1);
      final alumno = Alumno(
        id: '123',
        nombre: 'Juan',
        apellidos: 'Pérez',
        fechaNacimiento: fechaNacimiento,
        padreId: 'padre-123',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act
      final edad = alumno.edad;

      // Assert
      final edadEsperada = DateTime.now().year - 2020;
      expect(edad, edadEsperada);
    });

    test('Debe convertir alumno a JSON correctamente', () {
      // Arrange
      final alumno = Alumno(
        id: '123',
        nombre: 'Juan',
        apellidos: 'Pérez',
        fechaNacimiento: DateTime(2020, 1, 1),
        genero: 'niño',
        gradoId: 'maternal-1',
        padreId: 'padre-123',
        activo: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act
      final json = alumno.toJson();

      // Assert
      expect(json['id'], '123');
      expect(json['nombre'], 'Juan');
      expect(json['apellidos'], 'Pérez');
      expect(json['genero'], 'niño');
      expect(json['grado_id'], 'maternal-1');
      expect(json['padre_id'], 'padre-123');
      expect(json['activo'], true);
    });

    test('Debe manejar alergias correctamente', () {
      // Arrange
      final alumnoConAlergias = Alumno(
        id: '123',
        nombre: 'Juan',
        apellidos: 'Pérez',
        fechaNacimiento: DateTime(2020, 1, 1),
        padreId: 'padre-123',
        alergias: 'Lactosa',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final alumnoSinAlergias = Alumno(
        id: '456',
        nombre: 'María',
        apellidos: 'López',
        fechaNacimiento: DateTime(2020, 1, 1),
        padreId: 'padre-456',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Assert
      expect(alumnoConAlergias.tieneAlergias, true);
      expect(alumnoSinAlergias.tieneAlergias, false);
    });
  });
}
