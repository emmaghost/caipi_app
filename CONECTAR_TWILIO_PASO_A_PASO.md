# 📱 CONECTAR TWILIO WHATSAPP - PASO A PASO

## ✅ **OBTENER CREDENCIALES DE TWILIO**

---

### **PASO 1: Ir a la consola de Twilio**

1. Abre tu navegador
2. Ve a: **https://console.twilio.com**
3. Login con tu cuenta

---

### **PASO 2: Copiar Account SID**

En el Dashboard principal verás un recuadro que dice:

En el panel verás **Account SID** (empieza con `AC`, ~34 caracteres) y **Auth Token** (tras pulsar *Show*). Cópialos a mano; no pegues credenciales reales en archivos que vayan a Git.

**Acción:**
- Click en el **Account SID** para copiarlo
- Guárdalo temporalmente en un bloc de notas

---

### **PASO 3: Copiar Auth Token**

1. En el mismo recuadro, busca **"Auth Token"**
2. Click en el botón **"Show"** (🔓)
3. Te pedirá verificación (SMS o email)
4. Una vez verificado, verás el token completo
5. Click para copiar el **Auth Token**
6. Guárdalo en tu bloc de notas

El Auth Token son 32 caracteres hexadecimales (Twilio te lo muestra al pulsar *Show*).

---

### **PASO 4: Obtener número de WhatsApp**

#### **Opción A: Sandbox (Pruebas) - RECOMENDADO PARA EMPEZAR**

1. En el menú izquierdo de Twilio, busca:
   - **Messaging** → **Try it out** → **Send a WhatsApp message**

2. Verás algo como:

```
╔════════════════════════════════════════╗
║  WhatsApp Sandbox                      ║
╠════════════════════════════════════════╣
║  Your Sandbox Number:                  ║
║  +1 415 523 8886                       ║  ← ESTE ES EL NÚMERO
╠════════════════════════════════════════╣
║  Join Code:                            ║
║  join pretty-mountain                  ║  ← ESTE ES TU CÓDIGO
╚════════════════════════════════════════╝
```

**Tu número de sandbox es:** `+1 415 523 8886` (formato para código: `+14155238886`)

3. **IMPORTANTE:** Tú (la directora) debes unirte al sandbox:
   - Abre WhatsApp en tu celular
   - Guarda el contacto: +1 (415) 523-8886
   - Envía el mensaje: `join tu-codigo-unico`
   - Ejemplo: `join pretty-mountain`
   - Espera confirmación: "Sandbox Connected!"

#### **Opción B: Número propio (Producción)**

Si ya tienes un número de WhatsApp Business verificado:
1. Ve a: **Messaging** → **WhatsApp** → **Senders**
2. Verás tu número verificado
3. Formato: `+521234567890` (ejemplo para México)

---

## 📝 **RESUMEN DE TUS CREDENCIALES**

Deberías tener anotado (en un gestor de notas privado, no en el repo):

- Account SID, Auth Token (consola Twilio)
- Número sandbox de WhatsApp y el texto *join …* que te indique Twilio

---

## 🔧 **PEGAR CREDENCIALES EN LA APP**

### **PASO 5: Abrir archivo de configuración**

1. En VS Code / Cursor, abre:
   ```
   lib/config/twilio_config.dart
   ```

2. Verás algo así:

```dart
class TwilioConfig {
  static const String accountSid = 'TU_ACCOUNT_SID_AQUI';
  static const String authToken = 'TU_AUTH_TOKEN_AQUI';
  static const String whatsappNumber = 'whatsapp:+14155238886';
  static const bool isSandbox = true;
}
```

---

### **PASO 6: Reemplazar credenciales**

**Reemplaza** `TU_ACCOUNT_SID_AQUI` y `TU_AUTH_TOKEN_AQUI` por los valores que copiaste de Twilio.

**Importante:** deja las comillas simples; no subas este archivo con credenciales reales a un repo público.

---

### **PASO 7: Configurar número de WhatsApp**

#### **Si usas Sandbox (recomendado para empezar):**

```dart
static const String whatsappNumber = 'whatsapp:+14155238886';
static const bool isSandbox = true; // Déjalo en true
```

#### **Si usas número propio (producción):**

```dart
static const String whatsappNumber = 'whatsapp:+521234567890'; // Tu número
static const bool isSandbox = false; // Cambia a false
```

---

### **PASO 8: Guardar archivo**

1. Guarda el archivo: `Ctrl + S`
2. Verifica que no haya errores de sintaxis

