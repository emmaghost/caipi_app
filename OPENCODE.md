# CAIPI — Briefing completo para OpenCode

> **Cómo usarlo:** primer mensaje `@OPENCODE.md` (o pega el archivo) y luego el ticket.  
> Fuente de verdad para **cualquier cambio de la app** (no solo pagos).  
> No reescribas el sistema. No migres a Firebase. No inventes módulos. La galería está **cancelada**.

**Repo:** `https://github.com/emmaghost/caipi_app.git` · rama `main`  
**Package:** `escuela_caipi` · versión `1.0.8+4009` (este es el build de App Store / TestFlight)  
**Cliente:** Viridiana (directora) en **iPad / iPhone** y a veces Android.  
**Producto:** gestión de un preescolar (CAIPI): alumnos, cobranza, bitácoras, chat, Portage, recogida.

**Congelado (1 sep 2026):** este archivo describe **solo lo que ya está en el código**. No inventes pantallas, columnas ni módulos. No “completes” WhatsApp, el escáner QR ni la galería. Cotización = solo en Configuración de costos.

---

## 0. Rol al implementar (senior iOS + Android)

Eres senior móvil en una app Flutter **ya en producción escolar**.

- Piensa **iPhone, iPad (tableta a papás) y Android**. Safe Area, notch, home indicator, teclado, swipe-back iOS, back físico Android.
- Versionado: `pubspec.yaml` → iOS `CFBundleShortVersionString` + `CFBundleVersion` y Android `versionName`/`versionCode`. Si Viri debe **bajar** el build, sube al menos el `+N` (`4009` → `4010`).
- No toques Xcode / `Info.plist` / Gradle salvo bug nativo (permisos, push, signing).
- Widgets actuales (`FilterChip`, `ExpansionTile`, `withValues`, `go_router`) **ya corren en iOS**. No uses APIs web-only ni plugins sin impl iOS.
- Copy **español MX**. Montos: `NumberFormat('#,##0.00', 'es_MX')`.
- Cambios **mínimos y locales**. Varias pantallas son enormes (`pagos_screen.dart` ~2700 líneas): no las partas “porque sí”.
- En Windows **no hay simulador iOS**. En Mac: iPhone + iPad. Android: emulador Pixel o device.

---

## 1. Stack real

| Capa | Tecnología |
|------|------------|
| App | Flutter 3.x, Dart `>=3.0.0 <4.0.0`, Material |
| UI | `google_fonts` (Poppins cuerpo, Fredoka títulos), `AppColors` |
| Estado | `provider`: `AuthService`, `AccesoPadreService` |
| Nav | `go_router` (`lib/routes/app_router.dart`) + redirect login/rol |
| Backend | **Supabase**: Auth, Postgres, RLS, Realtime, Storage |
| Push | **FCM** (`firebase_messaging`) + locales + Realtime. Firebase **no** es la BD. |
| PDF / Excel | `pdf` + `printing`, `excel` + share / `file_saver` |
| QR | `qr_flutter` (padre genera; escáner escuela incompleto) |

**Ignora** cualquier `.md` viejo de Firestore/Firebase como backend. Hay decenas.  
Config: `lib/config/supabase_config.dart` · proyecto `qxldfqnuwpucptajcazf.supabase.co`.

### Cómo correr

```bash
cd <repo>
flutter pub get
# Android
flutter emulators --launch Pixel_9_Pro_XL
flutter run -d emulator-5554
# iOS (Mac)
cd ios && pod install && cd ..
flutter run -d <iphone-o-ipad>
```

| Plataforma | IDs | Notas |
|------------|-----|--------|
| Android | `com.escuela.caipi` | APK / emulador OK |
| iOS | `com.escuela.escuelaCaipi` | Display **CAIPI**, iOS 12+, `Info.plist` cámara/galería |
| Windows desktop | — | Falla sin VS + C++. No es bug de app |

`flutter_launcher_icons.ios: false` — no regeneres íconos iOS sin pedirlo.

---

## 2. Mapa del repo

