import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:http/http.dart' as http;

/// Guarda la imagen en Fotos del teléfono. Solo avisa cuando sí quedó guardada.
Future<void> descargarImagen(BuildContext context, String url) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  try {
    final res = await http.get(Uri.parse(url));
    if (res.statusCode != 200 || res.bodyBytes.isEmpty) {
      throw StateError('No se pudo bajar la imagen');
    }
    final ext = _extensionDeImagen(res.bodyBytes);
    await Gal.putImageBytes(
      res.bodyBytes,
      name: 'caipi_${DateTime.now().millisecondsSinceEpoch}.$ext',
    );
    messenger?.showSnackBar(
      const SnackBar(content: Text('Imagen guardada en Fotos')),
    );
  } on GalException catch (e) {
    final texto = e.type == GalExceptionType.permissionDenied
        ? 'Permite el acceso a Fotos para guardar la imagen'
        : 'No se pudo guardar la imagen';
    messenger?.showSnackBar(SnackBar(content: Text(texto)));
  } catch (e) {
    messenger?.showSnackBar(
      SnackBar(content: Text('No se pudo descargar: $e')),
    );
  }
}

String _extensionDeImagen(List<int> bytes) {
  if (bytes.length >= 4 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4E &&
      bytes[3] == 0x47) {
    return 'png';
  }
  if (bytes.length >= 12 &&
      bytes[0] == 0x52 &&
      bytes[1] == 0x49 &&
      bytes[2] == 0x46 &&
      bytes[3] == 0x46) {
    return 'webp';
  }
  return 'jpg';
}

void mostrarVisorFoto(BuildContext context, String url) {
  showDialog<void>(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.black,
      insetPadding: const EdgeInsets.all(12),
      child: Stack(
        children: [
          InteractiveViewer(
            child: Image.network(url, fit: BoxFit.contain),
          ),
          Positioned(
            left: 0,
            top: 0,
            child: IconButton(
              tooltip: 'Descargar',
              onPressed: () => descargarImagen(context, url),
              icon: const Icon(Icons.download, color: Colors.white),
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            child: IconButton(
              onPressed: () => Navigator.pop(ctx),
              icon: const Icon(Icons.close, color: Colors.white),
            ),
          ),
        ],
      ),
    ),
  );
}

class FotoDescargable extends StatelessWidget {
  final String url;
  final double height;

  const FotoDescargable({
    super.key,
    required this.url,
    this.height = 220,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        GestureDetector(
          onTap: () => mostrarVisorFoto(context, url),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: ColoredBox(
              color: const Color(0xFFF3F0FA),
              child: SizedBox(
                height: height,
                width: double.infinity,
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Text('No se pudo cargar la imagen'),
                  ),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(6),
          child: IconButton.filled(
            tooltip: 'Descargar',
            style: IconButton.styleFrom(
              backgroundColor: Colors.black54,
              foregroundColor: Colors.white,
            ),
            onPressed: () => descargarImagen(context, url),
            icon: const Icon(Icons.download),
          ),
        ),
      ],
    );
  }
}
