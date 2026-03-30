# 🧪 Tests - Sistema CAIPI

## 📊 **RESUMEN DE TESTS**

### ✅ **Tests Activos:**
- **Tests de Modelos** (9 tests) → `test/models/`
  - Alumno: 4 tests
  - Pago: 5 tests
  
- **Tests de Rutas** (34 tests) → `test/routes/`
  - Validación de rutas: 31 tests
  - Tests básicos del router: 3 tests

**Total: 43 tests funcionando** ✅

### ⏸️ **Tests Deshabilitados:**
- Tests de integración → Requieren mocks complejos de Supabase

---

## 🚀 **EJECUTAR TESTS**

### **Todos los tests:**
```powershell
flutter test
```

### **Solo tests de modelos:**
```powershell
flutter test test/models/
```

### **Solo tests de rutas:**
```powershell
flutter test test/routes/
```

### **Un archivo específico:**
```powershell
flutter test test/models/alumno_test.dart
```

---

## 📋 **TESTS DE MODELOS**

### **Alumno** (`test/models/alumno_test.dart`)
```
✅ Debe crear un alumno desde JSON
✅ Debe calcular la edad correctamente
✅ Debe convertir alumno a JSON
✅ Debe detectar alergias correctamente
```

### **Pago** (`test/models/pago_test.dart`)
```
✅ Debe crear un pago desde JSON
✅ Debe identificar pago pendiente
✅ Debe identificar pago vencido
✅ Debe identificar pago pagado
✅ Debe convertir quien recibió correctamente
```

---

## 🗺️ **TESTS DE RUTAS**

### **Validación de Estructura** (`test/routes/rutas_validacion_test.dart`)
```
✅ Total de 18 rutas
✅ Todas las rutas son únicas
✅ Todas empiezan con /
✅ Rutas de directora con prefijo correcto (14 rutas)
✅ Rutas de padre con prefijo correcto (2 rutas)
✅ 6 rutas con parámetros (:id, :pagoId, :alumnoId)
✅ Validación de módulos (Alumnos, Pagos, Profesores, Padres, etc.)
✅ Seguridad y protección de rutas
✅ Consistencia de patrones CRUD
```

### **Tests del Router** (`test/routes/app_router_test.dart`)
```
✅ Router está configurado correctamente
✅ Tiene rutas configuradas
✅ La app carga con el router
```

---

## 🎯 **RESULTADO ESPERADO**

Al ejecutar `flutter test` debes ver:

```
00:05 +43: All tests passed! ✅
```

---

## 🔍 **DETALLES DE CADA MÓDULO**

### **Módulo de Alumnos** (3 rutas validadas)
- `/directora/alumnos` - Lista de alumnos
- `/directora/alumnos/crear` - Crear alumno
- `/directora/alumnos/editar/:id` - Editar alumno

### **Módulo de Pagos** (2 rutas validadas)
- `/directora/pagos` - Ver pagos
- `/acreditar-pago/:pagoId` - Acreditar pago

### **Módulo de Profesores** (3 rutas validadas)
- `/directora/profesores` - Lista de profesores
- `/directora/profesores/crear` - Crear profesor
- `/directora/profesores/editar/:id` - Editar profesor

### **Módulo de Padres** (3 rutas validadas)
- `/directora/padres` - Lista de padres
- `/directora/padres/crear` - Crear padre
- `/directora/padres/ver/:id` - Ver detalles del padre

### **Módulo de Personas Autorizadas** (1 ruta validada)
- `/directora/personas-autorizadas/:alumnoId` - Gestionar personas autorizadas

### **Módulo de Anuncios** (1 ruta validada)
- `/directora/anuncios/crear` - Crear anuncio

### **Vista de Padres** (2 rutas validadas)
- `/padre` - Dashboard del padre
- `/padre/hijo/:id` - Ver detalles del hijo

---

## ⚠️ **SOLUCIÓN DE PROBLEMAS**

### ❌ **Error: Some tests failed**
1. Ejecuta `flutter clean`
2. Ejecuta `flutter pub get`
3. Vuelve a ejecutar `flutter test`

### ❌ **Error: Compilation failed**
1. Verifica que no haya errores de sintaxis
2. Ejecuta `flutter analyze`
3. Corrige los errores y vuelve a intentar

### ❌ **Error: Package not found**
1. Ejecuta `flutter pub get`
2. Verifica que todas las dependencias estén en `pubspec.yaml`

---

## 📝 **CONVENCIONES DE TESTS**

### **Nomenclatura:**
- Archivos terminan en `_test.dart`
- Grupos con `group('Nombre', () {...})`
- Tests individuales con `test('descripción', () {...})`
- Tests de widgets con `testWidgets('descripción', (tester) async {...})`

### **Estructura:**
```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Grupo de Tests', () {
    test('Debe hacer algo específico', () {
      // Arrange (preparar)
      final valor = 10;
      
      // Act (actuar)
      final resultado = valor * 2;
      
      // Assert (verificar)
      expect(resultado, 20);
    });
  });
}
```

---

## 🎓 **MEJORES PRÁCTICAS**

1. ✅ **Tests unitarios** - Probar funciones y clases individuales
2. ✅ **Tests de widgets** - Probar componentes de UI
3. ✅ **Mocks simples** - Para dependencias externas
4. ✅ **Tests independientes** - Cada test debe poder ejecutarse solo
5. ✅ **Nombres descriptivos** - Que expliquen qué se está probando

---

## 📚 **RECURSOS**

- [Documentación oficial de Flutter Testing](https://docs.flutter.dev/testing)
- [Paquete flutter_test](https://api.flutter.dev/flutter/flutter_test/flutter_test-library.html)
- [Mapa de rutas completo](./RUTAS_SISTEMA.md)

---

**Última actualización:** 2026-03-05  
**Total de Tests:** 43  
**Estado:** ✅ Todos pasando
