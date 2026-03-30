# 🗄️ Diagrama de Base de Datos - Firestore

## 📊 Estructura Completa

```
Firebase Firestore (NoSQL)
│
├── 📁 usuarios/
│   ├── 📄 {userId} (UID de Firebase Auth)
│   │   ├── email: string
│   │   ├── nombre: string
│   │   ├── telefono: string
│   │   ├── rol: "directora" | "padre"
│   │   ├── hijos: array<string>  ← IDs de alumnos (solo padres)
│   │   └── createdAt: timestamp
│   │
│   ├── 📄 directora001 (ejemplo)
│   │   ├── email: "directora@escuela.com"
│   │   ├── nombre: "Ana María López"
│   │   ├── telefono: "5512345678"
│   │   ├── rol: "directora"
│   │   ├── hijos: []
│   │   └── createdAt: 2026-03-02 10:00:00
│   │
│   └── 📄 padre001 (ejemplo)
│       ├── email: "carlos@gmail.com"
│       ├── nombre: "Carlos Pérez"
│       ├── telefono: "5598765432"
│       ├── rol: "padre"
│       ├── hijos: ["alumno001", "alumno002"]
│       └── createdAt: 2026-03-02 10:30:00
│
├── 📁 alumnos/
│   └── 📄 {alumnoId} (UUID generado)
│       ├── nombre: string
│       ├── apellidos: string
│       ├── fecha_nacimiento: timestamp
│       ├── grado: string  ← "1ro A", "2do B", etc
│       ├── foto_url: string | null
│       ├── padre_id: string  ← referencia a usuarios/{userId}
│       ├── activo: boolean
│       └── createdAt: timestamp
│
├── 📁 pagos/
│   └── 📄 {pagoId} (UUID generado)
│       ├── alumno_id: string  ← referencia a alumnos/{alumnoId}
│       ├── mes: string  ← "Marzo 2026"
│       ├── monto: number  ← 500.00
│       ├── concepto: string  ← "Colegiatura", "Inscripción"
│       ├── pagado: boolean
│       ├── fecha_limite: timestamp
│       ├── fecha_pago: timestamp | null
│       ├── metodo_pago: string | null  ← "efectivo", "transferencia"
│       ├── comprobante_url: string | null
│       └── createdAt: timestamp
│
├── 📁 calificaciones/
│   └── 📄 {calificacionId} (UUID generado)
│       ├── alumno_id: string  ← referencia a alumnos/{alumnoId}
│       ├── materia: string  ← "Matemáticas", "Español"
│       ├── calificacion: number  ← 8.5, 9.0, etc
│       ├── periodo: string  ← "1er Bimestre 2026"
│       ├── comentarios: string | null
│       └── fecha: timestamp
│
├── 📁 incidentes/
│   └── 📄 {incidenteId} (UUID generado)
│       ├── alumno_id: string  ← referencia a alumnos/{alumnoId}
│       ├── tipo: string  ← "accidente" | "conducta" | "enfermedad"
│       ├── descripcion: string
│       ├── gravedad: string  ← "leve" | "moderado" | "grave"
│       ├── atendido: boolean
│       ├── padre_notificado: boolean
│       ├── fecha: timestamp
│       └── reportado_por: string  ← UID de la directora
│
├── 📁 anuncios/
│   └── 📄 {anuncioId} (UUID generado)
│       ├── titulo: string
│       ├── mensaje: string
│       ├── prioridad: string  ← "alta" | "normal"
│       ├── fecha_publicacion: timestamp
│       ├── fecha_evento: timestamp | null  ← Fecha del evento si aplica
│       ├── leido_por: array<string>  ← UIDs de usuarios que leyeron
│       └── creado_por: string  ← UID de la directora
│
└── 📁 grados/
    └── 📄 {gradoId}
        ├── nombre: string  ← "1ro A", "2do B"
        ├── nivel: string  ← "primaria" | "secundaria"
        ├── ciclo_escolar: string  ← "2025-2026"
        └── total_alumnos: number
```

---

## 🔗 Relaciones entre Colecciones

```
usuario (padre)
    └── tiene → alumnos (hijos)
            ├── tiene → pagos
            ├── tiene → calificaciones
            └── tiene → incidentes

alumno
    ├── pertenece a → grado
    └── pertenece a → usuario (padre)

anuncio
    └── creado por → usuario (directora)
```

---

## 📝 Queries Principales

### Para Directora:

```javascript
// Ver todos los alumnos activos
alumnos.where('activo', '==', true).orderBy('apellidos')

// Ver alumnos de un grado específico
alumnos.where('grado', '==', '3ro A').where('activo', '==', true)

// Ver pagos pendientes
pagos.where('pagado', '==', false).orderBy('fecha_limite')

// Ver incidentes sin atender
incidentes.where('atendido', '==', false).orderBy('fecha', 'desc')
```

---

### Para Padre:

```javascript
// Ver mis hijos
alumnos.where('padre_id', '==', 'mi-uid').where('activo', '==', true)

// Ver pagos de mi hijo
pagos.where('alumno_id', '==', 'hijo-uid').orderBy('fecha_limite', 'desc')

// Ver calificaciones de mi hijo
calificaciones.where('alumno_id', '==', 'hijo-uid').orderBy('fecha', 'desc')

// Ver incidentes de mi hijo
incidentes.where('alumno_id', '==', 'hijo-uid').orderBy('fecha', 'desc')

// Ver anuncios (todos)
anuncios.orderBy('fecha_publicacion', 'desc')
```

---

## 💾 Índices Compuestos Necesarios

Firestore creará estos automáticamente cuando los uses por primera vez.

Si te da error, ve a Firestore → Pestaña **"Índices"** y créalos manualmente:

1. **alumnos:**
   - `grado` (Ascending) + `activo` (Ascending) + `apellidos` (Ascending)

2. **pagos:**
   - `alumno_id` (Ascending) + `fecha_limite` (Descending)
   - `pagado` (Ascending) + `fecha_limite` (Ascending)

3. **calificaciones:**
   - `alumno_id` (Ascending) + `fecha` (Descending)
   - `alumno_id` (Ascending) + `periodo` (Ascending) + `materia` (Ascending)

4. **incidentes:**
   - `alumno_id` (Ascending) + `fecha` (Descending)
   - `atendido` (Ascending) + `fecha` (Descending)

---

## 📈 Límites del Plan Gratuito (Spark)

### Firestore:
- 50,000 lecturas/día
- 20,000 escrituras/día
- 20,000 eliminaciones/día
- 1 GB de almacenamiento

### Storage:
- 5 GB de almacenamiento
- 1 GB de descarga/día

### Authentication:
- Usuarios ilimitados

**Para una escuela de ~200 alumnos con 100 padres activos diariamente, el plan gratuito es SUFICIENTE.**

---

## 💰 ¿Cuándo Actualizar a Plan Pago?

Solo si superas:
- Más de 50K consultas/día
- Más de 1000 usuarios activos diariamente
- Necesitas respaldo automático

Plan Blaze (pago por uso):
- $0.06 por 100,000 lecturas
- Muy económico para escuelas

---

¡Firebase está listo! 🔥
