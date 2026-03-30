# 🎯 IMPLEMENTACIÓN: PLANES DE PAGO 10 Y 12 MESES

## ✅ **QUÉ SE IMPLEMENTÓ:**

### **1. Configuración de Costos (Directora)**
- Pantalla para que la directora configure:
  - 💰 Costo Inscripción Anual
  - 🏥 Costo Seguro + Credencial
  - 📅 Costo Mensualidad (Plan 12 meses)
  - 📅 Costo Mensualidad (Plan 10 meses)

### **2. Selección de Plan al Crear Alumno**
- Al dar de alta un niño, se puede elegir:
  - **Plan 12 meses**: Agosto a Julio (mensualidad más económica)
  - **Plan 10 meses**: Agosto a Mayo (mensualidad más cara)
- También se selecciona la fecha de ingreso

### **3. Pagos Automáticos Según Plan**
- Al crear un alumno, se generan automáticamente:
  - **Plan 12 meses**: 14 pagos (Inscripción + Seguro + 12 mensualidades)
  - **Plan 10 meses**: 12 pagos (Inscripción + Seguro + 10 mensualidades)

---

## 📋 **PASO A PASO PARA ACTIVAR:**

### **PASO 1: Ejecutar SQL en Supabase**

1. Ve a Supabase → SQL Editor
2. Abre el archivo: `FIX_PLANES_PAGO_Y_CONFIG.sql`
3. Copia TODO el contenido
4. Pégalo en el editor SQL
5. Click en **"RUN"**
6. Espera el mensaje: ✅ **Success. No rows returned**

**Este script:**
- ✅ Crea tabla `configuracion_costos`
- ✅ Agrega campo `plan_pagos` a tabla `alumnos`
- ✅ Agrega campo `fecha_ingreso` a tabla `alumnos`
- ✅ Reemplaza el trigger de pagos automáticos
- ✅ Inserta configuración inicial:
  - Inscripción: $1,500
  - Seguro: $300
  - Mensualidad 12: $2,000 (Total: $26,300)
  - Mensualidad 10: $2,400 (Total: $25,800)

---

### **PASO 2: Verificar que se ejecutó correctamente**

En Supabase → SQL Editor, ejecuta:

```sql
-- Verificar tabla de configuración
SELECT * FROM configuracion_costos;

-- Verificar columnas nuevas en alumnos
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'alumnos' 
AND column_name IN ('plan_pagos', 'fecha_ingreso');

-- Verificar trigger
SELECT trigger_name 
FROM information_schema.triggers 
WHERE trigger_name = 'trigger_crear_pagos_automaticos';
```

Debes ver:
- ✅ 1 registro en `configuracion_costos` con los costos iniciales
- ✅ 2 columnas: `plan_pagos` (integer) y `fecha_ingreso` (date)
- ✅ 1 trigger: `trigger_crear_pagos_automaticos`

---

### **PASO 3: Reiniciar la app Flutter**

```powershell
# Si ya está corriendo, presiona 'r' en la terminal
# O detén y vuelve a ejecutar:
flutter run
```

---

### **PASO 4: Prueba Completa**

#### **Test 1: Configurar Costos**

1. Login como Directora
2. Menú lateral → **"Configuración de Costos"**
3. Verifica que aparezcan los costos actuales:
   - Inscripción: $1,500.00
   - Seguro: $300.00
   - Mensualidad 12: $2,000.00
   - Mensualidad 10: $2,400.00
4. Modifica algún costo (ejemplo: Mensualidad 12 → $2,100)
5. Click **"Guardar Configuración"**
6. Verifica que se guardó correctamente

#### **Test 2: Crear Alumno Plan 12 Meses**

