# 📱 GUÍA COMPLETA DE NOTIFICACIONES - CAIPI

## ✅ **LO QUE YA ESTÁ IMPLEMENTADO:**

1. ✅ Servicio de notificaciones (`NotificationService`)
2. ✅ Inicialización automática en `main.dart`
3. ✅ Permisos solicitados al inicio
4. ✅ Integrado con `Provider` para uso global

---

## 🎯 **TIPOS DE NOTIFICACIONES DISPONIBLES:**

### 1️⃣ **Notificación de Pago Pendiente**
```dart
notificationService.notificarPagoPendiente(
  nombreAlumno: 'Juan Pérez',
  mes: 'Enero 2026',
  monto: 500.00,
);
```
**Resultado:** "💰 Pago Pendiente - Juan Pérez tiene pendiente el pago de Enero 2026 ($500.00)"

---

### 2️⃣ **Notificación de Pago Vencido**
```dart
notificationService.notificarPagoVencido(
  nombreAlumno: 'María García',
  mes: 'Diciembre 2025',
  diasVencidos: 15,
);
```
**Resultado:** "🚨 Pago Vencido - María García: Pago de Diciembre 2025 vencido hace 15 días"

---

### 3️⃣ **Notificación de Incidente Grave**
```dart
notificationService.notificarIncidenteGrave(
  nombreAlumno: 'Pedro López',
  titulo: 'Golpe en la cabeza',
  nivel: 4,
);
```
**Resultado:** "⚠️ Incidente Nivel 4 - Pedro López: Golpe en la cabeza"

---

### 4️⃣ **Notificación de Nuevo Anuncio**
```dart
notificationService.notificarNuevoAnuncio(
  titulo: 'Junta de padres el viernes',
  esUrgente: true,
);
```
**Resultado:** "🔔 Anuncio Urgente - Junta de padres el viernes"

---

### 5️⃣ **Notificación de Nuevo Evento**
```dart
notificationService.notificarNuevoEvento(
  titulo: 'Festival de primavera',
  fecha: DateTime(2026, 3, 20),
);
```
**Resultado:** "📅 Nuevo Evento - Festival de primavera - 20/3/2026"

---

### 6️⃣ **Notificación de Recordatorio**
```dart
notificationService.notificarRecordatorio(
  titulo: 'Traer uniforme',
  mensaje: 'Mañana es presentación de danza',
);
```
**Resultado:** "⏰ Recordatorio - Traer uniforme: Mañana es presentación de danza"

---

## 💡 **CÓMO USAR EN TUS PANTALLAS:**

### **Ejemplo 1: Notificar al acreditar un pago**

En `acreditar_pago_screen.dart`:

```dart
import 'package:provider/provider.dart';
import '../../services/notification_service.dart';

// ...dentro de tu función de acreditar pago:
Future<void> _acreditarPago() async {
  try {
    // Tu lógica actual para acreditar...
    await supabaseService.marcarPagoComoPagado(...);
    
    // NUEVO: Enviar notificación
    final notificationService = context.read<NotificationService>();
    await notificationService.showNotification(
      id: DateTime.now().millisecond,
      title: '✅ Pago Acreditado',
      body: 'El pago de ${pago.mes} ha sido registrado exitosamente',
    );
    
    // Mostrar SnackBar...
  } catch (e) {
    // ...
  }
}
```

---

### **Ejemplo 2: Notificar al crear un incidente grave**

En `crear_incidente_screen.dart`:

```dart
Future<void> _guardarIncidente() async {
  try {
    // Guardar incidente...
    await supabaseService.crearIncidente(...);
    
    // NUEVO: Si es nivel 4 o 5, notificar
    if (nivel >= 4) {
      final notificationService = context.read<NotificationService>();
      await notificationService.notificarIncidenteGrave(
        nombreAlumno: alumnoSeleccionado.nombreCompleto,
        titulo: tituloController.text,
        nivel: nivel,
      );
    }
    
    // Navegar...
  } catch (e) {
    // ...
  }
}
```

---

### **Ejemplo 3: Notificar al crear un anuncio**

En `crear_anuncio_screen.dart`:

```dart
Future<void> _guardarAnuncio() async {
  try {
    // Guardar anuncio...
    await supabaseService.crearAnuncio(...);
    
    // NUEVO: Notificar a padres
    final notificationService = context.read<NotificationService>();
    await notificationService.notificarNuevoAnuncio(
      titulo: tituloController.text,
      esUrgente: prioridad == PrioridadAnuncio.alta,
    );
    
    // Navegar...
  } catch (e) {
    // ...
  }
}
```

---

## 🔔 **NOTIFICACIONES AUTOMÁTICAS DE PAGOS VENCIDOS:**

### **Opción A: Verificar al entrar a la app (Recomendado)**

