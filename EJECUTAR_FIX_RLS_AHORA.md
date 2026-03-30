# 🚨 EJECUTAR FIX RLS AHORA

## ⚡ **PASOS RÁPIDOS:**

### 1️⃣ **IR A SUPABASE:**
   - Dashboard → Tu proyecto → SQL Editor

### 2️⃣ **COPIAR Y PEGAR:**
   - Archivo: `FIX_RLS_TODAS_TABLAS.sql`
   - Copiar TODO el contenido
   - Pegar en SQL Editor

### 3️⃣ **EJECUTAR:**
   - Click en **"RUN"** (botón abajo a la derecha)
   - Esperar a que termine (⏱️ ~5 segundos)

### 4️⃣ **VERIFICAR:**
   - Deberías ver al final:
     ```
     ✅ POLÍTICAS RLS CORREGIDAS
     alumnos: 4
     pagos: 3
     profesores: 2
     usuarios: 3
     grados: 2
     eventos: 2
     incidentes: 2
     entrevistas_padres: 2
     ```

### 5️⃣ **REINICIAR LA APP:**
   - En la terminal de VS Code:
   ```powershell
   # Presiona Ctrl+C si está corriendo
   # Luego:
   flutter run --release
   ```

### 6️⃣ **PROBAR CREAR ALUMNO:**
   - Intenta crear un alumno de nuevo
   - Ahora SÍ debería guardarse correctamente ✅

---

## 🤔 **¿POR QUÉ FALLÓ ANTES?**

Las políticas RLS (Row Level Security) de Supabase estaban bloqueando la inserción porque:
- No estaban bien configuradas para el rol de `directora`
- Faltaban políticas específicas para `INSERT` en la tabla `alumnos`
- La tabla `pagos` necesita permitir creación automática por el trigger

---

## ✅ **DESPUÉS DE ESTO:**

Ya deberías poder:
- ✅ Crear alumnos
- ✅ Editar alumnos (sin ese error que tenías)
- ✅ Crear pagos automáticos al crear alumno
- ✅ Ver la entrevista de padres
- ✅ Todo correctamente protegido por RLS

---

## 📞 **SI SIGUE SIN FUNCIONAR:**

1. Verifica que el usuario con el que estás logueado tenga `rol = 'directora'` en la tabla `usuarios`
2. Ejecuta esto en SQL Editor para verificar tu rol:
   ```sql
   SELECT id, nombre, email, rol FROM usuarios WHERE id = auth.uid();
   ```

---

## 🎯 **LISTO PARA PROBAR:**

Una vez ejecutado este script, la app debería funcionar al 100% ✨
