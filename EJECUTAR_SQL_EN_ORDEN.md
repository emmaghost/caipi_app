# 📋 GUÍA DE EJECUCIÓN SQL - ORDEN CORRECTO

## ⚠️ IMPORTANTE: Ejecuta en este orden exacto

### 🎯 **SITUACIÓN ACTUAL**

Si ya ejecutaste algunos SQLs y obtuviste errores, **NO IMPORTA**. Los nuevos archivos corregidos tienen `ON CONFLICT DO NOTHING` y `IF NOT EXISTS`, así que puedes ejecutarlos sin problemas.

---

## 🚀 **ORDEN DE EJECUCIÓN**

### **1️⃣ Tablas Base** (DATABASE_COMPLETA.sql)

**Archivo**: `DATABASE_COMPLETA.sql`  
**Qué hace**: Crea todas las tablas principales del sistema  
**Tiempo**: ~30 segundos

<details>
<summary>📝 Contenido (click para expandir)</summary>

Crea estas tablas:
- ✅ usuarios
- ✅ alumnos
- ✅ pagos
- ✅ calificaciones
- ✅ anuncios
- ✅ grados
- ✅ profesores
- ✅ personas_autorizadas
- ✅ control_salidas
- ✅ bitacora_diaria
- ✅ menu_maternal
- ✅ notificaciones
- ✅ galeria
- ✅ clases_extracurriculares
- ✅ participantes_clase

</details>

**Estado**: ✅ Probablemente ya lo ejecutaste

---

### **2️⃣ Sistema de Permisos** (SISTEMA_PERMISOS_CORREGIDO.sql) ⭐

**Archivo**: `SISTEMA_PERMISOS_CORREGIDO.sql` ⬅️ **USA ESTE (CORREGIDO)**  
**Qué hace**: Crea el sistema completo de roles y permisos  
**Tiempo**: ~15 segundos

<details>
<summary>📝 Contenido (click para expandir)</summary>

Crea:
- ✅ Tabla `permisos` (29 permisos)
- ✅ Tabla `roles` (4 roles: directora, profesor_admin, profesor, padre)
- ✅ Tabla `roles_permisos` (asignación roles ↔ permisos)
- ✅ Tabla `usuarios_permisos` (permisos extras por usuario)
- ✅ Función `usuario_tiene_permiso()`
- ✅ Vista `v_permisos_usuario` (SIN RLS, solo consulta)
- ✅ RLS en las **tablas** (no en la vista)
- ✅ Asigna todos los permisos a cada rol

</details>

**⚠️ Si tuviste error**: "v_permisos_usuario is not a table"  
**Solución**: Usa `SISTEMA_PERMISOS_CORREGIDO.sql` en lugar del original

---

### **3️⃣ Eventos e Incidentes** (EVENTOS_E_INCIDENTES_CORREGIDO.sql) ⭐

**Archivo**: `EVENTOS_E_INCIDENTES_CORREGIDO.sql` ⬅️ **USA ESTE (CORREGIDO)**  
**Qué hace**: Crea tablas de eventos e incidentes con catálogo inicial  
**Tiempo**: ~10 segundos

<details>
<summary>📝 Contenido (click para expandir)</summary>

Crea:
- ✅ Tabla `eventos`
- ✅ Tabla `tipos_incidentes` (catálogo con 15 tipos)
- ✅ Tabla `incidentes`
- ✅ RLS para las 3 tablas (CORREGIDO: relación padres-hijos)
- ✅ Trigger para notificación automática de incidentes nivel 4-5
- ✅ INSERT con `ON CONFLICT DO NOTHING` (evita duplicados)

</details>

**⚠️ Errores corregidos**:
- ✅ "duplicate key value violates unique constraint" → Arreglado con `ON CONFLICT`
- ✅ "column u.hijos_ids does not exist" → Arreglado usando `alumnos.padre_id`

---

### **4️⃣ Datos Iniciales** (DATA_INICIAL_COMPLETA.sql)

**Archivo**: `DATA_INICIAL_COMPLETA.sql`  
**Qué hace**: Inserta datos iniciales (grados, usuario directora)  
**Tiempo**: ~5 segundos

<details>
<summary>📝 Contenido (click para expandir)</summary>

Inserta:
- ✅ 6 grados iniciales (Maternal, Kinder 1, 2, 3, Preescolar 1, 2)
- ✅ Usuario directora (si no existe)

</details>

**Nota**: Usa `ON CONFLICT DO NOTHING`, así que no hay problema si ya tienes datos.

---

## 🎯 **RESUMEN DE ARCHIVOS A EJECUTAR**

