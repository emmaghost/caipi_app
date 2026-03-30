# ⚡ INICIO RÁPIDO - 10 Minutos

## ✅ Ya tienes Flutter instalado

Ahora solo necesitas configurar Firebase y ejecutar. ¡Vamos!

---

## 🚀 PASO 1: Instalar Node.js (5 min)

Descarga e instala:
```
https://nodejs.org/
```

Elige versión **LTS**, siguiente → siguiente → instalar.

**Verifica** (cierra y abre PowerShell nuevo):
```bash
node --version
```

---

## 🚀 PASO 2: Instalar Firebase CLI (2 min)

En PowerShell:

```powershell
npm install -g firebase-tools
dart pub global activate flutterfire_cli
```

---

## 🚀 PASO 3: Crear Proyecto Firebase (5 min)

1. Ve a: https://console.firebase.google.com/
2. Click **"Agregar proyecto"**
3. Nombre: `escuela-caipi`
4. Desactiva Analytics
5. Click **"Crear"**

**Dentro del proyecto:**

→ **Authentication** → Comenzar → Habilitar **Email/Password**
→ **Firestore Database** → Crear → **Modo prueba** → Habilitar
→ **Storage** → Comenzar → Modo prueba → Listo

---

## 🚀 PASO 4: Conectar Firebase (2 min)

En PowerShell:

```bash
cd C:\laragon\www\app-caipi
firebase login
flutterfire configure
```

- Selecciona proyecto `escuela-caipi`
- Selecciona `android` y `ios` (con espacio)
- Enter

---

## 🚀 PASO 5: Instalar Dependencias (2 min)

```bash
flutter pub get
```

---

## 🚀 PASO 6: Crear Usuario Directora (3 min)

### En Firebase Console:

1. **Authentication** → **Users** → **Agregar usuario**
   - Email: `directora@escuela.com`
   - Password: `escuela123`
   - **COPIA el UID** que se genera

2. **Firestore** → **Iniciar colección** → `usuarios`
   - ID documento: **Pega el UID**
   - Agrega campos:
     ```
     email: "directora@escuela.com"
     nombre: "Directora"
     telefono: "5512345678"
     rol: "directora"
     hijos: [] (array vacío)
     createdAt: (timestamp ahora)
     ```
   - Guardar

---

## 🚀 PASO 7: Ejecutar la App (1 min)

### Opción A: En emulador
1. Abre Android Studio → Device Manager → Inicia un emulador

### Opción B: En tu teléfono
1. Conecta por USB
2. Activa depuración USB

### Ejecutar:

```bash
flutter run
```

La primera vez tarda 3-5 minutos compilando.

---

## 🎉 ¡LISTO!

Login con:
- Email: `directora@escuela.com`
- Password: `escuela123`

Deberías ver el **Dashboard de Directora** ✅

---

## 📦 Compilar APK

Cuando esté funcionando:

```bash
flutter build apk --release
```

APK estará en: `build\app\outputs\flutter-apk\app-release.apk`

Envíalo por WhatsApp y cualquiera puede instalarlo.

---

## ❓ ¿Problemas?

Lee los archivos detallados:
- `INSTRUCCIONES_PASO_A_PASO.md`
- `CONFIGURACION_FIREBASE.md`
- `README.md`

---

¡A probar! 🚀📱
