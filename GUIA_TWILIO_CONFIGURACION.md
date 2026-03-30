# 📱 GUÍA COMPLETA: CONFIGURAR TWILIO PARA WHATSAPP

## ✅ **RESUMEN RÁPIDO:**

**Costo:** $10-30 pesos/mes para CAIPI  
**Tiempo de configuración:** 20 minutos  
**Ventaja:** Envío 100% automático

---

## 🚀 **PASO 1: CREAR CUENTA TWILIO (5 min)**

### **1.1 Registrarse**

1. Ve a: **https://www.twilio.com/try-twilio**
2. Click en **"Sign up"**
3. Llena el formulario:
   ```
   First Name: Tu nombre
   Last Name: Tu apellido
   Email: tu@email.com
   Password: (contraseña segura)
   ```
4. Acepta términos y da click en **"Start your free trial"**

### **1.2 Verificar Email**

1. Revisa tu correo
2. Click en el enlace de verificación
3. Regresa a Twilio Console

### **1.3 Verificar Teléfono**

1. Twilio te pedirá verificar tu número de teléfono
2. Ingresa tu número (con código +52 para México):
   ```
   +52 55 1234 5678
   ```
3. Recibirás un SMS con código
4. Ingresa el código
5. ✅ **Recibes $15 USD de crédito gratis** 🎁

---

## 📱 **PASO 2: ACTIVAR WHATSAPP SANDBOX (3 min)**

El sandbox te permite probar WhatsApp GRATIS antes de comprar un número.

### **2.1 Ir a WhatsApp Sandbox**

1. En Twilio Console, ve a:
   ```
   Messaging → Try it out → Send a WhatsApp message
   ```
2. O busca: **"WhatsApp Sandbox"** en la barra de búsqueda

### **2.2 Unirse al Sandbox**

Verás algo como esto:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
WhatsApp Sandbox

To connect, send this message:
join <código-aleatorio-123>

To WhatsApp number:
+1 (415) 523-8886
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Desde tu WhatsApp personal:**

1. Abre WhatsApp
2. Crea un nuevo chat al número: **+1 (415) 523-8886**
3. Envía exactamente: **join <el-código-que-te-mostraron>**
4. Espera la respuesta: **"Joined twilio-sandbox"** ✅

**Listo**, tu número ya puede recibir mensajes del sandbox.

### **2.3 Conectar más números (Padres de familia)**

Cada padre debe hacer lo mismo:

1. Guardar: **+1 (415) 523-8886** en sus contactos
2. Enviar: **join <código>** por WhatsApp
3. Esperar confirmación

**Esto solo se hace UNA VEZ por teléfono.**

---

## 🔑 **PASO 3: OBTENER CREDENCIALES (2 min)**

### **3.1 Ir a Account Info**

1. En Twilio Console, busca el panel derecho
2. Verás: **"Account Info"**

### **3.2 Copiar 3 datos importantes:**

```
┌─────────────────────────────────────────┐
│ ACCOUNT SID                             │
│ ACxxxxxxxxxxxxxxxxxxxxxxxxxxxx          │
│ [Copiar]                                │
├─────────────────────────────────────────┤
│ AUTH TOKEN                              │
│ ●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●      │
│ [Show] [Copy]                           │
└─────────────────────────────────────────┘
```

**Copia estos 3 datos a un lugar seguro:**

1. ✅ **Account SID:** `ACxxxxxxxxxxxxxxxxxxxxxxxxxxxx`
2. ✅ **Auth Token:** `xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx` (da click en "Show" primero)
3. ✅ **WhatsApp Number:** `+1 415 523 8886` (el de sandbox)

---

## 💻 **PASO 4: CONFIGURAR EN LA APP (5 min)**

### **4.1 Abrir archivo de configuración**

Abre el archivo:
```
C:\laragon\www\app-caipi\lib\config\twilio_config.dart
```

### **4.2 Pegar tus credenciales**

Busca estas líneas y reemplaza:

```dart
// ANTES:
static const String accountSid = 'TU_ACCOUNT_SID_AQUI';
static const String authToken = 'TU_AUTH_TOKEN_AQUI';

// DESPUÉS (con tus datos reales):
static const String accountSid = 'AC1234567890abcdef1234567890abcd';
static const String authToken = 'abc123def456ghi789jkl012mno345pq';
```

**Ejemplo completo:**

```dart
class TwilioConfig {
  // Tus credenciales reales de Twilio
  static const String accountSid = 'AC1234567890abcdef1234567890abcd';
  static const String authToken = 'abc123def456ghi789jkl012mno345pq';
  
  // Número de WhatsApp (sandbox)
  static const String whatsappNumber = 'whatsapp:+14155238886';
  
  // Modo sandbox activado (cambiar a false en producción)
  static const bool isSandbox = true;
  
  // ... resto del código ...
}
```

### **4.3 Guardar el archivo**

Guarda los cambios: **Ctrl + S**

---

## 🧪 **PASO 5: PROBAR QUE FUNCIONA (5 min)**

### **5.1 Instalar dependencias**

En la terminal:

```powershell
cd C:\laragon\www\app-caipi
flutter pub get
```

Espera que termine de descargar paquetes.

### **5.2 Reiniciar la app**

```powershell
# Si ya está corriendo, presiona 'R'
# O ejecuta:
flutter run
```

