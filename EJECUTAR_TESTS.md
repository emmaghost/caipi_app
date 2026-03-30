# 🧪 GUÍA PARA EJECUTAR TESTS AUTOMATIZADOS

## 📦 **1. INSTALAR DEPENDENCIAS**

Primero, agrega las dependencias de testing a `pubspec.yaml`:

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
  flutter_lints: ^5.0.0
```

Luego ejecuta:
```powershell
flutter pub get
```

---

## 🧪 **2. TIPOS DE TESTS DISPONIBLES**

### **A. Tests Unitarios (Models)**
Prueban la lógica de negocio de los modelos.

**Ubicación:** `test/models/`

**Tests creados:**
- `alumno_test.dart` → Prueba modelo Alumno
- `pago_test.dart` → Prueba modelo Pago

---

### **B. Tests de Integración (Flujo Completo)**
Prueban la aplicación completa end-to-end.

**Ubicación:** `test/integration/`

**Tests creados:**
- `flujo_completo_test.dart` → Prueba todos los flujos

---

## 🚀 **3. EJECUTAR TESTS**

### **Opción 1: Tests Unitarios (Rápido)**

```powershell
# Todos los tests unitarios
flutter test

# Solo test de alumno
flutter test test/models/alumno_test.dart

# Solo test de pago
flutter test test/models/pago_test.dart
```

**Resultado esperado:**
```
✓ Alumno Model Tests > Debe crear un alumno correctamente desde JSON (50ms)
✓ Alumno Model Tests > Debe calcular la edad correctamente (10ms)
✓ Alumno Model Tests > Debe convertir alumno a JSON correctamente (15ms)
✓ Alumno Model Tests > Debe manejar alergias correctamente (8ms)

✓ Pago Model Tests > Debe crear un pago desde JSON (45ms)
✓ Pago Model Tests > Debe identificar pago pendiente correctamente (12ms)
✓ Pago Model Tests > Debe identificar pago vencido correctamente (11ms)
✓ Pago Model Tests > Debe identificar pago pagado correctamente (9ms)

00:02 +8: All tests passed!
```

---

### **Opción 2: Tests de Integración (Requiere dispositivo/emulador)**

**⚠️ IMPORTANTE:** Debes tener el emulador corriendo o un dispositivo conectado.

```powershell
# Ejecutar tests de integración
flutter test integration_test/flujo_completo_test.dart
```

**O con más verbose:**
```powershell
flutter drive `
  --driver=test_driver/integration_test.dart `
  --target=integration_test/flujo_completo_test.dart
```

---

## 📊 **4. LO QUE PRUEBAN LOS TESTS**

### **Tests Unitarios - Alumno:**
✅ Crear alumno desde JSON  
✅ Calcular edad correctamente  
✅ Convertir alumno a JSON  
✅ Manejar alergias  
✅ Nombre completo  

### **Tests Unitarios - Pago:**
✅ Crear pago desde JSON  
✅ Estado pendiente (fecha futura)  
✅ Estado vencido (fecha pasada)  
✅ Estado pagado  
✅ Método de pago  
✅ Quién recibió el pago  

### **Tests de Integración - Directora:**
✅ Login y navegación al dashboard  
✅ Crear alumno → Generar 14 pagos  
✅ Acreditar un pago  
✅ Crear profesor → Asignar grupo  
✅ Crear padre  

### **Tests de Integración - Padre:**
✅ Ver hijos en dashboard  
✅ Ver pagos en solo lectura  
✅ NO ver botón "Acreditar"  

### **Tests de Seguridad:**
✅ Padre NO puede acceder a rutas de directora  
✅ Redirección automática según rol  

---

## 🔧 **5. CONFIGURAR TEST DRIVER (Para tests de integración)**

Crea el archivo `test_driver/integration_test.dart`:

```dart
import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver();
```

---

## 📈 **6. EJECUTAR TESTS CON REPORTE**

```powershell
# Con cobertura de código
flutter test --coverage

# Generar reporte HTML (requiere lcov)
genhtml coverage/lcov.info -o coverage/html
```

---

## 🎯 **7. TESTS EN CI/CD**

Para GitHub Actions, crea `.github/workflows/tests.yml`:

```yaml
name: Flutter Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.41.2'
      - run: flutter pub get
      - run: flutter test
```

---

## ✅ **8. VERIFICAR QUE TODO FUNCIONA**

### **Paso 1: Ejecuta tests unitarios**
```powershell
flutter test
```

**Debe pasar:** ✅ 8 tests

---

### **Paso 2: Ejecuta tests de integración (con emulador)**
```powershell
flutter test integration_test/flujo_completo_test.dart
```

**Debe pasar:**  
✅ Login y dashboard  
✅ Crear alumno  
✅ Acreditar pago  
✅ Crear profesor  
✅ Crear padre  
✅ Ver como padre  

---

## 🐛 **TROUBLESHOOTING**

### **Error: "Cannot find integration_test"**

**Solución:**
```powershell
flutter pub get
```

### **Error: "No devices found"**

**Solución:**
1. Abre el emulador en Android Studio
2. O conecta un dispositivo físico
3. Verifica con: `flutter devices`

### **Error: "Test timeout"**

**Solución:**
Los tests de integración pueden tardar. Aumenta el timeout:

```dart
testWidgets('...', (tester) async {
  // ...
}, timeout: const Timeout(Duration(minutes: 5)));
```

---

## 📊 **RESULTADOS ESPERADOS**

### **Tests Unitarios (Rápido - ≈5 segundos):**
```
Running Dart VM tests...
✓ Alumno Model Tests
  ✓ Debe crear un alumno correctamente desde JSON
  ✓ Debe calcular la edad correctamente  
  ✓ Debe convertir alumno a JSON correctamente
  ✓ Debe manejar alergias correctamente

✓ Pago Model Tests
  ✓ Debe crear un pago desde JSON
  ✓ Debe identificar pago pendiente correctamente
  ✓ Debe identificar pago vencido correctamente
  ✓ Debe identificar pago pagado correctamente

00:05 +8: All tests passed!
```

### **Tests de Integración (Lento - ≈3-5 minutos):**
```
Running Integration Tests on Android...
✓ Flujo Completo - Directora
  ✓ Debe hacer login y navegar al dashboard (15s)
  ✓ Debe crear un alumno y generar 14 pagos (25s)
  ✓ Debe acreditar un pago correctamente (18s)
  ✓ Debe crear un profesor y asignar grupo (12s)
  ✓ Debe crear un padre (10s)

✓ Flujo Completo - Padre
  ✓ Debe ver sus hijos y pagos en solo lectura (10s)

✓ Validación de Seguridad
  ✓ Padre NO puede acceder a rutas de directora (8s)

04:38 +7: All tests passed!
```

---

## 🎯 **PRÓXIMOS PASOS**

1. **Ejecuta primero los tests unitarios:**
   ```powershell
   flutter test
   ```

2. **Si pasan, ejecuta los de integración:**
   ```powershell
   flutter test integration_test/
   ```

3. **Automatiza en CI/CD** (opcional)

---

**¡Los tests validan automáticamente todo el flujo sin intervención manual!** 🚀
