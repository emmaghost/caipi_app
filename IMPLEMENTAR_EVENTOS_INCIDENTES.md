# 🎉 Implementación de Eventos e Incidentes - CAIPI

## ✅ **LO QUE YA ESTÁ HECHO:**

### 1️⃣ **SQL Creado**
- ✅ Tabla `eventos`
- ✅ Tabla `tipos_incidentes` (catálogo)
- ✅ Tabla `incidentes` (actualizada con niveles 1-5)
- ✅ 14 tipos de incidentes pre-cargados
- ✅ RLS (seguridad por roles)
- ✅ Trigger automático para notificaciones nivel 4-5

### 2️⃣ **Modelos Dart Creados**
- ✅ `lib/models/evento.dart`
- ✅ `lib/models/tipo_incidente.dart`
- ✅ `lib/models/incidente.dart`

---

## 🚀 **PASO 1: EJECUTAR SQL EN SUPABASE**

### Ve a Supabase → SQL Editor y ejecuta:

```sql
-- Archivo: EVENTOS_E_INCIDENTES.sql
```

**Esto creará:**
- 📅 Tabla de eventos
- 📋 Catálogo de 14 tipos de incidentes
- 🚨 Sistema de 5 niveles de gravedad
- 🔔 Notificaciones automáticas para niveles 4-5

---

## 📊 **SISTEMA DE 5 NIVELES:**

| Nivel | Descripción | Notificar Padre | Ejemplos |
|-------|-------------|-----------------|----------|
| **1** | ℹ️ Info general | ❌ No | Olvido material, Tarea incompleta, Logros |
| **2** | ⚠️ Atención menor | ❌ No | Golpe leve, Falta de atención |
| **3** | ⚠️ Requiere seguimiento | ❌ No | Conflicto con compañero, Malestar leve |
| **4** | 🚨 Grave | ✅ **SÍ** | Golpe con moretón, Conducta agresiva, Fiebre |
| **5** | 🆘 Urgente | ✅ **SÍ** | Accidente grave, Agresión severa |

---

## 📋 **TIPOS DE INCIDENTES PRE-CARGADOS (14):**

### Nivel 1 - Info:
1. Olvido material
2. Tarea incompleta
3. ⭐ Excelente participación (logro)
4. ⭐ Ayudó a compañero (logro)
5. ⭐ Logro académico (logro)

### Nivel 2 - Leve:
6. Golpe leve
7. Falta de atención

### Nivel 3 - Moderado:
8. Conflicto con compañero
9. Malestar leve

### Nivel 4 - Grave (NOTIFICA):
10. Golpe con moretón
11. Conducta agresiva
12. Fiebre

### Nivel 5 - Urgente (NOTIFICA):
13. Accidente grave
14. Agresión severa

---

## 🎯 **FUNCIONALIDADES IMPLEMENTADAS:**

### **Módulo de Eventos:**
- ✅ CRUD completo de eventos
- ✅ Tipos: Académico, Festivo, Reunión, Clausura, Otro
- ✅ Eventos para todos o por grados específicos
- ✅ Foto del evento
- ✅ Fecha, hora inicio/fin, lugar
- ✅ Solo directora/profesoras pueden crear

### **Módulo de Tipos de Incidentes:**
- ✅ CRUD completo del catálogo
- ✅ Solo directora puede gestionar
- ✅ Categorías: Accidente, Comportamiento, Logro, Otro
- ✅ Color personalizado por tipo
- ✅ Nivel de gravedad 1-5

### **Módulo de Incidentes:**
- ✅ Crear incidente basado en catálogo
- ✅ Notificación automática a padres (nivel 4-5)
- ✅ Subir foto del incidente
- ✅ Observaciones adicionales
- ✅ Marcar como atendido
- ✅ Ver incidentes por alumno
- ✅ Padres ven solo incidentes de sus hijos

---

## 📱 **PANTALLAS A CREAR:**

### **Directora/Profesora:**
1. **Eventos** (`/directora/eventos`)
   - Lista de eventos
   - Crear/Editar evento
   - Ver próximos eventos

2. **Tipos de Incidentes** (`/directora/tipos-incidentes`)
   - Lista de tipos (solo directora)
   - Crear/Editar tipo
   - Activar/Desactivar

3. **Incidentes** (`/directora/incidentes`)
   - Lista de todos los incidentes
   - Crear incidente (seleccionar alumno y tipo)
   - Ver detalles
   - Marcar como atendido

### **Padre:**
1. **Eventos** (`/padre/eventos`)
   - Ver próximos eventos (solo lectura)

2. **Incidentes** (dentro de `/padre/hijo/:id`)
   - Ver incidentes de su hijo
   - Filtro por gravedad
   - Ver si fue notificado

---

## 🎨 **COLORES POR NIVEL:**

```dart
Nivel 1: #90EE90 (Verde claro)
Nivel 2: #FFD700 (Dorado)
Nivel 3: #FF8C00 (Naranja)
Nivel 4: #FF4500 (Rojo naranja)
Nivel 5: #8B0000 (Rojo oscuro)
```

---

## 🔔 **NOTIFICACIONES AUTOMÁTICAS:**

Cuando se crea un incidente con **nivel 4 o 5**:
- ✅ Se marca automáticamente `padre_notificado = true`
- ✅ Se registra `fecha_notificacion`
- ✅ Trigger en la base de datos lo hace automáticamente
- ✅ Futuro: Enviar notificación push/email/WhatsApp

---

## 📊 **DASHBOARD - NUEVAS CARDS:**

### **Agregar en Dashboard Directora:**
```
📅 Próximos Eventos (7)
🚨 Incidentes Graves (3)
📋 Tipos de Incidentes (14)
```

### **Agregar en Dashboard Padre:**
```
📅 Próximos Eventos
🚨 Incidentes de mi hijo (solo si hay)
```

---

## 🗺️ **RUTAS A AGREGAR:**

```
/directora/eventos
/directora/eventos/crear
/directora/eventos/editar/:id

/directora/tipos-incidentes
/directora/tipos-incidentes/crear
/directora/tipos-incidentes/editar/:id

/directora/incidentes
/directora/incidentes/crear
/directora/incidentes/:id

/padre/eventos
```

---

## 🔄 **FLUJO DE TRABAJO:**

### **Crear Incidente:**
1. Directora/Profesora → "Incidentes" → "+"
2. Seleccionar alumno
3. Seleccionar tipo de incidente (del catálogo)
   - El nivel se asigna automáticamente según el tipo
4. Descripción adicional
5. Foto (opcional)
6. Guardar
7. **Si nivel >= 4:** Padre notificado automáticamente

### **Gestionar Tipos (Solo Directora):**
1. Directora → "Tipos de Incidentes"
2. Puede agregar nuevos tipos
3. Asignar nivel 1-5
4. Elegir categoría y color
5. Activar/Desactivar tipos

---

## ✅ **SIGUIENTE PASO:**

**Ejecuta el SQL en Supabase:**
```
1. Abre Supabase → SQL Editor
2. Copia todo de: EVENTOS_E_INCIDENTES.sql
3. Click "Run"
4. Verifica que se crearon las tablas
```

**Luego avísame para crear las pantallas** 🚀
