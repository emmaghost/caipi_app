# 💰 SISTEMA DE PAGOS - CAIPI

## 📋 **PAGOS QUE SE GENERAN AL CREAR UN ALUMNO**

Cuando creas un nuevo alumno, se generan automáticamente:

### 1️⃣ **INSCRIPCIÓN ANUAL**
- **Concepto:** Inscripción Anual
- **Monto:** $2,000.00
- **Frecuencia:** Una vez por año
- **Fecha límite:** Día 15 del mes de inscripción

### 2️⃣ **SEGURO + CREDENCIAL**
- **Concepto:** Seguro y Credencial
- **Monto:** $500.00
- **Frecuencia:** Una vez por año
- **Fecha límite:** Día 15 del mes de inscripción

### 3️⃣ **COLEGIATURAS MENSUALES (12 pagos)**
- **Concepto:** Colegiatura
- **Monto:** $1,500.00 por mes
- **Frecuencia:** 12 meses (Enero - Diciembre)
- **Fecha límite:** Día 10 de cada mes

---

## 📚 **PAGOS OPCIONALES (Se agregan manualmente)**

### 🔹 **LIBROS**
- **Concepto:** Paquete de Libros
- **Monto:** Variable por grado
  - Maternal: $600.00
  - Kinder 1: $700.00
  - Kinder 2: $800.00
  - Kinder 3: $900.00
- **Frecuencia:** Una vez por año (inicio de ciclo escolar)

### 🔹 **UNIFORMES**
- **Concepto:** Uniforme
- **Monto:** $250.00 por pieza
- **Frecuencia:** A pedido del padre
- **Nota:** Se registra cantidad de piezas

---

## 🚦 **SISTEMA DE SEMÁFORO**

Los pagos se clasifican con colores según su estado:

| Color | Estado | Descripción |
|-------|--------|-------------|
| 🟢 Verde | Pagado | El pago fue acreditado |
| 🟡 Amarillo | Pendiente | Dentro del plazo |
| 🔴 Rojo | Vencido | Pasó la fecha límite |

---

## 📝 **REGISTRO DE PAGO**

Al acreditar un pago, se registra:

1. ✅ **Método de pago:**
   - Efectivo
   - Transferencia
   - Tarjeta

2. ✅ **Recibido por:**
   - Directora
   - Joss

3. ✅ **Referencia/Recibo:** (Opcional)
   - Número de recibo o referencia

4. ✅ **Fecha de pago:** Se registra automáticamente

---

## 💡 **EJEMPLO DE FLUJO COMPLETO**

### **Al inscribir a "Ian Dimitri" el 4 de Marzo 2026:**

Se generan automáticamente:

```
✓ Inscripción 2026         - $2,000.00 - Límite: 15/03/2026
✓ Seguro 2026              - $  500.00 - Límite: 15/03/2026
✓ Colegiatura Enero 2026   - $1,500.00 - Límite: 10/01/2026 [VENCIDO]
✓ Colegiatura Febrero 2026 - $1,500.00 - Límite: 10/02/2026 [VENCIDO]
✓ Colegiatura Marzo 2026   - $1,500.00 - Límite: 10/03/2026 [PENDIENTE]
✓ Colegiatura Abril 2026   - $1,500.00 - Límite: 10/04/2026 [PENDIENTE]
... (hasta Diciembre 2026)
```

### **Agregar pago de libros (opcional):**

La directora va a:
1. Gestión de Pagos
2. Presiona botón "Agregar Pago"
3. Selecciona "Libros"
4. Elige al alumno y monto
5. Se crea el pago

### **Acreditar un pago:**

La directora:
1. Ve la lista de pagos pendientes
2. Presiona "Acreditar Pago"
3. Selecciona: Efectivo / Transferencia / Tarjeta
4. Selecciona: Directora / Joss
5. Escribe referencia (opcional): REC-001
6. Confirma

El sistema actualiza:
- ✅ `pagado = true`
- ✅ `fecha_pago = hoy`
- ✅ `metodo_pago = "Efectivo"`
- ✅ `recibido_por = "directora"`
- ✅ `referencia = "REC-001"`

---

## 🎯 **AJUSTAR MONTOS**

Los montos están en el código:

**Archivo:** `lib/services/supabase_service.dart`

**Método:** `_generarPagosIniciales()`

```dart
// INSCRIPCIÓN
'monto': 2000.00,

// SEGURO + CREDENCIAL
'monto': 500.00,

// COLEGIATURA MENSUAL
'monto': 1500.00,

// LIBROS (en método agregarPagoLibros)
// Se pasa como parámetro

// UNIFORMES (en método agregarPagoUniforme)
// Se calcula: cantidad * precioUnitario
```

Para cambiar los montos, edita estos valores y reinicia la app con `R`.
