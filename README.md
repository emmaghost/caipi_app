# 🎓 Escuela CAIPI - Sistema de Gestión Escolar

Sistema completo de gestión escolar para padres y directora con Flutter + Firebase.

## 📱 Características

### Para Directora:
- ✅ Panel de administración completo
- ✅ Gestión de alumnos (CRUD completo)
- ✅ Control de pagos y colegiaturas
- ✅ Registro de calificaciones
- ✅ Reportes de incidentes/accidentes
- ✅ Publicación de anuncios
- ✅ Vista de todos los grados

### Para Padres:
- ✅ Ver información de sus hijos
- ✅ Consultar estado de pagos
- ✅ Ver calificaciones por periodo
- ✅ Recibir notificaciones de incidentes
- ✅ Leer anuncios de la directora
- ✅ Seguimiento del progreso escolar

---

## 🗄️ Estructura de Base de Datos (Firebase Firestore)

```
📁 usuarios/          → Directora y padres
📁 alumnos/           → Estudiantes registrados
📁 pagos/             → Control de colegiaturas
📁 calificaciones/    → Calificaciones por materia
📁 incidentes/        → Accidentes y reportes
📁 anuncios/          → Comunicados de la directora
📁 grados/            → Grados escolares
```

---

## 📦 Requisitos Previos

### 1. Flutter SDK
- ✅ Ya instalado en: `C:\dev\flutter_windows_3.41.2-stable\flutter`

### 2. Android SDK
- ✅ Ya instalado en: `C:\Users\emmaghost\AppData\Local\Android\Sdk`

### 3. Herramientas adicionales:
- Git (para control de versiones)
- Node.js (para Firebase CLI)
- VS Code con extensiones Flutter y Dart

---

## 🚀 Instalación y Configuración

### PASO 1: Verificar Flutter

```bash
flutter doctor
```

Deberías ver:
```
[√] Flutter
[√] Android toolchain
[√] Connected device
```

---

### PASO 2: Instalar Firebase CLI

Abre PowerShell como Administrador:

```powershell
npm install -g firebase-tools
```

Luego instala FlutterFire CLI:

```powershell
dart pub global activate flutterfire_cli
```

Agrega FlutterFire al PATH (en PowerShell):

```powershell
$env:Path += ";$env:USERPROFILE\AppData\Local\Pub\Cache\bin"
```

---

### PASO 3: Crear Proyecto en Firebase

1. Ve a: https://console.firebase.google.com/
2. Click en **"Agregar proyecto"**
3. Nombre del proyecto: `escuela-caipi`
4. Desactiva Google Analytics (opcional)
5. Click **"Crear proyecto"**

**En Firebase Console:**

#### A) Activar Authentication:
1. Ve a **"Authentication"** en el menú lateral
2. Click **"Comenzar"**
3. Habilita **"Correo electrónico/Contraseña"**
4. Click **"Guardar"**

#### B) Activar Firestore Database:
1. Ve a **"Firestore Database"**
2. Click **"Crear base de datos"**
3. Selecciona **"Modo de prueba"** (por ahora)
4. Ubicación: Elige la más cercana (us-central, southamerica-east1, etc)
5. Click **"Habilitar"**

#### C) Activar Storage:
1. Ve a **"Storage"**
2. Click **"Comenzar"**
3. Acepta las reglas por defecto
4. Click **"Listo"**

---

### PASO 4: Conectar Firebase con la App

En tu terminal, navega al proyecto:

```bash
cd C:\laragon\www\app-caipi
```

Login en Firebase:

```bash
firebase login
```

Configurar Firebase en el proyecto:

```bash
flutterfire configure
```

- Selecciona el proyecto `escuela-caipi`
- Selecciona plataformas: **Android** (presiona espacio) y **iOS** (presiona espacio)
- Presiona Enter

Esto generará automáticamente:
- `firebase_options.dart` (con tus credenciales)
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

---

### PASO 5: Instalar Dependencias

```bash
flutter pub get
```

Espera a que descargue todas las dependencias (1-2 minutos).

---

## 🏃 Ejecutar la App

### En Emulador de Android:

1. Abre Android Studio
2. Ve a **Device Manager** (icono de teléfono)
3. Crea un dispositivo virtual o inicia uno existente

Luego ejecuta:

```bash
flutter run
```

---

### En tu Teléfono Android:

1. Activa **"Modo desarrollador"** en tu Android:
   - Ve a Ajustes → Acerca del teléfono
   - Toca 7 veces en "Número de compilación"

2. Activa **"Depuración USB"**:
   - Ve a Ajustes → Opciones de desarrollador
   - Activa "Depuración USB"

3. Conecta tu teléfono con USB al PC

4. Verifica que lo detecta:
```bash
flutter devices
```

5. Ejecuta:
```bash
flutter run
```

---

## 📦 Compilar APK para Distribución

### Para pruebas (APK Debug):

```bash
flutter build apk --debug
```

APK estará en: `build\app\outputs\flutter-apk\app-debug.apk`

---

### Para producción (APK Release):

```bash
flutter build apk --release
```

APK estará en: `build\app\outputs\flutter-apk\app-release.apk`

Puedes enviar este APK a cualquier Android para instalar.

---

## 🍎 Compilar para iOS (Cuando estés listo)

**Requisitos:**
- Mac con Xcode instalado
- Apple Developer Account ($99/año)

```bash
flutter build ios --release
```

---

## 🗃️ Estructura del Proyecto

