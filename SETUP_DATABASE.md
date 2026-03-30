# 🗄️ CONFIGURACIÓN DE LA BASE DE DATOS CAIPI

## 📋 **Contenido de la Base de Datos:**

### **15 Tablas principales:**
1. ✅ **usuarios** - Directora, Profesores, Padres
2. ✅ **grados** - Maternal, Kinder 1, 2, 3
3. ✅ **profesores** - Asignación de profesores a grupos
4. ✅ **alumnos** - Datos de los niños
5. ✅ **personas_autorizadas** - Quiénes pueden recoger a cada niño
6. ✅ **control_salidas** - Entrada/Salida diaria
7. ✅ **bitacora_diaria** - Comió, pipí, popó, dientes (Kinders)
8. ✅ **menu_maternal** - Menú del día para Maternal
9. ✅ **pagos** - Control de pagos mensuales
10. ✅ **calificaciones** - Evaluaciones y calificaciones
11. ✅ **incidentes** - Accidentes, comportamiento, logros
12. ✅ **notificaciones** - Avisos y mensajes en la app
13. ✅ **galeria** - Fotos del día
14. ✅ **clases_extracurriculares** - Danza, Inglés, etc.
15. ✅ **participantes_clases** - Alumnos o externos en clases extra

---

## 🚀 **PASOS PARA CONFIGURAR:**

### **1. Entrar a Supabase**
1. Ve a https://supabase.com
2. Inicia sesión
3. Abre tu proyecto CAIPI (o crea uno nuevo)

### **2. Ejecutar el SQL**
1. En el menú izquierdo, haz clic en **SQL Editor**
2. Haz clic en **"+ New query"**
3. Abre el archivo `DATABASE_COMPLETA.sql`
4. **Copia TODO el contenido** y pégalo en el editor
5. Haz clic en **"Run"** (abajo derecha)
6. Espera a que termine (tomará 10-20 segundos)
7. Deberías ver: **"Success. No rows returned"**

### **3. Verificar que se crearon las tablas**
1. En el menú izquierdo, haz clic en **Table Editor**
2. Deberías ver las 15 tablas listadas

### **4. Crear usuario Directora**
1. Ve a **Authentication** → **Users**
2. Haz clic en **"Add user"** → **"Create new user"**
3. Ingresa:
   - **Email:** tu correo (ej: `directora@caipi.com`)
   - **Password:** una contraseña segura
   - **Auto Confirm User:** ✅ (marcado)
4. Haz clic en **"Create user"**
5. **Copia el User UID** que aparece

### **5. Agregar datos de la directora en la tabla usuarios**
1. Ve a **SQL Editor**
2. Crea una nueva query
3. Pega este código (reemplaza `TU_USER_UID` con el UID que copiaste):

```sql
INSERT INTO usuarios (id, email, rol, nombre, apellidos, telefono, whatsapp)
VALUES (
  'TU_USER_UID',  -- Reemplaza con el UID del paso 4
  'directora@caipi.com',  -- Tu correo
  'directora',
  'Nombre Directora',
  'Apellidos',
  '1234567890',
  '1234567890'
);
```

4. Haz clic en **"Run"**

---

## 🎨 **LO QUE INCLUYE:**

### ✅ **Relaciones automáticas:**
- Cuando borras un alumno, se borran sus pagos, bitácoras, etc.
- Cuando cambias un alumno de grado, se actualiza el contador automáticamente
- Los profesores solo ven alumnos de su grupo
- Los padres solo ven info de sus hijos

### ✅ **Seguridad (RLS):**
- **Directora:** Ve y edita TODO
- **Profesores:** Solo ven/editan su grupo asignado
- **Padres:** Solo ven info de sus hijos

### ✅ **Funciones automáticas:**
- Actualización de timestamps (`updated_at`)
- Contador de alumnos por grado
- Validaciones de datos

### ✅ **Datos iniciales:**
- Los 4 grados ya creados (Maternal, Kinder 1, 2, 3)
- Con colores asignados para la UI

---

## 📊 **CAMPOS IMPORTANTES:**

### **Alumnos:**
- `foto_default_genero`: Si no tiene foto, usa 'nino' o 'nina'
- `alergias`: Información médica importante
- `activo`: false = alumno dado de baja

### **Bitácora Diaria:**
- `comio`: 'si', 'no', 'medio'
- `animo`: 'feliz', 'normal', 'triste', 'irritable'
- Única por alumno por día

### **Control de Salidas:**
- Registra quién trajo y quién recogió
- Valida contra `personas_autorizadas`

### **Clases Extracurriculares:**
- `permite_externos`: true = pueden inscribirse mamás u otros

### **Notificaciones:**
- `para_grado_id`: NULL = para todos
- `leido_por`: Array de IDs que la leyeron

---

## ⚠️ **IMPORTANTE:**

1. **Guarda tus credenciales de Supabase:**
   - URL del proyecto
   - Anon Key (pública)
   - Service Role Key (privada, no compartir)

2. **Storage (para fotos):**
   - Ve a **Storage** → **Create a new bucket**
   - Nombre: `caipi-files`
   - Público: ✅
   - Allowed file types: `image/*`

3. **Actualiza las credenciales en la app:**
   - Edita `lib/config/supabase_config.dart`
   - Pon tu URL y Anon Key

---

## 🎯 **SIGUIENTE PASO:**

Una vez ejecutado todo, avísame y empiezo a crear:
1. Los modelos Dart para cada tabla
2. El dashboard con diseño Crayola
3. Las pantallas de cada módulo

**¿Listo para ejecutar el SQL?** 🚀