```
lib/
  main.dart                         # Supabase, push, Provider, GoRouter
  config/                           # colores, supabase, twilio
  models/                           # un DTO por entidad (fromJson/toJson)
  utils/                            # lógica pura (pago_helpers, portage_stats)
  services/                         # datos + PDF + push + chat
  routes/app_router.dart            # TODAS las rutas
  screens/
    login_screen.dart
    cambiar_contrasena_screen.dart
    directora/                      # staff (directora, profes, secretaria)
    padres/                         # familia
    chat/                           # lista escuela + conversación + chat padre
  widgets/                          # drawer, cards, recogida, Portage
test/                               # utils + widgets; router tests rotos (no “arregles”)
ios/  android/
ADD_*.sql  FIX_*.sql                # parches de schema (no hay un SQL único perfecto)
```

**Patrón de pantalla:** `AppDrawer` + `AppBar` → `FutureBuilder`/`StreamBuilder`/`initState` → `context.go`/`push` → `SnackBar`.  
`go()` sin stack deja **pantalla negra** al pop. Si llegaron con `push`, usa `pop()`; si no, `context.go('/directora')`.

---

## 3. Auth, roles y menú

Login: Supabase Auth → fila `usuarios` con `id = auth.uid`. Inactivo → sign out.

`AuthService`: `isLoggedIn`, `esDirectora`, `esProfesor`, `esPadre`, `esStaff`, `esMaestraIngles`.

| `usuarios.rol` | Superficie | Notas |
|----------------|------------|--------|
| `directora` | `/directora` · menú completo | Permisos del drawer **hardcoded true** (en iOS el RPC dejaba spinner y “no había chat”) |
| `profesor` / `profesor_admin` | `/directora` + permisos | `esProfesor` incluye ambos. Titular vs inglés: `profesores.especialidad` |
| `secretaria` | `/directora` · menú **solo alta de alumno** | |
| `padre` | `/padre` | Si RPC `padre_acceso_restringido` → `/padre/adeudo` (chat sí, resto no) |

Maestra de **inglés:** menú corto (alumnos del grupo + calificaciones de Inglés). No edita fichas (`puedeEditarAlumnos` = false).

**Permisos (`ver_alumnos`, `ver_pagos`, …):** ocultan **menú**, no rutas. Navegar a `/directora/pagos` a mano no revalida. Defensa real = **RLS**.  
Pagos en menú: solo si `ver_pagos` **y** `esDirectora`.  
Profesoras: `ver_pagos` se fuerza a `false` en el drawer.

Router: staff (`esStaff`) → árbol `/directora`; padre → `/padre`.  
`/acreditar-pago/:pagoId` está en el árbol staff.

**Router extra (ya en código, no lo “arregles”):**
- Secretaria: solo `/directora`, `/directora/alumnos*` y cambiar contraseña. `/alumnos` redirige a **crear**.
- Maestra inglés: solo dashboard, lista alumnos y `/calificaciones*`.

---

## 4. Rutas (inventario)

**Públicas:** `/` → redirect · `/login` · `/cambiar-contrasena`

**Staff `/directora`**

| Área | Rutas |
|------|--------|
| Home | `/directora` |
| Alumnos | `/alumnos`, `/alumnos/crear`, `/alumnos/editar/:id` |
| Entrevista | `/entrevistas`, `/entrevista/crear?alumnoId=`, `/entrevista/editar/:id` |
| Portage | `/portage`, `/portage/alumno/:id`, `/portage/lista/:id`, `/portage/evaluacion/:id`, `/portage/evaluacion/:evalId/alumno/:alumnoId` |
| Ligas Drive | `/ligas`, `/ligas/crear`, `/ligas/editar/:id` |
| Pagos | `/pagos`, `/configuracion-costos` · acreditar: `/acreditar-pago/:pagoId` |
| Personal | `/profesores` (+ crear/editar/`/:id/permisos`), `/padres` (+ crear/`ver/:id`) |
| Autorizados | `/personas-autorizadas/:alumnoId` |
| Comms | `/anuncios`, `/eventos`, `/incidentes`, `/tipos-incidentes` (CRUD típico) |
| Grados | `/grados` (+ crear/editar) |
| Bitácoras | `/bitacoras`, `/bitacora-gastos` (+ crear/editar) |
| Salidas | `/control-salidas` (+ crear/editar) |
| Calificaciones | `/calificaciones`, `/calificaciones/alumno/:alumnoId` |
| Maternal | `/menu-maternal` (+ crear/editar) |
| Extra | `/clases-extracurriculares` (+ crear/editar) |
| Chat | `/chat`, `/chat/:id` |
| Reportes | `/reportes-pdf` |
| Config | `/config-chat-horario` · `/test-whatsapp` (no está en menú) |

