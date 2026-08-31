import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/acceso_padre_estado.dart';

/// Consulta si un papá debe ver la app en modo restringido (adeudo).
class AccesoPadreService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  AccesoPadreEstado? _estado;
  String? _padreIdCache;
  DateTime? _ultimaConsulta;

  AccesoPadreEstado? get estado => _estado;
  bool get restringido => _estado?.restringido == true;

  static const _cacheDuracion = Duration(seconds: 45);

  Future<AccesoPadreEstado> consultar(
    String padreId, {
    bool forzar = false,
  }) async {
    final ahora = DateTime.now();
    if (!forzar &&
        _padreIdCache == padreId &&
        _estado != null &&
        _ultimaConsulta != null &&
        ahora.difference(_ultimaConsulta!) < _cacheDuracion) {
      return _estado!;
    }

    try {
      final raw = await _supabase.rpc(
        'padre_acceso_restringido',
        params: {'p_padre_id': padreId},
      );
      _estado = AccesoPadreEstado.fromJson(raw);
    } catch (e) {
      debugPrint('padre_acceso_restringido: $e');
      _estado = AccesoPadreEstado.libre();
    }

    _padreIdCache = padreId;
    _ultimaConsulta = ahora;
    notifyListeners();
    return _estado!;
  }

  void limpiar() {
    _estado = null;
    _padreIdCache = null;
    _ultimaConsulta = null;
    notifyListeners();
  }
}
