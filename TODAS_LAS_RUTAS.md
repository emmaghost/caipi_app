# 📍 TODAS LAS RUTAS DEL SISTEMA CAIPI

## 🔐 **AUTENTICACIÓN**

| Ruta | Pantalla | Acceso |
|------|----------|--------|
| `/` | Redirige a `/login` | Público |
| `/login` | Login Screen | Público |

---

## 👩‍💼 **DIRECTORA** (Solo Directora)

### **Dashboard**
| Ruta | Pantalla | Descripción |
|------|----------|-------------|
| `/directora` | Dashboard Directora | Inicio, estadísticas, accesos rápidos |

### **Alumnos**
| Ruta | Pantalla | Descripción |
|------|----------|-------------|
| `/directora/alumnos` | Lista de Alumnos | Ver todos los alumnos |
| `/directora/alumnos/crear` | Crear Alumno | Agregar nuevo alumno |
| `/directora/alumnos/editar/:id` | Editar Alumno | Modificar datos del alumno |

### **Pagos**
| Ruta | Pantalla | Descripción |
|------|----------|-------------|
| `/directora/pagos` | Gestión de Pagos | Ver todos los pagos |
| `/acreditar-pago/:pagoId` | Acreditar Pago | Registrar pago recibido |

### **Profesores**
| Ruta | Pantalla | Descripción |
|------|----------|-------------|
| `/directora/profesores` | Lista de Profesores | Ver todos los profesores |
| `/directora/profesores/crear` | Crear Profesor | Agregar nuevo profesor |
| `/directora/profesores/editar/:id` | Editar Profesor | Modificar datos del profesor |

### **Padres**
| Ruta | Pantalla | Descripción |
|------|----------|-------------|
| `/directora/padres` | Lista de Padres | Ver todos los padres |
| `/directora/padres/crear` | Crear Padre | Agregar nuevo padre |
| `/directora/padres/ver/:id` | Ver Padre | Ver detalle del padre |

### **Personas Autorizadas**
| Ruta | Pantalla | Descripción |
|------|----------|-------------|
| `/directora/personas-autorizadas/:alumnoId?nombre=...` | Personas Autorizadas | Gestionar quién puede recoger al niño |

### **Anuncios**
| Ruta | Pantalla | Descripción |
|------|----------|-------------|
| `/directora/anuncios/crear` | Crear Anuncio | Enviar mensaje a padres |

---

## 👨‍👩‍👧 **PADRES** (Solo Padres)

| Ruta | Pantalla | Descripción |
|------|----------|-------------|
| `/padre` | Dashboard Padre | Ver hijos, pagos, mensajes |
| `/padre/hijo/:id` | Detalle de Hijo | Ver información completa del hijo |

---

## 🔒 **SEGURIDAD - REDIRECCIONES AUTOMÁTICAS**

### **Si NO está logueado:**
- Cualquier ruta → Redirige a `/login`

### **Si está logueado como Directora:**
- `/login` → Redirige a `/directora`
- Puede acceder a **todas** las rutas de `/directora/*`
- **NO** puede acceder a `/padre/*`

### **Si está logueado como Padre:**
- `/login` → Redirige a `/padre`
- Puede acceder a `/padre` y `/padre/hijo/:id`
- **NO** puede acceder a `/directora/*`

---

## 📱 **NAVEGACIÓN DESDE DASHBOARD DIRECTORA**

```
┌─────────────────────────────────────────┐
│   🏫 DASHBOARD DIRECTORA                │
├─────────────────────────────────────────┤
│                                         │
│  [Ver Alumnos] → /directora/alumnos    │
│                                         │
│  [Gestionar Pagos] → /directora/pagos  │
│                                         │
│  [Profesores] → /directora/profesores  │
│                                         │
│  [Padres] → /directora/padres          │
│                                         │
│  [Nuevo Anuncio] → /directora/anuncios/crear │
│                                         │
│  [Agregar Alumno] → /directora/alumnos/crear │
│                                         │
└─────────────────────────────────────────┘
```

---

## 📱 **NAVEGACIÓN DESDE DASHBOARD PADRE**

