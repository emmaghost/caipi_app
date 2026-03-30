/// Configuración de Twilio para WhatsApp
/// 
/// IMPORTANTE: 
/// 1. Obtén tus credenciales en: https://console.twilio.com
/// 2. Para producción, usa variables de entorno
/// 3. Nunca subas este archivo a GitHub con credenciales reales

class TwilioConfig {
  // ============================================
  // CREDENCIALES DE TWILIO
  // ============================================
  
  /// Account SID de Twilio
  /// Obtenerlo en: https://console.twilio.com
  /// Ejemplo: ACxxxxxxxxxxxxxxxxxxxxxxxxxxxx
  static const String accountSid = 'TU_ACCOUNT_SID_AQUI';
  
  /// Auth Token de Twilio
  /// Obtenerlo en: https://console.twilio.com → Account → Auth Token
  /// Ejemplo: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
  static const String authToken = 'TU_AUTH_TOKEN_AQUI';
  
  /// Número de WhatsApp de Twilio
  /// Para Sandbox (pruebas): +1 415 523 8886
  /// Para producción: Tu número verificado de WhatsApp Business
  static const String whatsappNumber = 'whatsapp:+14155238886'; // Sandbox por defecto
  
  // ============================================
  // CONFIGURACIÓN
  // ============================================
  
  /// URL base de la API de Twilio
  static const String apiUrl = 'https://api.twilio.com/2010-04-01';
  
  /// Prefijo de número de WhatsApp (para México)
  static const String whatsappPrefix = 'whatsapp:+52';
  
  /// ¿Está en modo sandbox? (pruebas)
  /// Si es true, muestra advertencias sobre que los usuarios deben unirse al sandbox
  static const bool isSandbox = true;
  
  // ============================================
  // VALIDACIÓN
  // ============================================
  
  /// Verifica si las credenciales están configuradas
  static bool get isConfigured {
    return accountSid != 'TU_ACCOUNT_SID_AQUI' &&
           authToken != 'TU_AUTH_TOKEN_AQUI' &&
           accountSid.isNotEmpty &&
           authToken.isNotEmpty;
  }
  
  /// Mensaje de error si no está configurado
  static String get configErrorMessage {
    if (!isConfigured) {
      return 'Twilio no está configurado. '
             'Edita lib/config/twilio_config.dart con tus credenciales.';
    }
    return '';
  }
  
  // ============================================
  // HELPERS
  // ============================================
  
  /// Formatea un número de teléfono mexicano para WhatsApp
  /// Ejemplo: "5551234567" → "whatsapp:+525551234567"
  static String formatWhatsAppNumber(String phoneNumber) {
    // Remover espacios, guiones, paréntesis
    final cleaned = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    
    // Si ya tiene código de país (52), no agregarlo de nuevo
    if (cleaned.startsWith('52') && cleaned.length == 12) {
      return '$whatsappPrefix${cleaned.substring(2)}';
    }
    
    // Si es un número de 10 dígitos, agregar código de país
    if (cleaned.length == 10) {
      return '$whatsappPrefix$cleaned';
    }
    
    // Si ya está completo
    return '$whatsappPrefix$cleaned';
  }
  
  /// Instrucciones para unirse al sandbox (solo en modo pruebas)
  static String get sandboxInstructions {
    if (!isSandbox) return '';
    
    return '''
⚠️ MODO SANDBOX (PRUEBAS)

Para recibir mensajes, los padres deben:

1. Guardar el número: +1 (415) 523-8886 en sus contactos
2. Enviar por WhatsApp: "join troops-suit"
3. Esperar confirmación: "Sandbox Connected!"

Esto solo se hace UNA VEZ.

Para producción (sin este paso):
- Configura WhatsApp Business API en Twilio
- Cambia isSandbox = false en twilio_config.dart
    ''';
  }
}
