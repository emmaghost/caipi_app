# 🎨 CAMBIAR LOGO DE CAIPI

## 📍 **UBICACIÓN DEL LOGO:**

El logo actual está en:
```
C:\laragon\www\app-caipi\assets\images\logo_caipi.jpg
```

---

## ⚡ **PASOS PARA CAMBIARLO:**

### **1️⃣ GUARDAR LA NUEVA IMAGEN:**

1. **Guarda la imagen nueva** que te compartí como:
   ```
   C:\laragon\www\app-caipi\assets\images\logo_caipi_nuevo.png
   ```

2. **O si prefieres reemplazar el actual:**
   - Guarda como `logo_caipi.png` (en PNG para transparencia)
   - Elimina el viejo `logo_caipi.jpg`

---

### **2️⃣ ACTUALIZAR EL CÓDIGO:**

Los logos se usan en:
- ✅ **Login** (`lib/screens/login_screen.dart`)
- ✅ **Menú lateral** (`lib/widgets/app_drawer.dart`)
- ✅ **Dashboard directora** (`lib/screens/directora/dashboard_directora.dart`)
- ✅ **Icono de la app** (`pubspec.yaml`)

---

### **3️⃣ GENERAR NUEVA APK:**

```powershell
cd C:\laragon\www\app-caipi
flutter clean
flutter pub get
flutter pub run flutter_launcher_icons
flutter build apk --release
```

---

## 🎯 **FORMATO RECOMENDADO:**

- **Formato:** PNG (con transparencia)
- **Tamaño:** 512x512 px (mínimo)
- **Nombre:** `logo_caipi.png`

---

## 📂 **CARPETA DE ASSETS:**

Ya abrí la carpeta en el explorador de Windows donde debes poner la imagen.

---

## ✅ **DESPUÉS:**

Una vez que guardes la imagen, yo actualizaré el código automáticamente.