**Galería:** rutas **comentadas**. No reimplementar.

**Padre `/padre`**

| Ruta | Qué |
|------|-----|
| `/padre` | Dashboard hijos |
| `/padre/adeudo` | Modo restringido por cobranza |
| `/padre/hijo/:id` | Detalle (incidentes, ligas, etc.) |
| `/padre/hijo/:id/pagos` | Cuadro del hijo (sin insc/seguro kínder) |
| `/padre/hijo/:id/bitacora` | Bitácora diaria |
| `/padre/hijo/:id/personas-autorizadas` | Autorizados |
| `/padre/chat` | Su única conversación |
| `/padre/eventos` | Eventos visibles |
| `/padre/qr-temporal` | Genera QR |

---

## 5. Módulos de la app (toda)

Leyenda: ✅ estable · ⚠️ frágil / incompleto · ❌ no tocar / cancelado

### 5.1 Núcleo

| Módulo | Estado | Dónde | Qué saber |
|--------|--------|-------|-----------|
| Login / sesión | ✅ | `login_screen`, `auth_service` | Email + password. Usuario inactivo → out |
| Roles / drawer | ✅ / ⚠️ | `app_drawer`, `permisos_service` | Menú ≠ seguridad. Directora no pega RPC |
| Cambiar contraseña | ✅ | `cambiar_contrasena_screen` | |
| Dashboard staff | ✅ | `dashboard_directora` | Tiles + “Pagos vencidos” + panel recogida. Profesora filtra por `grado_id` |

### 5.2 Alumnos y estructura

| Módulo | Estado | Dónde | Qué saber |
|--------|--------|-------|-----------|
| Grados | ✅ | `grados_screen`, `models/grado.dart` | `esKinder` / `esMaternal` / `esEstimulacion` por **nombre**. Colegiatura auto **solo kínder**. Maternal+estimulación = mismo grupo |
| Alumnos | ✅ | `alumnos_screen`, `crear_alumno_screen` | Alta → genera pagos. Si pagos fallan → **rollback alumno**. `plan_pagos` 10/11/12, beca, `fecha_ingreso`. Foto opcional → Storage (abajo) |
| Padres | ✅ | `padres_screen`, crear/ver | Un padre → varios hijos. Un alumno → **máx. 2 tutores** (`alumnos_padres` + `alumnos.padre_id` = el primero). `guardarPadresAlumno` |
| Profesoras | ✅ | `profesores_screen` | `especialidad` titular/ingles, `grado_id` |
| Permisos profesora | ✅ | `permisos_profesor_screen` | Extra sobre el rol. RLS manda |

### 5.3 Cobranza (caliente — Viri la usa diario)

| Módulo | Estado | Dónde |
|--------|--------|-------|
| Pagos staff | ✅ | `pagos_screen` — 3 tabs: Alumnos / Extra / Bitácora gastos |
| Acreditar | ✅ | **Único flujo en uso:** `/acreditar-pago/:pagoId` → `acreditar_pago_screen` → `acreditarPagoParcial` + recibo PDF |
| Abono (huérfano) | ⚠️ | `registrar_abono_screen.dart` **existe pero no está en el router ni se navega**. No lo uses; no lo borres “porque sí”. El camino de Viri es Acreditar |
| Config costos | ✅ | `configuracion_costos_screen` — cotización y chips de suma **solo aquí** |
| Pagos padre | ✅ | `pagos_padre_screen` |
| Excel pagos | ✅ | `exportacion_pagos_excel.dart` — botón en AppBar de Pagos; respeta filtros de **esa** pestaña. Compartir o guardar en el teléfono |

**Semáforo** (`pago.dart`, fecha a medianoche):

- `estaPagado` = estatus `pagado` **o** `montoPagado >= monto`
- `estaVencido` = no pagado, no cancelado, **hoy > fecha_vencimiento**
- `esFuturo` = hoy < límite
- **Vence hoy ≠ vencido**

**Filtros Pagos:** default `_filtroEstado = 'vencidos'`.  
Por eso ves **43** y no 564: 564 = chip **Todos**. No cambies el default sin pedirlo.