1. Ir a: **Alumnos** → **"Crear Alumno"**
2. Llenar datos:
   - Nombre: PRUEBA
   - Apellidos: PLAN 12
   - Género: Niño
   - Fecha nacimiento: 01/01/2020
   - **Fecha ingreso**: HOY (automático)
   - Grado: Kinder 1
   - **Plan de Pagos**: **12 meses (Agosto - Julio)**
   - Email padre: padre12@test.com
3. Click **"Guardar Alumno"**
4. Ir a: **Pagos**
5. Filtrar por alumno: PRUEBA PLAN 12
6. **Verificar que aparecen 14 pagos:**
   - 1x Inscripción Anual ($1,500 o el que configuraste)
   - 1x Seguro + Credencial ($300)
   - 12x Mensualidades de Agosto a Julio ($2,100 o el que configuraste)

**Totales esperados con configuración inicial:**
- Total Plan 12: $1,500 + $300 + (12 × $2,000) = **$25,800**

#### **Test 3: Crear Alumno Plan 10 Meses**

1. Ir a: **Alumnos** → **"Crear Alumno"**
2. Llenar datos:
   - Nombre: PRUEBA
   - Apellidos: PLAN 10
   - Género: Niña
   - Fecha nacimiento: 01/01/2020
   - **Fecha ingreso**: HOY
   - Grado: Maternal
   - **Plan de Pagos**: **10 meses (Agosto - Mayo)**
   - Email padre: padre10@test.com
3. Click **"Guardar Alumno"**
4. Ir a: **Pagos**
5. Filtrar por alumno: PRUEBA PLAN 10
6. **Verificar que aparecen 12 pagos:**
   - 1x Inscripción Anual ($1,500)
   - 1x Seguro + Credencial ($300)
   - 10x Mensualidades de Agosto a Mayo ($2,400 cada una)

**Totales esperados con configuración inicial:**
- Total Plan 10: $1,500 + $300 + (10 × $2,400) = **$25,800**

---

## 🎨 **CÓMO SE VE EN LA APP:**

### **Pantalla: Configuración de Costos**

```
╔══════════════════════════════════════╗
║  Configuración de Costos             ║
║  (Gradiente arcoíris CAIPI)          ║
╚══════════════════════════════════════╝

📋 Información:
Los padres podrán elegir entre plan de 10 o 12 
meses al inscribir a su hijo.

💰 Costo de Inscripción Anual
   [$1,500.00                          ]

🏥 Costo Seguro + Credencial
   [$300.00                            ]

📅 Mensualidad (Plan 12 meses)
   [$2,000.00                          ]

📅 Mensualidad (Plan 10 meses)
   [$2,400.00                          ]

📝 Notas (opcional)
   [                                   ]
   [                                   ]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 Comparativa de Planes

┌─────────────────┐  ┌─────────────────┐
│ Plan 12 Meses   │  │ Plan 10 Meses   │
│                 │  │                 │
│ $2,000.00       │  │ $2,400.00       │
│ por mes         │  │ por mes         │
│                 │  │                 │
│ Total: $26,300  │  │ Total: $25,800  │
└─────────────────┘  └─────────────────┘

        [💾 Guardar Configuración]
```

### **Pantalla: Crear Alumno (NUEVO)**

```
╔══════════════════════════════════════╗
║  Crear Nuevo Alumno                  ║
╚══════════════════════════════════════╝

📸 [Foto circular]

👤 Nombre(s)
   [Juan                               ]

👤 Apellidos
   [Pérez García                       ]

⚧ Género
   [Niño                           ▼]

🎂 Fecha de nacimiento
   [15/05/2020                         ]

🏫 Grado
   [Kinder 1                       ▼]

📅 Fecha de ingreso          ← NUEVO
   [11/03/2026                         ]

💳 Plan de Pagos             ← NUEVO
   [12 meses (Agosto - Julio)      ▼]
   Selecciona entre 10 o 12 mensualidades

📧 Email del padre/madre
   [padre@email.com                    ]

⚠️ Alergias (opcional)
   [Ninguna                            ]

        [💾 Crear Alumno]
```

