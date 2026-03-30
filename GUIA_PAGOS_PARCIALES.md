# 💵 SISTEMA DE PAGOS PARCIALES - GUÍA COMPLETA

## ✅ **QUÉ SE IMPLEMENTÓ:**

### **1. Base de Datos**
- ✅ Tabla `abonos` para registrar pagos parciales
- ✅ Campo `monto_pagado` en tabla `pagos`
- ✅ Nuevo estatus `'parcial'` para pagos a medias
- ✅ Trigger automático que actualiza el estatus según abonos
- ✅ Folio único automático para cada abono (REC-2026-0001)

### **2. Modelos Dart**
- ✅ Modelo `Abono` con todos los campos
- ✅ Modelo `Pago` actualizado con:
  - Campo `montoPagado`
  - Métodos para calcular saldo pendiente
  - Métodos para calcular porcentaje pagado

### **3. Pantallas**
- ✅ `RegistrarAbonoScreen` para registrar pagos parciales
- ✅ Muestra historial de abonos
- ✅ Valida que no exceda el saldo pendiente

---

## 🎯 **CÓMO FUNCIONA:**

### **Ejemplo Real:**

```
Pago: Mensualidad Marzo 2026
Monto Total: $2,000.00

┌──────────────────────────────────┐
│ Abono 1 (05/03/2026)             │
│ Efectivo: $500.00                │
│ Folio: REC-2026-0001             │
├──────────────────────────────────┤
│ ESTATUS: Parcial ⚠️              │
│ PAGADO: $500.00                  │
│ PENDIENTE: $1,500.00             │
└──────────────────────────────────┘

┌──────────────────────────────────┐
│ Abono 2 (10/03/2026)             │
│ Transferencia: $800.00           │
│ Ref: 123456                      │
│ Folio: REC-2026-0002             │
├──────────────────────────────────┤
│ ESTATUS: Parcial ⚠️              │
│ PAGADO: $1,300.00                │
│ PENDIENTE: $700.00               │
└──────────────────────────────────┘

┌──────────────────────────────────┐
│ Abono 3 (15/03/2026)             │
│ Tarjeta: $700.00                 │
│ Folio: REC-2026-0003             │
├──────────────────────────────────┤
│ ESTATUS: Pagado ✅               │
│ PAGADO: $2,000.00                │
│ PENDIENTE: $0.00                 │
└──────────────────────────────────┘
```

---

## 📋 **PASOS PARA ACTIVAR:**

### **PASO 1: Ejecutar SQL en Supabase**

1. Ve a Supabase → SQL Editor
2. Abre el archivo: `FIX_PAGOS_PARCIALES.sql`
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

#### **Test 1: Pago parcial en 2 abonos**

1. Login como Directora
2. Ir a: **Pagos**
3. Buscar un pago pendiente (ejemplo: $2,000)
4. Click en el pago
5. **Nuevo botón**: **"Registrar Abono"**
6. Llenar:
   - Monto: $500
   - Forma de pago: Efectivo
   - Fecha: HOY
7. Click **"Registrar Abono"**
8. Verificar:
   - ✅ Estatus cambió a **"Parcial"**
   - ✅ Se ve: Pagado $500, Pendiente $1,500
   - ✅ Se generó folio: REC-2026-0001

9. Registrar segundo abono:
   - Monto: $1,500
   - Forma de pago: Transferencia
10. Verificar:
    - ✅ Estatus cambió a **"Pagado"** ✅
    - ✅ Se ve: Pagado $2,000, Pendiente $0
    - ✅ Se generó folio: REC-2026-0002

#### **Test 2: Ver historial de abonos**

1. En la pantalla de **Registrar Abono**
2. Debe mostrar **"Historial de Abonos"**
3. Con todos los abonos anteriores:
   - Monto
   - Fecha
   - Forma de pago
   - Folio

---

## 💡 **CARACTERÍSTICAS:**

### **1. Validaciones Automáticas**

```
✅ No puedes abonar más del saldo pendiente
✅ No puedes abonar $0 o negativo
✅ El estatus se actualiza automáticamente:
   - pendiente → parcial (cuando hay 1+ abonos)
   - parcial → pagado (cuando suma 100%)
```

### **2. Folio Único**

Cada abono recibe un folio único:
```
REC-2026-0001
REC-2026-0002
REC-2026-0003
...
```

**Formato:** `REC-[AÑO]-[CONSECUTIVO]`

### **3. Historial Completo**

Cada abono registra:
- ✅ Monto
- ✅ Fecha del abono
- ✅ Forma de pago
- ✅ Referencia (opcional)
- ✅ Notas (opcional)
- ✅ Folio de recibo
- ✅ Quién lo registró

---

## 📊 **ESTATUS DE PAGOS:**