| Chip | Qué deja |
|------|----------|
| todos | Tipo/grado/alumno solamente |
| vencidos | `!pagado && estaVencido` |
| pendientes | no pagado y no futuro (incluye vencidos + hoy) |
| futuros | `esFuturo` |
| pagados | `estaPagado` |

Tab Alumnos: excluye extracurricular; `PagoHelpers.esTipoCuadroPagos` **oculta inscripción/seguro de kínder** (sí insc. estimulación).  
Filtros de alumnos **empiezan colapsados**.

**Config + cotización (solo `/directora/configuracion-costos`, NO en Pagos):**

- Totales de los cuadritos = **solo colegiaturas** por default.
- Chips de **sesión** (no se guardan): Sumar inscripción / Sumar seguro. Para cuando un papá pide el total en la tableta.
- Campos anticipado / recargo 12-11-10 en el mismo form. Si vacíos o no hay columnas (`ADD_PLANES_ANTICIPADO_RECARGO.sql`) → `mensualidad × meses`. Save reintenta sin esas columnas.
- Inscripción/seguro aceptan `0`. El truco de `0.01` ya no hace falta.
- **No vuelvas a poner el recuadro de planes en Gestión de Pagos.**

Alta alumno: solo colegiaturas del plan. No metas insc/seguro otra vez al cuadro.

### 5.4 Comunicación

| Módulo | Estado | Dónde | Qué saber |
|--------|--------|-------|-----------|
| Chat | ✅ | `chat_service`, `chat_*_screen` | **1 conversación por padre**. Realtime. Lista escuela: búsqueda, “con mensajes / no leídos” |
| Horario chat | ✅ | `chat_horario_service`, `/config-chat-horario` | Fuera de horario no envía (default Lun–Vie 08:00–16:00). Directora sí |
| Anuncios | ✅ | `anuncios_screen` | Alcance todos o por grado |
| Eventos | ✅ | `eventos_screen` | Staff CRUD; padres ven filtrados |
| Incidentes | ✅ | `incidentes_screen`, tipos | Severidad 1–5. Padres los ven en detalle hijo |
| Push FCM | ⚠️ | `push_notification_service` | Token al login. Edge `notify-chat`. Firebase **solo** para esto |
| Notif. locales | ✅ | `notification_service` + `app_realtime_notifications` | Realtime de chat y recogida → banner local (también en foreground). Distinto de FCM |
| WhatsApp | ⚠️ | `whatsapp_service`, `twilio_config.dart` | **Placeholders** (`TU_ACCOUNT_SID_AQUI`, sandbox). No está en menú (`/test-whatsapp`). No “actives” Twilio en este freeze |

Mensaje masivo: cuenta destinatarios, solo activos, errores claros (commit reciente).

### 5.5 Operación diaria

| Módulo | Estado | Dónde | Qué saber |
|--------|--------|-------|-----------|
| Bitácora diaria | ✅ | `bitacoras_screen`, `bitacora_padre_screen` | Comió, baño, siesta, ánimo. Padres la ven |
| Bitácora gastos | ✅ | `bitacora_gastos_screen` + panel embebido en tab 3 de Pagos | Alcance: todos / general escuela / por grado. **Excel** `exportacion_gastos_excel.dart` (mismo compartir/guardar que pagos) |
| Entrada/salida | ✅ | `control_salidas_screen` | Quién trajo/recogió |
| Autorizados | ✅ | `personas_autorizadas_screen` (staff y padre) | |
| Recogida | ✅ | `solicitud_recogida_*`, panel dashboard | Padre pide; escuela atiende sheet |
| QR temporal | ⚠️ | `qr_temporal_screen` | Padre genera. **Escáner puerta incompleto** |
| Menú maternal | ✅ | `menu_maternal_screen` | |
| Extracurriculares | ⚠️ | `clases_extracurriculares_screen` | CRUD clases; participantes menos pulido. Pagos tipo `extracurricular` |
| Calificaciones | ✅ | `calificaciones_*` | Inglés: solo materia inglés |
| Reportes PDF | ✅ | `reportes_pdf_screen` | Solo directora. Branding `pdf_branding.dart` |
| Ligas Drive | ✅ | `liga_drive_service` | Guías por grado / alumno. Padres las ven |

### 5.6 Pedagógico

