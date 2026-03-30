# 📋 GUÍA PASO A PASO - Escuela CAIPI

## ✅ LO QUE YA TIENES INSTALADO:

- ✅ Flutter SDK en `C:\dev\flutter_windows_3.41.2-stable\flutter`
- ✅ Android SDK en `C:\Users\emmaghost\AppData\Local\Android\Sdk`
- ✅ Flutter funcionando (ejecutaste `flutter --version`)

---

## 🎯 PASO 1: Instalar Node.js (para Firebase CLI)

### Descargar:
```
https://nodejs.org/
```

- Descarga la versión **LTS** (Long Term Support)
- Ejecuta el instalador
- Siguiente → Siguiente → Instalar
- Reinicia PowerShell después

### Verificar instalación:
```bash
node --version
npm --version
```

---

## 🎯 PASO 2: Instalar Firebase CLI

En PowerShell:

```powershell
npm install -g firebase-tools
```

Espera 1-2 minutos.

Verifica:
```bash
firebase --version
```

---

## 🎯 PASO 3: Instalar FlutterFire CLI

```powershell
dart pub global activate flutterfire_cli
```

### Agregar al PATH:

En PowerShell ejecuta:
```powershell
$env:Path += ";$env:USERPROFILE\AppData\Local\Pub\Cache\bin"
```

Para que sea permanente, agrégalo a las variables de entorno manualmente.

Verifica:
```bash
flutterfire --version
```

---

## 🎯 PASO 4: Crear Proyecto en Firebase Console

### A) Crear el proyecto:

1. Ve a: https://console.firebase.google.com/
2. Click **"Agregar proyecto"**
3. Nombre: `escuela-caipi` (o el que prefieras)
4. Desactiva Google Analytics (opcional)
5. Click **"Crear proyecto"**
6. Espera 1 minuto

---

### B) Activar Authentication:

1. En el menú lateral, click en **"Authentication"**
2. Click **"Comenzar"**
3. En "Métodos de acceso", click en **"Correo electrónico/Contraseña"**
4. Activa el switch **"Habilitar"**
5. Click **"Guardar"**

---

### C) Activar Firestore Database:

1. En el menú lateral, click en **"Firestore Database"**
2. Click **"Crear base de datos"**
3. Selecciona **"Comenzar en modo de prueba"**
4. Click **"Siguiente"**
5. Ubicación: Elige `us-central1` o la más cercana
6. Click **"Habilitar"**
7. Espera 1-2 minutos

---

### D) Activar Storage:

1. En el menú lateral, click en **"Storage"**
2. Click **"Comenzar"**
3. Acepta las reglas en modo prueba
4. Click **"Listo"**

---

## 🎯 PASO 5: Conectar Firebase con tu App Flutter

### En PowerShell, ve a la carpeta del proyecto:

```bash
cd C:\laragon\www\app-caipi
```

### Login en Firebase:

```bash
firebase login
```

Se abrirá tu navegador para que inicies sesión con Google.

---

### Configurar Firebase:

```bash
flutterfire configure
```

Te preguntará:
1. **"Select a Firebase project"**: Elige `escuela-caipi`
2. **"Which platforms?"**: Selecciona `android` y `ios` (usa flechas y espacio)
3. Presiona **Enter**

Esto generará:
- ✅ `lib/firebase_options.dart` (con tus credenciales reales)
- ✅ `android/app/google-services.json`

---

## 🎯 PASO 6: Instalar Dependencias del Proyecto

```bash
flutter pub get
```

Espera 1-2 minutos mientras descarga todo.

---

## 🎯 PASO 7: Crear Usuario Directora (Primera vez)

### Desde Firebase Console:

1. Ve a **Authentication** → Pestaña **"Users"**
2. Click **"Agregar usuario"**
3. Ingresa:
   - Email: `directora@escuela.com`
   - Contraseña: `escuela123` (o la que prefieras)
4. Click **"Agregar usuario"**
5. **COPIA el UID** que se genera (algo como: `Kf8x2mN9...`)

---