| Estatus | Significado | Color |
|---------|-------------|-------|
| **Pendiente** | No se ha abonado nada | 🔴 Rojo |
| **Parcial** | Se ha abonado, pero falta | 🟡 Amarillo |
| **Pagado** | Totalmente pagado | 🟢 Verde |
| **Vencido** | Pasó la fecha y no está pagado | 🟠 Naranja |

---

## 🔍 **CONSULTAS ÚTILES EN SUPABASE:**

### **Ver todos los abonos de un pago:**

```sql
SELECT * FROM abonos 
WHERE pago_id = 'uuid-del-pago'
ORDER BY fecha_abono DESC;
```

### **Ver pagos con abonos (vista preparada):**

```sql
SELECT * FROM vista_pagos_abonos 
WHERE alumno_id = 'uuid-del-alumno';
```

### **Calcular saldo pendiente de un pago:**

```sql
SELECT calcular_saldo_pago('uuid-del-pago');
```

### **Ver abonos del día:**

```sql
SELECT 
  ab.recibo_folio,
  a.nombre || ' ' || a.apellidos AS alumno,
  p.concepto,
  ab.monto,
  ab.forma_pago
FROM abonos ab
INNER JOIN pagos p ON ab.pago_id = p.id
INNER JOIN alumnos a ON p.alumno_id = a.id
WHERE ab.fecha_abono = CURRENT_DATE
ORDER BY ab.created_at DESC;
```

---

## 🎨 **CÓMO SE VE EN LA APP:**

### **Pantalla: Detalle de Pago**

```
╔══════════════════════════════════════╗
║  Pago: Mensualidad Marzo 2026        ║
╚══════════════════════════════════════╝

👤 Alumno: Juan Pérez García
📅 Vence: 05/03/2026

💰 Monto Total: $2,000.00
✅ Pagado: $500.00
⚠️ Pendiente: $1,500.00

Estado: Parcial (25%)
[███░░░░░░░] 25%

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Historial de Abonos:

✅ 05/03/2026 - $500.00
   Efectivo
   Folio: REC-2026-0001

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

        [💳 Registrar Abono]
```

### **Pantalla: Registrar Abono**

```
╔══════════════════════════════════════╗
║  Registrar Abono                     ║
╚══════════════════════════════════════╝

Información del Pago:
👤 Alumno: Juan Pérez García
📝 Concepto: Mensualidad Marzo 2026
💰 Monto Total: $2,000.00
✅ Pagado: $500.00
⚠️ Saldo Pendiente: $1,500.00

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Nuevo Abono:

💵 Monto del abono
   [$1,500.00                          ]
   Máximo: $1,500.00

💳 Forma de pago
   [Transferencia                   ▼]

📅 Fecha del abono
   [15/03/2026                         ]

🔢 Referencia (opcional)
   [123456                             ]

📝 Notas (opcional)
   [Pago por transferencia             ]
   [                                   ]

        [💾 Registrar Abono]
```

---

## ⚠️ **IMPORTANTE:**

### **Migración de pagos existentes:**

Los pagos que ya existen en el sistema:
- ✅ Ahora tienen `monto_pagado = 0` (automático)
- ✅ Pueden recibir abonos normalmente
- ✅ Si estaban "pagados", siguen pagados

### **No se puede:**

- ❌ Eliminar abonos (solo la directora desde SQL)
- ❌ Modificar abonos (se registran como están)
- ❌ Abonar más del saldo pendiente

---

## 🚀 **PRÓXIMOS PASOS:**

### **1. Generación de Recibos PDF**
Cada abono debe poder imprimir un recibo con:
- Folio único
- Logo de CAIPI
- Datos del padre y alumno
- Monto abonado
- Saldo pendiente

### **2. Enviar recibo por WhatsApp**
Al registrar un abono:
- Generar PDF del recibo
- Enviarlo al padre por WhatsApp automáticamente

---

## ✅ **CHECKLIST DE VERIFICACIÓN:**

- [ ] SQL ejecutado sin errores
- [ ] App reiniciada
- [ ] Probado registrar primer abono (estatus → parcial)
- [ ] Probado completar pago (estatus → pagado)
- [ ] Verificado que no se puede abonar más del saldo
- [ ] Verificado que se genera folio único
- [ ] Verificado historial de abonos
- [ ] Probado diferentes formas de pago

---

## 🎉 **¡LISTO!**

Ahora tienes un sistema completo de pagos parciales:
- ✅ Los padres pueden abonar en varias partes
- ✅ Historial completo de cada abono
- ✅ Folio único para cada recibo
- ✅ Actualización automática de estatus
- ✅ Validaciones para evitar errores

**¿Dudas? Revisa esta guía paso a paso.** 📚