En `dashboard_padre.dart` o `dashboard_directora.dart`:

```dart
@override
void initState() {
  super.initState();
  _verificarPagosVencidos();
}

Future<void> _verificarPagosVencidos() async {
  final supabaseService = context.read<SupabaseService>();
  final notificationService = context.read<NotificationService>();
  
  // Obtener pagos pendientes
  final pagos = await supabaseService.obtenerPagos();
  final hoy = DateTime.now();
  
  for (final pago in pagos) {
    if (!pago.pagado && pago.fechaLimite.isBefore(hoy)) {
      final diasVencidos = hoy.difference(pago.fechaLimite).inDays;
      
      // Notificar solo si está vencido hace 1, 7, 15, 30 días (para no saturar)
      if ([1, 7, 15, 30].contains(diasVencidos)) {
        await notificationService.notificarPagoVencido(
          nombreAlumno: pago.alumnoNombre,
          mes: pago.mes,
          diasVencidos: diasVencidos,
        );
      }
    }
  }
}
```

---

### **Opción B: Función Cloud (Avanzado - requiere Supabase Edge Functions)**

Crear una función que se ejecute diariamente y envíe notificaciones:

```typescript
// supabase/functions/notificar-pagos/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

serve(async (req) => {
  // Consultar pagos vencidos
  // Enviar notificaciones push/email
  return new Response(JSON.stringify({ success: true }))
})
```

---

## 🎨 **PERSONALIZAR NOTIFICACIONES:**

### **Cambiar el canal de notificaciones:**

En `notification_service.dart`, modifica:

```dart
const AndroidNotificationDetails(
  'caipi_channel',  // ID único
  'CAIPI Notificaciones',  // Nombre visible
  channelDescription: 'Notificaciones del Sistema Escolar CAIPI',
  importance: Importance.high,  // Alta, Media, Baja
  priority: Priority.high,
  showWhen: true,
  playSound: true,  // Activar sonido
  enableVibration: true,  // Activar vibración
);
```

---

### **Agregar sonido personalizado:**

1. Coloca tu archivo `.mp3` en `android/app/src/main/res/raw/mi_sonido.mp3`
2. Modifica `AndroidNotificationDetails`:

```dart
sound: RawResourceAndroidNotificationSound('mi_sonido'),
```

---

### **Cambiar el ícono:**

1. Crea un ícono blanco y negro en `android/app/src/main/res/drawable/`
2. Modifica `AndroidInitializationSettings`:

```dart
const AndroidInitializationSettings('@drawable/mi_icono');
```

---

## 📊 **ESTADÍSTICAS Y TRACKING:**

### **Contar notificaciones enviadas:**

```dart
// En tu servicio o dashboard
Future<int> contarNotificacionesEnviadas() async {
  return await supabaseService.getNotificaciones().length;
}
```

---

## 🚨 **PROBLEMAS COMUNES:**

### **Las notificaciones no aparecen**
**Solución:**
1. Verifica que solicitaste permisos:
```dart
final permisos = await notificationService.areNotificationsEnabled();
if (!permisos) {
  await notificationService.requestPermissions();
}
```

### **Error: MissingPluginException**
**Solución:**
```bash
flutter clean
flutter pub get
flutter run
```

### **No funcionan en iOS**
**Solución:**
1. Abre `ios/Runner/Info.plist`
2. Agrega:
```xml
<key>UIBackgroundModes</key>
<array>
  <string>remote-notification</string>
</array>
```

---

## 📱 **NOTIFICACIONES PUSH (Firebase Cloud Messaging)**

Para notificaciones incluso cuando la app está cerrada:

### **Pasos:**
1. Agregar `firebase_messaging` al `pubspec.yaml`
2. Configurar Firebase Console
3. Agregar certificados iOS/Android
4. Integrar con Supabase Edge Functions

**¿Quieres que implemente FCM completo?** Avísame.

---

## ✅ **RESUMEN:**

| Tipo | Cuándo usar | Ya implementado |
|------|-------------|-----------------|
| Pago pendiente | Al acercarse fecha límite | ✅ |
| Pago vencido | Cuando pasa la fecha | ✅ |
| Incidente grave | Nivel 4-5 | ✅ |
| Nuevo anuncio | Al publicar | ✅ |
| Nuevo evento | Al crear | ✅ |
| Recordatorio | Personalizado | ✅ |

---

## 🎯 **PRÓXIMOS PASOS:**

1. ✅ Configurar templates de email en Supabase (ya lo tienes)
2. ✅ Inicializar NotificationService (ya lo tienes)
3. ⏳ Agregar llamadas en pantallas clave
4. ⏳ Implementar verificación automática de pagos vencidos
5. ⏳ (Opcional) Implementar FCM para notificaciones push

---

**¿Listo para probar?** Corre la app con `flutter run` y prueba las notificaciones! 🚀
