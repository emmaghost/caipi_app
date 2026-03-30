# 🎓 SISTEMA DE BECAS - GUÍA COMPLETA

## ✅ **QUÉ SE IMPLEMENTÓ:**

### **1. Base de Datos**
- ✅ Campo `beca_porcentaje` en tabla `alumnos` (0-100)
- ✅ Trigger actualizado para aplicar descuento automáticamente
- ✅ El descuento se aplica a:
  - Inscripción anual
  - Seguro + Credencial
  - TODAS las mensualidades
- ✅ Vista `vista_alumnos_con_becas` para consultas

### **2. Modelos Dart**
- ✅ Campo `becaPorcentaje` en modelo `Alumno`
- ✅ Getters útiles:
  - `tieneBeca` (bool)
  - `becaDescripcion` (texto descriptivo)

### **3. Pantallas**
- ✅ Selector de beca en pantalla de crear/editar alumno
- ✅ Opciones: 0%, 10%, 20%, 30%... hasta 100%
- ✅ Se muestra claramente si el alumno tiene beca

---

## 🎯 **CÓMO FUNCIONA:**

### **Ejemplo 1: Beca del 20%**

```
CONFIGURACIÓN:
- Inscripción: $1,500
- Seguro: $300
- Mensualidad (12 meses): $2,000

ALUMNO CON BECA DEL 20%:
╔════════════════════════════════════════╗
║ Inscripción Anual (Beca 20%)           ║
║ $1,500 → $1,200 ✅ (ahorra $300)       ║
╠════════════════════════════════════════╣
║ Seguro + Credencial (Beca 20%)         ║
║ $300 → $240 ✅ (ahorra $60)            ║
╠════════════════════════════════════════╣
║ Mensualidad Agosto (Beca 20%)          ║
║ $2,000 → $1,600 ✅ (ahorra $400)       ║
╠════════════════════════════════════════╣
║ Mensualidad Septiembre (Beca 20%)      ║
║ $2,000 → $1,600 ✅ (ahorra $400)       ║
╠════════════════════════════════════════╣
║ ...y así cada mes                      ║
╚════════════════════════════════════════╝

AHORRO ANUAL:
- Inscripción: -$300
- Seguro: -$60
- 12 meses × $400 = -$4,800
━━━━━━━━━━━━━━━━━━━━━━━━━━
TOTAL AHORRADO: $5,160 💰
```

### **Ejemplo 2: Beca del 50%**

```
ALUMNO CON BECA DEL 50%:
- Inscripción: $1,500 → $750 (50% OFF)
- Seguro: $300 → $150 (50% OFF)
- Mensualidad: $2,000 → $1,000 (50% OFF)

AHORRO ANUAL: $12,900 💰
```

### **Ejemplo 3: Beca del 100% (Beca Completa)**

```
ALUMNO CON BECA DEL 100%:
- Inscripción: $1,500 → $0 (GRATIS)
- Seguro: $300 → $0 (GRATIS)
- Mensualidad: $2,000 → $0 (GRATIS)

TODO GRATIS 🎉
```

---

## 📋 **PASOS PARA ACTIVAR:**

### **PASO 1: Ejecutar SQL en Supabase**

1. Ve a Supabase → SQL Editor
2. Abre el archivo: `FIX_SISTEMA_BECAS.sql`
3. Copia TODO el contenido
4. Pégalo en el editor
5. Click en **"RUN"**
6. Espera: ✅ **Success. No rows returned**

---

### **PASO 2: Reinstalar app**

```powershell
# Detener la app (Ctrl+C si está corriendo)
# Luego:
flutter run
```

---

### **PASO 3: Probar**

#### **Test 1: Crear alumno con beca del 30%**

1. Login como Directora
2. Ir a: **Alumnos → Crear Alumno**
3. Llenar datos del alumno:
   - Nombre: Juan
   - Apellidos: Pérez García
   - Grado: Lactantes
   - Plan de pagos: **12 meses**
   - **Beca / Descuento**: **30% de descuento** ⭐
4. Click **"Crear Alumno"**
5. Verificar en **Pagos**:
   - ✅ Se crearon 14 pagos (1 inscripción + 1 seguro + 12 mensualidades)
   - ✅ Todos los pagos tienen **30% de descuento**
   - ✅ En el concepto dice: *"(Beca 30%)"*
   - ✅ En notas dice: *"Beca 30% aplicada. Monto original: $XXX"*

#### **Test 2: Crear alumno SIN beca**

1. Crear otro alumno
2. En **Beca / Descuento**: **Sin beca (0%)**
3. Verificar pagos:
   - ✅ Montos normales (sin descuento)

#### **Test 3: Editar alumno y cambiar beca**

