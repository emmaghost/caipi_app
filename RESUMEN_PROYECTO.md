# 📱 Escuela CAIPI - Resumen del Proyecto

## 🎯 ¿Qué es esta app?

Sistema completo de gestión escolar para una escuela primaria con dos tipos de usuarios:

1. **Directora:** Administra TODO (alumnos, pagos, calificaciones, anuncios)
2. **Padres:** Solo ven información de SUS hijos

---

## ✨ Funcionalidades Principales

### 👩‍💼 Para la Directora:

✅ **Dashboard con estadísticas:**
- Total de alumnos
- Pagos pendientes
- Incidentes sin atender
- Total de grados

✅ **Gestión de Alumnos:**
- Ver lista completa de alumnos
- Agregar nuevos alumnos con foto
- Editar información
- Filtrar por grado
- Buscar por nombre
- Organizar por grados (1ro A, 2do B, etc)

✅ **Control de Pagos:**
- Ver todos los pagos pendientes
- Marcar como pagado (efectivo/transferencia)
- Ver historial de pagos por alumno
- Generar pagos mensuales

✅ **Registro de Calificaciones:**
- Agregar calificaciones por materia
- Por periodo (bimestres)
- Con comentarios del maestro

✅ **Reportar Incidentes/Accidentes:**
- Tipo: Accidente, Conducta, Enfermedad
- Gravedad: Leve, Moderado, Grave
- Notificar automáticamente al padre
- Marcar como atendido

✅ **Publicar Anuncios:**
- Crear anuncios para todos los padres
- Marcar como "Urgente" o "Normal"
- Agregar fecha de evento
- Ver quién leyó el anuncio

---

### 👨‍👩‍👧 Para los Padres:

✅ **Ver sus hijos:**
- Lista de todos sus hijos
- Foto, nombre, grado, edad

✅ **Estado de Pagos:**
- Ver pagos pendientes
- Ver pagos realizados
- Fechas límite
- Monto adeudado

✅ **Calificaciones:**
- Ver calificaciones por materia
- Por periodo escolar
- Comentarios del maestro
- Promedio general

✅ **Reportes/Incidentes:**
- Ver si hubo algún accidente
- Notificaciones de conducta
- Reportes de enfermedad

✅ **Recibir Anuncios:**
- Anuncios de la directora
- Notificación de urgencia
- Marcar como leído
- Ver detalles del evento

---

## 🏗️ Tecnologías Usadas

### Frontend (App Móvil):
- **Flutter 3.41** → Framework multiplataforma
- **Dart 3.11** → Lenguaje de programación
- **Material Design 3** → UI moderna y bonita

### Backend (Sin servidor):
- **Firebase Authentication** → Login seguro
- **Firestore Database** → Base de datos en tiempo real
- **Firebase Storage** → Almacenar fotos
- **Cloud Messaging** → Notificaciones push (próximamente)

### Librerías Principales:
- `provider` → Manejo de estado
- `go_router` → Navegación
- `google_fonts` → Tipografías bonitas
- `cached_network_image` → Cargar fotos eficientemente
- `intl` → Formato de fechas/números

---

## 📁 Estructura del Código

```
lib/
├── main.dart                     ← Punto de entrada
├── firebase_options.dart         ← Config de Firebase
│
├── models/                       ← Modelos de datos
│   ├── usuario.dart             (Directora/Padre)
│   ├── alumno.dart              (Estudiantes)
│   ├── pago.dart                (Colegiaturas)
│   ├── calificacion.dart        (Notas)
│   ├── incidente.dart           (Accidentes/reportes)
│   ├── anuncio.dart             (Comunicados)
│   └── grado.dart               (1ro A, 2do B, etc)
│
├── services/                     ← Lógica de negocio
│   ├── auth_service.dart        (Login/Logout)
│   ├── firestore_service.dart   (CRUD de BD)
│   └── storage_service.dart     (Subir fotos)
│
├── screens/                      ← Pantallas
│   ├── login_screen.dart        (Login universal)
│   ├── directora/
│   │   ├── dashboard_directora.dart
│   │   ├── alumnos_screen.dart
│   │   ├── crear_alumno_screen.dart
│   │   ├── pagos_screen.dart
│   │   └── crear_anuncio_screen.dart
│   └── padres/
│       ├── dashboard_padre.dart
│       └── detalle_hijo_screen.dart
│
├── widgets/                      ← Componentes reutilizables
│   ├── stat_card.dart           (Tarjetas de estadísticas)
│   ├── alumno_card.dart         (Tarjeta de alumno)
│   ├── hijo_card.dart           (Tarjeta de hijo)
│   ├── pago_card.dart           (Tarjeta de pago)
│   ├── anuncio_card.dart        (Tarjeta de anuncio)
│   ├── empty_state.dart         (Estado vacío)
│   └── loading_overlay.dart     (Overlay de carga)
│
├── routes/                       ← Navegación
│   └── app_router.dart          (Rutas y protección)
│
└── utils/                        ← Utilidades
    ├── constantes.dart          (Grados, materias)
    └── formatters.dart          (Fechas, dinero)
```

---

## 🗄️ Base de Datos (Firestore)

### 7 Colecciones principales:

1. **usuarios** → Directora y padres
2. **alumnos** → Estudiantes
3. **pagos** → Colegiaturas
4. **calificaciones** → Notas escolares
5. **incidentes** → Accidentes/reportes
6. **anuncios** → Comunicados
7. **grados** → Organización de grupos

