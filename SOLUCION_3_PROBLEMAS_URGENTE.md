# 🚨 SOLUCIÓN URGENTE - 3 PROBLEMAS

## ⚠️ PROBLEMAS ACTUALES

1. ❌ **Menú vacío** (solo muestra "Inicio")
2. ❌ **Error al crear profesora** ("User already registered")
3. ❓ **Contraseñas:** ¿Dónde se asignan? ¿Cuál es la default?

---

## 🔧 SOLUCIÓN COMPLETA

### **PASO 1: EJECUTAR SQL** (10 segundos)

1. Abre **Supabase** → **SQL Editor**
2. Abre el archivo: **`FIX_MENU_Y_PROFESORES_URGENTE.sql`**
3. Copia TODO y pégalo
4. Click **"Run"** ▶️

✅ Esto corrige:
- Función de permisos (para que el menú funcione)
- Asigna TODOS los permisos a 'directora'
- El menú se llenará completo

---

### **PASO 2: REINICIAR FLUTTER** (Instantáneo)

Presiona **`R`** en la terminal de Flutter

---

## 🔑 CONTRASEÑAS - RESPUESTAS

### **¿Dónde se asignan?**
En el código cuando creas el usuario:
```dart
password: 'Caipi2026'  // ← Línea 159 de crear_profesor_screen.dart
```

### **¿Cuál es la contraseña por defecto?**
```
Contraseña: Caipi2026
```

**Para TODOS:**
- ✅ Profesores nuevos → `Caipi2026`
- ✅ Padres nuevos → `Caipi2026`
- ✅ Directora → La que pusiste cuando la creaste

### **¿Cómo cambiarla?**

**OPCIÓN 1: En Supabase (Rápido)**
1. Abre **Supabase** → **Authentication** → **Users**
2. Busca el usuario (por email)
3. Click en **"..."** → **"Reset Password"**
4. Escribe la nueva contraseña
5. Guarda

**OPCIÓN 2: Cambiar el default en el código**
Edita la línea 159 de `crear_profesor_screen.dart`:
```dart
password: 'TuNuevaPassword2026',  // ← Cámbialo aquí
```

---

## 🐛 ERROR "USER ALREADY REGISTERED"

### **¿Qué significa?**
El email **omi@naomi.com** ya está registrado en Supabase.

### **¿Cómo solucionarlo?**

**OPCIÓN A: Usar otro email**
```
❌ omi@naomi.com  (ya existe)
✅ naomi.profesora@caipi.edu.mx  (nuevo)
✅ naomi2@naomi.com  (nuevo)
```

**OPCIÓN B: Eliminar el usuario duplicado**
1. Abre **Supabase** → **Authentication** → **Users**
2. Busca: `omi@naomi.com`
3. Click en **"..."** → **"Delete User"**
4. Confirma
5. Ahora sí puedes crear la profesora con ese email

---

## ✅ MEJORAS APLICADAS AL CÓDIGO

### **1️⃣ Error mejorado al crear profesor**
Ahora muestra:
```
✅ ANTES: "Error: Exception: ..."
✅ AHORA: "❌ Este email ya está registrado.
          Usa otro email o elimina el usuario existente."
```

### **2️⃣ Menú con fallback**
Si los permisos fallan, la directora ve todo el menú por defecto.

### **3️⃣ Logs de debug**
Ahora imprime los permisos en consola para debug.

---

## 📋 CHECKLIST

- [ ] **1.** Ejecutar `FIX_MENU_Y_PROFESORES_URGENTE.sql` en Supabase
- [ ] **2.** Presionar `R` en Flutter
- [ ] **3.** Verificar que el menú se ve completo
- [ ] **4.** Eliminar usuario `omi@naomi.com` en Supabase Auth
- [ ] **5.** Crear profesora nuevamente

---

## 📱 MENÚ COMPLETO (Lo que deberías ver)

```
🏠 Inicio

ALUMNOS
├─ 👶 Alumnos
├─ 📄 Entrevista a Padres
├─ 👤 Personas Autorizadas
├─ 🎓 Grados
└─ 📊 Calificaciones

PAGOS
├─ 💰 Pagos
└─ 💳 Configuración de Costos

PROFESORES
├─ 👨‍🏫 Profesores

COMUNICACIÓN
├─ 📢 Anuncios
├─ 📅 Eventos

SEGURIDAD
├─ 🚨 Incidentes
├─ 🏷️ Tipos de Incidentes
├─ 📋 Control de Salidas
└─ 📖 Bitácora Diaria

PRUEBAS
└─ 🧪 Prueba WhatsApp

🚪 Cerrar Sesión
```

---

## ⏱️ TIEMPO TOTAL: 1 MINUTO

1. SQL → 10 segundos
2. Hot Reload → Instantáneo
3. Eliminar usuario duplicado → 30 segundos

---

**🎯 EJECUTA EL SQL PRIMERO, LUEGO PRESIONA R** ✨
