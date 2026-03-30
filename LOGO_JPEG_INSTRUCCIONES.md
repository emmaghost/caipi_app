# 🎨 ACTUALIZAR LOGO (JPEG) - INSTRUCCIONES FINALES

---

## ✅ **CÓDIGO YA ACTUALIZADO**

Ya cambié el código para usar `logo_caipi.jpeg` (tu formato).

---

## 📂 **PASO 1: GUARDAR TU LOGO**

### **Opción más fácil:**

1. **Copia tu archivo JPEG** (el del cerebrito nuevo)
2. **Pégalo en la carpeta que ya abrí:**
   ```
   C:\laragon\www\app-caipi\assets\images\
   ```
3. **Renómbralo exactamente a:**
   ```
   logo_caipi.jpeg
   ```
4. **Borra el viejo:**
   - Si ves `logo_caipi.jpg`, bórralo

---

## 🚀 **PASO 2: GENERAR APK CON LOGO NUEVO**

### **Opción A: Script automático (RECOMENDADO)**

**Doble click en:**
```
C:\laragon\www\app-caipi\actualizar_logo.bat
```

Espera 5-7 minutos y listo ✅

---

### **Opción B: Manual (si el script da error)**

En PowerShell:

```powershell
cd C:\laragon\www\app-caipi
flutter clean
flutter pub get
flutter pub run flutter_launcher_icons
flutter build apk --release
```

---

## 📱 **PASO 3: INSTALAR EN TU CEL**

1. El script abrirá automáticamente la carpeta con `app-release.apk`
2. Copia a tu Galaxy Note 9 (WhatsApp/USB/Drive)
3. Instala
4. ✅ **¡Logo nuevo en toda la app!**

---

## 🎯 **LO QUE SE VA A ACTUALIZAR:**

- ✅ **Icono de la app** (el que aparece en tu celular) 📱
- ✅ **Pantalla de Login** (círculo grande) 🔐
- ✅ **Menú lateral** (arriba) ☰
- ✅ **Dashboard Directora** (barra superior) ✨

---

## 📝 **CHECKLIST:**

- [ ] Guardar nuevo logo como `logo_caipi.jpeg` en `assets/images/`
- [ ] Borrar viejo `logo_caipi.jpg`
- [ ] Ejecutar `actualizar_logo.bat`
- [ ] Esperar 5-7 minutos
- [ ] Copiar APK al celular
- [ ] Instalar y probar

---

## ⏱️ **TIEMPO TOTAL: 10 MINUTOS**

---

**¿Listo para ejecutar el script después de guardar el logo?** 🚀
