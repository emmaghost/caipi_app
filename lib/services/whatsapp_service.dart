import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/twilio_config.dart';

/// Servicio para enviar mensajes de WhatsApp usando Twilio
class WhatsAppService {
  // ============================================
  // ENVIAR MENSAJE INDIVIDUAL
  // ============================================
  
  /// Envía un mensaje de WhatsApp a un número específico
  /// 
  /// [telefono] Número del destinatario (ejemplo: "5551234567")
  /// [mensaje] Texto del mensaje a enviar
  /// 
  /// Returns true si se envió exitosamente, false si hubo error
  static Future<bool> enviarMensaje({
    required String telefono,
    required String mensaje,
  }) async {
    try {
      // Validar que Twilio esté configurado
      if (!TwilioConfig.isConfigured) {
        throw Exception(TwilioConfig.configErrorMessage);
      }

      // Formatear número de WhatsApp
      final toNumber = TwilioConfig.formatWhatsAppNumber(telefono);

      // Construir URL de la API
      final url = Uri.parse(
        '${TwilioConfig.apiUrl}/Accounts/${TwilioConfig.accountSid}/Messages.json',
      );

      // Credenciales en Base64 para autenticación
      final credentials = base64Encode(
        utf8.encode('${TwilioConfig.accountSid}:${TwilioConfig.authToken}'),
      );

      // Hacer petición POST a Twilio
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Basic $credentials',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'From': TwilioConfig.whatsappNumber,
          'To': toNumber,
          'Body': mensaje,
        },
      );

