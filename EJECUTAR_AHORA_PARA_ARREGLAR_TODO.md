# ⚠️ EJECUTAR AHORA PARA ARREGLAR TODO

---

## 🎯 **3 SCRIPTS SQL QUE DEBES EJECUTAR:**

---

### **Script 1: FIX_FUNCION_PERMISOS.sql** ⚙️
**Arregla:** Error general de permisos
```
PostgrestException: could not find in the schema cache
```

---

### **Script 2: FIX_RLS_POLICIES.sql** 🔒
**Arregla:** Errores de "Forbidden policy"
- Crear profesoras ❌
- Crear bitácoras ❌
- Crear eventos ❌
- Crear anuncios ❌
- Crear incidentes ❌
- Crear control salidas ❌

---

### **Script 3: FIX_PAGOS_AUTOMATICOS.sql** 💰 **← NUEVO**
**Arregla:** Pagos NO se crean automáticamente
- 12 pagos de mensualidad (Enero a Diciembre) ❌
- 1 pago de inscripción anual ❌
- 1 pago de seguro + credencial ❌

---

## 🚀 **CÓMO EJECUTARLOS (5 MINUTOS):**

### **Paso 1: Ir a Supabase**
```
https://supabase.com/dashboard
→ Tu Proyecto
→ SQL Editor
→ New query
```

---

### **Paso 2: Ejecutar Script 1**

**Copiar contenido de:** `FIX_FUNCION_PERMISOS.sql`

**Pegar en SQL Editor y click:** `Run` ▶️

**Resultado esperado:**
```
Success. No rows returned
```

---

### **Paso 3: Ejecutar Script 2**

**Copiar contenido de:** `FIX_RLS_POLICIES.sql`

**Pegar en SQL Editor y click:** `Run` ▶️

**Resultado esperado:**
```
Tabla con 15+ políticas creadas
```

---

### **Paso 4: Ejecutar Script 3** ⭐ **IMPORTANTE**

**Copiar contenido de:** `FIX_PAGOS_AUTOMATICOS.sql`

**Pegar en SQL Editor y click:** `Run` ▶️

**Resultado esperado:**
```
trigger_generar_pagos_alumno | INSERT | alumnos | EXECUTE FUNCTION generar_pagos_alumno()
```

---

### **Paso 5: Hot Restart**

En tu terminal de Flutter:
```
Presionar: R (letra R mayúscula)
```

---

## ✅ **VERIFICAR QUE TODO FUNCIONA:**

### **Test 1: Crear Profesora**
```
1. Ir a: Profesoras → Nueva Profesora
2. Llenar datos con email: profesora1@caipi.com
3. Click Guardar
4. ✅ Debe crear sin error
```

---

### **Test 2: Crear Alumno (IMPORTANTE)** ⭐
```
1. Ir a: Alumnos → Crear Alumno
2. Llenar todos los datos
3. Click Guardar
4. ✅ Debe crear sin error
5. Ir a: Pagos
6. ✅ Debe mostrar 14 pagos del alumno:
   - 1x Inscripción Anual ($1,500)
   - 1x Seguro + Credencial ($300)
   - 12x Mensualidades ($2,000 cada una)
```

---

### **Test 3: Crear Control de Salida**
```
1. Ir a: Control de Entrada/Salida
2. Click "Crear Registro"
3. Seleccionar alumno
4. Llenar datos
5. Click Guardar
6. ✅ Debe crear sin error
```

---

## 💰 **MONTOS DE PAGOS AUTOMÁTICOS:**

| Concepto | Monto | Fecha Límite |
|----------|-------|--------------|
| **Inscripción Anual** | $1,500 | Hoy + 15 días |
| **Seguro + Credencial** | $300 | Hoy + 15 días |
| **Enero** | $2,000 | 5 de Enero |
| **Febrero** | $2,000 | 5 de Febrero |
| **Marzo** | $2,000 | 5 de Marzo |
| **Abril** | $2,000 | 5 de Abril |
| **Mayo** | $2,000 | 5 de Mayo |
| **Junio** | $2,000 | 5 de Junio |
| **Julio** | $2,000 | 5 de Julio |
| **Agosto** | $2,000 | 5 de Agosto |
| **Septiembre** | $2,000 | 5 de Septiembre |
| **Octubre** | $2,000 | 5 de Octubre |
| **Noviembre** | $2,000 | 5 de Noviembre |
| **Diciembre** | $2,000 | 5 de Diciembre |

**Total por alumno al año:** $26,300

---

## 🎯 **AJUSTAR MONTOS (SI NECESITAS):**

Si quieres cambiar los montos, edita estas líneas en `FIX_PAGOS_AUTOMATICOS.sql`:

```sql
-- Línea 30: Inscripción
monto = 1500.00,  ← Cambiar aquí

-- Línea 53: Seguro + Credencial
monto = 300.00,   ← Cambiar aquí

-- Línea 95: Mensualidad
monto = 2000.00,  ← Cambiar aquí
```

Luego vuelve a ejecutar el script ✅

---

## ⚠️ **IMPORTANTE:**

### **¿Y los alumnos que ya creé?**

Los pagos **NO se crean retroactivamente**.

**Opciones:**

**A) Borrar y volver a crear** (Recomendado si es de prueba)
```sql
-- En Supabase SQL Editor
DELETE FROM alumnos WHERE nombre = 'nombre-del-alumno';
```
Luego crear el alumno de nuevo → Los pagos se generarán automáticamente ✅

**B) Crear pagos manualmente para alumnos existentes**
En la app:
1. Ir a: Pagos
2. Click "Agregar Pago"
3. Seleccionar: Libros/Uniformes
4. Repetir 14 veces 😅 (no recomendado)

---

## 📊 **RESUMEN:**

| Script | Qué arregla | Tiempo |
|--------|-------------|--------|
| FIX_FUNCION_PERMISOS.sql | Error de permisos general | 30 seg |
| FIX_RLS_POLICIES.sql | Forbidden en todos los módulos | 1 min |
| FIX_PAGOS_AUTOMATICOS.sql | Pagos automáticos ⭐ | 1 min |
| **TOTAL** | **Todo funcionando** | **3 min** |

---

## 🎉 **DESPUÉS DE EJECUTAR:**

✅ Crear profesoras funciona
✅ Crear bitácoras funciona
✅ Crear eventos funciona
✅ Crear anuncios funciona
✅ Crear incidentes funciona
✅ Crear control salidas funciona
✅ **Crear alumno genera 14 pagos automáticamente** ⭐

---

## 🚀 **EMPEZAR AHORA:**

```
1. Abrir: https://supabase.com/dashboard
2. SQL Editor
3. Copiar y pegar cada script
4. Run ▶️
5. Hot restart (R)
6. Probar crear alumno
7. Verificar que aparecen 14 pagos ✅
```

**¡Listo en 5 minutos!** ⏱️
