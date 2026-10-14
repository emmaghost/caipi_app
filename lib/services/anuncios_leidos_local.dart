import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Anuncios que el papá ya marcó en este teléfono.
/// Si la base rechaza el update, el leído igual se queda.
class AnunciosLeidosLocal {
  AnunciosLeidosLocal._();

  static final ValueNotifier<int> tick = ValueNotifier(0);
  static final Set<String> _ids = {};
  static String? _uid;

  static bool contiene(String id) => _ids.contains(id);

  static Future<void> cargar(String uid) async {
    if (_uid == uid) return;
    _uid = uid;
    final prefs = await SharedPreferences.getInstance();
    _ids
      ..clear()
      ..addAll(prefs.getStringList(_clave(uid)) ?? const []);
    tick.value++;
  }

  static Future<void> marcar(String uid, String anuncioId) async {
    await cargar(uid);
    if (!_ids.add(anuncioId)) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_clave(uid), _ids.toList());
    tick.value++;
  }

  static String _clave(String uid) => 'anuncios_leidos_$uid';
}
