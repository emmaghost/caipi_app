# 📦 Guía Completa: Compilar APK

## 🎯 Compilar para Pruebas (Debug APK)

### Para probar en tu teléfono o compartir con amigos:

```bash
cd C:\laragon\www\app-caipi
flutter build apk --debug
```

**Ubicación del APK:**
```
C:\laragon\www\app-caipi\build\app\outputs\flutter-apk\app-debug.apk
```

**Características:**
- ✅ Tamaño: ~40-50 MB
- ✅ Instalar en cualquier Android
- ⚠️ No optimizado (más lento)
- ⚠️ Solo para pruebas

---

## 🚀 Compilar para Producción (Release APK)

### Para publicar o distribuir oficialmente:

```bash
flutter build apk --release
```

**Ubicación del APK:**
```
C:\laragon\www\app-caipi\build\app\outputs\flutter-apk\app-release.apk
```

**Características:**
- ✅ Optimizado y rápido
- ✅ Tamaño: ~15-20 MB (comprimido)
- ✅ Listo para distribuir
- ✅ Mejor rendimiento

---

## 📦 APK Dividido por Arquitectura (Más pequeño)

### Para reducir el tamaño del APK:

```bash
flutter build apk --split-per-abi
```

Esto genera **3 APKs diferentes:**

```
build/app/outputs/flutter-apk/
├── app-armeabi-v7a-release.apk  (~13 MB) - ARM 32-bit
├── app-arm64-v8a-release.apk    (~15 MB) - ARM 64-bit (mayoría de teléfonos modernos)
└── app-x86_64-release.apk       (~16 MB) - Emuladores
```

**Ventaja:** Archivos más pequeños para cada dispositivo

**Cuál distribuir:**
- **arm64-v8a** → Para la mayoría de teléfonos Android modernos (2018+)
- **armeabi-v7a** → Para teléfonos Android antiguos

---

## 🏪 Compilar para Google Play Store (AAB)

### Si quieres publicar en Play Store:

```bash
flutter build appbundle --release
```

**Ubicación del AAB:**
```
C:\laragon\www\app-caipi\build\app\outputs\bundle\release\app-release.aab
```

**Nota:** Google Play Store solo acepta formato AAB, NO APK.

---

## 🔐 Firmar el APK (Para Producción Seria)

### Si quieres que el APK esté firmado correctamente:

#### PASO 1: Generar keystore

En PowerShell:

```bash
keytool -genkey -v -keystore C:\Users\emmaghost\escuela-caipi-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias caipi
```

Te pedirá:
- Password del keystore (guárdalo bien)
- Nombre y apellido
- Organización: Escuela CAIPI
- Ciudad, estado, país

---

#### PASO 2: Crear archivo de configuración

Crea: `android/key.properties`

```properties
storePassword=TU_PASSWORD_AQUI
keyPassword=TU_PASSWORD_AQUI
keyAlias=caipi
storeFile=C:/Users/emmaghost/escuela-caipi-key.jks
```

---

#### PASO 3: Modificar build.gradle

Edita `android/app/build.gradle`:

Agrega ANTES de `android {`:

```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}
```

Dentro de `android { ... }`, reemplaza `buildTypes`:

```gradle
signingConfigs {
    release {
        keyAlias keystoreProperties['keyAlias']
        keyPassword keystoreProperties['keyPassword']
        storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
        storePassword keystoreProperties['storePassword']
    }
}

buildTypes {
    release {
        signingConfig signingConfigs.release
    }
}
```

---

#### PASO 4: Compilar APK firmado

```bash
flutter build apk --release
```

Ahora el APK estará firmado con tu keystore personal.

---

## 📱 Instalar APK en Android

### Método 1: Por USB

1. Conecta tu teléfono
2. Activa "Depuración USB"
3. Ejecuta:

```bash
flutter install
```

---

### Método 2: Compartir archivo

1. Copia el APK a tu teléfono (por cable, Bluetooth, email, etc)
2. En el teléfono, abre el archivo APK
3. Acepta "Instalar desde fuentes desconocidas"
4. Click "Instalar"

---

### Método 3: Google Drive / Dropbox

1. Sube el APK a Google Drive
2. Comparte el enlace
3. Abre el enlace desde el teléfono Android
4. Descarga e instala

---

## 🍎 Compilar para iOS (Requiere Mac)

### En Mac con Xcode instalado:

```bash
flutter build ios --release
```

Luego abre el proyecto en Xcode:

```bash
open ios/Runner.xcworkspace
```

Desde Xcode:
1. Conecta tu iPhone
2. Selecciona como dispositivo de destino
3. Product → Archive
4. Distribute App → App Store Connect o Ad Hoc

---

## 🌐 Alternativa: Compilar iOS desde Windows (Servicios Cloud)

Si no tienes Mac, usa servicios como:

### Codemagic:
```
https://codemagic.io/
```
- Conecta tu repositorio Git
- Configura para Flutter
- Genera IPA automáticamente
- Gratis para proyectos pequeños

### AppCircle:
```
https://appcircle.io/
```
- Similar a Codemagic
- Plan gratuito disponible

---

## 🔍 Verificar el APK

### Ver información del APK:

```bash
flutter analyze
```

### Ver tamaño de los archivos:

```bash
flutter build apk --analyze-size
```

Esto te muestra qué ocupa más espacio en tu APK.

---

## 🐛 Problemas Comunes

### "Gradle build failed"

```bash
cd android
gradlew clean
cd ..
flutter clean
flutter pub get
flutter build apk --release
```

---

### "Min SDK version error"

Verifica en `android/app/build.gradle`:

```gradle
minSdkVersion 21  // Android 5.0+
```

---

### "APK muy grande"

1. Usa `--split-per-abi` para dividir por arquitectura
2. Revisa con `--analyze-size` qué ocupa espacio
3. Reduce tamaño de imágenes en assets
4. Usa ProGuard (ya incluido en release)

---

## 📊 Comparación de Tamaños

| Modo | Tamaño Aprox |
|------|--------------|
| Debug APK | 40-50 MB |
| Release APK | 15-20 MB |
| Split per ABI | 10-15 MB cada uno |
| AAB (Play Store) | 12-18 MB |

---

## ✅ Checklist Antes de Distribuir

- [ ] Probaste en modo release (no solo debug)
- [ ] Verificaste que Firebase funciona
- [ ] Probaste login de directora
- [ ] Probaste login de padre
- [ ] Cambiaste el nombre de la app
- [ ] Cambiaste el icono (opcional)
- [ ] Actualizaste `pubspec.yaml` con la versión correcta
- [ ] El APK funciona en al menos 2 teléfonos diferentes

---

## 🎨 Cambiar Icono de la App

### Herramienta automática:

1. Crea tu icono (1024x1024 px)
2. Guárdalo como `assets/icon.png`

3. Agrega a `pubspec.yaml`:

```yaml
dev_dependencies:
  flutter_launcher_icons: ^0.13.1

flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/icon.png"
```

4. Ejecuta:

```bash
flutter pub get
flutter pub run flutter_launcher_icons
```

---

## 🚀 Distribución Final

### Para distribución privada:
- Comparte el APK por WhatsApp, email, Drive, etc.
- Los usuarios solo necesitan instalar desde fuentes desconocidas

### Para Play Store:
- Compila con `flutter build appbundle --release`
- Crea cuenta de desarrollador de Google ($25 una sola vez)
- Sube el AAB a Play Console

### Para App Store (iOS):
- Necesitas Mac + Xcode
- Apple Developer Account ($99/año)
- Sube desde Xcode

---

¡Listo para compilar! 📦🚀
