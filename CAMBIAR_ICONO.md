# 🎨 Cambiar Ícono de la App

## ❌ **PROBLEMA ACTUAL:**
El ícono muestra un **cuadrado morado** (ícono temporal XML)

## ✅ **SOLUCIÓN:**

### **Opción 1: Usar herramienta online (MÁS FÁCIL)**

1. **Ve a:** https://www.appicon.co/
2. **Sube tu logo:** `assets/images/logo_caipi.jpg`
3. **Selecciona:** Android
4. **Click:** Generate
5. **Descarga** el ZIP
6. **Extrae** y copia las carpetas `mipmap-*` a:
   ```
   C:\laragon\www\app-caipi\android\app\src\main\res\
   ```
7. **Reemplaza** las carpetas existentes
8. **En AndroidManifest.xml**, cambia:
   ```xml
   android:icon="@mipmap/ic_launcher"
   ```

---

### **Opción 2: Usar Flutter Launcher Icons (Automático)**

#### **Paso 1: Agregar dependencia**

Edita `pubspec.yaml`:

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
  flutter_lints: ^5.0.0
  flutter_launcher_icons: ^0.13.1  # ← AGREGAR
```

#### **Paso 2: Configurar el ícono**

En `pubspec.yaml`, al final agrega:

```yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/images/logo_caipi.jpg"
  adaptive_icon_background: "#FFFFFF"
  adaptive_icon_foreground: "assets/images/logo_caipi.jpg"
```

#### **Paso 3: Ejecutar comando**

```powershell
flutter pub get
flutter pub run flutter_launcher_icons
```

#### **Paso 4: Recompilar**

```powershell
flutter clean
flutter run
```

---

### **Opción 3: Manual (si tienes Photoshop/GIMP)**

Crear estos tamaños desde `logo_caipi.jpg`:

```
mipmap-mdpi/ic_launcher.png      → 48x48px
mipmap-hdpi/ic_launcher.png      → 72x72px
mipmap-xhdpi/ic_launcher.png     → 96x96px
mipmap-xxhdpi/ic_launcher.png    → 144x144px
mipmap-xxxhdpi/ic_launcher.png   → 192x192px
```

Copiarlos a: `android/app/src/main/res/`

---

## ⚡ **RECOMENDACIÓN:**

**Usa Opción 1 (appicon.co)** - Es la más rápida:
1. Sube logo
2. Descarga ZIP
3. Copia carpetas
4. Cambia AndroidManifest.xml
5. `flutter clean && flutter run`

---

## 🎯 **ARCHIVO A MODIFICAR:**

`android/app/src/main/AndroidManifest.xml`:

```xml
<application
    android:name="${applicationName}"
    android:label="CAIPI"
    android:icon="@mipmap/ic_launcher"  ← Cambiar a esto
```

**Línea actual (incorrecta):**
```xml
android:icon="@drawable/ic_launcher_temp"
```

**Línea correcta:**
```xml
android:icon="@mipmap/ic_launcher"
```
