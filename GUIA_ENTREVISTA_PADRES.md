# 📋 FORMULARIO DE ENTREVISTA A PADRES - GUÍA COMPLETA

## ✅ ¿QUÉ ES ESTO?

Un formulario completo que la **Directora** llena **ANTES** de inscribir a un niño. Recoge toda la información importante sobre:
- Datos de la madre y el padre
- Dirección donde vive el niño
- Información del hogar
- Antecedentes del embarazo
- Situación familiar (padres separados, etc.)
- Aspecto social del niño
- Expectativas de los padres

---

## 📊 ESTRUCTURA DEL FORMULARIO

### **Paso 1: Datos de la Madre** 👩
- Nombre completo
- Edad
- Ocupación
- Dirección
- Máximo grado de estudios
- Teléfono

### **Paso 2: Datos del Padre** 👨
- Nombre completo
- Edad
- Ocupación
- Dirección
- Máximo grado de estudios
- Teléfono

### **Paso 3: Dirección donde Vive el Alumno** 🏠
- Calle
- Colonia
- Número
- Referencia
- **Tipo de vivienda:** Casa / Departamento / Otro
- **Condición:** Propia / Rentada / De un familiar

### **Paso 4: Información del Hogar** 🏡
- Personas que viven con el alumno
- Quién cuida cuando no va a la escuela
- Enfermedades / padecimientos / tratamientos
- Alergias o cuidados especiales
- Control de esfínteres (Sí/No, ¿a qué edad?)
- Necesidades educativas especiales
- Dificultades que han notado
- Motivos de posibles inasistencias

### **Paso 5: Antecedentes** 👶
- ¿Fue un embarazo planeado?
- Tiempo del embarazo
- Dificultades durante el embarazo
- Edad en la que caminó
- Edad en la que habló

### **Paso 6: Padres Separados (Opcional)** 👨‍👩‍👧
*Solo se llena si los padres están separados*
- Quién tiene la patria potestad
- Convive con la otra parte? Explicar
- Tiene padrastro/madrastra? Cómo es la relación
- De qué forma lo llama
- Tiene hermanastros? Cómo es la relación

### **Paso 7: Aspecto Social del Hijo** 🧒
- Describa el carácter del niño
- Qué lo hace enojar
- Qué lo pone triste
- Cómo actúa cuando está así
- Qué es lo que más le gusta hacer
- Se viste sola (Sí/No)
- Se ata los cordones sola
- Hábitos de higiene
- Rutina después de la escuela
- A qué hora se duerme
- A qué hora se despierta

### **Paso 8: Aspecto Social (Familia)** 👨‍👩‍👧‍👦
- Acostumbra salir los fines de semana (Sí/No, ¿a dónde?)
- Actividades que realizan en familia
- Hace amigos con facilidad (Sí/No)
- Nombres de sus amigos
- Tiene mascotas (Sí/No, ¿cuáles?)
- Ayuda a los quehaceres de la casa (Sí/No)
- Cuando se porta mal, cómo actúa usted
- Hay castigos? Cuáles
- Cuando se porta bien, cómo se actúa
- En casa dicen groserías? Quién?
- Juguetes que usa con mayor frecuencia

### **Paso 9: Sobre Nosotros (Expectativas)** 🎯
- Qué espera de la maestra
- Qué espera de la escuela
- Está dispuesto a apoyar a su hija en todo lo que se refiere a la escuela (Sí/No)

---

## 🎯 FLUJO DE TRABAJO

### **OPCIÓN A: Entrevista ANTES de crear alumno** ✅ **RECOMENDADO**

1. **Llenar entrevista** (sin asociar a alumno aún)
2. **Crear alumno** (después)
3. **Asociar entrevista al alumno**

### **OPCIÓN B: Entrevista DESPUÉS de crear alumno**

1. **Crear alumno** (datos básicos)
2. **Llenar entrevista** (se asocia automáticamente)

---

## 🔧 ARCHIVOS CREADOS

### **1. SQL:**
- ✅ `FIX_AGREGAR_ENTREVISTA_PADRES.sql`
  - Crea tabla `entrevistas_padres`
  - Agrega permisos
  - Configura RLS policies
  - Crea índices

### **2. Modelo Dart:**
- ✅ `lib/models/entrevista_padres.dart`
  - Modelo completo con todos los campos
  - `fromJson` y `toJson`

### **3. Pantalla UI:**
- ✅ `lib/screens/directora/entrevista_padres_screen.dart`
  - Formulario con 9 pasos (Stepper)
  - Botones de Continuar/Atrás
  - Validación de campos
  - Guardado en Supabase

