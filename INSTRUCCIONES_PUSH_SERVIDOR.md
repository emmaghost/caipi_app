# Push automático (chat / recogida) — qué hacer en Supabase

El código de Node que muestra Firebase **no lo uses**. Aquí va con **Edge Function**.

## Ya quedó en el repo

- Función: `supabase/functions/notify-chat/`
- Script: `tools/deploy_push_notify.ps1`
- Service account local (NO se sube a git): `secrets/firebase-service-account.json`

## Tú ejecutas (una vez)

### A) En PowerShell (desde la carpeta del proyecto)

```powershell
cd c:\laragon\www\app-caipi
.\tools\deploy_push_notify.ps1
```

Si pide login, acepta en el navegador.  
Project ref: `qxldfqnuwpucptajcazf`

### B) Webhooks en el Dashboard (obligatorio — 3 hooks)

Crea **tres** webhooks (misma función `notify-chat`):

| Nombre | Tabla | Evento | Function |
|--------|--------|--------|----------|
| `notify-chat-mensaje` | `mensajes_chat` | **Insert** | `notify-chat` |
| `notify-recogida` | `solicitudes_recogida` | **Insert** | `notify-chat` |
| `notify-pago-abono` | `abonos` | **Insert** | `notify-chat` |

Ruta: **Database → Webhooks → Create a new hook**  
Tipo: **Supabase Edge Functions** · Method: **POST**

#### Qué hace cada uno
- **Chat:** avisa al otro (padre ↔ escuela)
- **Recogida:** avisa a directora/profesoras (“padre en la entrada”)
- **Pagos (`abonos`):** cuando acreditan un pago, avisa al **padre** para abrir e **imprimir/ver recibo** (`/padre/hijo/{id}/pagos`)

Tras cambiar el código de la función, vuelve a desplegar:

```powershell
cd c:\laragon\www\app-caipi
npx supabase functions deploy notify-chat --no-verify-jwt
```

### C) Confirmar SQL de tokens

Ya debiste correr `ADD_CHAT_HORARIO_Y_PUSH_TOKENS.sql`.

## Cómo probar

1. APK/app en **celular físico** (con Google Play), login, aceptar notificaciones.  
2. En Table Editor → `device_tokens` debe haber fila.  
3. Cierra la app (o bloquea pantalla).  
4. Desde otra cuenta manda un mensaje de chat.  
5. Debe llegar la notificación.

## Emulador

Casi nunca sirve para FCM (`SERVICE_NOT_AVAILABLE`). Usa teléfono real.

## Seguridad

No compartas el JSON de service account en chats públicos ni lo subas a GitHub.  
Si se filtró, en Google Cloud puedes **rotar / desactivar** esa clave y generar otra.

---

## Si el script falla

Sube la función a mano:

```powershell
cd c:\laragon\www\app-caipi
npx supabase login
npx supabase link --project-ref qxldfqnuwpucptajcazf
# Secret (Base64 del JSON):
$b64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes("secrets\firebase-service-account.json"))
npx supabase secrets set "FIREBASE_SERVICE_ACCOUNT_B64=$b64"
npx supabase functions deploy notify-chat --no-verify-jwt
```

Luego crea el webhook del paso B.