⚠️ **IMPORTANTE:** Si editas un alumno que ya tiene pagos generados:
- Los pagos YA CREADOS no se modifican
- Solo nuevos pagos tendrán la nueva beca
- Si necesitas cambiar los pagos existentes, hay que hacerlo manualmente

---

## 🎨 **CÓMO SE VE EN LA APP:**

### **Pantalla: Crear/Editar Alumno**

```
╔══════════════════════════════════════╗
║  Crear Alumno                        ║
╚══════════════════════════════════════╝

📝 Nombre
   [Juan                               ]

📝 Apellidos
   [Pérez García                       ]

📚 Grado
   [Lactantes                       ▼]

💳 Plan de Pagos
   [12 meses (Agosto - Julio)       ▼]

🎓 Beca / Descuento
   [30% de descuento                ▼]
   ✅ Alumno con beca del 30%

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

        [💾 Crear Alumno]
```

### **Opciones del selector de beca:**

```
╔══════════════════════════════════════╗
║ 🎓 Beca / Descuento                  ║
╠══════════════════════════════════════╣
║ ○ Sin beca (0%)                      ║
║ ○ 10% de descuento                   ║
║ ○ 20% de descuento                   ║
║ ● 30% de descuento ✓                 ║
║ ○ 40% de descuento                   ║
║ ○ 50% de descuento                   ║
║ ○ 60% de descuento                   ║
║ ○ 70% de descuento                   ║
║ ○ 80% de descuento                   ║
║ ○ 90% de descuento                   ║
║ ○ 100% de descuento (BECA COMPLETA)  ║
╚══════════════════════════════════════╝
```

### **Pantalla: Lista de Pagos (con beca)**

```
╔══════════════════════════════════════╗
║  Pagos de Juan Pérez García          ║
╚══════════════════════════════════════╝

📄 Inscripción Anual 2026 (Beca 30%)
   Monto: $1,050.00 (Original: $1,500)
   Vence: 15/08/2026
   Estado: Pendiente

🛡️ Seguro + Credencial 2026 (Beca 30%)
   Monto: $210.00 (Original: $300)
   Vence: 15/08/2026
   Estado: Pendiente

📅 Mensualidad Agosto 2026 (1/12) - Beca 30%
   Monto: $1,400.00 (Original: $2,000)
   Vence: 05/08/2026
   Estado: Pendiente

📅 Mensualidad Septiembre 2026 (2/12) - Beca 30%
   Monto: $1,400.00 (Original: $2,000)
   Vence: 05/09/2026
   Estado: Pendiente

...
```

---

## 🔍 **CONSULTAS ÚTILES EN SUPABASE:**

### **Ver todos los alumnos con becas:**

```sql
SELECT * FROM vista_alumnos_con_becas;
```

Resultado:
```
nombre_completo       | beca_porcentaje | total_a_pagar | total_pendiente
----------------------|-----------------|---------------|----------------
Juan Pérez García     | 30              | $18,060.00    | $18,060.00
María López Sánchez   | 50              | $12,900.00    | $12,900.00
Pedro Ramírez Flores  | 100             | $0.00         | $0.00
```

### **Calcular ahorro total por becas:**

```sql
SELECT 
  SUM(
    CASE 
      WHEN a.plan_pagos = 12 THEN
        (cc.costo_inscripcion + cc.costo_seguro_credencial + (cc.costo_mensualidad_12 * 12)) * (a.beca_porcentaje / 100.0)
      ELSE
        (cc.costo_inscripcion + cc.costo_seguro_credencial + (cc.costo_mensualidad_10 * 10)) * (a.beca_porcentaje / 100.0)
    END
  ) AS ahorro_total_becas
FROM alumnos a
CROSS JOIN configuracion_costos cc
WHERE a.beca_porcentaje > 0
  AND a.activo = true
  AND cc.vigente = true;
```

### **Ver estadísticas de becas:**

```sql
SELECT 
  COUNT(*) AS alumnos_con_beca,
  AVG(beca_porcentaje) AS promedio_beca,
  MIN(beca_porcentaje) AS beca_minima,
  MAX(beca_porcentaje) AS beca_maxima
FROM alumnos
WHERE beca_porcentaje > 0
  AND activo = true;
```

### **Alumnos por nivel de beca:**

