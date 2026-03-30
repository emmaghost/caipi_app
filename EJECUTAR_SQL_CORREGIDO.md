# 🚀 SQL MAESTRO COMPLETO - CORREGIDO

## ⚠️ **PROBLEMA SOLUCIONADO:**

El error `column "para_usuario_id" does not exist` ocurría porque:
- Ya existía una tabla `notificaciones` de un script anterior
- Tenía columnas diferentes
- `CREATE TABLE IF NOT EXISTS` no la recreaba

## ✅ **SOLUCIÓN APLICADA:**

He actualizado `SQL_MAESTRO_COMPLETO.sql` para que **elimine todas las tablas primero** y luego las recree con la estructura correcta.

---

## 📋 **INSTRUCCIONES PARA EJECUTAR:**

### **1. Abrir Supabase SQL Editor**
- Ve a: [https://supabase.com/dashboard](https://supabase.com/dashboard)
- Selecciona tu proyecto CAIPI
- Click en **"SQL Editor"** en el menú izquierdo
- Click en **"New Query"**

### **2. Copiar y Pegar el SQL**
- Abre el archivo: `SQL_MAESTRO_COMPLETO.sql`
- **Copia TODO** el contenido (Ctrl+A, Ctrl+C)
- **Pégalo** en el SQL Editor de Supabase

### **3. ⚠️ ADVERTENCIA**
Este script **ELIMINARÁ todas las tablas existentes** incluyendo:
- usuarios
- alumnos
- pagos
- profesores
- etc.

**Si tienes datos importantes, haz backup primero.**

### **4. Ejecutar**
- Click en **"Run"** (botón verde abajo a la derecha)
- Espera a que termine (puede tardar 30-60 segundos)
- Debe decir: **"Success. No rows returned"**

### **5. Verificar**
Corre esta query para confirmar que todo se creó:

```sql
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_type = 'BASE TABLE'
ORDER BY table_name;
```

Deberías ver **22 tablas:**
1. alumnos
2. anuncios
3. bitacora_diaria
4. calificaciones
5. clases_extracurriculares
6. control_salidas
7. eventos
8. galeria
9. grados
10. incidentes
11. menu_maternal
12. notificaciones
13. pagos
14. participantes_clase
15. permisos
16. permisos_usuario
17. personas_autorizadas
18. profesores
19. roles
20. roles_permisos
21. tipos_incidentes
22. usuarios

---

## 📊 **DATOS INICIALES INCLUIDOS:**

Después de ejecutar, tendrás:
- ✅ 6 grados (Maternal, Kinder 1, 2, 3, Preprimaria, Primaria 1)
- ✅ 4 roles (directora, profesor_admin, profesor, padre)
- ✅ 19 permisos para el sistema
- ✅ 15 tipos de incidentes (con niveles 1-5)
- ✅ Todas las RLS policies configuradas
- ✅ Todos los triggers funcionando

---

## 🎯 **SIGUIENTES PASOS:**

### **Paso 2: Crear Usuario Director** 👤

1. **Ve a Authentication → Users**
   - En el dashboard de Supabase
   - Click en "Add user" → "Create new user"

2. **Datos del usuario:**
   - **Email:** `viri@caipi.com`
   - **Password:** `Caipi123`
   - ✅ Deja "Auto Confirm User" activado
   - Click en **"Create user"**

3. **Copiar UUID:**
   - Una vez creado, verás el usuario en la lista
   - **COPIA el UUID** (columna ID, algo como: `75a24887-ed15-4fca-9116-a514182a7c20`)

4. **Insertar en tabla usuarios:**
   - Ve de nuevo a **SQL Editor**
   - Copia y ejecuta esto (reemplazando el UUID):

```sql
INSERT INTO usuarios (id, email, rol, nombre, apellidos, telefono, whatsapp, activo)
VALUES (
  'PEGA-AQUI-EL-UUID',  -- ← Reemplaza con el UUID que copiaste
  'viri@caipi.com',
  'directora',
  'Viridiana',
  'Directora CAIPI',
  '1234567890',
  '1234567890',
  true
);
```

---

### **Paso 3: Crear Bucket de Galería** 📸

1. **Ve a Storage en Supabase**
2. **Click en "Create a new bucket"**
3. **Nombre:** `galeria`
4. **✅ Marca como "Public bucket"**
5. **Click "Create bucket"**

---

### **Paso 4: Configurar Emails** 📧

1. Abre el archivo `EMAILS_5_TEMPLATES.txt`
2. Sigue las instrucciones dentro del archivo
3. Pega cada template en su sección correspondiente

---

### **Paso 5: Correr la App** 🚀

```powershell
cd C:\laragon\www\app-caipi
flutter pub get
flutter run
```

**Login:**
- Email: `viri@caipi.com`
- Password: `Caipi123`

---

## ❓ **¿ERRORES?**

Si ves algún error al ejecutar:
1. **Copia el mensaje de error completo**
2. **Dime en qué línea ocurrió**
3. Te ayudaré a corregirlo

---

**Versión:** Corregida 2026-03-05 (Elimina todas las tablas antes de recrear)
