import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Guarda en el teléfono la imagen que ya está subida. La ve quien tenga la pantalla.
Future<void> descargarImagen(BuildContext context, String url) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  try {
    final res = await http.get(Uri.parse(url));
    if (res.statusCode != 200 || res.bodyBytes.isEmpty) {
      throw StateError('No se pudo bajar la imagen');
    }
    final path = Uri.parse(url).path.toLowerCase();
    final esPng = path.endsWith('.png');
    final esWebp = path.endsWith('.webp');
    final ext = esPng
        ? 'png'
        : esWebp
            ? 'webp'
            : 'jpg';
    await FileSaver.instance.saveFile(
      name: 'caipi_${DateTime.now().millisecondsSinceEpoch}',
      bytes: res.bodyBytes,
      fileExtension: ext,
      mimeType: esPng
          ? MimeType.png
          : esWebp
              ? MimeType.other
              : MimeType.jpeg,
    );
    messenger?.showSnackBar(
      const SnackBar(content: Text('Imagen guardada en tu teléfono')),
    );
  } catch (e) {
    messenger?.showSnackBar(
      SnackBar(content: Text('No se pudo descargar: $e')),
    );
  }
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
