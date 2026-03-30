# 💰 Flujo de Pagos - Sistema CAIPI

## 📊 **¿CÓMO FUNCIONAN LOS PAGOS?**

---

## 🔄 **FLUJO COMPLETO:**

### **1️⃣ CREACIÓN AUTOMÁTICA DE PAGOS**

Cuando **creas un alumno nuevo**, el sistema **genera automáticamente 14 pagos**:

```
📝 AL CREAR ALUMNO "Juan Pérez" → SE CREAN:

✅ 1 pago → Inscripción Anual 2026 ($5,000)
✅ 1 pago → Seguro + Credencial ($1,500)
✅ 12 pagos → Colegiaturas mensuales ($3,500 c/u)
   - Enero 2026
   - Febrero 2026
   - Marzo 2026
   - ... hasta Diciembre 2026

TOTAL: 14 pagos pendientes
```

---

### **2️⃣ VER PAGOS PENDIENTES**

**Desde la app:**
1. Login como Directora
2. Dashboard → **"Pagos"**
3. ✅ Verás todos los pagos del sistema

**Semáforo de estados:**
```
🔴 ROJO    → Vencido (fecha límite pasada)
🟡 AMARILLO → Por vencer (falta poco)
🟢 VERDE   → Pagado
```

---

### **3️⃣ ACREDITAR UN PAGO**

**Cuando un padre paga:**

1. **Directora va a "Pagos"**
2. **Click en un pago pendiente**
3. **Se abre pantalla de acreditación:**
   - Seleccionar **método de pago**:
     - 💵 Efectivo
     - 💳 Transferencia
     - 💳 Tarjeta
   - Seleccionar **quién recibió**:
     - 👩‍💼 Directora (Viri)
     - 👨 Joss (esposo)
   - **Referencia** (opcional):
     - Número de transferencia, etc.
4. **Click "Acreditar Pago"**
5. ✅ **Pago marcado como pagado**
6. 🟢 **Semáforo cambia a VERDE**

---

## 💳 **PAGOS ADICIONALES (OPCIONALES)**

### **Libros (Por grado)**
- Se crean **manualmente** desde la app
- La directora va a "Pagos" → **"Agregar Pago"** → **"Libros"**
- Selecciona el alumno y grado
- Se genera 1 pago de libros

### **Uniformes (A demanda)**
- Se crean **cuando el padre lo solicita**
- La directora va a "Pagos" → **"Agregar Pago"** → **"Uniformes"**
- Selecciona el alumno
- Se genera 1 pago de uniformes

---

## 📋 **EJEMPLO PRÁCTICO**

### **Caso: Alumno "María García"**

#### **Paso 1: Crear Alumno**
```
Directora crea alumno:
- Nombre: María García
- Fecha nacimiento: 15/03/2022
- Grado: Maternal 2
- Email padre: mama.maria@gmail.com
- Click "Guardar"
```

#### **Paso 2: Pagos Generados Automáticamente**
```sql
-- SE CREAN AUTOMÁTICAMENTE EN LA BD:

INSERT INTO pagos (alumno_id, concepto, monto, fecha_limite, estado)
VALUES
  ('maria-uuid', 'Inscripción Anual 2026', 5000, '2026-01-31', 'pendiente'),
  ('maria-uuid', 'Seguro + Credencial', 1500, '2026-01-31', 'pendiente'),
  ('maria-uuid', 'Colegiatura Enero 2026', 3500, '2026-01-10', 'pendiente'),
  ('maria-uuid', 'Colegiatura Febrero 2026', 3500, '2026-02-10', 'pendiente'),
  -- ... etc hasta diciembre
```

#### **Paso 3: Padre Paga Inscripción**
```
1. Padre transfiere $5,000
2. Directora entra a "Pagos"
3. Busca "María García - Inscripción"
4. Click → Acreditar Pago
5. Método: Transferencia
6. Recibido por: Directora
7. Referencia: "TRANS-123456"
8. ✅ Guardar
```

#### **Paso 4: Pago Actualizado**
```sql
UPDATE pagos
SET
  estado = 'pagado',
  fecha_pago = '2026-03-05',
  metodo_pago = 'transferencia',
  recibido_por = 'directora',
  referencia = 'TRANS-123456'
WHERE concepto = 'Inscripción Anual 2026'
  AND alumno_id = 'maria-uuid';
```

---

## 🎯 **ESTADOS DE PAGOS**

| Estado | Color | Descripción | Condición |
|--------|-------|-------------|-----------|
| **Pendiente** | 🟡 Amarillo | Por vencer | `fecha_limite > hoy` |
| **Vencido** | 🔴 Rojo | Ya pasó la fecha | `fecha_limite < hoy` Y `estado = pendiente` |
| **Pagado** | 🟢 Verde | Ya pagado | `estado = pagado` |

---

## 📊 **RESUMEN DE MONTOS TÍPICOS**

```
📌 PAGOS ANUALES:
├─ Inscripción: $5,000 (una vez al año)
└─ Seguro + Credencial: $1,500 (una vez)

📌 PAGOS MENSUALES:
└─ Colegiatura: $3,500 x 12 meses = $42,000/año

📌 PAGOS OPCIONALES:
├─ Libros (por grado): $500 - $1,500
└─ Uniformes (a demanda): $800 - $1,200

💰 TOTAL ANUAL POR ALUMNO: ~$49,000
```

---

## 🔍 **VERIFICAR PAGOS EN SUPABASE**

```sql
-- Ver todos los pagos de un alumno
SELECT 
  a.nombre,
  p.concepto,
  p.monto,
  p.estado,
  p.fecha_limite,
  p.fecha_pago
FROM pagos p
JOIN alumnos a ON p.alumno_id = a.id
WHERE a.nombre = 'María García'
ORDER BY p.fecha_limite;

-- Ver resumen de pagos por estado
SELECT 
  estado,
  COUNT(*) as cantidad,
  SUM(monto) as total
FROM pagos
GROUP BY estado;

-- Ver pagos vencidos
SELECT 
  a.nombre,
  p.concepto,
  p.monto,
  p.fecha_limite,
  CURRENT_DATE - p.fecha_limite as dias_vencido
FROM pagos p
JOIN alumnos a ON p.alumno_id = a.id
WHERE p.estado = 'pendiente'
  AND p.fecha_limite < CURRENT_DATE
ORDER BY p.fecha_limite;
```

---

## ✅ **CHECKLIST DE DATA NECESARIA**

Para que el sistema funcione completamente:

### **✅ Ya tienes:**
- [x] Usuario directora (`viri@caipi.com`)
- [x] Tabla `grados` con 6 grados
- [x] Tabla `usuarios` con registro de directora

### **📝 Se crea desde la app:**
- [ ] **Alumnos** → Crear desde "Nuevo Alumno"
- [ ] **Pagos** → Se crean AUTOMÁTICAMENTE al crear alumno
- [ ] **Profesores** → Crear desde "Profesores"
- [ ] **Padres** → Crear desde "Padres de Familia"

---

## 🚀 **SIGUIENTE PASO:**

1. ✅ **Ejecuta el SQL de grados** (si no lo hiciste)
2. ✅ **Crea tu primer alumno** desde la app
3. ✅ **Ve a "Pagos"** → Debes ver 14 pagos creados
4. ✅ **Acredita un pago** → Prueba el flujo completo

---

**¿Necesitas más detalles sobre algún paso?** 🎯