### **5.3 Hacer prueba**

1. **Login como Directora**
2. Ve a: **Pagos**
3. Busca un pago pendiente
4. Click en el pago
5. **Nuevo botón:** **"📱 Notificar por WhatsApp"**
6. Da click

**¿Qué debe pasar?**

- ✅ Mensaje de "Enviando WhatsApp..."
- ✅ Después de 2-3 segundos: "✅ WhatsApp enviado"
- ✅ **El padre recibe el mensaje en WhatsApp automáticamente**

---

## 💰 **COSTOS Y PRODUCCIÓN**

### **Sandbox (Pruebas) - GRATIS**

- ✅ $15 USD de crédito gratis
- ✅ ~1,500 mensajes gratis
- ❌ Requiere que cada padre se una (envíe "join <código>")
- ⏱️ Dura 2-3 meses para CAIPI

### **Producción (Después del crédito)**

Cuando se acabe el crédito gratis:

1. **Recargar cuenta:**
   - Mínimo: $20 USD (~$400 pesos)
   - Twilio → Billing → Add funds

2. **Costo por mensaje:**
   - $0.005 USD por mensaje (~$0.10 pesos)
   - 30 padres × 4 mensajes/mes = 120 mensajes
   - **Costo mensual: $12 pesos**

3. **Quitar sandbox (opcional):**
   - Solicitar número de WhatsApp Business
   - Costo: $1.50 USD/mes extra (~$30 pesos/mes)
   - Ventaja: Los padres NO necesitan enviar "join"

---

## 🎯 **DÓNDE SE USA EN LA APP**

Ya implementé el botón **"Notificar por WhatsApp"** en:

### **1. Pagos** ✅
```
[Ver pago] → [📱 Notificar Pago]
→ Envía mensaje de pago pendiente al padre
```

### **2. Eventos** ✅
```
[Crear evento] → [📱 Notificar a Padres]
→ Envía recordatorio a todos los padres del grado
```

### **3. Incidentes** ✅
```
[Registrar incidente] → [📱 Notificar Incidente]
→ Envía alerta de incidente al padre del alumno
```

### **4. Bitácoras** ✅
```
[Ver bitácora] → [📱 Enviar Bitácora]
→ Envía resumen del día al padre
```

---

## ⚠️ **PREGUNTAS FRECUENTES**

### **¿Puedo usar mi propio número de WhatsApp?**

No directamente. Twilio requiere:
- WhatsApp Business API (verificación de negocio)
- Proceso de aprobación (1-2 semanas)
- Costo adicional: $1.50 USD/mes

Para empezar, usa el **sandbox** (gratis).

### **¿Los padres SIEMPRE deben enviar "join"?**

Solo en modo **sandbox** (pruebas). 

Para producción (sin "join"):
1. Solicitar número de WhatsApp Business en Twilio
2. Cambiar en `twilio_config.dart`: `isSandbox = false`
3. Costo: +$1.50 USD/mes

### **¿Cuándo se me acaba el crédito gratis?**

- Tienes $15 USD gratis (~1,500 mensajes)
- Con 30 padres y 4 mensajes/mes = 120 mensajes/mes
- **Te dura ~12 meses** sin pagar nada

### **¿Qué pasa si se acaba el crédito?**

- Los mensajes dejan de enviarse
- La app mostrará: "Error: Insufficient balance"
- Debes recargar mínimo $20 USD en Twilio

### **¿Puedo ver cuánto crédito me queda?**

Sí, en Twilio Console:
```
Account → Usage → Current Balance
```

Verás algo como: **$14.87 USD**

---

## ✅ **CHECKLIST DE VERIFICACIÓN**

Antes de usar en producción, verifica:

- [ ] Cuenta Twilio creada
- [ ] Email verificado
- [ ] Teléfono verificado
- [ ] $15 USD de crédito gratis recibidos
- [ ] WhatsApp Sandbox activado
- [ ] Tu número conectado al sandbox (enviaste "join")
- [ ] Account SID copiado
- [ ] Auth Token copiado
- [ ] Credenciales pegadas en `twilio_config.dart`
- [ ] `flutter pub get` ejecutado
- [ ] App reiniciada
- [ ] Mensaje de prueba enviado exitosamente
- [ ] Mensaje recibido en WhatsApp

---

## 🆘 **SOPORTE**

### **Error: "Account SID not found"**

- Verifica que copiaste bien el Account SID
- Debe empezar con: `AC...`

### **Error: "Authentication failed"**

- Verifica el Auth Token
- En Twilio Console → Account → Show → Copiar de nuevo

### **Error: "To number is not a valid WhatsApp number"**

- El padre debe unirse al sandbox primero
- Enviar: `join <código>` a +1 (415) 523-8886

### **No recibo mensajes**

1. Verifica que enviaste "join" correctamente
2. Revisa que el número en la app sea correcto (10 dígitos)
3. Verifica que tengas crédito en Twilio

---

## 🎉 **¡LISTO!**

Ahora tienes WhatsApp automático en CAIPI:

- ✅ Envío automático de mensajes
- ✅ Sin click manual
- ✅ Confirmaciones de entrega
- ✅ $15 USD gratis para empezar
- ✅ ~$12 pesos/mes después

**¿Dudas? Revisa esta guía paso a paso.** 📚
