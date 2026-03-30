# ✅ CHECKLIST - DATOS INICIALES EN SQL MAESTRO

## 📊 **VERIFICACIÓN COMPLETA DE `SQL_MAESTRO_COMPLETO.sql`**

---

### ✅ **1. LIMPIEZA (PARTE 0)**

El script ahora **ELIMINA primero:**
- ✅ Todas las funciones existentes (6 funciones)
- ✅ Todas las vistas existentes (v_permisos_usuario)
- ✅ Todas las tablas existentes (22 tablas)

**Esto soluciona:** Errores de columnas incompatibles y funciones con parámetros diferentes.

---

### ✅ **2. TABLAS (PARTE 1 y 2)**

Crea **22 tablas:**
1. ✅ usuarios
2. ✅ grados
3. ✅ profesores
4. ✅ alumnos
5. ✅ personas_autorizadas
6. ✅ pagos
7. ✅ calificaciones
8. ✅ control_salidas
9. ✅ bitacora_diaria
10. ✅ menu_maternal
11. ✅ notificaciones (con columna `para_usuario_id`)
12. ✅ galeria
13. ✅ clases_extracurriculares
14. ✅ participantes_clase
15. ✅ eventos
16. ✅ tipos_incidentes
17. ✅ incidentes
18. ✅ anuncios
19. ✅ roles
20. ✅ permisos
21. ✅ roles_permisos
22. ✅ permisos_usuario

---

### ✅ **3. FUNCIONES Y TRIGGERS (PARTE 3)**

Crea **3 funciones:**
1. ✅ `update_grados_updated_at()` - Actualiza fecha de modificación
2. ✅ `notificar_padre_incidente()` - Marca incidentes graves para notificar
3. ✅ `usuario_tiene_permiso()` - Verifica permisos de usuario

Crea **2 triggers:**
1. ✅ `trigger_update_grados_updated_at` - Ejecuta al actualizar grados
2. ✅ `trigger_notificar_incidente` - Ejecuta al crear/actualizar incidentes

---

### ✅ **4. POLÍTICAS RLS (PARTE 4)**

Configura seguridad por roles para:
- ✅ usuarios (lectura y escritura para autenticados)
- ✅ grados (todos ven, solo directora edita)
- ✅ profesores (todos ven, solo directora edita)
- ✅ alumnos (padres solo ven sus hijos, directora ve todo)
- ✅ personas_autorizadas (padres gestionan las de sus hijos)
- ✅ pagos (padres ven sus pagos, directora gestiona)
- ✅ anuncios (todos ven, directora gestiona)
- ✅ permisos y roles (todos leen)

**Total:** ~15 políticas RLS configuradas

---

### ✅ **5. DATOS INICIALES (PARTE 5)**

#### **5.1 Roles (4)**
```
directora         - Nivel 1 (acceso total)
profesor_admin    - Nivel 2 (permisos administrativos)
profesor          - Nivel 3 (acceso básico)
padre             - Nivel 4 (solo sus hijos)
```

#### **5.2 Permisos (19)**
```
Módulo: alumnos
  - ver_alumnos
  - crear_alumnos
  - editar_alumnos
  - eliminar_alumnos

Módulo: pagos
  - ver_pagos
  - acreditar_pagos
  - crear_pagos

Módulo: profesores
  - ver_profesores
  - crear_profesores
  - editar_profesores

Módulo: padres
  - ver_padres
  - crear_padres

Módulo: eventos
  - ver_eventos
  - crear_eventos
  - editar_eventos

Módulo: incidentes
  - ver_incidentes
  - crear_incidentes
  - ver_tipos_incidentes

Módulo: bitacora
  - ver_bitacora
  - crear_bitacora

Módulo: seguridad
  - ver_personas_autorizadas
  - crear_personas_autorizadas

Módulo: comunicacion
  - ver_anuncios
  - crear_anuncios
```

#### **5.3 Grados (6)**
```
Maternal 1  - 1-2 años  - Cupo: 15
Maternal 2  - 2-3 años  - Cupo: 15
Maternal 3  - 3-4 años  - Cupo: 20
Kinder 1    - 4-5 años  - Cupo: 20
Kinder 2    - 5-6 años  - Cupo: 20
Kinder 3    - 6-7 años  - Cupo: 20
```