```
┌─────────────────────────────────────────┐
│   👨‍👩‍👧 DASHBOARD PADRE                  │
├─────────────────────────────────────────┤
│                                         │
│  [Tarjeta Hijo 1] → /padre/hijo/:id    │
│  [Tarjeta Hijo 2] → /padre/hijo/:id    │
│                                         │
│  Secciones en detalle:                  │
│  - Información personal                 │
│  - Pagos (solo lectura)                 │
│  - Bitácora (próximamente)              │
│  - Mensajes                             │
│                                         │
└─────────────────────────────────────────┘
```

---

## 🔄 **FLUJOS DE NAVEGACIÓN COMPLETOS**

### **Flujo 1: Crear Alumno y Ver Pagos**
```
/directora
  → [Agregar Alumno]
  → /directora/alumnos/crear
  → [Guardar]
  → /directora/alumnos (lista)
  → [Gestionar Pagos]
  → /directora/pagos (ver 14 pagos generados)
  → [Acreditar Pago]
  → /acreditar-pago/:pagoId
  → [Confirmar]
  → /directora/pagos
```

### **Flujo 2: Asignar Personas Autorizadas**
```
/directora
  → [Ver Alumnos]
  → /directora/alumnos
  → [Icono 🛡️ en alumno]
  → /directora/personas-autorizadas/:alumnoId?nombre=...
  → [+ Agregar Persona]
  → [Guardar]
  → Lista actualizada
```

### **Flujo 3: Crear Profesor y Asignar Grupo**
```
/directora
  → [Profesores]
  → /directora/profesores
  → [+ Agregar Profesor]
  → /directora/profesores/crear
  → Seleccionar grupo en dropdown
  → [Guardar]
  → /directora/profesores (lista con grupo asignado)
```

### **Flujo 4: Padre Ve Sus Hijos**
```
/login (como padre)
  → /padre
  → [Tarjeta del hijo]
  → /padre/hijo/:id
  → Ver pagos (solo lectura)
  → Ver bitácora
  → Ver mensajes
```

---

## ⚠️ **ERRORES COMUNES Y SOLUCIONES**

### **Error: "Page Not Found"**

**Causa:** Presionaste `r` (minúscula) en lugar de `R` (mayúscula)

**Solución:**
1. Cierra la app en el emulador
2. En PowerShell: `R` (MAYÚSCULA)
3. Espera compilación completa

---

### **Error: "GoException: no routes for location"**

**Causa:** La ruta no está registrada o tiene errores de sintaxis

**Rutas problemáticas comunes:**
- `/personas-autorizadas/...` (vieja) ❌
- `/directora/personas-autorizadas/:alumnoId?nombre=...` (nueva) ✅

**Solución:**
1. Verifica que usas la ruta correcta
2. Reinicia con `R` (MAYÚSCULA)

---

### **Error: Redirección infinita**

**Causa:** Problema en la lógica de redirect del router

**Solución:**
1. Verifica que el usuario tiene rol correcto en la BD
2. Cierra sesión y vuelve a entrar
3. Reinicia con `R`

---

## ✅ **VALIDACIÓN DE RUTAS**

### **Checklist antes de probar:**

- [ ] Ejecutaste SQL completo en Supabase
- [ ] Cerraste la app en el emulador
- [ ] Presionaste `R` (MAYÚSCULA) en PowerShell
- [ ] Esperaste compilación completa (≈1 minuto)
- [ ] Usuario tiene rol correcto en BD

### **Prueba rápida de todas las rutas:**

1. Login Directora → `/directora` ✅
2. Ver alumnos → `/directora/alumnos` ✅
3. Crear alumno → `/directora/alumnos/crear` ✅
4. Ver pagos → `/directora/pagos` ✅
5. Acreditar pago → `/acreditar-pago/:id` ✅
6. Ver profesores → `/directora/profesores` ✅
7. Crear profesor → `/directora/profesores/crear` ✅
8. Ver padres → `/directora/padres` ✅
9. Crear padre → `/directora/padres/crear` ✅
10. Personas autorizadas → `/directora/personas-autorizadas/:id?nombre=...` ✅
11. Logout → `/login` ✅
12. Login Padre → `/padre` ✅
13. Ver hijo → `/padre/hijo/:id` ✅

---

**TOTAL: 13 rutas principales + variantes = Sistema completo funcionando** ✨