```sql
SELECT 
  CASE 
    WHEN beca_porcentaje = 0 THEN 'Sin beca'
    WHEN beca_porcentaje <= 30 THEN 'Beca baja (10-30%)'
    WHEN beca_porcentaje <= 60 THEN 'Beca media (40-60%)'
    WHEN beca_porcentaje <= 90 THEN 'Beca alta (70-90%)'
    ELSE 'Beca completa (100%)'
  END AS nivel_beca,
  COUNT(*) AS cantidad
FROM alumnos
WHERE activo = true
GROUP BY nivel_beca
ORDER BY 
  CASE 
    WHEN beca_porcentaje = 0 THEN 1
    WHEN beca_porcentaje <= 30 THEN 2
    WHEN beca_porcentaje <= 60 THEN 3
    WHEN beca_porcentaje <= 90 THEN 4
    ELSE 5
  END;
```

---

## 💡 **CARACTERÍSTICAS IMPORTANTES:**

### **1. El descuento se aplica a TODO:**

✅ Inscripción anual
✅ Seguro + Credencial
✅ TODAS las mensualidades (10 o 12)

### **2. Transparencia total:**

- En el concepto del pago se indica: *"(Beca XX%)"*
- En las notas se guarda el monto original
- Fácil auditoría y reportes

### **3. Opciones flexibles:**

Puedes elegir desde:
- 0% (sin beca)
- 10%, 20%, 30%... hasta 100%
- En incrementos de 10%

### **4. Cálculo automático:**

El sistema calcula automáticamente:
```
Monto con descuento = Monto original × (100 - % beca) / 100

Ejemplo: Beca 25%
$2,000 × (100 - 25) / 100 = $2,000 × 0.75 = $1,500
```

---

## ⚠️ **IMPORTANTE:**

### **Modificar becas en alumnos existentes:**

Si un alumno YA TIENE pagos generados:
- Editar su beca NO modifica los pagos existentes
- Solo afectará pagos futuros (si se generan nuevos)

### **Para modificar pagos existentes:**

Opción 1: Manual (SQL):
```sql
-- Aplicar beca del 20% a todos los pagos pendientes de un alumno
UPDATE pagos
SET 
  monto = monto * 0.80,
  concepto = concepto || ' (Beca 20%)',
  notas = 'Beca 20% aplicada retroactivamente'
WHERE alumno_id = 'uuid-del-alumno'
  AND estatus = 'pendiente';
```

Opción 2: Eliminar pagos y volver a crear alumno (PELIGROSO):
```sql
-- Solo si el alumno NO tiene pagos realizados
DELETE FROM pagos WHERE alumno_id = 'uuid-del-alumno';
DELETE FROM alumnos WHERE id = 'uuid-del-alumno';
-- Luego crear de nuevo con la beca correcta
```

---

## 🎉 **VENTAJAS DEL SISTEMA:**

### **1. Automático:**
- No calculas descuentos manualmente
- Se aplica al crear el alumno

### **2. Transparente:**
- Padres ven claramente que tienen beca
- Directora puede auditar fácilmente

### **3. Flexible:**
- Desde 10% hasta 100%
- Se aplica a todos los pagos

### **4. Reportes fáciles:**
- Vista SQL preparada
- Consultas rápidas sobre becas

---

## 📊 **EJEMPLO COMPLETO:**

### **Alumno: María López Sánchez**

**Configuración:**
- Grado: Maternal
- Plan: 12 meses
- **Beca: 40%** 🎓

**Pagos generados:**

| Concepto | Monto Original | Con Beca 40% | Ahorro |
|----------|---------------|--------------|--------|
| Inscripción 2026 (Beca 40%) | $1,500 | $900 | $600 |
| Seguro + Credencial 2026 (Beca 40%) | $300 | $180 | $120 |
| Mensualidad Agosto (1/12) - Beca 40% | $2,000 | $1,200 | $800 |
| Mensualidad Septiembre (2/12) - Beca 40% | $2,000 | $1,200 | $800 |
| ... (10 meses más) | ... | ... | ... |
| **TOTAL ANUAL** | **$25,800** | **$15,480** | **$10,320** |

---

## ✅ **CHECKLIST DE VERIFICACIÓN:**

- [ ] SQL ejecutado sin errores
- [ ] App reiniciada
- [ ] Crear alumno con beca 20% → Pagos con descuento
- [ ] Crear alumno con beca 50% → Pagos con descuento
- [ ] Crear alumno con beca 100% → Pagos en $0
- [ ] Crear alumno sin beca → Pagos normales
- [ ] Verificar que el concepto diga "(Beca XX%)"
- [ ] Verificar que las notas indiquen el monto original
- [ ] Consultar vista `vista_alumnos_con_becas`

---

## 🚀 **¡LISTO!**

Ahora tienes un sistema completo de becas:
- ✅ Selector visual en la app (0% a 100%)
- ✅ Descuentos automáticos al crear alumno
- ✅ Aplicado a todos los pagos
- ✅ Reportes y consultas preparadas
- ✅ Transparencia total

**¿Dudas? Revisa esta guía paso a paso.** 📚
