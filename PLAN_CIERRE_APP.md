# PLAN DE CIERRE — App CAIPI al toque

Objetivo: dejar la app **servicial** para pruebas reales (APK) con:
1. Roles / permisos bien
2. Chat por horario escolar
3. Notificaciones push (Android gratis con FCM)
4. Escáner QR (siguiente bloque)
5. iOS / Play Store después (cuentas de pago)

---

## Orden de trabajo

| Fase | Qué | Quién | Estado |
|------|-----|-------|--------|
| **A** | Roles + router + staff vs padre | Agente (código) | ✅ Hecho |
| **B** | Chat horario Lun–Vie (configurable) | Agente | ✅ Hecho (falta que tú corras el SQL) |
| **C** | Push FCM Android (gratis) | Gradle + JSON + token en app | ✅ Cliente listo · falta SQL + prueba / envío servidor |
| **D** | Escáner QR puerta | Agente | Pendiente |
| **E** | Guards permisos finos en cada pantalla + SQL canónico | Agente | Parcial (router + drawer); pantallas después |
| **F** | iOS push + App Store / Play | Tú (cuentas) + agente | Después |

---

## LO QUE TÚ HACES (Firebase push — gratis en pruebas)

### Paso 1 — Crear proyecto Firebase (5–10 min)

1. Entra a https://console.firebase.google.com/ con tu Gmail  
2. **Agregar proyecto** → nombre ej. `caipi-escuela`  
3. Desactiva Google Analytics si quieres (opcional) → Crear  

### Paso 2 — Agregar app Android

1. En el proyecto → **Agregar app** → icono Android  
2. **Nombre del paquete (obligatorio exacto):**  
   `com.escuela.caipi`  
3. Apodo: `CAIPI`  
4. **No hace falta** SHA-1 para push básico en APK de prueba  
5. Descargar **`google-services.json`**

### Paso 3 — Qué me pasas (importante)

Pásame / deja en el proyecto:

| Archivo / dato | Dónde |
|----------------|--------|
| `google-services.json` | Lo pongo en `android/app/google-services.json` (puedes pegarlo en el chat o copiarlo a esa ruta) |
| Confirmación | “Ya creé el proyecto Firebase y la app Android” |

**No necesitas pasarme** contraseñas de Google.  
**No subas** a chat público la *service account* privada si no hace falta aún; para el primer envío desde Edge Function sí hará falta después una clave de servidor (te digo cuándo).

### Paso 4 — En el celular de prueba

1. Instalar el APK nuevo que compilemos después  
2. Aceptar permiso de **notificaciones** cuando salga  
3. Login como padre y como directora  
4. Probar: mensaje de chat → debe sonar aviso con app cerrada  

### Lo que NO necesitas ahora

- Apple Developer (solo iOS)  
- Pagar Firebase  
- Cuenta de Google Play (solo cuando publiquen en la tienda)  
- Pusher.com  

---

## LO QUE HAGO YO (código)

### A — Roles (ya empezando)
- `esStaff` = directora \| profesor \| profesor_admin  
- Router: staff → `/directora`, padre → `/padre` (profesora ya no cae en padres)  
- Drawer: sin fallback “dar todos los permisos”  
- Documentar permisos pendientes de SQL único  

### B — Chat horario
- Config (ej. 08:00–16:00, Lun–Vie, zona México)  
- Padre no envía fuera de horario (banner claro)  
- Escuela puede responder siempre (o mismo horario; default: escuela siempre)  
- SQL + pantalla config para directora  

### C — Push (cuando me pases `google-services.json`)
- Paquetes `firebase_core` + `firebase_messaging`  
- Tabla `device_tokens` en Supabase  
- Registrar token al login  
- Enviar push en: chat nuevo, solicitud recogida (y luego pagos/anuncios)  
- Edge Function o ruta segura para disparar FCM  

### D — QR escáner
- Cámara en staff + validar código + ligar a control salida  

---

## Definición de “al toque” para las pruebas actuales

- [ ] Profesora entra a dashboard de escuela, no de padre  
- [ ] Padre no ve menús de admin  
- [ ] Chat solo en horario (padre)  
- [ ] Notificación push Android con app cerrada (chat o recogida)  
- [ ] APK nuevo repartido a quien ya está probando  

---

## Contacto rápido (cópialo cuando termines Firebase)

```
Listo Firebase.
- Proyecto: _______________
- Package: com.escuela.caipi
- Archivo: google-services.json (adjunto / ya en android/app/)
Sigue con push + lo que falte del plan.
```

---

*Actualizar este archivo conforme se cierren fases.*
