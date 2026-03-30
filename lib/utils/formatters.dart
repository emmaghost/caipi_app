import 'package:intl/intl.dart';

class Formatters {
  // Formato de fecha: 15/Mar/2026
  static String formatFecha(DateTime fecha) {
    return DateFormat('dd/MMM/yyyy', 'es_MX').format(fecha);
  }

  // Formato de fecha y hora: 15/Mar/2026 14:30
  static String formatFechaHora(DateTime fecha) {
    return DateFormat('dd/MMM/yyyy HH:mm', 'es_MX').format(fecha);
  }

  // Formato de dinero: $1,234.56
  static String formatDinero(double cantidad) {
    return '\$${cantidad.toStringAsFixed(2)}';
  }

  // Formato de teléfono: (55) 1234-5678
  static String formatTelefono(String telefono) {
    if (telefono.length == 10) {
      return '(${telefono.substring(0, 2)}) ${telefono.substring(2, 6)}-${telefono.substring(6)}';
    }
    return telefono;
  }

  // Validar email
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Obtener iniciales: Juan Pérez → JP
  static String getIniciales(String nombre, String apellido) {
    final inicial1 = nombre.isNotEmpty ? nombre[0].toUpperCase() : '';
    final inicial2 = apellido.isNotEmpty ? apellido[0].toUpperCase() : '';
    return '$inicial1$inicial2';
  }
}