```
app-caipi/
├── lib/
│   ├── main.dart                    # Punto de entrada
│   ├── firebase_options.dart        # Config Firebase
│   │
│   ├── models/                      # Modelos de datos
│   │   ├── usuario.dart
│   │   ├── alumno.dart
│   │   ├── pago.dart
│   │   ├── calificacion.dart
│   │   ├── incidente.dart
│   │   ├── anuncio.dart
│   │   └── grado.dart
│   │
│   ├── services/                    # Servicios
│   │   ├── auth_service.dart        # Autenticación
│   │   ├── firestore_service.dart   # Base de datos
│   │   └── storage_service.dart     # Almacenamiento
│   │
│   ├── screens/                     # Pantallas
│   │   ├── login_screen.dart
│   │   ├── directora/
│   │   │   ├── dashboard_directora.dart
│   │   │   ├── alumnos_screen.dart
│   │   │   ├── crear_alumno_screen.dart
│   │   │   ├── pagos_screen.dart
│   │   │   └── crear_anuncio_screen.dart
│   │   └── padres/
│   │       ├── dashboard_padre.dart
│   │       └── detalle_hijo_screen.dart
│   │
│   ├── widgets/                     # Componentes reutilizables
│   │   ├── stat_card.dart
│   │   ├── alumno_card.dart
│   │   ├── hijo_card.dart
│   │   ├── pago_card.dart
│   │   └── anuncio_card.dart
│   │
│   └── routes/                      # Navegación
│       └── app_router.dart
│
├── android/                         # Configuración Android
├── ios/                             # Configuración iOS
└── pubspec.yaml                     # Dependencias
```

---

## 🔐 Crear Usuario Directora (Primera vez)

Después de configurar Firebase, crea la cuenta de directora manualmente:

### OPCIÓN A: Desde Firebase Console

1. Ve a **Authentication** en Firebase Console
2. Click en **"Agregar usuario"**
3. Email: `directora@escuela.com`
4. Contraseña: La que quieras
5. Click **"Agregar usuario"**

6. Ve a **Firestore Database**
7. Click **"Iniciar colección"**
8. ID de colección: `usuarios`
9. ID del documento: Copia el UID del usuario que creaste
10. Agrega estos campos:
```
email: "directora@escuela.com"
nombre: "Ana María López"
telefono: "1234567890"
rol: "directora"
hijos: []
createdAt: [timestamp actual]
```

---

### OPCIÓN B: Desde código (después de primer login)

Puedes crear un script temporal o hacerlo manualmente desde la app.

---

## 🧪 Probar la App

### Credenciales de prueba:

**Directora:**
- Email: `directora@escuela.com`
- Password: La que configuraste

**Padre (debes crearlo desde la directora):**
- La directora puede registrar padres desde la app

---

## 🎨 Personalización

### Cambiar colores:

Edita `lib/main.dart` en la sección de `ThemeData`:

```dart
colorScheme: ColorScheme.fromSeed(
  seedColor: const Color(0xFF6366F1), // Cambia este color
),
```

### Cambiar nombre de la app:

Edita `android/app/src/main/AndroidManifest.xml`:

```xml
android:label="Tu Nombre Aquí"
```

---

## 🐛 Solución de Problemas Comunes

### Error: "Gradle build failed"
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

### Error: "Firebase not configured"
- Asegúrate de haber ejecutado `flutterfire configure`
- Verifica que exista `google-services.json` en `android/app/`

### Error: "Unable to locate Android SDK"
- Verifica que `local.properties` tenga la ruta correcta del SDK

---

## 📚 Próximos Pasos

1. ✅ Configurar Firebase (sigue las instrucciones arriba)
2. ✅ Ejecutar `flutter pub get`
3. ✅ Crear usuario directora en Firebase
4. ✅ Ejecutar la app: `flutter run`
5. ✅ Probar funcionalidades
6. ✅ Compilar APK: `flutter build apk --release`

---

## 🆘 Soporte

Si tienes problemas:
1. Ejecuta `flutter doctor -v` para ver detalles
2. Revisa los logs en la consola
3. Verifica la configuración de Firebase

---

## 📝 Notas Importantes

- **Firebase tiene un plan GRATIS** que es suficiente para empezar
- **El mismo código funciona en Android e iOS** sin cambios
- **Las reglas de Firestore** están en modo prueba, cambia a producción después
- **Para producción** deberás configurar reglas de seguridad en Firebase

---

## 🔒 Reglas de Seguridad (Firestore)

Cuando estés listo para producción, ve a Firestore y actualiza las reglas:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Usuarios solo pueden leer su propia info
    match /usuarios/{userId} {
      allow read: if request.auth != null && request.auth.uid == userId;
      allow write: if request.auth != null && 
                   get(/databases/$(database)/documents/usuarios/$(request.auth.uid)).data.rol == 'directora';
    }
    
    // Alumnos: directora ve todo, padres solo sus hijos
    match /alumnos/{alumnoId} {
      allow read: if request.auth != null && (
        get(/databases/$(database)/documents/usuarios/$(request.auth.uid)).data.rol == 'directora' ||
        get(/databases/$(database)/documents/alumnos/$(alumnoId)).data.padre_id == request.auth.uid
      );
      allow write: if request.auth != null && 
                   get(/databases/$(database)/documents/usuarios/$(request.auth.uid)).data.rol == 'directora';
    }
    
    // Similar para pagos, calificaciones, incidentes, etc.
  }
}
```

---

¡Listo! Ahora sigue las instrucciones paso a paso. 🚀
