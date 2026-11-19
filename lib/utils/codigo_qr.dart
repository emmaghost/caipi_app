/// El QR de recogida trae un código de 8 caracteres.
/// Acepta espacios o texto alrededor, por si la cámara lee de más.
String? codigoDesdeEscaneo(String raw) {
  final limpio = raw.trim().toUpperCase();
  if (limpio.isEmpty) return null;
  if (RegExp(r'^[A-Z0-9]{8}$').hasMatch(limpio)) return limpio;
  return RegExp(r'[A-Z0-9]{8}').firstMatch(limpio)?.group(0);
}
