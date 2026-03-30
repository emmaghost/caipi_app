# 🔥 Guía Completa de Configuración de Firebase

## 📋 Requisitos Previos

- ✅ Node.js instalado
- ✅ Flutter instalado
- ✅ Cuenta de Google

---

## 🎯 PASO 1: Instalar Herramientas

### A) Instalar Firebase CLI

En PowerShell:

```powershell
npm install -g firebase-tools
```

Verifica:
```bash
firebase --version
```

---

### B) Instalar FlutterFire CLI

```powershell
dart pub global activate flutterfire_cli
```

Verifica:
```bash
flutterfire --version
```

**Si dice "no se reconoce el comando"**, agrega al PATH:

```powershell
$env:Path += ";$env:USERPROFILE\AppData\Local\Pub\Cache\bin"
```

---

## 🎯 PASO 2: Crear Proyecto en Firebase Console

### Ve a: https://console.firebase.google.com/

1. Click **"Agregar proyecto"** o **"Add project"**

2. **Nombre del proyecto:**
   - Escribe: `escuela-caipi`
   - Click **"Continuar"**

3. **Google Analytics:**
   - Puedes desactivarlo (no es necesario por ahora)
   - Click **"Crear proyecto"**

4. **Espera 30-60 segundos** mientras se crea

5. Click **"Continuar"** cuando termine

---

## 🎯 PASO 3: Configurar Authentication (Login)

1. En el menú lateral izquierdo, busca **"Compilación"** o **"Build"**

2. Click en **"Authentication"**

3. Click en botón **"Comenzar"** o **"Get Started"**

4. En **"Métodos de acceso"** o **"Sign-in method"**:
   - Click en **"Correo electrónico/Contraseña"**
   - Activa el switch para **"Habilitar"**
   - Click **"Guardar"**

✅ **Listo - Ya puedes hacer login con email/password**

---

## 🎯 PASO 4: Configurar Firestore Database

1. En el menú lateral, click en **"Firestore Database"**

2. Click **"Crear base de datos"** o **"Create database"**

3. **Modo:**
   - Selecciona **"Comenzar en modo de prueba"** o **"Start in test mode"**
   - Click **"Siguiente"**

   > ⚠️ Esto es temporal. Cambiaremos las reglas después.

4. **Ubicación:**
   - Elige la más cercana a ti:
     - `us-central1` (Estados Unidos - Centro)
     - `southamerica-east1` (São Paulo, Brasil)
     - `us-west1` (Oregon, EE.UU.)
   - Click **"Habilitar"**

5. **Espera 1-2 minutos** mientras se crea

✅ **Listo - Base de datos creada**

---

## 🎯 PASO 5: Configurar Storage (Almacenamiento)

1. En el menú lateral, click en **"Storage"**

2. Click **"Comenzar"** o **"Get Started"**

3. En las reglas de seguridad:
   - Deja las reglas por defecto (modo prueba)
   - Click **"Siguiente"**

4. **Ubicación:**
   - Usa la misma que elegiste para Firestore
   - Click **"Listo"**

✅ **Listo - Storage configurado para fotos**

---

## 🎯 PASO 6: Conectar Firebase con tu App

### En PowerShell, ve a tu proyecto:

```bash
cd C:\laragon\www\app-caipi
```

---

### A) Login en Firebase:

```bash
firebase login
```

- Se abrirá tu navegador
- Inicia sesión con tu cuenta de Google
- Autoriza Firebase CLI
- Vuelve a la terminal

---

### B) Configurar FlutterFire:

```bash
flutterfire configure
```

Esto te preguntará:

**1. "Select a Firebase project to configure"**
   - Usa las flechas ↑↓ para seleccionar `escuela-caipi`
   - Presiona **Enter**

**2. "Which platforms should your configuration support?"**
   - Presiona **Espacio** en `android` (se marca con *)
   - Presiona **Espacio** en `ios` (se marca con *)
   - Presiona **Enter**

**3. Espera mientras configura...**

✅ **Se generarán automáticamente:**
- `lib/firebase_options.dart` (REEMPLAZARÁ el placeholder)
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

---

## 🎯 PASO 7: Instalar Dependencias

```bash
flutter pub get
```

Espera 1-2 minutos mientras descarga todo.

---

## 🎯 PASO 8: Crear Usuario Directora

### Desde Firebase Console:

1. Ve a **Authentication** → Pestaña **"Users"**

2. Click **"Agregar usuario"** o **"Add user"**

3. Completa:
   - **Email:** `directora@escuela.com`
   - **Contraseña:** `escuela123` (o la que prefieras)
   - Click **"Agregar usuario"**

4. **COPIA el UID** (identificador único) del usuario
   - Se ve algo así: `Kf8x2mN9pQeR7tYuI5o...`

---

### Crear documento en Firestore:

1. Ve a **Firestore Database**

2. Click **"Iniciar colección"** o **"Start collection"**

3. **ID de colección:** `usuarios`
   - Click **"Siguiente"**

4. **ID del documento:** Pega el UID que copiaste

