# 📋 MÓDULOS PENDIENTES - CAIPI

## ✅ **LO QUE YA ESTÁ LISTO:**

### **CORE (100%):**
- ✅ Login/Logout
- ✅ Sistema de roles (4 roles)
- ✅ Sistema de permisos (29 permisos)
- ✅ Menú lateral dinámico
- ✅ Dashboards (Directora, Padre)

### **ALUMNOS (80%):**
- ✅ Ver lista de alumnos
- ✅ Crear alumno (+ pagos automáticos)
- ✅ Filtros y búsqueda
- ⚠️ Editar alumno (existe ruta, falta cargar datos)

### **PAGOS (90%):**
- ✅ Ver todos los pagos
- ✅ Acreditar pagos
- ✅ Sistema de semáforo (verde/amarillo/rojo)
- ✅ Crear pagos de libros/uniformes
- ✅ Pagos automáticos al crear alumno

### **PROFESORAS (80%):**
- ✅ Ver lista de profesoras
- ✅ Crear profesora
- ✅ Asignar grupo
- ✅ Gestionar permisos especiales
- ⚠️ Editar profesora (existe ruta, falta cargar datos)

### **PADRES (70%):**
- ✅ Ver lista de padres
- ✅ Crear padre
- ✅ Ver detalle de padre
- ✅ Ver sus hijos
- ⚠️ Editar padre (falta pantalla)

### **PERSONAS AUTORIZADAS (100%):**
- ✅ Ver personas autorizadas por alumno
- ✅ Agregar nuevas personas
- ✅ Relación ilimitada por alumno

### **EVENTOS (90%):**
- ✅ Ver lista de eventos
- ✅ Crear eventos
- ✅ Editar eventos
- ✅ Próximos eventos en dashboard
- ⚠️ Vista para padres (falta pantalla)

### **INCIDENTES (85%):**
- ✅ Ver lista de incidentes
- ✅ Crear incidentes
- ✅ Sistema de 5 niveles
- ✅ Catálogo de 14 tipos
- ✅ Notificación automática nivel 4-5
- ⚠️ Crear/editar tipos (falta UI completa)
- ⚠️ Vista para padres (falta pantalla)

### **ANUNCIOS (60%):**
- ✅ Crear anuncio
- ⚠️ Ver lista de anuncios (falta pantalla)
- ⚠️ Editar anuncio (falta pantalla)

---

## ❌ **MÓDULOS COMPLETAMENTE PENDIENTES:**

### **1. GRADOS (0%)**
```
Prioridad: 🔴 ALTA

Funcionalidad:
- CRUD completo de grados
- Activar/desactivar
- Asignar profesora responsable
- Ver alumnos por grado

Pantallas necesarias:
- /directora/grados (lista)
- /directora/grados/crear (formulario)
- /directora/grados/editar/:id (formulario)

Archivos a crear:
- lib/screens/directora/grados_screen.dart
- lib/screens/directora/crear_grado_screen.dart

SQL:
- Ya existe tabla `grados`
- Solo crear pantallas
```

---

### **2. BITÁCORA DIARIA (0%)**
```
Prioridad: 🟡 MEDIA

Funcionalidad:
- Profesoras registran diariamente:
  - ¿Comió?
  - ¿Hizo pipí/popó?
  - ¿Lavó dientes?
  - ¿Hizo siesta?
  - Estado de ánimo
  - Observaciones
- Padres ven bitácora de sus hijos

Pantallas necesarias:
- /directora/bitacora (lista por fecha)
- /directora/bitacora/crear (formulario rápido)
- /padre/hijo/:id (agregar sección bitácora)

Archivos a crear:
- lib/screens/directora/bitacora_screen.dart
- lib/screens/directora/crear_bitacora_screen.dart
- lib/widgets/bitacora_card.dart

SQL:
- Ya existe tabla `bitacora_diaria`
- Solo crear pantallas
```

---

### **3. CONTROL DE ENTRADA/SALIDA (0%)**
```
Prioridad: 🟡 MEDIA

Funcionalidad:
- Registrar hora de entrada
- Registrar quién trajo al niño
- Registrar hora de salida
- Registrar quién recogió (de personas autorizadas)
- Alertas si recoge persona no autorizada

Pantallas necesarias:
- /directora/control-salidas (lista por fecha)
- /directora/control-salidas/entrada (registro rápido)
- /directora/control-salidas/salida (registro rápido)

Archivos a crear:
- lib/screens/directora/control_salidas_screen.dart
- lib/widgets/control_salida_card.dart

SQL:
- Ya existe tabla `control_salidas`
- Solo crear pantallas
```

---

### **4. MENÚ MATERNAL (0%)**
```
Prioridad: 🟢 BAJA

Funcionalidad:
- Profesoras registran menú del día:
  - Desayuno
  - Comida
  - Merienda
  - Observaciones
- Padres ven menú del día

Pantallas necesarias:
- /directora/menu-maternal (lista por fecha)
- /directora/menu-maternal/crear (formulario)
- /padre (agregar sección menú del día)

Archivos a crear:
- lib/screens/directora/menu_maternal_screen.dart
- lib/widgets/menu_dia_card.dart

SQL:
- Ya existe tabla `menu_maternal`
- Solo crear pantallas
```

---

