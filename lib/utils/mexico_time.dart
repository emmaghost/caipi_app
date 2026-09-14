import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Toda la app CAIPI usa solo hora de México Centro (`America/Mexico_City`).
/// No depende del huso del emulador / teléfono.
class MexicoTime {
  MexicoTime._();

  static const String locationName = 'America/Mexico_City';
  static bool _listo = false;

  static void init() {
    if (_listo) return;
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation(locationName));
    _listo = true;
  }

  static tz.Location get location {
    if (!_listo) init();
    return tz.getLocation(locationName);
  }

  /// Ahora en México (Centro).
  static DateTime now() => tz.TZDateTime.now(location);

  /// Convierte cualquier instante a reloj de México.
  static DateTime toMexico(DateTime dt) {
    final utc = dt.isUtc ? dt : dt.toUtc();
    return tz.TZDateTime.from(utc, location);
  }

  /// Parsea ISO de Supabase/Postgres y lo deja en México.
  static DateTime parse(String raw) {
    final dt = DateTime.parse(raw.trim());
    // Sin zona → se asume UTC (Supabase / timestamptz).
    if (!dt.isUtc && !raw.contains('Z') && !RegExp(r'[+-]\d{2}:\d{2}$').hasMatch(raw)) {
      return toMexico(DateTime.utc(
        dt.year,
        dt.month,
        dt.day,
        dt.hour,
        dt.minute,
        dt.second,
        dt.millisecond,
        dt.microsecond,
      ));
    }
    return toMexico(dt);
  }

  static String format(
    DateTime dt,
    String pattern, {
    String locale = 'es_MX',
  }) {
    return DateFormat(pattern, locale).format(toMexico(dt));
  }

  static String fecha(DateTime dt) => format(dt, 'dd/MM/yyyy');

  static String fechaHora(DateTime dt) => format(dt, 'dd/MM/yyyy HH:mm');

  static String hora(DateTime dt) => format(dt, 'HH:mm');

  static String ymd(DateTime dt) => format(dt, 'yyyy-MM-dd');

  static String hms(DateTime dt) => format(dt, 'HH:mm:ss');

  /// ISO UTC para guardar en BD.
  static String nowUtcIso() => DateTime.now().toUtc().toIso8601String();
}
