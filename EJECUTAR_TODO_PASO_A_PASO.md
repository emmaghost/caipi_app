# 🚀 GUÍA COMPLETA - EJECUTAR TODO PASO A PASO

## 📝 **LO QUE CONTIENE `SQL_MAESTRO_COMPLETO.sql`:**

### ✅ **22 Tablas:**
1. usuarios
2. grados
3. profesores
4. alumnos
5. personas_autorizadas
6. pagos
7. calificaciones
8. control_salidas
9. bitacora_diaria
10. menu_maternal
11. notificaciones
12. galeria
13. clases_extracurriculares
14. participantes_clase
15. eventos
16. tipos_incidentes
17. incidentes
18. anuncios
19. roles
20. permisos
21. roles_permisos
22. permisos_usuario

### ✅ **Datos Iniciales:**
- **6 Grados:** Maternal 1, 2, 3 + Kinder 1, 2, 3
- **4 Roles:** directora, profesor_admin, profesor, padre
- **19 Permisos:** ver_alumnos, crear_alumnos, ver_pagos, etc.
- **15 Tipos de Incidentes:** Con niveles 1-5 y colores

### ✅ **Configuraciones:**
- Políticas RLS (Row Level Security) por roles
- Triggers automáticos (updated_at, notificaciones)
- Índices para optimizar consultas
- Funciones auxiliares

---

## 🔧 **PASO 1: EJECUTAR SQL MAESTRO**

