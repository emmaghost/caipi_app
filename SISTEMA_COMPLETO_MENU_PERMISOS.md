# 🎯 SISTEMA COMPLETO: MENÚ + PERMISOS + EVENTOS + INCIDENTES

## ✅ **LO QUE SE IMPLEMENTÓ:**

### 🔐 **1. SISTEMA DE PERMISOS (COMPLETO)**

#### **SQL Creado:**
- ✅ Tabla `permisos` (catálogo de 29 permisos)
- ✅ Tabla `roles` (4 roles: directora, profesor_admin, profesor, padre)
- ✅ Tabla `roles_permisos` (relación roles ↔ permisos)
- ✅ Tabla `usuarios_permisos` (permisos adicionales por usuario)
- ✅ Función `usuario_tiene_permiso()` para validar permisos
- ✅ Vista `v_permisos_usuario` para consultar permisos
- ✅ RLS (seguridad por roles)

#### **Modelos Dart:**
- ✅ `lib/models/permiso.dart`
- ✅ `lib/models/rol.dart`

#### **Servicios:**
- ✅ `lib/services/permisos_service.dart`
  - Verificar permisos del usuario
  - Obtener catálogo completo de permisos
  - Otorgar/revocar permisos individuales
  - Cache de permisos para rendimiento

#### **Pantallas:**
- ✅ `lib/screens/directora/permisos_profesor_screen.dart`
  - Gestionar permisos de profesoras
  - Ver permisos por módulo
  - Otorgar/revocar permisos especiales
  - Solo accesible por directora

---

### 📱 **2. MENÚ LATERAL (DRAWER) - COMPLETO**

#### **Widget:**
- ✅ `lib/widgets/app_drawer.dart`
  - Menú lateral con logo CAIPI
  - Muestra nombre y rol del usuario
  - Items dinámicos según permisos
  - Navegación a todos los módulos
  - Botón de cerrar sesión
  - Secciones organizadas:
    - ALUMNOS
    - PAGOS
    - PERSONAL
    - EVENTOS & INCIDENTES
    - COMUNICACIÓN
    - BITÁCORA

#### **Pantallas con Drawer:**
- ✅ Dashboard Directora
- ✅ Dashboard Padre
- ✅ Alumnos
- ✅ Pagos
- ✅ Profesoras
- ✅ Padres
- ✅ Ver Padre
- ✅ Personas Autorizadas
- ✅ Eventos
- ✅ Incidentes
- ✅ Tipos de Incidentes

---

### 📅 **3. MÓDULO DE EVENTOS (COMPLETO)**

#### **SQL Creado:**
- ✅ Tabla `eventos` con campos:
  - titulo, descripcion, fecha_evento
  - hora_inicio, hora_fin, lugar
  - tipo (academico, festivo, reunion, clausura, otro)
  - para_todos, grados_ids
  - foto_url, creado_por, activo
- ✅ RLS por roles

#### **Modelos Dart:**
- ✅ `lib/models/evento.dart`
  - Getters: `yaOcurrio`, `esHoy`, `esProximo`
  - Emoji por tipo

#### **Pantallas:**
- ✅ `lib/screens/directora/eventos_screen.dart`
  - Lista de eventos (próximos y pasados)
  - Filtros por tipo
  - Navegación a crear/editar
  
- ✅ `lib/screens/directora/crear_evento_screen.dart`
  - Crear/editar eventos
  - Seleccionar fecha, hora, lugar
  - Tipo de evento con emojis
  - Destinatarios (todos o por grados)

#### **Dashboard:**
- ✅ Sección "Próximos Eventos" en dashboard_directora
  - Muestra eventos de los próximos 7 días
  - Enlace a ver todos

---

### 🚨 **4. MÓDULO DE INCIDENTES (COMPLETO)**

#### **SQL Creado:**
- ✅ Tabla `tipos_incidentes` (catálogo)
  - 14 tipos pre-cargados
  - 5 niveles de gravedad
  - Categorías: accidente, comportamiento, logro, otro
  - Color personalizado

- ✅ Tabla `incidentes` (actualizada)
  - Relación con tipos_incidentes
  - Sistema de 5 niveles
  - Notificación automática nivel 4-5
  - Trigger para marcar `padre_notificado`

