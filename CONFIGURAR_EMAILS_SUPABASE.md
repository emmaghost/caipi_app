# 📧 CONFIGURAR EMAILS EN SUPABASE

## 🎯 **UBICACIÓN:**

Los emails se configuran en **Supabase**, NO en la app Flutter.

---

## 📍 **¿DÓNDE EN SUPABASE?**

### **Paso 1: Ir a Authentication**

1. Abre: [https://supabase.com/dashboard](https://supabase.com/dashboard)
2. Selecciona tu proyecto: **CAIPI**
3. En el menú lateral izquierdo: **Authentication**
4. Click en: **⚙️ Email Templates**

**Ruta completa:**
```
Dashboard → Tu Proyecto → Authentication → Email Templates
```

---

## 📧 **5 TEMPLATES QUE DEBES CONFIGURAR:**

### **1️⃣ Confirm signup** (Confirmación de registro)
**Cuándo se usa:** Cuando la directora crea un nuevo usuario (profesor/padre)

### **2️⃣ Reset password** ⭐ (Recuperar contraseña)
**Cuándo se usa:** Cuando alguien olvida su contraseña

### **3️⃣ Invite user** (Invitar usuario)
**Cuándo se usa:** Si usas invitaciones en lugar de crear cuentas

### **4️⃣ Change email** (Cambiar correo)
**Cuándo se usa:** Cuando un usuario cambia su email

### **5️⃣ Magic link** (Enlace mágico - opcional)
**Cuándo se usa:** Login sin contraseña (si lo activas)

---

## 🛠️ **CÓMO CONFIGURAR CADA EMAIL:**

### **PASO A PASO:**

1. **Authentication → Email Templates**
2. Selecciona el template (ej: "Confirm signup")
3. **Copia el contenido** de `EMAILS_5_TEMPLATES.txt`
4. **Pega en el campo** "Message Body"
5. Click **Save**
6. Repite para los otros 4 templates

⏱️ **Tiempo:** ~1 minuto por email = 5 minutos total

---

## 🎨 **PREVIEW DE LOS EMAILS:**

### **ANTES (Email por defecto de Supabase):**
```
Subject: Confirm Your Signup

Click here to confirm: [link]
```
❌ Feo y genérico

### **DESPUÉS (Con tus templates CAIPI):**
```
🎉 ¡Bienvenido a CAIPI!

Gracias por registrarte en el Sistema Escolar CAIPI.

[BOTÓN CON DEGRADADO BONITO]
✅ Confirmar mi cuenta

Sistema Escolar CAIPI 💙
```
✅ Profesional y con marca

---

## 📋 **CHECKLIST:**

### **Configuración Básica (Emails):**
- [ ] Template 1: Confirm signup
- [ ] Template 2: Reset password ⭐ (IMPORTANTE)
- [ ] Template 3: Invite user
- [ ] Template 4: Change email
- [ ] Template 5: Magic link (opcional)

### **Configuración Avanzada (Opcional):**
- [ ] Sender name: `CAIPI`
- [ ] Rate limits (límites de envío)
- [ ] Email OTP (código de 6 dígitos)

---

## ⚙️ **CONFIGURACIÓN EXTRA (OPCIONAL):**

### **1. Cambiar Nombre del Remitente:**

**Ubicación:**
```
Authentication → Settings → Email Auth
```

**Cambiar:**
- **Sender Name:** De `noreply` a `CAIPI`
- **Sender Email:** Mantener el de Supabase o usar dominio propio

**Resultado:**
```
Antes: From: noreply@mail.app.supabase.io
Después: From: CAIPI <noreply@mail.app.supabase.io>
```

---

### **2. Usar Tu Propio Dominio (PRO):**

Si tienes dominio propio (ej: `caipi.edu.mx`):

**Ubicación:**
```
Project Settings → API → Custom SMTP
```

**Configurar:**
- SMTP Host: `smtp.gmail.com` (si usas Gmail)
- Port: `587`
- Username: `tu-email@gmail.com`
- Password: Contraseña de aplicación (no tu contraseña normal)

**Beneficios:**
- ✅ Emails desde `notificaciones@caipi.edu.mx`
- ✅ Mejor reputación (menos spam)
- ✅ Más profesional

---

## 🔧 **PROBAR QUE FUNCIONA:**

### **Método 1: Crear Usuario de Prueba**

1. **Authentication → Users**
2. Click **Add user**
3. Ingresa un email de prueba (tu email personal)
4. ✅ **Send user invite email**
5. Click **Create user**
6. **Revisa tu email** → Deberías recibir el email bonito de CAIPI

---

### **Método 2: Recuperar Contraseña**

1. En la app, click **"¿Olvidaste tu contraseña?"**
2. Ingresa el email de `viri@caipi.com`
3. Click **Enviar**
4. **Revisa el email** → Deberías recibir el email de reset

---

## 📊 **COMPARACIÓN:**

| Característica | Sin Configurar | Con Templates CAIPI |
|---------------|---------------|---------------------|
| **Diseño** | Texto plano ❌ | HTML bonito ✅ |
| **Marca** | Supabase genérico | CAIPI profesional |
| **Colores** | Sin colores | Degradado azul-morado |
| **Botones** | Link simple | Botón con efecto |
| **Emojis** | Sin emojis | Con emojis 🎉 |
| **Footer** | Nada | "Sistema CAIPI 💙" |

---

## 🚨 **IMPORTANTE:**

### **Variables que DEBES mantener:**

En los templates, estas variables son automáticas de Supabase:

```
{{ .ConfirmationURL }}  ← Enlace de confirmación (NO BORRAR)
{{ .Token }}           ← Token de seguridad (NO BORRAR)
{{ .SiteURL }}         ← URL de tu app (NO BORRAR)
```

⚠️ **NO ELIMINES** estas variables, o los emails no funcionarán.

---

## 📱 **NOTIFICACIONES IN-APP:**

Las notificaciones **dentro de la app** (pagos, incidentes, anuncios) se configuran en:

### **Archivo:**
```
lib/services/notification_service.dart
```

**Ya está implementado con:**
- ✅ Notificaciones locales (en el celular)
- ✅ Sonidos y vibración
- ✅ Badge con contador

**Para activarlas:**
```dart
NotificationService().mostrarNotificacion(
  titulo: 'Pago Vencido',
  mensaje: 'El pago de Juan Pérez está vencido',
  tipo: TipoNotificacion.pago,
);
```

---

## 🔐 **SEGURIDAD DE EMAILS:**

### **Rate Limits (Límites de envío):**

**Ubicación:**
```
Authentication → Rate Limits
```

**Recomendado:**
- Email verification: **10 emails/hora** por IP
- Password reset: **5 emails/hora** por IP
- Signup: **20 registros/hora** por IP

**Esto previene:**
- ❌ Spam
- ❌ Abuso del sistema
- ❌ Costos innecesarios

---

## 💰 **COSTOS DE EMAILS:**

### **Plan Gratuito de Supabase:**
```
✅ 30,000 usuarios gratis
✅ Emails ilimitados
✅ Sin costo adicional
```

**Solo pagas si usas SMTP propio con Gmail/SendGrid**

---

## 🎯 **RECOMENDACIÓN:**

### **PARA EMPEZAR (AHORA):**

1. ✅ Configura solo **2 templates esenciales:**
   - Reset password ⭐
   - Confirm signup

2. ✅ Usa emails por defecto de Supabase (gratis)

3. ✅ Prueba que funcionen

⏱️ **Tiempo:** 2 minutos

---

### **PARA PRODUCCIÓN (DESPUÉS):**

1. ✅ Configura los 5 templates
2. ✅ Personaliza sender name
3. ✅ Configura SMTP propio (opcional)
4. ✅ Agrega dominio personalizado (opcional)

⏱️ **Tiempo:** 15 minutos

---

## 📖 **GUÍA VISUAL:**

### **1. Ir a Email Templates:**

```
┌─────────────────────────────┐
│ 🏠 Dashboard                │
│                             │
│ 📁 Tu Proyecto (CAIPI)      │
│                             │
│ 👤 Authentication      ◄──  │ Click aquí
│   ├─ Users                  │
│   ├─ Policies               │
│   └─ ⚙️ Email Templates ◄── │ Luego aquí
│                             │
└─────────────────────────────┘
```

---

### **2. Ver Lista de Templates:**

```
┌──────────────────────────────────────┐
│ Email Templates                      │
├──────────────────────────────────────┤
│ 1️⃣ Confirm signup           [Edit] │
│ 2️⃣ Reset password           [Edit] │
│ 3️⃣ Invite user              [Edit] │
│ 4️⃣ Change email address     [Edit] │
│ 5️⃣ Magic Link               [Edit] │
└──────────────────────────────────────┘
```

---

### **3. Editar Template:**

```
┌──────────────────────────────────────┐
│ Confirm signup                       │
├──────────────────────────────────────┤
│ Subject:                             │
│ [Confirm Your Signup]                │
│                                      │
│ Message Body:                        │
│ ┌────────────────────────────────┐  │
│ │ <h2>🎉 ¡Bienvenido a CAIPI!</h2│  │ ← Pega aquí
│ │ <p>Gracias por registrarte...</p│  │
│ │ ...                             │  │
│ └────────────────────────────────┘  │
│                                      │
│ [Cancel]              [💾 Save]     │
└──────────────────────────────────────┘
```

---

## 🧪 **TESTING:**

### **Test 1: Crear Usuario**
```bash
1. Authentication → Users → Add user
2. Email: tu-email@gmail.com
3. ✅ Send email invite
4. Create user
5. Revisa tu bandeja de entrada
```

### **Test 2: Reset Password**
```bash
1. En la app, click "Olvidé mi contraseña"
2. Ingresa: viri@caipi.com
3. Click Enviar
4. Revisa inbox de viri@caipi.com
```

### **Test 3: Signup (desde app)**
```bash
1. En la app, logout
2. Click "Crear cuenta"
3. Completa formulario
4. Revisa email de confirmación
```

---

## 🔍 **TROUBLESHOOTING:**

### **No me llegan los emails:**

**1. Revisa carpeta de SPAM**
- Los emails de Supabase a veces caen en spam
- Marca como "No es spam"

**2. Verifica el email sea correcto**
- Authentication → Users
- Revisa que el email esté bien escrito

**3. Revisa los logs**
- Authentication → Logs
- Busca errores de envío

**4. Verifica rate limits**
- Authentication → Rate Limits
- Puede estar bloqueado temporalmente

---

### **Los emails se ven raros (sin formato):**

**Causa:** El cliente de email no soporta HTML

**Solución:**
1. Ve a Email Templates
2. Click "Show plain text version"
3. Agrega versión de texto simple
4. Save

---

### **Quiero cambiar el Subject (asunto):**

**Ubicación:**
```
Email Templates → [Template] → Subject
```

**Ejemplos:**
```
✅ "Bienvenido a CAIPI 🎓"
✅ "Recupera tu contraseña - CAIPI"
✅ "Confirma tu cuenta CAIPI"
```

---

## 📚 **RECURSOS:**

### **Documentación Oficial:**
- [Supabase Auth Emails](https://supabase.com/docs/guides/auth/auth-email-templates)
- [SMTP Configuration](https://supabase.com/docs/guides/auth/auth-smtp)

### **Archivos del Proyecto:**
- `EMAILS_5_TEMPLATES.txt` → Contenido de los emails
- `EJECUTAR_TODO_PASO_A_PASO.md` → Incluye sección de emails

---

## ✅ **CHECKLIST FINAL:**

### **Configuración Mínima (5 min):**
- [ ] Confirm signup configurado
- [ ] Reset password configurado ⭐
- [ ] Probado con tu email personal

### **Configuración Completa (15 min):**
- [ ] Los 5 templates configurados
- [ ] Sender name cambiado a "CAIPI"
- [ ] Rate limits configurados
- [ ] Probado con usuarios reales

### **Configuración Pro (30 min):**
- [ ] SMTP propio configurado
- [ ] Dominio personalizado
- [ ] Versión texto plano agregada
- [ ] Analytics de emails configurado

---

## 🎯 **RESUMEN:**

### **¿DÓNDE?**
```
Supabase Dashboard
  → Authentication
    → Email Templates
```

### **¿QUÉ ARCHIVO COPIAR?**
```
EMAILS_5_TEMPLATES.txt
```

### **¿CUÁNTO TARDA?**
```
2 templates esenciales: 2 minutos
5 templates completos: 5 minutos
```

---

## 🚀 **COMANDO RÁPIDO:**

Si ya ejecutaste el SQL y solo falta configurar emails:

1. Abre: `EMAILS_5_TEMPLATES.txt`
2. Ve a: [https://supabase.com/dashboard](https://supabase.com/dashboard)
3. `Authentication → Email Templates`
4. Copia y pega cada template
5. Save

**¡Listo en 5 minutos!** ⚡

---

## 📞 **¿NECESITAS AYUDA?**

Si algo no funciona:
1. Copia el error exacto
2. Dime qué template estás configurando
3. Envíame screenshot de la configuración
4. Te ayudo a resolverlo

---

🎉 **¡Emails bonitos y profesionales para CAIPI!** 📧