### **1.1 Abrir Supabase**
- Ve a: [https://supabase.com/dashboard](https://supabase.com/dashboard)
- Selecciona tu proyecto **CAIPI**

### **1.2 Ir a SQL Editor**
- Click en **"SQL Editor"** en el menú izquierdo
- Click en **"New Query"**

### **1.3 Copiar y Pegar**
- Abre el archivo: `SQL_MAESTRO_COMPLETO.sql`
- **Selecciona TODO** el contenido (Ctrl+A)
- **Copia** (Ctrl+C)
- **Pega** en el SQL Editor de Supabase (Ctrl+V)

### **1.4 ⚠️ IMPORTANTE**
Este script hará lo siguiente:
- ✅ **Eliminará todas las tablas existentes** (si las hay)
- ✅ **Recreará las 22 tablas** con la estructura correcta
- ✅ **Insertará datos iniciales** (grados, roles, permisos, tipos incidentes)

**⚠️ Si tienes datos que quieres conservar, haz backup primero.**

### **1.5 Ejecutar**
- Click en **"Run"** (botón verde, abajo a la derecha)
- Espera 30-60 segundos
- Debe decir: **"Success. No rows returned"** ✅

### **1.6 Verificar**
Ejecuta esta query en el mismo SQL Editor:

```sql
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_type = 'BASE TABLE'
ORDER BY table_name;
```

Deberías ver las **22 tablas** listadas.

---

## 👤 **PASO 2: CREAR USUARIO DIRECTOR**

### **2.1 Ir a Authentication**
- En Supabase, click en **"Authentication"** en el menú izquierdo
- Click en **"Users"**

### **2.2 Crear Usuario**
- Click en **"Add user"** → **"Create new user"**

### **2.3 Datos:**
- **Email:** `viri@caipi.com`
- **Password:** `Caipi123`
- ✅ **Marca:** "Auto Confirm User" (debe estar activado)
- Click en **"Create user"**

### **2.4 Copiar UUID**
- Una vez creado, verás el usuario en la lista
- En la columna **"ID"**, verás un UUID (algo como: `75a24887-ed15-4fca-9116-a514182a7c20`)
- **COPIA ese UUID completo**

### **2.5 Insertar en Tabla Usuarios**
- Ve de nuevo a **SQL Editor**
- Crea una **New Query**
- Pega este código (reemplazando el UUID):

```sql
INSERT INTO usuarios (id, email, rol, nombre, apellidos, telefono, whatsapp, activo)
VALUES (
  '75a24887-ed15-4fca-9116-a514182a7c20',  -- ← REEMPLAZA con el UUID que copiaste
  'viri@caipi.com',
  'directora',
  'Viridiana',
  'Directora CAIPI',
  '1234567890',
  '1234567890',
  true
);
```

- Click en **"Run"**
- Debe decir: **"Success. Rows returned: 0"** ✅

---

## 📸 **PASO 3: CREAR BUCKET DE GALERÍA**

### **3.1 Ir a Storage**
- En Supabase, click en **"Storage"** en el menú izquierdo

### **3.2 Crear Bucket**
- Click en **"Create a new bucket"**

### **3.3 Configurar:**
- **Name:** `galeria`
- ✅ **Public bucket:** Activado (importante)
- Click en **"Create bucket"**

---

## 📧 **PASO 4: CONFIGURAR EMAILS PERSONALIZADOS**

### **4.1 Abrir Templates**
- Abre el archivo: `EMAILS_5_TEMPLATES.txt`

### **4.2 Ir a Email Templates en Supabase**
- En Supabase, ve a: **Authentication → Email Templates**

### **4.3 Configurar cada uno:**

#### **Template 1: Confirm signup**
1. Click en **"Confirm signup"**
2. **Borra** todo el contenido existente
3. **Copia** el Template 1 de `EMAILS_5_TEMPLATES.txt`
4. **Pega** en el editor
5. Click en **"Save"**

#### **Template 2: Reset Password**
1. Click en **"Reset Password"** (o "Magic Link")
2. Repite el proceso con Template 2

#### **Template 3: Invite User**
1. Click en **"Invite User"**
2. Repite el proceso con Template 3

#### **Template 4: Change Email**
1. Click en **"Change Email Address"**
2. Repite el proceso con Template 4

#### **Template 5: Magic Link**
1. Click en **"Magic Link"** (si está separado)
2. Repite el proceso con Template 5

**Tiempo estimado:** 5 minutos

---

## 🚀 **PASO 5: EJECUTAR LA APP**

### **5.1 Abrir Terminal en el Proyecto**
```powershell
cd C:\laragon\www\app-caipi
```

### **5.2 Instalar Dependencias**
```powershell
flutter pub get
```

### **5.3 Ejecutar la App**
```powershell
flutter run
```

### **5.4 Login**
Una vez que la app cargue:
- **Email:** `viri@caipi.com`
- **Password:** `Caipi123`
- Click en **"Iniciar Sesión"**

---

## ✅ **VERIFICACIÓN FINAL**

Una vez dentro de la app como directora, verifica que puedas:

1. ✅ Ver el Dashboard con estadísticas
2. ✅ Acceder al menú lateral (☰)
3. ✅ Ver todas las opciones:
   - Alumnos
   - Pagos
   - Profesoras
   - Padres de Familia
   - Grados
   - Eventos
   - Incidentes
   - Tipos de Incidentes
   - Bitácora Diaria
   - Control de Salidas
   - Calificaciones
   - Anuncios
   - Menú Maternal
   - Galería
   - Clases Extracurriculares

4. ✅ Crear un alumno y verificar que se generen automáticamente:
   - 1 Pago de Inscripción
   - 1 Pago de Seguro + Credencial
   - 12 Pagos de Colegiatura (Enero - Diciembre)

---

## ❌ **¿PROBLEMAS?**

### **Si hay errores en el SQL:**
- Copia el mensaje de error completo
- Dime en qué línea ocurrió
- Te ayudaré a corregirlo

### **Si la app no carga:**
```powershell
flutter clean
flutter pub get
flutter run
```

### **Si no puedes hacer login:**
- Verifica que creaste el usuario en Authentication
- Verifica que insertaste el UUID en la tabla usuarios
- Verifica que el email y password sean correctos

---

## 📊 **RESUMEN DE LO QUE TENDRÁS:**

| Módulo | Tablas | Pantallas | Funcionalidad |
|--------|--------|-----------|---------------|
| Alumnos | alumnos, personas_autorizadas | 3 | CRUD + Personas autorizadas |
| Pagos | pagos | 2 | Ver + Acreditar + Generar automático |
| Profesoras | profesores, permisos_usuario | 3 | CRUD + Asignar permisos |
| Padres | usuarios (rol padre) | 2 | CRUD + Ver hijos |
| Grados | grados | 2 | CRUD completo |
| Eventos | eventos | 2 | CRUD + Dashboard |
| Incidentes | incidentes, tipos_incidentes | 3 | CRUD + Catálogo + Notificaciones |
| Bitácora | bitacora_diaria | 2 | CRUD por alumno |
| Control Salidas | control_salidas | 2 | Registrar entrada/salida |
| Calificaciones | calificaciones | 2 | CRUD por alumno |
| Anuncios | anuncios | 2 | CRUD + Prioridad |
| Menú Maternal | menu_maternal | 2 | CRUD por fecha |
| Galería | galeria | 2 | Ver + Subir fotos |
| Clases Extra | clases_extracurriculares | 2 | CRUD + Participantes |

**Total:** 14 módulos completos + Sistema de permisos + Notificaciones

---

**¿Listo para empezar?** 🎉 Ejecuta el Paso 1 (SQL) y avísame cuando termine.