---

## 🚀 **PROBAR LA CONEXIÓN**

### **PASO 9: Reinstalar app**

```powershell
# Si la app está corriendo, detenerla (Ctrl+C)
flutter run
```

---

### **PASO 10: Unirse al Sandbox (Solo si usas Sandbox)**

**Antes de probar, DEBES unirte al sandbox:**

1. Abre WhatsApp en tu celular
2. Agregar contacto: +1 (415) 523-8886
3. Enviar mensaje: `join tu-codigo-unico`
   - Ejemplo: `join pretty-mountain`
4. Esperar respuesta: "Sandbox Connected!" ✅

**NOTA:** Esto solo se hace UNA VEZ por cada teléfono.

---

### **PASO 11: Probar envío de mensaje**

1. En la app, ve al menú lateral
2. Click en **"🧪 Prueba WhatsApp"**
3. Llenar:
   - **Tu número (10 dígitos):** 5551234567
   - **Mensaje:** Hola, esta es una prueba
4. Click **"Enviar Mensaje de Prueba"**

**Si todo está bien, verás:**
- ✅ "Mensaje enviado correctamente"
- Recibirás el mensaje en WhatsApp

---

## ❌ **SOLUCIÓN DE PROBLEMAS**

### **Error: "Twilio no está configurado"**

**Solución:**
- Verifica que pegaste correctamente el `accountSid` y `authToken`
- No deben quedar los textos: `TU_ACCOUNT_SID_AQUI` o `TU_AUTH_TOKEN_AQUI`
- Reinicia la app: `flutter run`

---

### **Error: "Failed to send message" (código 21408)**

**Problema:** No estás unido al sandbox.

**Solución:**
1. Abre WhatsApp
2. Envía: `join tu-codigo` al número +1 (415) 523-8886
3. Espera confirmación
4. Intenta de nuevo

---

### **Error: "Invalid phone number"**

**Problema:** Formato incorrecto del número.

**Solución:**
- Usa 10 dígitos sin espacios: `5551234567`
- No agregues `+52` ni otros prefijos
- La app lo formatea automáticamente

---

### **Error: "Authentication failed" (código 20003)**

**Problema:** Account SID o Auth Token incorrectos.

**Solución:**
1. Ve a Twilio Console
2. Copia de nuevo el Account SID y Auth Token
3. Pégalos correctamente en `twilio_config.dart`
4. Guarda y reinicia la app

---

## 🎯 **CHECKLIST DE VERIFICACIÓN**

Antes de probar, verifica:

- [ ] Copiaste el **Account SID** de Twilio Console
- [ ] Copiaste el **Auth Token** de Twilio Console (mostrando el token)
- [ ] Pegaste ambos en `lib/config/twilio_config.dart`
- [ ] Guardaste el archivo (`Ctrl + S`)
- [ ] Reiniciaste la app (`flutter run`)
- [ ] **Si usas Sandbox:** Te uniste enviando `join codigo` por WhatsApp
- [ ] Esperaste confirmación "Sandbox Connected!"
- [ ] Probaste enviar mensaje desde "🧪 Prueba WhatsApp"

---

## 📊 **EJEMPLO COMPLETO**

### **Archivo: `lib/config/twilio_config.dart`**

```dart
class TwilioConfig {
  // ✅ CREDENCIALES REALES (ejemplo)
  static const String accountSid = 'AC1a2b3c4d5e6f7g8h9i0j1k2l3m4n5o6p';
  static const String authToken = '1234567890abcdef1234567890abcdef';
  
  // ✅ SANDBOX (para pruebas)
  static const String whatsappNumber = 'whatsapp:+14155238886';
  static const bool isSandbox = true;
  
  // O para PRODUCCIÓN:
  // static const String whatsappNumber = 'whatsapp:+525551234567';
  // static const bool isSandbox = false;
  
  // ... resto del archivo sin cambios
}
```

---

## 🎉 **¡LISTO!**

Si seguiste todos los pasos:
- ✅ Twilio está conectado
- ✅ Puedes enviar WhatsApp desde la app
- ✅ Puedes probar con "🧪 Prueba WhatsApp"

---

## 🚀 **SIGUIENTE:**

Una vez que funcione el WhatsApp:
1. Enviar recibos de pago automáticamente
2. Notificar a padres cuando se crea un evento
3. Alertas de pagos próximos a vencer

**¿Quieres que implemente los recibos en PDF primero?** 🧾