---

## 🔧 **ARCHIVOS MODIFICADOS:**

### **SQL:**
- ✅ `FIX_PLANES_PAGO_Y_CONFIG.sql` (NUEVO)

### **Modelos:**
- ✅ `lib/models/configuracion_costos.dart` (NUEVO)
- ✅ `lib/models/alumno.dart` (Modificado: agregó `planPagos` y `fechaIngreso`)

### **Pantallas:**
- ✅ `lib/screens/directora/configuracion_costos_screen.dart` (NUEVA)
- ✅ `lib/screens/directora/crear_alumno_screen.dart` (Modificada: agregó campos)

### **Rutas:**
- ✅ `lib/routes/app_router.dart` (Agregó ruta `/directora/configuracion-costos`)
- ✅ `lib/widgets/app_drawer.dart` (Agregó menú "Configuración de Costos")

---

## 💡 **VENTAJAS DEL NUEVO SISTEMA:**

### **Para la Directora:**
- ✅ Configurar costos desde la app (sin modificar código)
- ✅ Cambiar costos para el siguiente año escolar
- ✅ Ver comparativa de planes en tiempo real
- ✅ Historial de configuraciones (con vigencia)

### **Para los Padres:**
- ✅ Elegir plan que mejor se adapte a su economía
- ✅ Plan 12 meses: Pago mensual más bajo
- ✅ Plan 10 meses: Sin pagos en Junio/Julio (vacaciones)

### **Para el Sistema:**
- ✅ Pagos se crean automáticamente al inscribir alumno
- ✅ No hay errores de cálculo manual
- ✅ Facilita planificación financiera

---

## 📊 **COMPARATIVA DE PLANES (Ejemplo):**

| Concepto | Plan 12 Meses | Plan 10 Meses |
|----------|---------------|---------------|
| **Inscripción** | $1,500 | $1,500 |
| **Seguro** | $300 | $300 |
| **Mensualidad** | $2,000 × 12 | $2,400 × 10 |
| **Subtotal mensualidades** | $24,000 | $24,000 |
| **TOTAL ANUAL** | **$25,800** | **$25,800** |

**Nota:** Ambos planes cuestan lo mismo al año, pero el pago mensual varía.

---

## ⚠️ **IMPORTANTE:**

### **Si modificas los costos:**
- Solo afectan a **nuevos alumnos**
- Los alumnos ya inscritos mantienen sus pagos existentes
- Puedes crear una nueva configuración para el siguiente ciclo escolar

### **Migración de alumnos existentes:**
Si ya tienes alumnos en el sistema, sus pagos NO se regenerarán automáticamente. 
Para alumnos antiguos, los pagos ya existen y seguirán como están.

Solo los **nuevos alumnos** que se creen después de ejecutar este script 
tendrán el sistema de planes de pago.

---

## ✅ **CHECKLIST DE VERIFICACIÓN:**

- [ ] SQL ejecutado sin errores
- [ ] Configuración inicial visible en Supabase
- [ ] App reiniciada
- [ ] Pantalla "Configuración de Costos" aparece en el menú
- [ ] Puedo modificar y guardar costos
- [ ] Pantalla "Crear Alumno" muestra campo "Plan de Pagos"
- [ ] Pantalla "Crear Alumno" muestra campo "Fecha de ingreso"
- [ ] Al crear alumno Plan 12: Se generan 14 pagos correctos
- [ ] Al crear alumno Plan 10: Se generan 12 pagos correctos
- [ ] Montos de pagos coinciden con configuración

---

## 🎉 **¡LISTO!**

Ahora tienes un sistema completo de planes de pago que:
- Es configurable desde la app
- Se adapta a las necesidades de cada familia
- Genera pagos automáticamente
- Es fácil de mantener y actualizar

**¿Alguna duda o problema? Revisa este documento paso a paso.** 📚
