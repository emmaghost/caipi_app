# ✅ PRUEBAS COMPLETAS DEL SISTEMA - FLUJO COMPLETO

## 🔧 **ANTES DE EMPEZAR:**

### **1. Cerrar la app completamente en el emulador**
- Presiona el botón de aplicaciones recientes
- Desliza la app hacia arriba para cerrarla

### **2. En tu PowerShell, presiona:**
```
R
```
**(MAYÚSCULA R - MUY IMPORTANTE)**

---

## 📋 **LISTA DE TODAS LAS RUTAS DEL SISTEMA:**

### **🔐 Autenticación:**
- `/` → Redirige a `/login`
- `/login` → Pantalla de login

### **👩‍💼 Directora:**
- `/directora` → Dashboard Directora
- `/directora/alumnos` → Lista de alumnos
- `/directora/alumnos/crear` → Crear alumno
- `/directora/alumnos/editar/:id` → Editar alumno
- `/directora/pagos` → Gestión de pagos
- `/acreditar-pago/:pagoId` → Acreditar un pago
- `/directora/profesores` → Lista de profesores
- `/directora/profesores/crear` → Crear profesor
- `/directora/profesores/editar/:id` → Editar profesor
- `/directora/padres` → Lista de padres
- `/directora/padres/crear` → Crear padre
- `/directora/padres/ver/:id` → Ver detalle de padre
- `/directora/personas-autorizadas/:alumnoId?nombre=...` → Personas autorizadas
- `/directora/anuncios/crear` → Crear anuncio

### **👨‍👩‍👧 Padres:**
- `/padre` → Dashboard Padre
- `/padre/hijo/:id` → Detalle de hijo

---

## 🧪 **PRUEBA 1: FLUJO COMPLETO DIRECTORA**

### **Paso 1: Login como Directora**
✅ Email: `viri@caipi.com`  
✅ Password: `123456` (o la que configuraste)

**Resultado esperado:**
- ✅ Redirección automática a `/directora`
- ✅ Ver dashboard con estadísticas
- ✅ Ver 6 botones de acción

---

### **Paso 2: Crear un Alumno**

1. **Dashboard → Presiona "Agregar Alumno"**
   - Ruta: `/directora/alumnos/crear`
   
2. **Llena el formulario:**
   - Nombre: `Juan`
   - Apellidos: `Pérez López`
   - Género: `Niño`
   - Fecha nacimiento: `01/01/2020`
   - Grado: `Maternal`
   - Email padre: `juan.padre@gmail.com`
   - Alergias: `Ninguna`
   
3. **Presiona "Guardar Alumno"**

**Resultado esperado:**
- ✅ Alumno creado
- ✅ **14 pagos generados automáticamente:**
  - 1 Inscripción ($2,000)
  - 1 Seguro + Credencial ($500)
  - 12 Colegiaturas ($1,500 c/u)
- ✅ Padre creado con email `juan.padre@gmail.com`
- ✅ Password del padre: `Caipi2026`
- ✅ Redirección a lista de alumnos

---

### **Paso 3: Ver Pagos Generados**

1. **Dashboard → Presiona "Gestionar Pagos"**
   - Ruta: `/directora/pagos`

**Resultado esperado:**
- ✅ Ver 14 pagos pendientes
- ✅ Colores:
  - 🔴 Rojo = Pagos vencidos (meses pasados)
  - 🟡 Amarillo = Pagos pendientes (mes actual/futuros)
- ✅ Botón "Acreditar Pago" en cada uno

---

### **Paso 4: Acreditar un Pago**

1. **En lista de pagos → Presiona "Acreditar Pago" en Inscripción**
   - Ruta: `/acreditar-pago/:pagoId`
   
2. **Selecciona:**
   - Método: `Efectivo`
   - Recibido por: `Directora`
   - Referencia: `REC-001`
   
3. **Presiona "Acreditar Pago"**