#### **Modelos Dart:**
- ✅ `lib/models/tipo_incidente.dart`
  - Getters: `requiereNotificarPadre`, `emoji`, `nivelLabel`
  
- ✅ `lib/models/incidente.dart`
  - Getters: `requiereNotificarPadre`, `colorNivel`, `emoji`

#### **Pantallas:**
- ✅ `lib/screens/directora/incidentes_screen.dart`
  - Lista de todos los incidentes
  - Filtros por nivel (1-5)
  - Búsqueda por alumno/título
  - Marcar como atendido
  - Ver detalles en modal

- ✅ `lib/screens/directora/crear_incidente_screen.dart`
  - Seleccionar alumno
  - Seleccionar tipo del catálogo
  - Nivel asignado automáticamente
  - Descripción y observaciones
  - Fecha y hora
  - Alerta si nivel >= 4 (notifica padre)

- ✅ `lib/screens/directora/tipos_incidentes_screen.dart`
  - Catálogo completo de tipos
  - Agrupados por nivel
  - Activar/desactivar tipos
  - Resumen visual
  - Crear/editar tipos (pendiente UI completa)

---

## 📊 **SISTEMA DE 5 NIVELES:**

| Nivel | Emoji | Label | Notifica Padre | Color |
|-------|-------|-------|----------------|-------|
| **1** | ℹ️ | Info | ❌ No | Verde |
| **2** | ⚠️ | Leve | ❌ No | Amarillo |
| **3** | ⚠️ | Moderado | ❌ No | Naranja |
| **4** | 🚨 | Grave | ✅ **SÍ** | Rojo Naranja |
| **5** | 🆘 | Urgente | ✅ **SÍ** | Rojo Oscuro |

---

## 🔑 **SISTEMA DE PERMISOS:**

### **4 Roles Base:**

| Rol | Nivel | Permisos | Descripción |
|-----|-------|----------|-------------|
| **Directora** | 1 | 29/29 | Acceso total |
| **Profesor Admin** | 2 | 25/29 | Casi todo (no gestiona profesoras) |
| **Profesor** | 3 | 9/29 | Solo su grupo |
| **Padre** | 4 | 4/29 | Solo lectura de sus hijos |

### **29 Permisos por Módulo:**

#### **ALUMNOS (5):**
- `ver_alumnos`, `ver_alumno_detalle`
- `crear_alumno`, `editar_alumno`, `eliminar_alumno`

#### **PAGOS (4):**
- `ver_pagos`, `acreditar_pago`, `crear_pago`, `ver_reportes_pagos`

#### **PROFESORES (4):**
- `ver_profesores`, `crear_profesor`, `editar_profesor`, `asignar_permisos`

#### **PADRES (3):**
- `ver_padres`, `crear_padre`, `editar_padre`

#### **EVENTOS (4):**
- `ver_eventos`, `crear_evento`, `editar_evento`, `eliminar_evento`

#### **INCIDENTES (4):**
- `ver_incidentes`, `crear_incidente`
- `ver_tipos_incidentes`, `gestionar_tipos_incidentes`

#### **OTROS (5):**
- Personas Autorizadas (2)
- Bitácora (2)
- Anuncios (2)

---

## 🗺️ **NUEVAS RUTAS AGREGADAS:**

```
/directora/profesores/:id/permisos      → Gestionar permisos de profesora
/directora/eventos                       → Lista de eventos
/directora/eventos/crear                 → Crear evento
/directora/eventos/editar/:id            → Editar evento
/directora/incidentes                    → Lista de incidentes
/directora/incidentes/crear              → Crear incidente
/directora/tipos-incidentes              → Catálogo de tipos
```

**Total de rutas ahora: 25**

---

## 🎨 **MEJORAS DE UI/UX:**

1. ✅ **Drawer lateral** en todas las pantallas
   - 3 líneas (hamburger menu) para abrir
   - Logo CAIPI circular
   - Nombre y rol del usuario
   - Navegación organizada por secciones

2. ✅ **Botón HOME** en todas las pantallas
   - Siempre visible en AppBar
   - Regresa al dashboard

3. ✅ **Colores por nivel de incidente**
   - Verde, Amarillo, Naranja, Rojo Naranja, Rojo Oscuro

