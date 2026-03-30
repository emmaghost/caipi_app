# 📊 SQL A EJECUTAR EN SUPABASE - ORDEN CORRECTO

## 🎯 **ARCHIVOS SQL EN ORDEN:**

### **1️⃣ DATABASE_COMPLETA.sql** ✅ (Ya ejecutado)
```
✅ Ya lo ejecutaste antes
✅ Contiene las 15 tablas base
✅ Incluye RLS y triggers básicos
```

---

### **2️⃣ DATA_INICIAL_COMPLETA.sql** ✅ (Ya ejecutado)
```
✅ Ya lo ejecutaste antes
✅ Inserta 6 grados iniciales
✅ Crea usuario directora (viri@caipi.com)
```

---

### **3️⃣ SISTEMA_PERMISOS.sql** ⚠️ (EJECUTAR AHORA)
```
🚀 NUEVO - DEBES EJECUTARLO

Crea:
✅ Tabla permisos (29 permisos)
✅ Tabla roles (4 roles)
✅ Tabla roles_permisos
✅ Tabla usuarios_permisos
✅ Función usuario_tiene_permiso()
✅ Vista v_permisos_usuario
✅ Asigna permisos a cada rol

Tiempo estimado: 10 segundos
```

**CÓMO EJECUTAR:**
```bash
1. Supabase → SQL Editor
2. Abre: SISTEMA_PERMISOS.sql
3. Copia todo el contenido (Ctrl+A, Ctrl+C)
4. Pega en SQL Editor
5. Click: "RUN" ▶️
6. Verifica: "Query completed successfully ✅"
```

**VERIFICACIÓN:**
```sql
-- Ejecuta este query:
SELECT 
  'Permisos' as tabla, 
  COUNT(*) as total 
FROM permisos
UNION ALL
SELECT 'Roles', COUNT(*) FROM roles
UNION ALL
SELECT 'Directora tiene', COUNT(*)
FROM roles_permisos rp
JOIN roles r ON rp.rol_id = r.id
WHERE r.codigo = 'directora';

-- Debe mostrar:
-- Permisos: 29
-- Roles: 4
-- Directora tiene: 29
```

---

### **4️⃣ EVENTOS_E_INCIDENTES.sql** ⚠️ (EJECUTAR AHORA)
```
🚀 NUEVO - DEBES EJECUTARLO

Crea:
✅ Tabla eventos
✅ Tabla tipos_incidentes
✅ Actualiza tabla incidentes
✅ Inserta 14 tipos pre-cargados
✅ Trigger de notificación automática
✅ RLS por roles

Tiempo estimado: 10 segundos
```

**CÓMO EJECUTAR:**
```bash
1. Supabase → SQL Editor
2. Abre: EVENTOS_E_INCIDENTES.sql
3. Copia todo el contenido
4. Pega en SQL Editor
5. Click: "RUN" ▶️
6. Verifica: "Query completed successfully ✅"
```

**VERIFICACIÓN:**
```sql
-- Ejecuta este query:
SELECT 
  'Eventos' as tabla,
  COUNT(*) as total
FROM eventos
UNION ALL
SELECT 'Tipos Incidentes', COUNT(*) FROM tipos_incidentes
UNION ALL
SELECT 'Nivel 4-5 (Graves)', COUNT(*) 
FROM tipos_incidentes 
WHERE nivel >= 4;

-- Debe mostrar:
-- Eventos: 0 (normal, no hay aún)
-- Tipos Incidentes: 14
-- Nivel 4-5: 3
```

---

## 📋 **ORDEN DE EJECUCIÓN (RESUMEN):**

```
✅ 1. DATABASE_COMPLETA.sql        (Ya ejecutado)
✅ 2. DATA_INICIAL_COMPLETA.sql    (Ya ejecutado)
⚠️ 3. SISTEMA_PERMISOS.sql         (EJECUTAR AHORA)
⚠️ 4. EVENTOS_E_INCIDENTES.sql     (EJECUTAR AHORA)
```

---

## 🚨 **ERRORES COMUNES:**

### **Error: "relation permisos already exists"**
```
Solución:
- Ya ejecutaste este SQL antes
- Puedes ignorar este error
- O ejecutar: DROP TABLE permisos CASCADE;
  (solo si quieres empezar de cero)
```

### **Error: "function usuario_tiene_permiso already exists"**
```
Solución:
- Ya existe la función
- Puedes ignorar
- O ejecutar: DROP FUNCTION usuario_tiene_permiso;
```

### **Error: "column rol_id does not exist"**
```
Solución:
- Ejecuta: ALTER TABLE usuarios ADD COLUMN rol_id UUID;
- Luego re-ejecuta SISTEMA_PERMISOS.sql
```

---

## ✅ **DESPUÉS DE EJECUTAR TODO:**

### **Verificación Final:**
```sql
-- Ejecuta este mega-query:
SELECT 'Tablas Totales' as item, COUNT(*) as cantidad
FROM information_schema.tables 
WHERE table_schema = 'public'
UNION ALL
SELECT 'Permisos', COUNT(*) FROM permisos
UNION ALL
SELECT 'Roles', COUNT(*) FROM roles
UNION ALL
SELECT 'Tipos Incidentes', COUNT(*) FROM tipos_incidentes
UNION ALL
SELECT 'Grados', COUNT(*) FROM grados
UNION ALL
SELECT 'Usuarios', COUNT(*) FROM usuarios;

-- Debe mostrar:
-- Tablas Totales: ~20
-- Permisos: 29
-- Roles: 4
-- Tipos Incidentes: 14
-- Grados: 6
-- Usuarios: 1 (viri@caipi.com)
```

---

## 🎯 **SIGUIENTE PASO:**

1. ✅ Ejecuta `SISTEMA_PERMISOS.sql`
2. ✅ Ejecuta `EVENTOS_E_INCIDENTES.sql`
3. ✅ En la terminal donde corre Flutter, presiona **R** (mayúscula)
4. ✅ Abre el drawer (☰)
5. ✅ Navega a "Eventos" y crea uno
6. ✅ Navega a "Incidentes" y crea uno nivel 4
7. ✅ Verifica que en dashboard aparezca el evento

---

**¡Ejecuta los 2 SQL y avísame cuando termine!** 🚀
