import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Bloqueo de entrada si la app instalada es más vieja que [build_minimo].
class AppActualizacionService extends ChangeNotifier {
  bool bloqueada = false;
  String mensaje =
      'Hay una versión nueva de CAIPI. Actualiza desde la tienda para seguir usando la app.';
  String urlTienda = '';
  String nombreTienda = 'la tienda';

  /// true si hay que impedir el uso de la app.
  static bool debeBloquear({
    required int buildActual,
    required int buildMinimo,
    required bool activo,
  }) {
    if (!activo || buildMinimo <= 0) return false;
    return buildActual < buildMinimo;
  }

  Future<void> revisar() async {
    try {
      final info = await PackageInfo.fromPlatform()
          .timeout(const Duration(seconds: 4));
      final build = int.tryParse(info.buildNumber) ?? 0;

      final row = await Supabase.instance.client
          .from('app_actualizacion')
          .select('activo, build_minimo, mensaje, url_android, url_ios')
          .eq('id', 1)
          .maybeSingle()
          .timeout(const Duration(seconds: 8));

      if (row == null) return;

      final activo = row['activo'] == true;
      final minimo = (row['build_minimo'] as num?)?.toInt() ?? 0;
      final bloquear = debeBloquear(
        buildActual: build,
        buildMinimo: minimo,
        activo: activo,
      );

      final texto = (row['mensaje'] as String?)?.trim();
      if (texto != null && texto.isNotEmpty) mensaje = texto;

      final android = (row['url_android'] as String?)?.trim() ?? '';
      final ios = (row['url_ios'] as String?)?.trim() ?? '';
      final esIos = !kIsWeb && Platform.isIOS;
      if (esIos) {
        nombreTienda = 'App Store';
        urlTienda = ios.isNotEmpty
            ? ios
            : 'https://apps.apple.com/search?term=CAIPI';
      } else {
        nombreTienda = 'Play Store';
        urlTienda = android.isNotEmpty
            ? android
            : 'https://play.google.com/store/apps/details?id=com.escuela.caipi';
      }

      if (bloqueada != bloquear) {
        bloqueada = bloquear;
        notifyListeners();
      }
    } catch (e) {
      // Si Supabase o la tabla fallan, no encerramos a todo el colegio.
      debugPrint('Chequeo de actualización: $e');
    }
  }
}