4. ✅ **Emojis descriptivos**
   - Eventos: 📚 📅 🎉 👥 🎓
   - Incidentes: ℹ️ ⚠️ 🚨 🆘
   - Categorías: 🩹 👤 🌟 📝

5. ✅ **Dashboard mejorado**
   - Sección "Próximos Eventos" (7 días)
   - Cards coloridas con gradientes
   - Estadísticas en tiempo real

---

## 🚀 **PASOS PARA EJECUTAR:**

### **PASO 1: Ejecutar SQL de Permisos**
```bash
1. Abre Supabase → SQL Editor
2. Copia SISTEMA_PERMISOS.sql
3. Ejecuta
4. Verifica: SELECT COUNT(*) FROM permisos; -- Debe ser 29
```

### **PASO 2: Ejecutar SQL de Eventos e Incidentes**
```bash
1. Abre Supabase → SQL Editor
2. Copia EVENTOS_E_INCIDENTES.sql
3. Ejecuta
4. Verifica: SELECT COUNT(*) FROM tipos_incidentes; -- Debe ser 14
```

### **PASO 3: Instalar dependencias**
```bash
flutter pub get
```

### **PASO 4: Hot Restart (¡IMPORTANTE!)**
```bash
Presiona "R" (mayúscula) en la consola
NO uses "r" porque hay nuevas rutas
```

---

## 📖 **CÓMO FUNCIONA:**

### **Permisos:**
1. Directora entra → ve todo el menú
2. Profesor entra → solo ve su grupo, bitácora, incidentes
3. Directora puede convertir a profesor en "Admin":
   - Va a Profesoras
   - Click en icono 🔑 (llave)
   - Selecciona permisos adicionales
   - Profesor Admin puede ver casi todo

### **Eventos:**
1. Directora/Profesora crea evento
2. Selecciona tipo, fecha, destinatarios
3. Aparece en:
   - Dashboard (próximos 7 días)
   - Pantalla de Eventos
   - Futuro: Notificación a padres

### **Incidentes:**
1. Directora/Profesora crea incidente
2. Selecciona alumno y tipo (del catálogo)
3. **Nivel asignado automáticamente**
4. Si nivel >= 4:
   - Trigger marca `padre_notificado = true`
   - Registra `fecha_notificacion`
   - Futuro: Envía WhatsApp/Email
5. Directora puede:
   - Ver todos los incidentes
   - Filtrar por nivel
   - Marcar como atendido
   - Gestionar catálogo de tipos

---

## 🎯 **LO QUE FALTA:**

### **Funcionalidades Pendientes:**
- [ ] Editar Alumno (cargar datos existentes)
- [ ] Editar Profesor (cargar datos existentes)
- [ ] CRUD completo de Grados
- [ ] Diálogos completos para crear/editar tipos de incidentes
- [ ] Subir foto en incidentes
- [ ] Vista de incidentes para padres (en detalle del hijo)
- [ ] Vista de eventos para padres
- [ ] Notificaciones reales (WhatsApp, Email, Push)
- [ ] Módulo de Bitácora Diaria
- [ ] Módulo de Menú Maternal
- [ ] Módulo de Galería de Fotos
- [ ] Módulo de Clases Extracurriculares

---

## 📊 **ESTADÍSTICAS DEL PROYECTO:**

```
✅ 25 Rutas definidas
✅ 16 Pantallas con Drawer
✅ 29 Permisos catalogados
✅ 4 Roles configurados
✅ 14 Tipos de incidentes
✅ 5 Niveles de gravedad
✅ 15 Tablas en Supabase
✅ 12 Modelos Dart
```

---

## 🎨 **COLORES CAIPI:**

```dart
azulOscuro: #1B5E96
rosaClaro: #FFB6C1
amarilloClaro: #FFF9C4
verdeClaro: #C8E6C9
naranjaClaro: #FFE0B2
moradoClaro: #E1BEE7
grisClaro: #F5F5F5
```

---

## 📝 **ARCHIVOS CREADOS/MODIFICADOS:**

