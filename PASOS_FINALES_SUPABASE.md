# ✅ PROYECTO MIGRADO A SUPABASE - Pasos Finales

## 🎉 ¡TODO EL CÓDIGO YA ESTÁ ADAPTADO!

Ya modifiqué **más de 20 archivos** para usar Supabase en lugar de Firebase.

---

## 📋 SOLO TE FALTAN 4 PASOS:

### **PASO 1: Crear las tablas en Supabase** ⏱️ 5 min

1. Ve a tu Dashboard de Supabase: https://supabase.com/dashboard/project/qxldfqnuwpucptajcazf
2. En el menú lateral, click en **"SQL Editor"**
3. Abre el archivo: `MIGRACION_SUPABASE.md`
4. Copia y pega **TODOS los scripts SQL** uno por uno
5. Ejecuta cada uno con el botón **"Run"**

**Orden de ejecución:**
1. Tabla `usuarios`
2. Tabla `alumnos`
3. Tabla `pagos`
4. Tabla `calificaciones`
5. Tabla `incidentes`
6. Tabla `anuncios`
7. Tabla `grados`

---

### **PASO 2: Crear bucket de fotos** ⏱️ 2 min

1. En Supabase Dashboard → **Storage** (menú lateral)
2. Click **"New bucket"** o **"Create a new bucket"**
3. Name: `fotos`
4. **Public bucket:** ✅ Marca como público
5. Click **"Create bucket"**

---

### **PASO 3: Crear usuario directora** ⏱️ 3 min

1. En Supabase Dashboard → **Authentication** → **Users**
2. Click **"Add user"** → **"Create new user"**
3. Completa:
   - Email: `directora@escuela.com`
   - Password: `escuela123`
   - Auto Confirm User: ✅ (marca esto)
4. Click **"Create user"**
5. **COPIA el UUID** del usuario (algo como: `a1b2c3d4-...`)

6. Ve a **SQL Editor** y ejecuta (reemplaza el UUID):

```sql
INSERT INTO usuarios (id, email, nombre, telefono, rol, hijos)
VALUES (
  'PEGA-AQUI-EL-UUID-DEL-USUARIO',
  'directora@escuela.com',
  'Ana María López',
  '5512345678',
  'directora',
  '{}'
);
```

---

### **PASO 4: Instalar dependencias y ejecutar** ⏱️ 5 min

En PowerShell:

```powershell
cd C:\laragon\www\app-caipi
flutter pub get
```

Espera 2-3 minutos.

Luego ejecuta:

```powershell
flutter run
```

---

## 🔐 **Para hacer Login:**

- Email: `directora@escuela.com`
- Password: `escuela123`

---

## ✅ **Ventajas de Supabase:**

- 💚 **100% GRATIS** sin tarjeta
- ✅ Incluye Storage (1 GB gratis)
- ✅ PostgreSQL (500 MB gratis)
- ✅ Authentication incluido
- ✅ Tiempo real
- ✅ Sin límite de usuarios

---

## 📖 **Archivos de Ayuda:**

- `MIGRACION_SUPABASE.md` → Scripts SQL completos
- `README.md` → Documentación general
- `INICIO_RAPIDO.md` → Guía rápida

---

## 🐛 **Si algo falla:**

1. Verifica que ejecutaste **TODOS** los scripts SQL
2. Verifica que el bucket `fotos` existe y es público
3. Verifica que el usuario directora está en la tabla `usuarios`
4. Ejecuta: `flutter clean` y luego `flutter pub get`

---

## 🎯 **Resumen de lo que cambió:**

✅ **Firebase → Supabase**
✅ **Firestore → PostgreSQL**
✅ **Firebase Auth → Supabase Auth**
✅ **Firebase Storage → Supabase Storage**
✅ **Todo gratis y sin tarjeta** 🎉

---

¡A ejecutar los pasos! 🚀

**Dime cuando termines el PASO 1 (crear tablas) y te ayudo con los siguientes.**