| Módulo | Estado | Dónde | Qué saber |
|--------|--------|-------|-----------|
| Entrevista padres | ✅ | `entrevista_*` | Ligar `alumnoId`. `padre_usuario_id` = padre del niño, **no** la directora. PDF al completar |
| Portage / indicadores | ✅ | `portage_*`, `portage_service` | Listas, evaluación por alumno, gráficas, PDF. `portage_stats` para series |

### 5.7 Cancelado

| Módulo | |
|--------|--|
| Galería | ❌ Rutas comentadas, modelo `foto_galeria.dart` legacy. No revivir |

### 5.8 Servicios de apoyo (ya existen)

| Pieza | Dónde | Qué hace / qué no |
|-------|--------|-------------------|
| Capa de datos | `supabase_service.dart` | Mega-servicio: alumnos, pagos, abonos, califs, anuncios, incidentes, **2 papás**. Casi todo el CRUD pasa por aquí. No lo partas |
| Fotos Storage | `storage_service.dart` · bucket **`fotos`** | **En uso:** foto de alumno al crear/editar (`alumnos.foto_url`, cards). Cámara o galería (`image_picker`, 800px, quality 70). iOS ya tiene `NSCameraUsageDescription` + `NSPhotoLibraryUsageDescription` |
| Comprobante pago | mismo `StorageService.subirComprobantePago` | **Método escrito, nadie lo llama.** No lo cables en este freeze |
| Recibo PDF | `recibo_pago_pdf.dart` + `pdf_branding.dart` | Sale al acreditar |
| Permisos RPC | `permisos_service.dart` | Lo usa el drawer (profes). Directora **no** llama RPC |

---

## 6. Datos (Supabase) — modelo mental

```
auth.users
  └── usuarios (rol, activo, nombre…)
        ├── profesores (usuario_id, grado_id, especialidad)
        └── (padre) → alumnos.padre_id

grados
alumnos (grado_id, plan_pagos, beca, fecha_ingreso, foto_url, padre_id)
  ├── alumnos_padres (hasta 2 tutores; el 1º también en padre_id)
  ├── pagos → abonos
  ├── calificaciones, bitacora_diaria, control_salidas
  ├── incidentes, entrevistas_padres, personas_autorizadas
  └── qr_temporales, solicitudes_recogida

Storage bucket `fotos`:
  alumnos/{id}/foto.ext          ← en uso
  pagos/{id}/comprobante_*.ext   ← método listo, no se usa

configuracion_costos (vigente)
anuncios, eventos, menu_maternal
clases_extracurriculares + participantes
bitacora_gastos
conversaciones + mensajes_chat
roles / permisos / roles_permisos / usuarios_permisos
```

Pagos: `fecha_vencimiento` (no `fecha_limite`), `estatus`, `monto_pagado`, `tipo_pago`, `recibido_por_nombre`.  
SQL: el repo creció a parches. No asumas que todos los `FIX_*.sql` están en prod. Código Flutter **manda**: si el campo no está, `fromJson` debe tolerarlo.

RLS: padres solo hijos; staff según rol. Deletes a veces `.select()` para detectar “0 filas” silencioso.

---

## 7. Flujos que no rompas

1. **Alta alumno** → insert → generar colegiaturas del plan → si falla, borrar alumno.  
2. **Acreditar** → abono → actualizar `monto_pagado`/`estatus` → PDF recibo.  
3. **Chat** → una row `conversaciones` por padre → mensajes Realtime.  
4. **Padre con adeudo** → `/padre/adeudo` + chat; no le abras el resto.  
5. **Recogida** → solicitud padre → panel escuela → `control_salidas`.  
6. **Entrevista** → alumno correcto + padre del alumno + PDF.  
7. **Login profesora** → dashboard staff filtrado por grado, **nunca** dashboard padre.

---

## 8. Playbook de cambio (cualquier módulo)

