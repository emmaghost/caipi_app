# 🚨 EJECUTAR AHORA - CORRECCIONES URGENTES

## ❌ **PROBLEMAS DETECTADOS:**

1. ✅ JWT Expirado → Necesitas **REINICIAR SESIÓN**
2. ✅ Error de Null en Pagos → Ejecutar SQL pendientes
3. ✅ Grados incorrectos (4to, 5to) → Ejecutar SQL de corrección

---

## 🚀 **SOLUCIÓN (5 MIN):**

### **PASO 1: EJECUTAR TODOS LOS SQL EN SUPABASE** ⚡ (3 min)

Ve a **Supabase** → **SQL Editor** y ejecuta en este orden:

#### **1️⃣ FIX_PAGOS_EXISTENTES.sql**
```sql
-- Copia y pega el contenido del archivo
-- Click RUN
```
✅ Corrige pagos sin fecha_vencimiento

---

#### **2️⃣ FIX_AGREGAR_CAMPOS_ALUMNO.sql**
```sql
-- Copia y pega el contenido del archivo
-- Click RUN
```
✅ Agrega dirección, CURP, cartilla de vacunas

---

#### **3️⃣ FIX_GRADOS_CORRECTOS.sql**
```sql
-- Copia y pega el contenido del archivo
-- Click RUN
```
✅ Corrige grados a: Maternal, Kinder 1, Kinder 2, Kinder 3

---

#### **4️⃣ FIX_AGREGAR_ENTREVISTA_PADRES.sql**
```sql
-- Copia y pega el contenido del archivo
-- Click RUN
```
✅ Agrega formulario de entrevista a padres

---

### **PASO 2: REINICIAR SESIÓN EN LA APP** ⚡ (1 min)

1. En la app, abre el **Menú** (≡)
2. Baja hasta el final
3. Click en **Cerrar Sesión**
4. **Inicia sesión de nuevo** con tu email y contraseña
5. ✅ Ya no saldrá "JWT expired"

---

### **PASO 3: REINICIAR LA APP** ⚡ (1 min)

Cierra la app completamente y vuelve a abrirla:

1. En el emulador, presiona el botón **Atrás** varias veces
2. O cierra el emulador y reinicia
3. Abre la app de nuevo
4. Inicia sesión

---

## 🧪 **VERIFICAR QUE TODO FUNCIONA:**

### ✅ **1. Grados Correctos:**
1. Menú → **Alumnos**
2. ✅ Debe mostrar filtros: **Todos, Maternal, K1, K2, K3**
3. ❌ NO debe mostrar: 4to, 5to

### ✅ **2. Pagos Funcionan:**
1. Menú → **Pagos**
2. ✅ Debe cargar sin errores
3. ✅ Debe mostrar lista de pagos pendientes

### ✅ **3. Entrevista a Padres:**
1. Menú → **Entrevista a Padres**
2. ✅ Debe abrir el formulario con 9 pasos

---

## 📍 **DÓNDE ESTÁ EL MENÚ DE ENTREVISTA:**

1. Abre la app
2. Click en el **Menú** (≡) arriba a la izquierda
3. Baja hasta la sección **ALUMNOS**
4. ✅ Verás: "**📄 Entrevista a Padres**"
5. Click ahí para abrir el formulario

---

## 🎯 **ORDEN DE EJECUCIÓN SQL:**

```
1. FIX_PAGOS_EXISTENTES.sql          ← Corrige pagos
2. FIX_AGREGAR_CAMPOS_ALUMNO.sql     ← Agrega campos a alumnos
3. FIX_GRADOS_CORRECTOS.sql          ← Corrige grados
4. FIX_AGREGAR_ENTREVISTA_PADRES.sql ← Agrega entrevista
```

**IMPORTANTE:** Ejecuta en ese orden exacto.

---

## 🐛 **SI SIGUEN LOS ERRORES:**

### **Error: "JWT expired"**
➡️ **Solución:** Cierra sesión y vuelve a iniciar sesión

### **Error: "type Null is not a subtype"**
➡️ **Solución:** Ejecuta `FIX_PAGOS_EXISTENTES.sql`

### **Siguen apareciendo 4to, 5to**
➡️ **Solución:** 
1. Ejecuta `FIX_GRADOS_CORRECTOS.sql`
2. Reinicia la app completamente
3. Cierra sesión y vuelve a entrar

### **No aparece Entrevista en el menú**
➡️ **Solución:**
1. Ejecuta `FIX_AGREGAR_ENTREVISTA_PADRES.sql`
2. Reinicia la app

---

## 📊 **GRADOS CORRECTOS:**

Después de ejecutar el SQL, deberías tener:

| Grado | Descripción | Edad |
|-------|-------------|------|
| **Maternal** | Nivel Maternal | 0-3 años |
| **Kinder 1** | Primer año de Kinder | 3-4 años |
| **Kinder 2** | Segundo año de Kinder | 4-5 años |
| **Kinder 3** | Tercer año de Kinder | 5-6 años |

---

## ✅ **CHECKLIST:**

- [ ] Ejecutar `FIX_PAGOS_EXISTENTES.sql`
- [ ] Ejecutar `FIX_AGREGAR_CAMPOS_ALUMNO.sql`
- [ ] Ejecutar `FIX_GRADOS_CORRECTOS.sql`
- [ ] Ejecutar `FIX_AGREGAR_ENTREVISTA_PADRES.sql`
- [ ] Cerrar sesión en la app
- [ ] Iniciar sesión de nuevo
- [ ] Verificar que aparecen solo Maternal y Kinder 1,2,3
- [ ] Verificar que Pagos funciona sin errores
- [ ] Verificar que aparece Entrevista a Padres en el menú

---

## 🎯 **SIGUIENTE PASO:**

**AHORA MISMO:**
1. ✅ Ve a Supabase
2. ✅ Ejecuta los 4 SQL en orden
3. ✅ Cierra sesión en la app
4. ✅ Inicia sesión de nuevo
5. ✅ Verifica que todo funciona

**TIEMPO TOTAL:** 5 minutos

---

**¡Ejecuta los SQL y reinicia sesión para corregir todo!** 🚀