### **4. Router:**
- ✅ Rutas agregadas en `lib/routes/app_router.dart`:
  - `/directora/entrevista/crear`
  - `/directora/entrevista/editar/:id`

### **5. Menú:**
- ✅ Opción agregada en `lib/widgets/app_drawer.dart`:
  - Sección ALUMNOS → "Entrevista a Padres"

---

## 📋 PASOS PARA EJECUTAR

### **1. Ejecutar el SQL en Supabase**
```sql
-- Ve a Supabase > SQL Editor
-- Copia y pega el contenido de:
FIX_AGREGAR_ENTREVISTA_PADRES.sql

-- Ejecuta (Run)
```

### **2. Reiniciar la app Flutter**
```bash
# En terminal:
flutter run --release -d emulator-5554
```

### **3. Probar el formulario**
1. Abre la app
2. Menú → **Entrevista a Padres**
3. Llena el formulario paso por paso
4. Al final, haz click en **Guardar**
5. ✅ Entrevista creada exitosamente

---

## 🎨 CARACTERÍSTICAS DEL FORMULARIO

### **✅ Diseño:**
- Mismo estilo colorido de CAIPI
- Iconos para cada campo
- Stepper para navegar entre pasos
- Botones "Continuar" y "Atrás"

### **✅ Funcionalidad:**
- Campos opcionales y requeridos
- Switch para booleanos (Sí/No)
- Dropdowns para opciones fijas
- TextFields con validación
- Auto-guardado con indicador de carga

### **✅ Permisos:**
- Solo la **Directora** puede crear/editar
- RLS configurado en Supabase
- Padres pueden ver su propia entrevista (read-only)

---

## 🔒 PERMISOS

### **Quién puede acceder:**
- ✅ **Directora:** Crear, ver, editar todas las entrevistas
- ✅ **Padre:** Ver solo su propia entrevista (futuro)

### **Permiso creado:**
- `gestionar_entrevistas`: Crear y editar entrevistas de padres

---

## 💡 CASOS DE USO

### **Caso 1: Padre nuevo, niño nuevo**
1. Padre llega a inscribir a su hijo
2. Directora abre: Menú → Entrevista a Padres
3. Llena todos los datos
4. Guarda la entrevista
5. Luego, crea el alumno
6. (Opcional) Asocia la entrevista al alumno

### **Caso 2: Niño ya inscrito, falta entrevista**
1. Directora busca al alumno
2. Clic en "Editar alumno" o "Ver entrevista"
3. Llena la entrevista
4. Se asocia automáticamente al alumno

---

## 🚀 PRÓXIMAS MEJORAS (Futuras)

- [ ] Pantalla para listar todas las entrevistas
- [ ] Filtros por alumno, fecha, completado
- [ ] Exportar entrevistas a PDF
- [ ] Permitir que padres llenen su propia entrevista desde la app
- [ ] Notificación cuando falta entrevista de un alumno

---

## 📊 TABLA EN BASE DE DATOS

**Nombre:** `entrevistas_padres`

**Campos principales:**
- `id` (UUID)
- `alumno_id` (UUID, FK a `alumnos`)
- `padre_usuario_id` (UUID, FK a `usuarios`)
- ~70 campos más con toda la información

**Índices:**
- `idx_entrevistas_alumno` → Búsqueda por alumno
- `idx_entrevistas_padre` → Búsqueda por padre
- `idx_entrevistas_completado` → Filtro por estado

---

## ❓ PREGUNTAS FRECUENTES

### **¿Es obligatorio llenar la entrevista?**
No, pero es muy recomendable. Ayuda a conocer mejor al niño.

### **¿Se puede editar después?**
Sí, la directora puede editar en cualquier momento.

### **¿Los padres pueden verla?**
Sí, los padres pueden ver su propia entrevista (read-only).

### **¿Se puede asociar a varios hijos?**
Cada entrevista es por alumno. Si hay hermanos, se llena una por cada uno.

### **¿Qué pasa si los padres están separados?**
Hay una sección especial (Paso 6) que solo se muestra si activas el switch "Padres separados".

---

## 📞 SOPORTE

Si tienes dudas:
1. Revisa esta guía
2. Revisa el código en `entrevista_padres_screen.dart`
3. Verifica que el SQL se ejecutó correctamente
4. Revisa los permisos en Supabase

---

**¡Listo! Ya puedes usar el Formulario de Entrevista a Padres!** 🎉
