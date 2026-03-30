# 🧪 PLAN DE PRUEBAS COMPLETO - ANTES DE APK

## 📋 **ORDEN DE EJECUCIÓN:**

---

## ✅ **FASE 1: BASE DE DATOS (SUPABASE)**

### **1.1 Ejecutar SQL de RLS:**

Ve a **Supabase** → SQL Editor → Ejecuta:

```sql
-- Archivo: FIX_RLS_TODAS_TABLAS.sql
-- Este script corrige las políticas de seguridad
```

**Resultado esperado:**
```
✅ POLÍTICAS RLS CORREGIDAS
alumnos: 4
pagos: 3
profesores: 2
usuarios: 3
grados: 2
eventos: 2
incidentes: 2
entrevistas_padres: 2
```

---

### **1.2 Verificar Usuario Directora:**

Ejecuta en SQL Editor:

```sql
SELECT id, nombre, email, rol 
FROM usuarios 
WHERE rol = 'directora';
```

**Si NO existe:**

```sql
-- 1. Ir a Authentication → Users → Add User
--    Email: directora@caipi.com
--    Password: CAIPI2026!
--    Confirm user: ✅ (marcar como confirmado)

-- 2. Ejecutar esto:
INSERT INTO usuarios (id, nombre, email, rol, telefono, activo)
SELECT au.id, 'Virginia', 'directora@caipi.com', 'directora', '5540504618', true
FROM auth.users au
WHERE au.email = 'directora@caipi.com'
ON CONFLICT (id) DO UPDATE SET rol = 'directora';
```

---

### **1.3 Verificar Grados:**

```sql
SELECT id, nombre, descripcion, edad_minima, edad_maxima 
FROM grados 
WHERE activo = true
ORDER BY nombre;
```

**Debe mostrar:**
- Kinder 1 (3-4 años)
- Kinder 2 (4-5 años)
- Kinder 3 (5-6 años)
- Maternal (0-3 años)

---

## ✅ **FASE 2: PRUEBAS COMO DIRECTORA**

### **2.1 Login:**
- [ ] Cerrar sesión si estás como padre
- [ ] Login con: `directora@caipi.com` / `CAIPI2026!`
- [ ] Dashboard carga correctamente
- [ ] Logo nuevo se ve bien

---

### **2.2 Crear Alumno COMPLETO:**

**Datos del Niño:**
- [ ] Nombre, apellidos, fecha nacimiento
- [ ] Género
- [ ] Grado (debe mostrar: Maternal, Kinder 1, 2, 3)
- [ ] **CURP** (nuevo)
- [ ] **Cartilla de vacunas completa** (Switch)
- [ ] **Vacunas faltantes** (si no está completa)

**Dirección del Niño:** (nuevo)
- [ ] Calle
- [ ] Colonia
- [ ] Código Postal
- [ ] Ciudad
- [ ] Estado

**Plan de Pagos:** (nuevo)
- [ ] Plan 10 meses
- [ ] Plan 12 meses
- [ ] Beca (0-100%)

**Datos del Padre:**
- [ ] Nombre, email, teléfono
- [ ] Foto (opcional)

**Contacto de Emergencia:**
- [ ] Nombre
- [ ] Teléfono

**Al guardar:**
- [ ] Se crea sin error RLS ✅
- [ ] Se generan 12 pagos (o 10 según plan)
- [ ] Se aplica descuento de beca
- [ ] Se crea inscripción

---

### **2.3 Editar Alumno:**
- [ ] Abrir alumno creado
- [ ] Cambiar algún dato
- [ ] Guardar
- [ ] ✅ Se guarda correctamente (antes fallaba)

---

### **2.4 Crear Profesor:**
- [ ] Nombre, email, teléfono
- [ ] Asignar grado
- [ ] Guardar sin error ✅

---

### **2.5 Crear Evento:**
- [ ] Título, descripción
- [ ] Fecha
- [ ] Guardar sin error ✅

---

### **2.6 Crear Tipo de Incidente:**
- [ ] Nombre, descripción, color
- [ ] Guardar sin error ✅

---

### **2.7 Crear Incidente:**
- [ ] Seleccionar alumno
- [ ] Seleccionar tipo
- [ ] Descripción
- [ ] Guardar sin error ✅

---

### **2.8 Bitácora Diaria:**
- [ ] Crear registro
- [ ] Estado ánimo, comió, pipí, popó
- [ ] Guardar sin error ✅

---

### **2.9 Registrar Entrada/Salida:**
- [ ] Fecha automática (hoy)
- [ ] Hora entrada (9 AM automática)
- [ ] Hora salida (2 PM automática)
- [ ] Guardar sin error ✅

---

### **2.10 Gestionar Pagos:**
- [ ] Ver pagos pendientes
- [ ] Acreditar pago (efectivo/transferencia/tarjeta)
- [ ] Registrar abono (pago parcial)
- [ ] Guardar sin error ✅

---

### **2.11 Entrevista a Padres:** (nuevo)
- [ ] Formulario de 5 pasos se muestra
- [ ] Campos del padre/madre
- [ ] Dirección del alumno
- [ ] Información familiar
- [ ] Historia médica
- [ ] Aspectos sociales
- [ ] Guardar sin error ✅

---

### **2.12 Configuración de Costos:** (nuevo)
- [ ] Ver configuración actual
- [ ] Modificar costos
- [ ] Guardar sin error ✅

---

### **2.13 Prueba WhatsApp:** (nuevo)
- [ ] Pantalla tiene botón de regreso
- [ ] Enviar mensaje (respeta límite sandbox)
- [ ] Sin crashes ✅

---

## ✅ **FASE 3: PRUEBAS COMO PADRE**

### **3.1 Login como Padre:**
- [ ] Cerrar sesión
- [ ] Login con cuenta padre
- [ ] Dashboard carga correctamente

### **3.2 Ver Hijos:**
- [ ] Lista de hijos se muestra
- [ ] Click en hijo abre detalle
- [ ] Logo nuevo se ve bien

### **3.3 Ver Pagos:**
- [ ] Lista de pagos del hijo
- [ ] Pagos pagados y pendientes
- [ ] Sin crashes

### **3.4 Ver Eventos:**
- [ ] Lista de próximos eventos
- [ ] Sin crashes

---

## ✅ **FASE 4: UI/UX**

- [ ] **Logo nuevo:**
  - Icono de app
  - Login
  - Menú lateral
  - Dashboard
  
- [ ] **Menú arcoíris:**
  - Degradado correcto
  - Todos los íconos visibles
  
- [ ] **Colores correctos:**
  - Incidentes (NO azul genérico)
  - Bitácora (NO azul genérico)
  - Eventos (colores CAIPI)
  
- [ ] **Botones NO transparentes**

---

## 🎯 **PRIORIDAD ALTA:**

1. ✅ **Ejecutar `FIX_RLS_TODAS_TABLAS.sql`** (URGENTE)
2. ✅ **Crear/Verificar usuario directora**
3. ✅ **Probar crear alumno completo**
4. ✅ **Probar editar alumno**
5. ✅ **Verificar filtros de alumnos**

---

## 📱 **DESPUÉS DE TODO:**

Si todas las pruebas pasan → Generar APK final ✅
