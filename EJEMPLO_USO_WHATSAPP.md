# 💻 EJEMPLO: CÓMO USAR WHATSAPP EN LA APP

## 📱 **Ejemplo 1: Notificar Pago Pendiente**

### **Dónde:** Pantalla de detalle de pago

```dart
import '../services/whatsapp_service.dart';

// ... en tu StatefulWidget ...

Future<void> _notificarPagoPorWhatsApp() async {
  setState(() => _enviando = true);
  
  try {
    // Obtener datos del padre
    final padre = await _obtenerDatosPadre();
    
    // Generar mensaje
    final mensaje = WhatsAppService.mensajePagoPendiente(
      nombrePadre: padre['nombre'],
      nombreAlumno: alumno.nombreCompleto,
      concepto: pago.concepto,
      monto: pago.monto.toStringAsFixed(2),
      fechaVencimiento: DateFormat('dd/MM/yyyy').format(pago.fechaVencimiento),
    );
    
    // Enviar mensaje
    final exito = await WhatsAppService.enviarMensaje(
      telefono: padre['telefono'], // Ejemplo: "5551234567"
      mensaje: mensaje,
    );
    
    if (exito && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ WhatsApp enviado correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Error al enviar WhatsApp'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  } finally {
    if (mounted) {
      setState(() => _enviando = false);
    }
  }
}

// ... en el build() ...

ElevatedButton.icon(
  onPressed: _enviando ? null : _notificarPagoPorWhatsApp,
  icon: const Icon(Icons.whatsapp, color: Colors.white),
  label: Text(_enviando ? 'Enviando...' : 'Notificar por WhatsApp'),
  style: ElevatedButton.styleFrom(
    backgroundColor: const Color(0xFF25D366), // Verde WhatsApp
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
  ),
)
```

---

## 🎉 **Ejemplo 2: Notificar Evento a Múltiples Padres**

### **Dónde:** Al crear o editar un evento

```dart
Future<void> _notificarEventoPorWhatsApp() async {
  setState(() => _enviando = true);
  
  try {
    // Obtener padres del grado seleccionado
    final padres = await _obtenerPadresDelGrado(gradoId);
    
    if (padres.isEmpty) {
      throw Exception('No hay padres en este grado');
    }
    
    // Obtener teléfonos
    final telefonos = padres
        .map((p) => p['telefono'] as String)
        .where((t) => t.isNotEmpty)
        .toList();
    
    if (telefonos.isEmpty) {
      throw Exception('Ningún padre tiene teléfono registrado');
    }
    
    // Generar mensaje
    final mensaje = WhatsAppService.mensajeEvento(
      nombrePadre: '', // Se enviará genérico
      nombreEvento: _tituloController.text,
      fecha: DateFormat('dd/MM/yyyy').format(_fecha!),
      hora: _hora!.format(context),
      lugar: _lugarController.text.isNotEmpty ? _lugarController.text : null,
      descripcion: _descripcionController.text.isNotEmpty ? _descripcionController.text : null,
    );
    
    // Mostrar diálogo de confirmación
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar envío'),
        content: Text(
          'Se enviará WhatsApp a ${telefonos.length} padres de familia.\n\n'
          '¿Continuar?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
    
    if (confirmar != true) return;
    
    // Enviar masivamente
    final resultados = await WhatsAppService.enviarMensajeMasivo(
      telefonos: telefonos,
      mensaje: mensaje,
    );
    
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('✅ Envío completado'),
          content: Text(
            'Exitosos: ${resultados['exitosos']}\n'
            'Fallidos: ${resultados['fallidos']}'
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  } finally {
    if (mounted) {
      setState(() => _enviando = false);
    }
  }
}
```

---

## 🚨 **Ejemplo 3: Notificar Incidente**

```dart
Future<void> _notificarIncidentePorWhatsApp() async {
  try {
    // Obtener padre del alumno
    final padre = await _obtenerPadrePorAlumno(alumnoId);
    
    // Generar mensaje
    final mensaje = WhatsAppService.mensajeIncidente(
      nombrePadre: padre['nombre'],
      nombreAlumno: alumno.nombreCompleto,
      tipoIncidente: tipoIncidenteNombre,
      descripcion: _descripcionController.text,
      fecha: DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()),
    );
    
    // Enviar
    final exito = await WhatsAppService.enviarMensaje(
      telefono: padre['telefono'],
      mensaje: mensaje,
    );
    
    if (exito && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Padre notificado')),
      );
    }
  } catch (e) {
    print('Error notificando incidente: $e');
  }
}
```

---

## 📝 **Ejemplo 4: Enviar Bitácora Diaria**

```dart
Future<void> _enviarBitacoraPorWhatsApp() async {
  try {
    final padre = await _obtenerPadrePorAlumno(bitacora.alumnoId);
    
    final mensaje = WhatsAppService.mensajeBitacora(
      nombrePadre: padre['nombre'],
      nombreAlumno: alumno.nombreCompleto,
      fecha: DateFormat('dd/MM/yyyy').format(bitacora.fecha),
      estadoAnimo: bitacora.estadoAnimo,
      comio: bitacora.comio ?? 'No especificado',
      pipi: bitacora.pipi,
      popo: bitacora.popo,
      observaciones: bitacora.observaciones,
    );
    
    final exito = await WhatsAppService.enviarMensaje(
      telefono: padre['telefono'],
      mensaje: mensaje,
    );
    
    if (exito && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Bitácora enviada al padre')),
      );
    }
  } catch (e) {
    print('Error enviando bitácora: $e');
  }
}
```