### Crear documento en Firestore:

1. Ve a **Firestore Database**
2. Click **"Iniciar colección"**
3. ID de colección: `usuarios`
4. Click **"Siguiente"**
5. ID del documento: **Pega el UID que copiaste**
6. Agrega estos campos (uno por uno con "+ Agregar campo"):

```
Campo: email          Tipo: string    Valor: directora@escuela.com
Campo: nombre         Tipo: string    Valor: Ana María López
Campo: telefono       Tipo: string    Valor: 5512345678
Campo: rol            Tipo: string    Valor: directora
Campo: hijos          Tipo: array     Valor: [] (vacío)
Campo: createdAt      Tipo: timestamp Valor: [click en fecha/hora actual]
```

7. Click **"Guardar"**

---

## 🎯 PASO 8: Ejecutar la App

### Opción A: En emulador de Android Studio

1. Abre Android Studio
2. Ve a: **More Actions** → **Virtual Device Manager**
3. Click **"Create Device"**
4. Elige un teléfono (ej: Pixel 6)
5. Descarga una imagen del sistema (ej: API 33)
6. Click **"Finish"**
7. Click en el botón ▶️ para iniciar el emulador

---

### Opción B: En tu teléfono real

1. Conecta tu Android por USB
2. Acepta la depuración USB en el teléfono

---

### Ejecutar:

En PowerShell:

```bash
cd C:\laragon\www\app-caipi
flutter run
```

La primera vez tardará 3-5 minutos compilando.

---

## 🎯 PASO 9: Probar el Login

1. La app se abrirá en el emulador/teléfono
2. Ingresa:
   - Email: `directora@escuela.com`
   - Password: `escuela123` (o la que pusiste)
3. Click **"Iniciar Sesión"**
4. Deberías ver el Dashboard de Directora ✅

---

## 🎯 PASO 10: Crear un Padre de Prueba

**Desde la app (próximamente agregaremos esta función)**

O manualmente desde Firebase Console:

1. Ve a **Authentication** → **"Agregar usuario"**
2. Email: `padre1@gmail.com`
3. Password: `padre123`
4. Copia el UID

5. Ve a **Firestore** → Colección `usuarios` → **"Agregar documento"**
6. ID: El UID del padre
7. Campos:
```
email: padre1@gmail.com
nombre: Carlos Pérez
telefono: 5598765432
rol: padre
hijos: [] (por ahora vacío)
createdAt: [timestamp actual]
```

---

## 📦 PASO 11: Compilar APK para Instalar en Otros Teléfonos

### Para pruebas:

```bash
flutter build apk --debug
```

### Para producción (versión final):

```bash
flutter build apk --release
```

El APK estará en:
```
C:\laragon\www\app-caipi\build\app\outputs\flutter-apk\app-release.apk
```

**Envía ese archivo por WhatsApp/email** y cualquiera puede instalarlo en Android.

---

## 🚀 SIGUIENTES FUNCIONALIDADES A AGREGAR

- [ ] Crear padre desde la app (directora)
- [ ] Vincular alumnos con padres existentes
- [ ] Generar pagos mensuales automáticamente
- [ ] Notificaciones push cuando hay anuncios
- [ ] Chat entre directora y padres
- [ ] Exportar reportes a PDF
- [ ] Calendario de eventos

---

## ❓ Comandos Útiles

```bash
# Ver dispositivos conectados
flutter devices

# Limpiar proyecto
flutter clean

# Actualizar dependencias
flutter pub get

# Ver logs detallados
flutter run -v

# Compilar APK
flutter build apk --release

# Ver versión de Flutter
flutter --version

# Diagnosticar problemas
flutter doctor -v
```

---

## 💡 Tips

1. **Primera compilación** siempre tarda 5+ minutos
2. **Hot reload** con `r` mientras la app corre
3. **Hot restart** con `R` (mayúscula)
4. **Logs en tiempo real** aparecen en la terminal
5. **Firebase gratis** hasta 50K lecturas/día

---

¡Éxito con tu app escolar! 🎓📱