      // Verificar respuesta
      if (response.statusCode == 201) {
        print('✅ Mensaje WhatsApp enviado a $telefono');
        return true;
      } else {
        print('❌ Error enviando WhatsApp: ${response.statusCode}');
        print('Respuesta: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Error enviando WhatsApp: $e');
      return false;
    }
  }

  // ============================================
  // ENVIAR MENSAJES MASIVOS
  // ============================================
  
  /// Envía el mismo mensaje a múltiples números
  /// 
  /// [telefonos] Lista de números de teléfono
  /// [mensaje] Mensaje a enviar
  /// 
  /// Returns un mapa con resultados: {'exitosos': 5, 'fallidos': 2}
  static Future<Map<String, int>> enviarMensajeMasivo({
    required List<String> telefonos,
    required String mensaje,
  }) async {
    int exitosos = 0;
    int fallidos = 0;

    for (final telefono in telefonos) {
      final resultado = await enviarMensaje(
        telefono: telefono,
        mensaje: mensaje,
      );

      if (resultado) {
        exitosos++;
      } else {
        fallidos++;
      }

      // Pequeña pausa entre mensajes para no saturar la API
      await Future.delayed(const Duration(milliseconds: 500));
    }

    return {
      'exitosos': exitosos,
      'fallidos': fallidos,
    };
  }

  // ============================================
  // PLANTILLAS DE MENSAJES
  // ============================================

  /// Genera mensaje de pago pendiente
  static String mensajePagoPendiente({
    required String nombrePadre,
    required String nombreAlumno,
    required String concepto,
    required String monto,
    required String fechaVencimiento,
  }) {
    return '''
🏫 *CAIPI - Pago Pendiente*

Hola $nombrePadre,

Le recordamos que tiene un pago pendiente:

📌 *Concepto:* $concepto
💰 *Monto:* \$$monto
📅 *Vence:* $fechaVencimiento

👤 *Alumno:* $nombreAlumno

Puede realizar su pago en la escuela de lunes a viernes de 8:00 AM a 2:00 PM.

Gracias por su atención 😊

_Mensaje automático de CAIPI_
''';
  }

  /// Mensaje opcional cuando ya quedó registrado un pago (p. ej. colegiatura del mes).
  /// La app de gestión de pagos no lo envía sola; sirve para pruebas o envío manual.
  static String mensajePagoRegistrado({
    required String nombrePadre,
    required String nombreAlumno,
    required String concepto,
    required String monto,
    required String periodoEtiqueta,
    String? fechaPago,
  }) {
    final fp = fechaPago != null && fechaPago.isNotEmpty
        ? '\n📅 *Fecha de registro:* $fechaPago'
        : '';
    return '''
🏫 *CAIPI - Pago registrado*

Hola $nombrePadre,

Confirmamos que registramos el pago de *$nombreAlumno*:

📌 *Concepto:* $concepto
📆 *Periodo / mes:* $periodoEtiqueta
💰 *Monto:* \$$monto$fp

Gracias por su puntualidad 😊

_Mensaje automático de CAIPI_
''';
  }

  /// Genera mensaje de recordatorio de evento
  static String mensajeEvento({
    required String nombrePadre,
    required String nombreEvento,
    required String fecha,
    required String hora,
    required String? lugar,
    required String? descripcion,
  }) {
    return '''
🏫 *CAIPI - Recordatorio de Evento*

Hola $nombrePadre,

Le recordamos el siguiente evento:

🎉 *$nombreEvento*
📅 *Fecha:* $fecha
🕐 *Hora:* $hora
${lugar != null ? '📍 *Lugar:* $lugar' : ''}

${descripcion != null ? '$descripcion\n' : ''}
¡Los esperamos! 🎊

_Mensaje automático de CAIPI_
''';
  }

  /// Genera mensaje de incidente
  static String mensajeIncidente({
    required String nombrePadre,
    required String nombreAlumno,
    required String tipoIncidente,
    required String descripcion,
    required String fecha,
  }) {
    return '''
🏫 *CAIPI - Notificación de Incidente*

Hola $nombrePadre,

Le informamos sobre un incidente de su hijo/a:

👤 *Alumno:* $nombreAlumno
⚠️ *Tipo:* $tipoIncidente
📅 *Fecha:* $fecha

📝 *Detalles:*
$descripcion

Si tiene alguna duda, no dude en contactarnos.

_Mensaje automático de CAIPI_
''';
  }

  /// Genera mensaje de bitácora diaria
  static String mensajeBitacora({
    required String nombrePadre,
    required String nombreAlumno,
    required String fecha,
    required String estadoAnimo,
    required String comio,
    required int pipi,
    required int popo,
    required String? observaciones,
  }) {
    // Emojis según estado de ánimo
    String emojiAnimo = '😊';
    if (estadoAnimo == 'triste') emojiAnimo = '😢';
    if (estadoAnimo == 'enojado') emojiAnimo = '😠';
    if (estadoAnimo == 'cansado') emojiAnimo = '😴';

    return '''
🏫 *CAIPI - Bitácora Diaria*

Hola $nombrePadre,

Resumen del día de *$nombreAlumno* ($fecha):

$emojiAnimo *Estado de ánimo:* $estadoAnimo
🍽️ *Comió:* $comio
🚽 *Pipí:* $pipi veces
💩 *Popó:* $popo veces

${observaciones != null && observaciones.isNotEmpty ? '📝 *Observaciones:*\n$observaciones\n' : ''}
¡Que tengan una linda tarde! 🌈

_Mensaje automático de CAIPI_
''';
  }

  /// Genera mensaje de anuncio general
  static String mensajeAnuncio({
    required String nombrePadre,
    required String titulo,
    required String contenido,
    required String fecha,
  }) {
    return '''
🏫 *CAIPI - Anuncio*

Hola $nombrePadre,

📢 *$titulo*

$contenido

📅 *Fecha:* $fecha

_Mensaje automático de CAIPI_
''';
  }

  // ============================================
  // VALIDACIÓN
  // ============================================

  /// Valida que un número de teléfono sea válido (10 dígitos para México)
  static bool validarTelefono(String telefono) {
    final cleaned = telefono.replaceAll(RegExp(r'[^\d]'), '');
    return cleaned.length == 10 || cleaned.length == 12;
  }

  /// Limpia y formatea un número de teléfono
  static String limpiarTelefono(String telefono) {
    return telefono.replaceAll(RegExp(r'[^\d]'), '');
  }
}
