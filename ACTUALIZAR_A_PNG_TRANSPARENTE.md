# 🎨 ACTUALIZAR A PNG TRANSPARENTE

## ⚫ **PROBLEMA:**
El icono sale negro porque el JPEG tiene fondo negro integrado.

---

## ✅ **SOLUCIÓN (5 MINUTOS):**

### **1️⃣ QUITAR FONDO NEGRO:**

**Ve a:** https://www.remove.bg/es

1. **"Subir imagen"**
2. Selecciona: `C:\laragon\www\app-caipi\assets\images\logo_caipi.jpeg`
3. **Remove.bg quita el fondo automáticamente** ✨
4. **"Descargar"** (PNG transparente)

---

### **2️⃣ GUARDAR PNG:**

1. **Renombra** el archivo descargado a:
   ```
   logo_caipi.png
   ```

2. **Cópialo** a:
   ```
   C:\laragon\www\app-caipi\assets\images\logo_caipi.png
   ```

3. **Borra** el viejo:
   - Elimina `logo_caipi.jpeg`

---

### **3️⃣ ACTUALIZAR CÓDIGO (YO LO HAGO):**

Una vez que guardes el PNG, yo actualizo:
- `login_screen.dart` → `.jpeg` a `.png`
- `app_drawer.dart` → `.jpeg` a `.png`
- `dashboard_directora.dart` → `.jpeg` a `.png`
- `pubspec.yaml` → `.jpeg` a `.png`

---

### **4️⃣ REGENERAR ICONO:**

```powershell
flutter pub run flutter_launcher_icons
```

---

## 🎯 **RESULTADO:**

- ✅ Icono con fondo transparente
- ✅ Se ve perfecto en el celular
- ✅ Sin bordes negros

---

## ⏱️ **TIEMPO: 5 MINUTOS**

---

## 🔗 **HERRAMIENTAS ALTERNATIVAS:**

Si remove.bg no funciona:
- https://photoscissors.com
- https://pixlr.com/remove-background
- https://www.canva.com/features/background-remover

---

**Dime cuando tengas el PNG y lo actualizo todo** 🚀
