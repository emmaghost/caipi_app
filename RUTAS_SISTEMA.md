# 🗺️ Mapa de Rutas - Sistema CAIPI

## 📊 **RESUMEN**

- **Total de Rutas:** 18
- **Rutas Públicas:** 2
- **Rutas Directora:** 14
- **Rutas Padre:** 2
- **Rutas con Parámetros:** 6

---

## 🔓 **RUTAS PÚBLICAS** (2)

| Ruta | Descripción | Componente |
|------|-------------|------------|
| `/` | Página raíz - Redirige según estado de autenticación | Redirect |
| `/login` | Pantalla de inicio de sesión | `LoginScreen` |

---

## 👩‍💼 **RUTAS DIRECTORA** (14)

### Dashboard
| Ruta | Descripción | Componente |
|------|-------------|------------|
| `/directora` | Dashboard principal de la directora | `DashboardDirectora` |

### Gestión de Alumnos (3 rutas)
| Ruta | Descripción | Componente | Parámetros |
|------|-------------|------------|------------|
| `/directora/alumnos` | Lista de todos los alumnos | `AlumnosScreen` | - |
| `/directora/alumnos/crear` | Crear nuevo alumno | `CrearAlumnoScreen` | - |
| `/directora/alumnos/editar/:id` | Editar alumno existente | `CrearAlumnoScreen` | `id` (UUID) |

### Gestión de Pagos (2 rutas)
| Ruta | Descripción | Componente | Parámetros |
|------|-------------|------------|------------|
| `/directora/pagos` | Ver todos los pagos del sistema | `PagosScreen` | - |
| `/acreditar-pago/:pagoId` | Acreditar pago específico | `AcreditarPagoScreen` | `pagoId` (UUID) |

### Gestión de Profesores (3 rutas)
| Ruta | Descripción | Componente | Parámetros |
|------|-------------|------------|------------|
| `/directora/profesores` | Lista de profesores | `ProfesoresScreen` | - |
| `/directora/profesores/crear` | Crear nuevo profesor | `CrearProfesorScreen` | - |
| `/directora/profesores/editar/:id` | Editar profesor existente | `CrearProfesorScreen` | `id` (UUID) |

### Gestión de Padres (3 rutas)
| Ruta | Descripción | Componente | Parámetros |
|------|-------------|------------|------------|
| `/directora/padres` | Lista de padres de familia | `PadresScreen` | - |
| `/directora/padres/crear` | Crear nueva cuenta de padre | `CrearPadreScreen` | - |
| `/directora/padres/ver/:id` | Ver detalles de un padre | `VerPadreScreen` | `id` (UUID) |

### Personas Autorizadas (1 ruta)
| Ruta | Descripción | Componente | Parámetros |
|------|-------------|------------|------------|
| `/directora/personas-autorizadas/:alumnoId` | Gestionar personas autorizadas para recoger al alumno | `PersonasAutorizadasScreen` | `alumnoId` (UUID) |

### Comunicación (1 ruta)
| Ruta | Descripción | Componente | Parámetros |
|------|-------------|------------|------------|
| `/directora/anuncios/crear` | Crear anuncios para padres | `CrearAnuncioScreen` | - |

---

## 👨‍👩‍👧 **RUTAS PADRE** (2)

| Ruta | Descripción | Componente | Parámetros |
|------|-------------|------------|------------|
| `/padre` | Dashboard del padre - Ver sus hijos | `DashboardPadre` | - |
| `/padre/hijo/:id` | Ver detalles de un hijo específico | `DetalleHijoScreen` | `id` (UUID del alumno) |

---

## 🔒 **PROTECCIÓN DE RUTAS**

### Middleware de Autenticación

Todas las rutas (excepto `/` y `/login`) requieren:
1. ✅ Usuario autenticado
2. ✅ Rol válido (directora, padre, profesor)

### Redirecciones Automáticas

| Condición | Acción |
|-----------|--------|
| Usuario NO logueado intenta acceder a ruta protegida | → `/login` |
| Usuario logueado en `/` o `/login` | → Dashboard según rol |
| Directora logueada | → `/directora` |
| Padre logueado | → `/padre` |
| Profesor logueado | → `/profesor` (futuro) |

---

## 📋 **MÓDULOS Y SUS RUTAS**

### 1️⃣ **Módulo de Alumnos** (3 rutas)
```
/directora/alumnos
├── /crear
└── /editar/:id
```

**Funcionalidades:**
- Ver lista completa de alumnos
- Crear nuevo alumno (genera pagos automáticamente)
- Editar información del alumno

---

### 2️⃣ **Módulo de Pagos** (2 rutas)
```
/directora/pagos
/acreditar-pago/:pagoId
```

**Funcionalidades:**
- Ver todos los pagos (pendientes, pagados, vencidos)
- Acreditar pagos con método de pago y recibido por
- Sistema de semáforo (rojo, amarillo, verde)