**Resultado esperado:**
- ✅ Pago marcado como pagado
- ✅ Color cambia a 🟢 Verde
- ✅ Fecha de pago registrada
- ✅ Redirección a lista de pagos

---

### **Paso 5: Agregar Pago de Libros**

1. **En lista de pagos → Presiona botón "+" (flotante)**
   
2. **Selecciona "Libros"**
   
3. **Llena:**
   - Alumno: `Juan Pérez López`
   - Monto: `800`
   
4. **Presiona "Agregar"**

**Resultado esperado:**
- ✅ Nuevo pago de libros creado
- ✅ Aparece en la lista de pagos
- ✅ Total de pagos: 15

---

### **Paso 6: Crear un Profesor**

1. **Dashboard → Presiona "Profesores"**
   - Ruta: `/directora/profesores`
   
2. **Presiona "+ Agregar Profesor"**
   - Ruta: `/directora/profesores/crear`
   
3. **Llena:**
   - Nombre: `María García`
   - Email: `maria.prof@caipi.com`
   - Teléfono: `5512345678`
   - Grupo: `Maternal`
   
4. **Presiona "Guardar Profesor"**

**Resultado esperado:**
- ✅ Profesor creado
- ✅ Password temporal: `Caipi2026`
- ✅ Asignado a grupo Maternal
- ✅ Redirección a lista de profesores

---

### **Paso 7: Ver Alumnos del Profesor**

1. **En lista de profesores → Ver que dice "Grupo: Maternal"**

**Resultado esperado:**
- ✅ Profesor asignado al grupo
- ✅ Puede ver alumnos de ese grupo (Juan Pérez)

---

### **Paso 8: Crear Padre**

1. **Dashboard → Presiona "Padres de Familia"**
   - Ruta: `/directora/padres`
   
2. **Presiona "+ Agregar Padre"**
   - Ruta: `/directora/padres/crear`
   
3. **Llena:**
   - Nombre: `Carlos`
   - Apellidos: `Rodríguez`
   - Email: `carlos.padre@gmail.com`
   - Teléfono: `5598765432`
   - WhatsApp: `5598765432`
   
4. **Presiona "Guardar Padre"**

**Resultado esperado:**
- ✅ Padre creado
- ✅ Password temporal: `Caipi2026`
- ✅ Aparece en lista de padres
- ✅ Muestra "0 hijos" (aún no tiene)

---

### **Paso 9: Agregar Personas Autorizadas**

1. **Dashboard → Presiona "Ver Alumnos"**
   
2. **En la tarjeta de Juan Pérez → Presiona icono verde 🛡️**
   - Ruta: `/directora/personas-autorizadas/:alumnoId?nombre=Juan+P%C3%A9rez+L%C3%B3pez`
   
3. **Presiona "+ Agregar Persona"**
   
4. **Llena:**
   - Nombre: `Rosa López`
   - Parentesco: `Abuela`
   - Teléfono: `5587654321`
   - Identificación: `INE123456`
   
5. **Presiona "Agregar"**

**Resultado esperado:**
- ✅ Persona agregada
- ✅ Aparece en la lista
- ✅ Puede agregar ilimitadas personas
- ✅ Icono de eliminar disponible

---

## 🧪 **PRUEBA 2: FLUJO COMPLETO PADRE**

### **Paso 1: Cerrar sesión de Directora**

1. **Dashboard → Botón de logout (arriba derecha)**

---

### **Paso 2: Login como Padre**

✅ Email: `juan.padre@gmail.com`  
✅ Password: `Caipi2026`

**Resultado esperado:**
- ✅ Redirección a `/padre`
- ✅ Ver dashboard de padre
- ✅ Ver tarjeta con hijo: Juan Pérez López

---

### **Paso 3: Ver Detalle del Hijo**

1. **Dashboard → Presiona en la tarjeta de Juan**
   - Ruta: `/padre/hijo/:id`

**Resultado esperado:**
- ✅ Ver información completa del hijo
- ✅ Ver sección de pagos
- ✅ Ver pagos pendientes y pagados
- ✅ **NO PUEDE modificar nada** (solo lectura)
- ✅ Ver historial de pagos

