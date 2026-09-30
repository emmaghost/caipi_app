import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();

  // Seleccionar imagen desde galería
  Future<File?> seleccionarImagenGaleria() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 70,
    );
    
    if (image != null) {
      return File(image.path);
    }
    return null;
  }

  // Tomar foto con cámara
  Future<File?> tomarFoto() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 70,
    );
    
    if (image != null) {
      return File(image.path);
    }
    return null;
  }

  // Subir foto de alumno
  Future<String?> subirFotoAlumno(File file, String alumnoId) async {
    try {
      final bytes = await file.readAsBytes();
      final fileExt = file.path.split('.').last;
      final fileName = 'alumnos/$alumnoId/foto.$fileExt';
      
      await _supabase.storage
          .from('fotos')
          .uploadBinary(fileName, bytes,
              fileOptions: const FileOptions(upsert: true));
      
      final url = _supabase.storage.from('fotos').getPublicUrl(fileName);
      return url;
    } catch (e) {
      print('Error subiendo foto: $e');
      return null;
    }
  }

  // Subir comprobante de pago
  Future<String?> subirComprobantePago(File file, String pagoId) async {
    try {
      final bytes = await file.readAsBytes();
      final fileExt = file.path.split('.').last;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'pagos/$pagoId/comprobante_$timestamp.$fileExt';
      
      await _supabase.storage
          .from('fotos')
          .uploadBinary(fileName, bytes);
      
      final url = _supabase.storage.from('fotos').getPublicUrl(fileName);
      return url;
    } catch (e) {
      print('Error subiendo comprobante: $e');
      return null;
    }
  }

  /// Foto de chat (tarea). Comprimida antes de subir. Solo guarda la URL en el mensaje.
  Future<String?> subirFotoChat(File file, String usuarioId) async {
    try {
      final bytes = await file.readAsBytes();
      final rawExt = file.path.split('.').last.toLowerCase();
      final fileExt =
          (rawExt == 'png' || rawExt == 'webp' || rawExt == 'jpeg')
              ? rawExt
              : 'jpg';
      final stamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'chat/$usuarioId/$stamp.$fileExt';
      final contentType = fileExt == 'png'
          ? 'image/png'
          : fileExt == 'webp'
              ? 'image/webp'
              : 'image/jpeg';

      await _supabase.storage.from('fotos').uploadBinary(
            fileName,
            bytes,
            fileOptions: FileOptions(contentType: contentType),
          );

      return _supabase.storage.from('fotos').getPublicUrl(fileName);
    } catch (e) {
      print('Error subiendo foto de chat: $e');
      return null;
    }
  }

  // Eliminar archivo
  Future<void> eliminarArchivo(String path) async {
    try {
      await _supabase.storage.from('fotos').remove([path]);
    } catch (e) {
      print('Error eliminando archivo: $e');
    }
  }
}