---

### 3️⃣ **Módulo de Profesores** (3 rutas)
```
/directora/profesores
├── /crear
└── /editar/:id
```

**Funcionalidades:**
- Ver lista de profesores
- Crear nuevo profesor y asignar grupo
- Editar información del profesor

---

### 4️⃣ **Módulo de Padres** (3 rutas)
```
/directora/padres
├── /crear
└── /ver/:id
```

**Funcionalidades:**
- Ver lista de padres de familia
- Crear nueva cuenta de padre
- Ver detalles de un padre

---

### 5️⃣ **Módulo de Personas Autorizadas** (1 ruta)
```
/directora/personas-autorizadas/:alumnoId
```

**Funcionalidades:**
- Gestionar personas autorizadas para recoger al alumno
- Agregar, editar, eliminar personas autorizadas

---

### 6️⃣ **Vista de Padres** (2 rutas)
```
/padre
└── /hijo/:id
```

**Funcionalidades:**
- Ver información de sus hijos
- Ver pagos pendientes y realizados
- Ver anuncios y notificaciones

---

## 🎯 **FLUJOS DE NAVEGACIÓN PRINCIPALES**

### Flujo: Crear Alumno Completo
1. `/directora` → Dashboard
2. `/directora/alumnos/crear` → Formulario de creación
3. **Acción:** Se crean automáticamente 14 pagos:
   - 1 inscripción anual
   - 1 seguro + credencial
   - 12 colegiaturas mensuales
4. `/directora/alumnos` → Ver alumno creado
5. `/directora/personas-autorizadas/:alumnoId` → Agregar personas autorizadas

---

### Flujo: Acreditar Pago
1. `/directora` → Dashboard
2. `/directora/pagos` → Ver pagos pendientes
3. `/acreditar-pago/:pagoId` → Seleccionar método y quién recibió
4. `/directora/pagos` → Ver pago actualizado (semáforo verde)

---

### Flujo: Crear Profesor
1. `/directora` → Dashboard
2. `/directora/profesores/crear` → Formulario
3. **Acción:** Se crea usuario con contraseña por defecto
4. `/directora/profesores` → Ver profesor creado

---

### Flujo: Padre ve a su hijo
1. `/padre` → Dashboard (lista de hijos)
2. `/padre/hijo/:id` → Ver detalles del hijo
   - Información personal
   - Pagos pendientes (solo lectura)
   - Anuncios

---

## 🧪 **TESTS DE RUTAS**

### Archivos de Test:
- `test/routes/app_router_test.dart` - Tests de integración de rutas
- `test/routes/rutas_validacion_test.dart` - Validación de estructura de rutas

### Ejecutar tests:
```bash
flutter test test/routes/
```

### Tests Validados:
- ✅ Total de 18 rutas
- ✅ No hay rutas duplicadas
- ✅ Todas empiezan con `/`
- ✅ Prefijos correctos por rol
- ✅ Parámetros bien formados
- ✅ Protección de rutas
- ✅ Consistencia CRUD

---

## 📝 **CONVENCIONES**

### Nomenclatura de Rutas:
- **Plural para listas:** `/alumnos`, `/profesores`, `/padres`
- **Singular para detalle:** `/hijo/:id`, `/editar/:id`
- **Acciones como verbos:** `/crear`, `/editar`, `/acreditar-pago`

### Parámetros:
- **UUID:** `:id`, `:pagoId`, `:alumnoId`
- **Descriptivos:** Usar nombres que indiquen el tipo de ID

### Estructura:
```
/[rol]/[módulo]/[acción]/:parámetro
```

Ejemplos:
- `/directora/alumnos/crear` ✅
- `/padre/hijo/:id` ✅
- `/acreditar-pago/:pagoId` ✅ (ruta especial)

---

## 🚀 **RUTAS FUTURAS (Roadmap)**

### Módulo de Profesor (Pendiente)
```
/profesor
├── /bitacora
├── /bitacora/crear
├── /grupo
└── /notificaciones
```

### Módulo de Eventos
```
/directora/eventos
├── /crear
└── /editar/:id

/padre/eventos
```

### Módulo de Galería
```
/directora/galeria
└── /subir

/padre/galeria
```

### Módulo de Calificaciones
```
/directora/calificaciones
└── /capturar

/padre/calificaciones/:hijoId
```

---

## 📞 **SOPORTE**

Si una ruta no funciona:
1. ✅ Verifica que esté en esta lista
2. ✅ Ejecuta los tests: `flutter test test/routes/`
3. ✅ Verifica que el usuario tenga el rol correcto
4. ✅ Usa Hot Restart (`R`) si agregaste rutas nuevas

---

**Última actualización:** 2026-03-05
**Total de Rutas:** 18
**Estado:** ✅ Todas operativas