---

### **Paso 4: Ver Pagos (Solo Lectura)**

1. **En detalle del hijo → Sección "Pagos"**

**Resultado esperado:**
- ✅ Ver lista de pagos:
  - Inscripción: 🟢 Pagado
  - Seguro: 🟡 Pendiente
  - Colegiaturas: 🟡 Pendientes
  - Libros: 🟡 Pendiente
- ✅ Ver monto de cada pago
- ✅ Ver fechas límite
- ✅ **NO HAY botón "Acreditar"** (solo directora)

---

## 🧪 **PRUEBA 3: VALIDACIÓN DE SEGURIDAD**

### **Intento 1: Padre accede a ruta de Directora**

**En el navegador, escribe manualmente:**
```
/directora
```

**Resultado esperado:**
- ✅ Redirige automáticamente a `/padre`
- ✅ **NO permite** acceso a rutas de directora

---

### **Intento 2: Padre accede a gestión de pagos**

**Escribe manualmente:**
```
/directora/pagos
```

**Resultado esperado:**
- ✅ Redirige a `/padre`
- ✅ **NO permite** acceso

---

## 📊 **RESUMEN DE VALIDACIONES:**

### ✅ **Directora PUEDE:**
- Ver y gestionar alumnos
- Crear, editar, eliminar alumnos
- Ver y acreditar pagos
- Agregar pagos de libros/uniformes
- Crear y gestionar profesores
- Asignar profesores a grupos
- Crear padres
- Ver todos los padres
- Gestionar personas autorizadas
- Crear anuncios

### ✅ **Padre PUEDE:**
- Ver sus hijos
- Ver pagos de sus hijos (solo lectura)
- Ver bitácora de sus hijos (próximamente)
- Ver mensajes/anuncios

### ❌ **Padre NO PUEDE:**
- Gestionar pagos
- Crear alumnos
- Ver otros hijos
- Acceder a rutas de directora

---

## 🐛 **SI ALGO NO FUNCIONA:**

### **Error: "Page Not Found"**

**Solución:**
1. Cierra la app en el emulador
2. En PowerShell, presiona `R` (MAYÚSCULA)
3. Espera a que compile completamente
4. Prueba de nuevo

### **Error: "GoException"**

**Causa:** Presionaste `r` (minúscula) en lugar de `R` (mayúscula)

**Solución:**
1. Presiona `R` (MAYÚSCULA) para reiniciar
2. Espera la recompilación completa

### **Error: No se crean los 14 pagos**

**Causa:** No ejecutaste el SQL de `recibido_por`

**Solución:**
```sql
ALTER TABLE pagos 
ADD COLUMN IF NOT EXISTS recibido_por TEXT CHECK (recibido_por IN ('directora', 'joss'));
```

---

## ✅ **CHECKLIST FINAL:**

Antes de probar, verifica:

- [ ] Ejecutaste TODO el SQL de `UPDATE_USUARIOS_PERSONAS.sql`
- [ ] Ejecutaste el SQL de `recibido_por` en pagos
- [ ] Cerraste la app en el emulador
- [ ] Presionaste `R` (MAYÚSCULA) en PowerShell
- [ ] Esperaste la compilación completa (≈1 minuto)
- [ ] Estás logueado como Directora
- [ ] Tienes grados creados en la base de datos

---

## 🚀 **ORDEN DE PRUEBAS RECOMENDADO:**

1. Login Directora
2. Crear Alumno → Verifica 14 pagos
3. Acreditar 1 pago
4. Agregar pago de libros
5. Crear Profesor → Asignar grupo
6. Crear Padre
7. Agregar personas autorizadas al alumno
8. Logout
9. Login como Padre
10. Ver hijo y pagos (solo lectura)

---

**¡SIGUE ESTE FLUJO COMPLETO Y VERIFICA QUE TODO FUNCIONE!** 🎯