5. **Agregar campos** (uno por uno con "+ Agregar campo"):

| Campo | Tipo | Valor |
|-------|------|-------|
| email | string | `directora@escuela.com` |
| nombre | string | `Ana María López` |
| telefono | string | `5512345678` |
| rol | string | `directora` |
| hijos | array | `[]` (vacío) |
| createdAt | timestamp | Click en reloj y selecciona fecha/hora actual |

6. Click **"Guardar"**

✅ **Usuario directora creado**

---

## 🎯 PASO 9: Verificar Configuración

### En PowerShell:

```bash
cd C:\laragon\www\app-caipi
flutter doctor
```

Deberías ver:
```
[√] Flutter
[√] Android toolchain
```

---

## ✅ ¡LISTO PARA EJECUTAR!

```bash
flutter run
```

---

## 🔒 Reglas de Seguridad (Para Producción)

Cuando estés listo para lanzar a producción, actualiza las reglas:

### Firestore Rules:

1. Ve a **Firestore Database** → Pestaña **"Reglas"**

2. Reemplaza con esto:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper: Verificar si es directora
    function isDirectora() {
      return request.auth != null && 
             get(/databases/$(database)/documents/usuarios/$(request.auth.uid)).data.rol == 'directora';
    }
    
    // Helper: Verificar si es padre del alumno
    function isPadreDelAlumno(alumnoId) {
      return request.auth != null &&
             get(/databases/$(database)/documents/alumnos/$(alumnoId)).data.padre_id == request.auth.uid;
    }
    
    // Usuarios
    match /usuarios/{userId} {
      allow read: if request.auth != null && request.auth.uid == userId;
      allow write: if isDirectora();
    }
    
    // Alumnos
    match /alumnos/{alumnoId} {
      allow read: if request.auth != null && (
        isDirectora() ||
        isPadreDelAlumno(alumnoId)
      );
      allow write: if isDirectora();
    }
    
    // Pagos
    match /pagos/{pagoId} {
      allow read: if request.auth != null && (
        isDirectora() ||
        isPadreDelAlumno(resource.data.alumno_id)
      );
      allow write: if isDirectora();
    }
    
    // Calificaciones
    match /calificaciones/{calificacionId} {
      allow read: if request.auth != null && (
        isDirectora() ||
        isPadreDelAlumno(resource.data.alumno_id)
      );
      allow write: if isDirectora();
    }
    
    // Incidentes
    match /incidentes/{incidenteId} {
      allow read: if request.auth != null && (
        isDirectora() ||
        isPadreDelAlumno(resource.data.alumno_id)
      );
      allow write: if isDirectora();
    }
    
    // Anuncios: todos pueden leer, solo directora puede escribir
    match /anuncios/{anuncioId} {
      allow read: if request.auth != null;
      allow write: if isDirectora();
    }
    
    // Grados: todos pueden leer, solo directora puede escribir
    match /grados/{gradoId} {
      allow read: if request.auth != null;
      allow write: if isDirectora();
    }
  }
}
```

3. Click **"Publicar"**

---

### Storage Rules:

1. Ve a **Storage** → Pestaña **"Reglas"**

2. Reemplaza con esto:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    
    // Fotos de alumnos
    match /alumnos/{alumnoId}/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
    
    // Comprobantes de pago
    match /pagos/{pagoId}/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
```

3. Click **"Publicar"**

---

## 📊 Datos de Prueba (Opcional)

Si quieres probar con datos de ejemplo, crea manualmente en Firestore:

### Grado de ejemplo:

Colección: `grados`
Documento ID: `grado-1a`

```
nombre: "1ro A"
nivel: "primaria"
ciclo_escolar: "2025-2026"
total_alumnos: 0
```

---

### Alumno de ejemplo:

Colección: `alumnos`
Documento ID: `alumno-001`

```
nombre: "Juan Carlos"
apellidos: "Pérez Martínez"
fecha_nacimiento: [Selecciona: 15/03/2018]
grado: "1ro A"
foto_url: null
padre_id: "UID_del_padre"
activo: true
createdAt: [timestamp actual]
```

---

## 💡 Tips

- **Modo de prueba** permite acceso total por 30 días
- **Actualiza las reglas** antes de lanzar a producción
- **Firestore tiene límites gratuitos:**
  - 50,000 lecturas/día
  - 20,000 escrituras/día
  - 1 GB de almacenamiento
  - Suficiente para una escuela pequeña-mediana

---

## ❓ Problemas Comunes

### "FirebaseOptions have not been configured"
- Ejecuta `flutterfire configure` de nuevo
- Asegúrate de estar en la carpeta del proyecto

### "No Firebase App '[DEFAULT]' has been created"
- Verifica que `firebase_options.dart` existe
- Revisa que `main.dart` tiene `await Firebase.initializeApp()`

### "Failed to connect to Firebase"
- Revisa tu conexión a internet
- Verifica que el proyecto existe en Firebase Console

---

¡Ya estás listo para usar Firebase! 🔥