| # | Archivo | Estado | Acción |
|---|---------|--------|--------|
| 1 | `DATABASE_COMPLETA.sql` | Opcional si ya lo hiciste | Ejecutar si es tu primera vez |
| 2 | `SISTEMA_PERMISOS_CORREGIDO.sql` | ⭐ REQUERIDO | Ejecutar siempre (corrige RLS) |
| 3 | `EVENTOS_E_INCIDENTES_CORREGIDO.sql` | ⭐ REQUERIDO | Ejecutar siempre (evita duplicados) |
| 4 | `DATA_INICIAL_COMPLETA.sql` | ⭐ REQUERIDO | Ejecutar siempre (datos iniciales) |

---

## ✅ **VERIFICACIÓN: ¿Funcionó todo?**

Después de ejecutar los 4 SQLs, ejecuta estas consultas para verificar:

```sql
-- 1. Ver permisos (deberías tener 29)
SELECT COUNT(*) as total_permisos FROM permisos;

-- 2. Ver roles (deberías tener 4)
SELECT * FROM roles ORDER BY nivel_jerarquia;

-- 3. Ver tipos de incidentes (deberías tener 15)
SELECT COUNT(*) as total_tipos FROM tipos_incidentes;

-- 4. Ver grados (deberías tener al menos 6)
SELECT * FROM grados ORDER BY nombre;

-- 5. Ver permisos de la directora
SELECT * FROM v_permisos_usuario 
WHERE email = 'viri@caipi.com';
```

**Resultados esperados**:
- ✅ 29 permisos
- ✅ 4 roles
- ✅ 15 tipos de incidentes
- ✅ 6+ grados
- ✅ La directora tiene 29 permisos

---

## 🔧 **SI AÚN TIENES ERRORES**

### Error: "relation already exists"
**Solución**: Normal, ignora. `IF NOT EXISTS` lo maneja.

### Error: "duplicate key"
**Solución**: Asegúrate de usar los archivos `_CORREGIDO.sql`

### Error: "v_permisos_usuario is not a table"
**Solución**: 
```sql
-- Primero elimina la política problemática
DROP POLICY IF EXISTS "Ver propios permisos" ON v_permisos_usuario;

-- Luego ejecuta SISTEMA_PERMISOS_CORREGIDO.sql
```

### Error: "column does not exist"
**Solución**: Verifica que ejecutaste `DATABASE_COMPLETA.sql` primero.

---

## 🎓 **DESPUÉS DE EJECUTAR TODO**

### 1. Crear Bucket de Storage (para galería de fotos):
1. Ve a **Storage** en Supabase
2. Click en **New bucket**
3. Nombre: `galeria`
4. Click en **Public bucket** ✅
5. Click en **Create bucket**

### 2. Crear usuario director en Auth (si no lo hiciste):
1. Ve a **Authentication** > **Users** en Supabase
2. Click en **Add user** > **Create new user**
3. Email: `viri@caipi.com`
4. Password: La que quieras (guárdala)
5. Click en **Create user**
6. Copia el **User UID**

### 3. Crear registro en tabla usuarios:
```sql
INSERT INTO usuarios (id, email, nombre, apellidos, rol, telefono, whatsapp, activo)
VALUES (
  'PEGA_AQUI_EL_USER_UID',
  'viri@caipi.com',
  'Virginia',
  'Directora',
  'directora',
  '1234567890',
  '1234567890',
  true
)
ON CONFLICT (id) DO NOTHING;
```

---

## 🚀 **EJECUTAR LA APP**

Una vez que tengas todo en Supabase:

```powershell
cd C:\laragon\www\app-caipi
flutter pub get
flutter run
```

**Login**:
- Email: `viri@caipi.com`
- Password: La que configuraste en Supabase Auth

---

## 📊 **ESTRUCTURA FINAL DE LA BD**

Después de ejecutar todo, tendrás **23 tablas**:

### Tablas Principales (15):
1. usuarios
2. alumnos
3. pagos
4. calificaciones
5. grados
6. profesores
7. personas_autorizadas
8. control_salidas
9. bitacora_diaria
10. menu_maternal
11. anuncios
12. eventos
13. incidentes
14. notificaciones
15. galeria

### Tablas del Sistema de Permisos (5):
16. permisos
17. roles
18. roles_permisos
19. usuarios_permisos
20. tipos_incidentes

### Tablas Auxiliares (3):
21. clases_extracurriculares
22. participantes_clase
23. anuncios_lecturas (si existe)

---

**¿Listo? ¡Ejecuta los SQLs en orden y prueba la app!** 🎉