### **Nuevos:**
1. `SISTEMA_PERMISOS.sql`
2. `EVENTOS_E_INCIDENTES.sql`
3. `lib/models/permiso.dart`
4. `lib/models/rol.dart`
5. `lib/models/evento.dart`
6. `lib/models/tipo_incidente.dart`
7. `lib/models/incidente.dart`
8. `lib/services/permisos_service.dart`
9. `lib/widgets/app_drawer.dart`
10. `lib/screens/directora/permisos_profesor_screen.dart`
11. `lib/screens/directora/eventos_screen.dart`
12. `lib/screens/directora/crear_evento_screen.dart`
13. `lib/screens/directora/incidentes_screen.dart`
14. `lib/screens/directora/crear_incidente_screen.dart`
15. `lib/screens/directora/tipos_incidentes_screen.dart`

### **Modificados:**
1. `lib/routes/app_router.dart` (7 rutas nuevas)
2. `lib/screens/directora/dashboard_directora.dart` (próximos eventos)
3. `lib/screens/directora/alumnos_screen.dart` (drawer)
4. `lib/screens/directora/pagos_screen.dart` (drawer)
5. `lib/screens/directora/profesores_screen.dart` (drawer + botón permisos)
6. `lib/screens/directora/padres_screen.dart` (drawer)
7. `lib/screens/directora/ver_padre_screen.dart` (drawer)
8. `lib/screens/directora/personas_autorizadas_screen.dart` (drawer)
9. `lib/screens/padres/dashboard_padre.dart` (drawer)

---

## 🎯 **CASOS DE USO:**

### **Caso 1: Profesor Normal**
```
Login → Ve Dashboard → Abre Drawer:
  ✅ Alumnos (solo su grupo)
  ✅ Eventos
  ✅ Crear Incidentes
  ✅ Bitácora
  ❌ NO ve: Pagos, Profesoras, Padres, Tipos de Incidentes
```

### **Caso 2: Profesor Admin**
```
Login → Ve Dashboard → Abre Drawer:
  ✅ Todo lo de Profesor Normal
  ✅ Ver Pagos (sin acreditar)
  ✅ Ver Profesoras (sin editar)
  ✅ Ver Padres
  ❌ NO ve: Gestionar Profesoras, Asignar Permisos
```

### **Caso 3: Directora**
```
Login → Ve Dashboard → Abre Drawer:
  ✅ VE TODO
  ✅ Gestiona Profesoras
  ✅ Asigna permisos especiales
  ✅ Crea eventos, incidentes, tipos
  ✅ Acceso completo
```

### **Caso 4: Padre**
```
Login → Ve Dashboard → Abre Drawer:
  ✅ Mis Hijos
  ✅ Eventos (solo lectura)
  ✅ Anuncios
  ❌ NO ve nada administrativo
```

---

## 🔔 **SISTEMA DE NOTIFICACIONES (AUTOMÁTICO):**

### **Trigger en Supabase:**
Cuando se crea un incidente con **nivel 4 o 5**:
```sql
→ UPDATE incidentes SET 
    padre_notificado = TRUE,
    fecha_notificacion = NOW()
  WHERE nivel >= 4;
```

### **Futuro (próxima versión):**
- Enviar WhatsApp usando API
- Enviar Email usando SendGrid/Mailgun
- Notificación Push en la app

---

## 📞 **SOPORTE Y PREGUNTAS:**

Si algo falta o necesitas ajustar:
1. **Permisos:** Edita `SISTEMA_PERMISOS.sql` y re-ejecuta
2. **Tipos de Incidentes:** Agrega directamente en Supabase o en la app
3. **Colores:** Modifica `lib/config/app_colors.dart`
4. **Menú:** Ajusta `lib/widgets/app_drawer.dart`

---

## ✅ **CHECKLIST DE INSTALACIÓN:**

- [ ] Ejecutar `SISTEMA_PERMISOS.sql` en Supabase
- [ ] Ejecutar `EVENTOS_E_INCIDENTES.sql` en Supabase
- [ ] Ejecutar `flutter pub get`
- [ ] Hot Restart con "R" (mayúscula)
- [ ] Probar login como directora
- [ ] Abrir drawer (3 líneas)
- [ ] Navegar a Eventos
- [ ] Navegar a Incidentes
- [ ] Crear un evento de prueba
- [ ] Crear un incidente de prueba (nivel 4)
- [ ] Verificar notificación automática
- [ ] Probar permisos de profesora

---

**¡TODO LISTO! 🚀**