---

## 🎨 **Botón Estilo WhatsApp**

```dart
// Botón verde de WhatsApp con icono
ElevatedButton.icon(
  onPressed: _notificarPorWhatsApp,
  icon: const Icon(Icons.whatsapp, color: Colors.white),
  label: const Text('Notificar por WhatsApp'),
  style: ElevatedButton.styleFrom(
    backgroundColor: const Color(0xFF25D366), // Verde oficial de WhatsApp
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
)

// Botón flotante
FloatingActionButton(
  onPressed: _notificarPorWhatsApp,
  backgroundColor: const Color(0xFF25D366),
  child: const Icon(Icons.whatsapp),
)

// Botón con loading
ElevatedButton.icon(
  onPressed: _enviando ? null : _notificarPorWhatsApp,
  icon: _enviando 
      ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        )
      : const Icon(Icons.whatsapp),
  label: Text(_enviando ? 'Enviando...' : 'Enviar WhatsApp'),
  style: ElevatedButton.styleFrom(
    backgroundColor: const Color(0xFF25D366),
    foregroundColor: Colors.white,
  ),
)
```

---

## ⚙️ **Helper: Obtener Datos del Padre**

```dart
// Método auxiliar para obtener datos del padre
Future<Map<String, dynamic>> _obtenerDatosPadre() async {
  final response = await Supabase.instance.client
      .from('usuarios')
      .select('id, nombre, apellidos, telefono, whatsapp')
      .eq('id', alumno.padreId)
      .single();
  
  return response;
}

// Método auxiliar para obtener padres de un grado
Future<List<Map<String, dynamic>>> _obtenerPadresDelGrado(String gradoId) async {
  final response = await Supabase.instance.client
      .from('alumnos')
      .select('''
        padre_id,
        usuarios!inner(nombre, apellidos, telefono, whatsapp)
      ''')
      .eq('grado_id', gradoId)
      .eq('activo', true);
  
  // Extraer datos de padres
  final padresSet = <String, Map<String, dynamic>>{};
  for (final alumno in response) {
    final padreId = alumno['padre_id'];
    if (!padresSet.containsKey(padreId)) {
      padresSet[padreId] = alumno['usuarios'];
    }
  }
  
  return padresSet.values.toList();
}
```

---

## 🔍 **Validación antes de enviar**

```dart
Future<bool> _validarAntesDe enviar(String telefono) async {
  // Validar que el teléfono existe y es válido
  if (telefono.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('❌ El padre no tiene teléfono registrado')),
    );
    return false;
  }
  
  // Validar formato
  if (!WhatsAppService.validarTelefono(telefono)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('❌ Número de teléfono inválido')),
    );
    return false;
  }
  
  // Validar que Twilio esté configurado
  if (!TwilioConfig.isConfigured) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(TwilioConfig.configErrorMessage)),
    );
    return false;
  }
  
  return true;
}
```

---

## 💡 **Tips de UX**

### **1. Mostrar estado de envío**

```dart
bool _enviando = false;

// Al iniciar envío
setState(() => _enviando = true);

// Al terminar
setState(() => _enviando = false);

// En el botón
ElevatedButton.icon(
  onPressed: _enviando ? null : _enviarWhatsApp,
  icon: _enviando 
      ? CircularProgressIndicator() 
      : Icon(Icons.whatsapp),
  label: Text(_enviando ? 'Enviando...' : 'Enviar'),
)
```

### **2. Confirmar antes de enviar masivo**

```dart
final confirmar = await showDialog<bool>(
  context: context,
  builder: (context) => AlertDialog(
    title: Text('¿Enviar a ${telefonos.length} padres?'),
    content: Text('Esto enviará WhatsApp a todos los padres del grado.'),
    actions: [
      TextButton(child: Text('Cancelar'), onPressed: () => Navigator.pop(context, false)),
      ElevatedButton(child: Text('Enviar'), onPressed: () => Navigator.pop(context, true)),
    ],
  ),
);

if (confirmar != true) return;
```

### **3. Mostrar resultados**

```dart
final resultados = await WhatsAppService.enviarMensajeMasivo(...);

showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: Text('Envío completado'),
    content: Text('✅ Exitosos: ${resultados['exitosos']}\n'
                  '❌ Fallidos: ${resultados['fallidos']}'),
    actions: [
      ElevatedButton(child: Text('OK'), onPressed: () => Navigator.pop(context)),
    ],
  ),
);
```

---

## ✅ **Checklist de Implementación**

Para agregar WhatsApp a una pantalla:

- [ ] Importar `whatsapp_service.dart`
- [ ] Agregar estado `bool _enviando = false`
- [ ] Crear método `_notificarPorWhatsApp()`
- [ ] Obtener datos del padre (teléfono)
- [ ] Generar mensaje con plantilla adecuada
- [ ] Llamar a `WhatsAppService.enviarMensaje()`
- [ ] Manejar éxito/error con `ScaffoldMessenger`
- [ ] Agregar botón con icono de WhatsApp
- [ ] Probar con número real

---

## 🎯 **Próximos pasos:**

1. Lee estos ejemplos
2. Elige dónde quieres agregar WhatsApp primero
3. Copia el ejemplo correspondiente
4. Adapta a tu pantalla
5. Prueba con tu número

**¿Dudas? Escríbeme.** 😊