#### **5.4 Tipos de Incidentes (15)**
```
Nivel 1 (Verde):
  - Olvido material
  - Tarea incompleta
  - Excelente comportamiento (logro)
  - Aprendizaje destacado (logro)
  - Ayudó a compañero (logro)

Nivel 2 (Amarillo):
  - Golpe leve
  - Falta de atención

Nivel 3 (Naranja):
  - Conflicto con compañero
  - Malestar leve

Nivel 4 (Rojo) ⚠️ Notifica a padres:
  - Golpe con moretón
  - Pelea
  - Fiebre

Nivel 5 (Rojo oscuro) 🚨 Notifica urgente:
  - Lesión grave
  - Conducta agresiva grave
  - Crisis de salud
```

---

### ❌ **6. LO QUE NO INCLUYE (DEBES HACER MANUAL):**

#### **6.1 Usuario Director:**
**Razón:** No se puede crear el usuario en `auth.users` desde SQL, debe ser desde el panel de Authentication.

**Pasos:**
1. Authentication → Users → Add user
2. Email: `viri@caipi.com`
3. Password: `Caipi123`
4. Copiar UUID generado
5. Ejecutar INSERT:

```sql
INSERT INTO usuarios (id, email, rol, nombre, apellidos, telefono, whatsapp, activo)
VALUES (
  'UUID-AQUI',  -- ← Pegar UUID
  'viri@caipi.com',
  'directora',
  'Viridiana',
  'Directora CAIPI',
  '1234567890',
  '1234567890',
  true
);
```

#### **6.2 Bucket de Galería:**
**Razón:** Los buckets de Storage no se pueden crear desde SQL.

**Pasos:**
1. Storage → Create bucket
2. Name: `galeria`
3. ✅ Public bucket
4. Create

---

## 🎯 **ORDEN DE EJECUCIÓN:**

```
1️⃣ Ejecutar SQL_MAESTRO_COMPLETO.sql (elimina todo y recrea)
   ↓
2️⃣ Crear usuario director en Authentication
   ↓
3️⃣ Insertar UUID del director en tabla usuarios (SQL)
   ↓
4️⃣ Crear bucket 'galeria' en Storage
   ↓
5️⃣ Configurar 5 templates de emails
   ↓
6️⃣ flutter pub get
   ↓
7️⃣ flutter run
   ↓
8️⃣ Login con viri@caipi.com / Caipi123
```

---

## 🔍 **CÓMO VERIFICAR QUE TODO FUNCIONÓ:**

### **Después de ejecutar el SQL:**

```sql
-- Ver cuántas tablas se crearon
SELECT COUNT(*) as total_tablas 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_type = 'BASE TABLE';
-- Debe ser: 22

-- Ver los grados
SELECT nombre, edad_minima, edad_maxima, cupo_maximo 
FROM grados 
ORDER BY edad_minima;
-- Debe mostrar: 6 grados

-- Ver los roles
SELECT codigo, nombre, nivel_jerarquia 
FROM roles 
ORDER BY nivel_jerarquia;
-- Debe mostrar: 4 roles

-- Ver los permisos
SELECT modulo, COUNT(*) as total 
FROM permisos 
GROUP BY modulo 
ORDER BY modulo;
-- Debe mostrar permisos agrupados por módulo

-- Ver tipos de incidentes
SELECT nivel, COUNT(*) as total 
FROM tipos_incidentes 
GROUP BY nivel 
ORDER BY nivel;
-- Debe mostrar incidentes por nivel (1-5)
```

---

## ✅ **RESUMEN:**

| Elemento | Cantidad | Status |
|----------|----------|--------|
| Tablas | 22 | ✅ En SQL |
| Funciones | 3 | ✅ En SQL |
| Triggers | 2 | ✅ En SQL |
| Políticas RLS | ~15 | ✅ En SQL |
| Grados | 6 | ✅ En SQL |
| Roles | 4 | ✅ En SQL |
| Permisos | 19 | ✅ En SQL |
| Tipos Incidentes | 15 | ✅ En SQL |
| Usuario Director | 1 | ❌ Manual |
| Bucket Galería | 1 | ❌ Manual |
| Email Templates | 5 | ❌ Manual |

---

**¿Dudas?** Ejecuta el SQL y avísame si sale algún error. ¡Ahora debería funcionar sin problemas! 🚀