**Ver detalles completos en:** `DIAGRAMA_BD.md`

---

## 🎨 Diseño de la App

### Colores principales:
- **Primario:** Indigo (#6366F1)
- **Éxito:** Verde (#10B981)
- **Advertencia:** Naranja (#F59E0B)
- **Error:** Rojo (#EF4444)

### Fuente:
- **Inter** (Google Fonts)
- Moderna y legible

### Estilo:
- Material Design 3
- Cards con bordes redondeados
- Íconos outline
- Sombras suaves

---

## 🔐 Seguridad

### Autenticación:
- Firebase Authentication con email/contraseña
- Tokens JWT automáticos
- Sesión persistente

### Autorización:
- Directora ve TODO
- Padres solo ven SUS hijos
- Reglas de Firestore configurables

### Datos:
- Comunicación HTTPS encriptada
- Datos en la nube (Firebase)
- Sin almacenamiento local de info sensible

---

## 📦 Cómo Funciona (Flujo)

### 1. Login:
```
Usuario abre app
   ↓
Pantalla de Login
   ↓
Ingresa email/password
   ↓
Firebase valida credenciales
   ↓
Si es directora → Dashboard Directora
Si es padre → Dashboard Padre
```

### 2. Directora agrega alumno:
```
Directora → Dashboard
   ↓
Click "Agregar Alumno"
   ↓
Llena formulario + foto
   ↓
Firebase Storage guarda foto
   ↓
Firestore guarda datos del alumno
   ↓
Se vincula con padre (por email)
   ↓
Padre puede ver al alumno en su app
```

### 3. Padre consulta calificaciones:
```
Padre → Dashboard
   ↓
Ve lista de sus hijos
   ↓
Click en un hijo
   ↓
Ve: Pagos, Calificaciones, Incidentes
   ↓
Todo en tiempo real desde Firestore
```

---

## 🚀 Compilación

### Para Android:
```bash
flutter build apk --release
```
**Resultado:** APK de ~15-20 MB

### Para iOS:
```bash
flutter build ios --release
```
**Requiere:** Mac con Xcode

**El mismo código funciona en AMBOS** sin cambios.

---

## 💰 Costos

### Firebase (Plan Gratis - Spark):
- ✅ 50,000 lecturas/día
- ✅ 20,000 escrituras/día
- ✅ 1 GB de almacenamiento
- ✅ Usuarios ilimitados
- ✅ **$0.00 / mes**

**Suficiente para:**
- 100-300 alumnos
- 100-200 padres
- Uso diario normal

### Si creces:
- Plan Blaze (pago por uso)
- ~$5-10/mes para escuela mediana
- ~$20-30/mes para escuela grande

---

## ⏱️ Tiempos de Desarrollo

### Lo que ya está hecho (100%):
- ✅ Estructura completa del proyecto
- ✅ Todos los modelos de datos
- ✅ Servicios de Firebase completos
- ✅ Pantalla de Login funcional
- ✅ Dashboard de Directora
- ✅ Dashboard de Padres
- ✅ Gestión de alumnos
- ✅ Sistema de pagos
- ✅ Calificaciones
- ✅ Incidentes
- ✅ Anuncios
- ✅ Configuración de Android

### Tiempo para tenerlo funcionando:
1. Instalar Node.js: 10 min
2. Configurar Firebase: 20 min
3. Ejecutar `flutter pub get`: 2 min
4. Crear usuario directora: 5 min
5. Primera compilación: 5 min
**Total: ~45 minutos**

---

## 📈 Próximas Funcionalidades (v2.0)

- [ ] Notificaciones push en tiempo real
- [ ] Chat entre directora y padres
- [ ] Calendario de eventos
- [ ] Asistencias diarias
- [ ] Exportar reportes a PDF
- [ ] Envío de tareas
- [ ] Galería de fotos por evento
- [ ] Pagos en línea (Stripe/PayPal)

---

## 🐛 Testing

### Ejecutar tests:
```bash
flutter test
```

### Analizar código:
```bash
flutter analyze
```

---

## 📚 Documentación Adicional

- **README.md** → Guía general
- **INSTRUCCIONES_PASO_A_PASO.md** → Tutorial completo
- **CONFIGURACION_FIREBASE.md** → Setup de Firebase
- **DIAGRAMA_BD.md** → Estructura de datos
- **COMO_COMPILAR_APK.md** → Generar APK/AAB

---

## 🎓 Para Aprender Más

### Flutter:
- https://docs.flutter.dev/
- https://flutter.dev/learn

### Firebase:
- https://firebase.google.com/docs
- https://firebase.google.com/docs/flutter/setup

### Dart:
- https://dart.dev/guides

---

## 📞 Soporte

Si tienes problemas:

1. **Revisa los logs:**
   ```bash
   flutter run -v
   ```

2. **Verifica Flutter:**
   ```bash
   flutter doctor -v
   ```

3. **Limpia el proyecto:**
   ```bash
   flutter clean
   flutter pub get
   ```

4. **Revisa Firebase Console:**
   - Authentication → Users
   - Firestore Database → Data
   - Storage → Files

---

## 🎉 ¡Éxito!

Ya tienes una app escolar completa lista para:
- ✅ Compilar a Android (APK)
- ✅ Compilar a iOS (cuando tengas Mac)
- ✅ Probar en emuladores
- ✅ Instalar en teléfonos reales
- ✅ Distribuir a la escuela

**¡A compilar y probar!** 🚀📱