1. Traduce el WhatsApp de Viri a: **pantalla + dato + default**.  
2. Localiza con este mapa. No copies pantallas enteras.  
3. Cálculos → `utils/*_helpers` + test. UI → screen/widget existente.  
4. Paleta: `AppColors.morado` / rosa / `exitoPago` / `errorPago`. Bordes 12–16. Chips.  
5. **iOS:** SafeArea, FAB vs último card, teclado vs AppBar, hit target ≥ 44 pt, no pidas cámara nueva sin `Info.plist`.  
6. **Android:** back = pop, no `go()` a ciegas; teclado decimal con formatter.  
7. SQL nuevo solo como `ADD_*.sql` + parseo tolerante.  
8. Tests del módulo que tocaste. **No “arregles”** `test/routes/app_router_test.dart` (`appRouter` no inicializado).  
9. Build para Viri: sube `+N` en `pubspec.yaml`.  
10. Commit en español, estilo repo: `Pagos: …` / `Chat padres: …` / `Arregla mensaje masivo: …`

### No hagas esto

- Riverpod / Bloc / “clean architecture”  
- Extraer pantallas de 2k líneas sin pedirlo  
- Default de filtros pagos → `todos`  
- Sumar insc+seguro en cotización **sin** chip  
- Reactivar galería  
- Cablear `subirComprobantePago` o `RegistrarAbonoScreen`  
- Poner credenciales reales en `twilio_config.dart`  
- Commitear `GeneratedPluginRegistrant.java`, `google-services.json`, `GoogleService-Info.plist`, secrets  
- `commit --amend` / force push a `main`

---

## 9. Verificación por tipo de cambio

| Tocaste… | Prueba mínima (iOS + Android en la cabeza; corre la que tengas) |
|----------|------------------------------------------------------------------|
| Login / router | Login directora → `/directora`. Login padre → `/padre`. Inactivo no entra |
| Drawer | iPad: menú no se queda en spinner. Chat visible para directora |
| Alumnos | Crear kínder genera N mensualidades. Maternal no inventa plan 12 |
| Pagos / filtros | Vencidos = 43-ish. Todos = todos. **Sin** recuadro de planes. Config: chips default off + anticipado/recargo |
| Acreditar | Desde Pagos → `/acreditar-pago/:id`. Abono + lista refresca + PDF. **No** abras `RegistrarAbonoScreen` |
| Excel pagos / gastos | Pagos AppBar y Bitácora gastos: generar → compartir o guardar |
| Foto alumno | Crear/editar alumno: cámara o galería; sale en cards. Bucket `fotos` |
| Chat | Enviar ambos lados. Fuera de horario bloquea padre. Lista no leídos |
| Bitácora | Staff escribe; padre ve el mismo día |
| Recogida | Padre solicita; dashboard sheet; no rompas el tile |
| Portage | Abrir alumno → evaluar → no pierdas items |
| Entrevista | Crear con `alumnoId`; PDF |
| Push | No rompas token FCM al login |
| Padre adeudo | Solo adeudo + chat |

---

## 10. Prompt para el siguiente ticket

```
Contexto: app Flutter CAIPI. Lee OPENCODE.md (toda la app). Cambio menor. No refactorices.

Ticket (literal):
"""
<pegar WhatsApp de Viri o el dueño>
"""

1. Identifica módulo + pantalla + default.
2. Mínimo de archivos.
3. Lógica en helpers + test si hay cálculo.
4. iOS (iPad tableta) y Android.
5. Al final: archivos, cómo probar, si hay que subir +N.
```

---

## 11. Docs: cuáles leer

| Archivo | Uso |
|---------|-----|
| **Este `OPENCODE.md`** | Toda la app **tal como está** en `1.0.8+4009` |
| `DOCUMENTACION_HANDOFF_SISTEMA.md` | Historia / SQL de clon (julio 2026; versión y “iOS 10%” desactualizados) |
| `ADD_PLANES_ANTICIPADO_RECARGO.sql` | Columnas cotización (opcionales; la app funciona sin ellas) |
| `ADD_PLAN_11_Y_CUADRO_COLEGIATURAS.sql` | Plan 11 + cuadro solo colegiaturas |
| `ADD_DOS_PADRES_POR_ALUMNO.sql` | Tabla `alumnos_padres` |
| `INSTRUCCIONES_PUSH_SERVIDOR.md` | Edge Function notify-chat |
| `GUIA_PAGOS_PARCIALES.md` | Habla de `RegistrarAbonoScreen` — **desactualizado**. El flujo real es Acreditar |
| `*.md` Firebase / `MODULOS_PENDIENTES.md` / `EJECUTAR_AHORA_*` | Ruido. No |

Fin. Conoce toda la escuela; cambia solo el salón que te pidieron.