### **5. GALERÍA DE FOTOS (0%)**
```
Prioridad: 🟢 BAJA

Funcionalidad:
- Profesoras suben fotos de actividades
- Por grupo o generales
- Padres ven fotos de su grupo
- Descripción por foto

Pantallas necesarias:
- /directora/galeria (lista de fotos)
- /directora/galeria/subir (formulario)
- /padre/galeria (vista filtrada)

Archivos a crear:
- lib/screens/directora/galeria_screen.dart
- lib/screens/directora/subir_foto_screen.dart
- lib/screens/padres/galeria_screen.dart
- lib/widgets/foto_galeria_card.dart

SQL:
- Ya existe tabla `galeria`
- Configurar bucket "galeria" en Storage
- Solo crear pantallas
```

---

### **6. CLASES EXTRACURRICULARES (0%)**
```
Prioridad: 🟢 BAJA

Funcionalidad:
- Crear clases extra (yoga, danza, etc.)
- Asignar profesor
- Definir costo y cupo
- Inscribir alumnos/externos
- Control de pagos

Pantallas necesarias:
- /directora/clases-extra (lista)
- /directora/clases-extra/crear (formulario)
- /directora/clases-extra/:id/participantes (lista)
- /padre/clases-extra (inscribirse)

Archivos a crear:
- lib/screens/directora/clases_extra_screen.dart
- lib/screens/directora/crear_clase_extra_screen.dart
- lib/screens/directora/participantes_clase_screen.dart
- lib/widgets/clase_extra_card.dart

SQL:
- Ya existe tabla `clases_extracurriculares`
- Ya existe tabla `participantes_clase`
- Solo crear pantallas
```

---

### **7. CALIFICACIONES (0%)**
```
Prioridad: 🟡 MEDIA

Funcionalidad:
- Profesoras registran calificaciones
- Por materia y periodo
- Padres ven calificaciones de sus hijos
- Reportes por alumno

Pantallas necesarias:
- /directora/calificaciones (lista por grupo)
- /directora/calificaciones/registrar (formulario)
- /padre/hijo/:id (agregar sección calificaciones)

Archivos a crear:
- lib/screens/directora/calificaciones_screen.dart
- lib/widgets/calificacion_card.dart

SQL:
- Ya existe tabla `calificaciones`
- Solo crear pantallas
```

---

### **8. NOTIFICACIONES REALES (0%)**
```
Prioridad: 🔴 ALTA

Funcionalidad:
- Integrar WhatsApp Business API
- Enviar emails con SendGrid/Mailgun
- Notificaciones push en la app
- Historial de notificaciones

Requerimientos:
- Cuenta WhatsApp Business API
- Servicio de Email (SendGrid gratuito)
- Firebase Cloud Messaging (opcional)
- Backend o Edge Functions en Supabase

Archivos a crear:
- lib/services/notificaciones_service.dart
- lib/services/whatsapp_service.dart
- lib/services/email_service.dart
```

---

## 📊 **PRIORIDADES SUGERIDAS:**

### **🔴 ALTA (Hacer primero):**
1. **Editar Alumno** (cargar datos existentes)
2. **Editar Profesor** (cargar datos existentes)
3. **CRUD de Grados** (gestión básica)
4. **Vista de Incidentes para Padres** (que vean incidentes de sus hijos)
5. **Vista de Eventos para Padres** (que vean eventos)

### **🟡 MEDIA (Hacer después):**
1. **Bitácora Diaria** (registro diario importante)
2. **Control Entrada/Salida** (seguridad)
3. **Calificaciones** (académico importante)
4. **Anuncios completo** (comunicación)

### **🟢 BAJA (Últimas funcionalidades):**
1. **Menú Maternal** (nice to have)
2. **Galería de Fotos** (nice to have)
3. **Clases Extracurriculares** (extra)

---

## 🛠️ **MEJORAS TÉCNICAS PENDIENTES:**

### **Testing:**
- [ ] Tests unitarios para permisos
- [ ] Tests de integración para eventos
- [ ] Tests de integración para incidentes
- [ ] Tests de rutas

### **Performance:**
- [ ] Caché de imágenes
- [ ] Paginación en listas largas
- [ ] Lazy loading de permisos

### **Seguridad:**
- [ ] Validar permisos en cada ruta (middleware)
- [ ] Rate limiting en creación de incidentes
- [ ] Logs de auditoría

### **UI/UX:**
- [ ] Animaciones de transición
- [ ] Skeleton loaders
- [ ] Pull to refresh
- [ ] Modo oscuro (opcional)

---

## 📈 **PROGRESO GENERAL:**

```
🟩🟩🟩🟩🟩🟩🟩🟨⬜⬜ 70% Completado

Módulos implementados: 8/15
Pantallas creadas: 20/35 estimadas
Rutas definidas: 25/40 estimadas
```

---

## 🎯 **RECOMENDACIÓN:**

### **Fase 1 (Ahora):**
```
1. Ejecutar SQL de Permisos
2. Ejecutar SQL de Eventos/Incidentes
3. Probar menú y navegación
4. Probar crear evento
5. Probar crear incidente nivel 4
```

### **Fase 2 (Esta semana):**
```
1. Completar edición de alumnos
2. Completar edición de profesoras
3. CRUD de Grados
4. Vista de eventos para padres
5. Vista de incidentes para padres
```

### **Fase 3 (Próxima semana):**
```
1. Bitácora Diaria
2. Control Entrada/Salida
3. Calificaciones
4. Anuncios completo
```

### **Fase 4 (Futuro):**
```
1. Notificaciones reales (WhatsApp/Email)
2. Galería, Menú Maternal, Clases Extra
3. Reportes y estadísticas avanzadas
```

---

**¡Enfócate primero en Fase 1 para validar que todo funciona!** 🚀
