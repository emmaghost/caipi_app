/// El QR de recogida trae solo el código de 8 caracteres.
String? codigoDesdeEscaneo(String raw) {
  final limpio = raw.trim().toUpperCase();
  if (RegExp(r'^[A-Z0-9]{8}$').hasMatch(limpio)) return limpio;
  return null;
}
