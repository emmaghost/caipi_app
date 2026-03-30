# 🚨 EJECUTAR FIX DE PAGOS URGENTE

## ⚠️ PROBLEMA ACTUAL
La app está crasheando en "Gestión de Pagos" con el error:
```
type 'Null' is not a subtype of type 'String' in type cast
```

## ✅ SOLUCIÓN

### PASO 1: Ejecutar SQL en Supabase
1. Abre: https://supabase.com/dashboard/project/YOUR_PROJECT/editor
2. Copia TODO el contenido de: `FIX_PAGOS_COMPLETO_URGENTE.sql`
3. Pégalo en el SQL Editor
4. Dale "Run" (botón verde)
5. **Verifica que diga "Success" y muestre los mensajes:**
   - ✅ Renombrado: fecha_limite → fecha_vencimiento
   - ✅ fecha_vencimiento ahora es NULLABLE
   - ✅ Columna estatus agregada
   - ✅ Migrado: pagado → estatus
   - ✅ Columna monto_pagado agregada
   - ✅ Columna tipo_pago agregada
   - 📋 ESTRUCTURA FINAL DE TABLA PAGOS
   - 📊 TIPOS DE PAGO EN LA BASE

### PASO 2: Verificar en la App
1. La app debería recargarse automáticamente (hot reload)
2. **Si NO se recarga**, presiona `r` en la terminal
3. Entra a "Gestión de Pagos" como directora
4. **Deberías ver:**
   - 2 tabs: "Pagos de Alumnos" y "Extracurriculares"
   - NO debe mostrar ningún error
   - Los pagos se muestran según su tipo

## 🎯 QUÉ HACE ESTE FIX

### Antes (❌):
- Columnas: `fecha_limite`, `pagado`, `metodo_pago`
- fecha_limite era NOT NULL → crasheaba con nulls
- Solo boolean pagado/no pagado
- Sin clasificación de tipos

### Después (✅):
- Columnas: `fecha_vencimiento`, `estatus`, `forma_pago`
- fecha_vencimiento es NULLABLE → no crashea
- estatus: pendiente, parcial, pagado, vencido, cancelado
- tipo_pago: inscripcion, mensualidad, extracurricular, seguro
- **Submenú funcional** para filtrar por tipo

## 📊 CLASIFICACIÓN AUTOMÁTICA

El script clasifica automáticamente los pagos existentes:
- **inscripcion**: Inscripciones
- **mensualidad**: Colegiaturas mensuales (Enero, Febrero, etc.)
- **extracurricular**: Libros, Uniformes, Clases extra, Baile, Deportes
- **seguro**: Seguro escolar

## 🔍 VERIFICACIÓN

Después de ejecutar, verifica:
- [ ] No hay error al entrar a "Gestión de Pagos"
- [ ] Se ven 2 tabs (Alumnos / Extracurriculares)
- [ ] Puedes agregar un pago de Libros (va a Extracurriculares)
- [ ] Puedes agregar un pago de Uniforme (va a Extracurriculares)
- [ ] Las mensualidades aparecen en "Pagos de Alumnos"

## 📝 NOTAS
- El código ya está actualizado para usar las columnas correctas
- Solo falta ejecutar el SQL para migrar la base de datos
- Esto NO afecta otros módulos
