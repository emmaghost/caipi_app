import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// `pronto_pago` = recordar que el pago está por llegar (evitar recargo).
/// `adeudo` = ya hay saldo vencido; pasar a pagar.
/// `admin` = mensaje general de la Administración.
class PagoAvisoTipo {
  static const prontoPago = 'pronto_pago';
  static const adeudo = 'adeudo';
  static const admin = 'admin';

  static const firma = 'Administración CAIPI';

  /// Montos siempre en pesos mexicanos con miles y decimales (ej. $27,830.00).
  static final formatoMxn = NumberFormat.currency(
    locale: 'es_MX',
    symbol: r'$',
    decimalDigits: 2,
  );

  static String etiqueta(String tipo) {
    switch (tipo) {
      case adeudo:
        return 'Adeudo / recargo';
      case admin:
        return 'Administración';
      case prontoPago:
      default:
        return 'Pronto pago';
    }
  }

  static String descripcion(String tipo) {
    switch (tipo) {
      case adeudo:
        return 'Solo a papás con saldo vencido: pasar a pagar / cuenta con adeudo. '
            'Texto 100% editable por caja y directora.';
      case admin:
        return 'Aviso institucional de colegiaturas. '
            'Texto 100% editable por caja y directora.';
      case prontoPago:
      default:
        return 'A quienes aún no liquidaron el ciclo: el pago está por llegar. '
            'Texto 100% editable por caja y directora.';
    }
  }

  static String mensajeDefault(String tipo) {
    switch (tipo) {
      case adeudo:
        return 'La cuenta de {nombres_hijos} tiene adeudo. '
            'Saldo actual: {saldo}. '
            'Te pedimos pasar a pagar lo antes posible; puede aplicar recargo. '
            'Si ya estás al corriente, ignora este mensaje.\n\n'
            '— $firma';
      case admin:
        return 'Te escribimos respecto a la colegiatura de {nombres_hijos}. '
            'Saldo pendiente: {saldo}. '
            'Mantente al corriente para evitar recargos y contratiempos. '
            'Cualquier duda, responde por este chat.\n\n'
            '— $firma';
      case prontoPago:
      default:
        return 'Te recordamos que el pago de colegiatura de {nombres_hijos} '
            'está por vencer. Saldo pendiente: {saldo}. '
            'Realízalo a tiempo para evitar recargos. '
            'Si ya liquidaste el ciclo completo, omite este aviso.\n\n'
            '— $firma';
    }
  }

  static String tituloDefault(String tipo) {
    switch (tipo) {
      case adeudo:
        return 'Administración CAIPI informa · Tu cuenta tiene adeudo';
      case admin:
        return 'Administración CAIPI informa · Aviso de colegiatura';
      case prontoPago:
      default:
        return 'Administración CAIPI informa · Pronto pago';
    }
  }

  static String nombreDefault(String tipo) {
    switch (tipo) {
      case adeudo:
        return 'Adeudo / pasar a pagar';
      case admin:
        return 'Aviso Administración';
      case prontoPago:
      default:
        return 'Pronto pago (evitar recargo)';
    }
  }

  static int diaDefault(String tipo) {
    switch (tipo) {
      case adeudo:
        return 11;
      case admin:
        return 1;
      case prontoPago:
      default:
        return 5;
    }
  }

  static String normalizar(String? tipo) {
    if (tipo == adeudo) return adeudo;
    if (tipo == admin) return admin;
    return prontoPago;
  }

  /// Título de push/chat con sello de administración (sin duplicar).
  static String tituloConFirma(String titulo) {
    final t = titulo.trim();
    if (t.isEmpty) return 'Administración CAIPI informa';
    final low = t.toLowerCase();
    if (low.startsWith('administración caipi') ||
        low.startsWith('administracion caipi')) {
      return t;
    }
    return 'Administración CAIPI informa · $t';
  }
}

class PagoAvisoProgramado {
  final String id;
  final String nombre;
  final int diaMes;
  final String titulo;
  final String mensaje;
  final String tipo;
  final bool activo;
  final bool soloConAdeudo;
  final bool enviarChat;
  final bool enviarPush;
  final String? createdBy;
  final DateTime? lastRunYmd;
  final DateTime createdAt;
  final DateTime updatedAt;

  PagoAvisoProgramado({
    required this.id,
    required this.nombre,
    required this.diaMes,
    required this.titulo,
    required this.mensaje,
    this.tipo = PagoAvisoTipo.prontoPago,
    this.activo = true,
    this.soloConAdeudo = true,
    this.enviarChat = true,
    this.enviarPush = true,
    this.createdBy,
    this.lastRunYmd,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get esAdeudo => tipo == PagoAvisoTipo.adeudo;
  bool get esAdmin => tipo == PagoAvisoTipo.admin;

  factory PagoAvisoProgramado.fromJson(Map<String, dynamic> json) {
    DateTime? ymd;
    final raw = json['last_run_ymd'];
    if (raw is String && raw.isNotEmpty) {
      ymd = DateTime.tryParse(raw);
    }
    return PagoAvisoProgramado(
      id: json['id'] as String,
      nombre: json['nombre'] as String? ?? 'Aviso',
      diaMes: json['dia_mes'] as int? ?? 1,
      titulo: json['titulo'] as String? ?? 'Recordatorio',
      mensaje: json['mensaje'] as String? ?? '',
      tipo: PagoAvisoTipo.normalizar(json['tipo'] as String?),
      activo: json['activo'] as bool? ?? true,
      soloConAdeudo: json['solo_con_adeudo'] as bool? ?? true,
      enviarChat: json['enviar_chat'] as bool? ?? true,
      enviarPush: json['enviar_push'] as bool? ?? true,
      createdBy: json['created_by'] as String?,
      lastRunYmd: ymd,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

class PadreAdeudoResumen {
  final String padreId;
  final String alumnoId;
  final String alumnoNombre;
  final double saldo;

  PadreAdeudoResumen({
    required this.padreId,
    required this.alumnoId,
    required this.alumnoNombre,
    required this.saldo,
  });

  factory PadreAdeudoResumen.fromJson(Map<String, dynamic> json) {
    return PadreAdeudoResumen(
      padreId: json['padre_id'] as String,
      alumnoId: json['alumno_id'] as String,
      alumnoNombre: (json['alumno_nombre'] as String?)?.trim() ?? 'tu hijo/a',
      saldo: (json['saldo'] as num?)?.toDouble() ?? 0,
    );
  }
}

class PagoAvisosService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<PagoAvisoProgramado>> listar() async {
    final rows = await _client
        .from('pago_avisos_programados')
        .select()
        .order('dia_mes');
    return (rows as List)
        .map((e) => PagoAvisoProgramado.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<PagoAvisoProgramado> guardar({
    String? id,
    required String nombre,
    required int diaMes,
    required String titulo,
    required String mensaje,
    required String tipo,
    required bool activo,
    required bool soloConAdeudo,
    required bool enviarChat,
    required bool enviarPush,
    String? createdBy,
  }) async {
    final tipoOk = PagoAvisoTipo.normalizar(tipo);
    final payload = {
      'nombre': nombre.trim(),
      'dia_mes': diaMes.clamp(1, 28),
      'titulo': titulo.trim(),
      'mensaje': mensaje.trim(),
      'tipo': tipoOk,
      'activo': activo,
      'solo_con_adeudo': soloConAdeudo,
      'enviar_chat': enviarChat,
      'enviar_push': enviarPush,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
      if (createdBy != null) 'created_by': createdBy,
    };
    if (id == null) {
      final row = await _client
          .from('pago_avisos_programados')
          .insert(payload)
          .select()
          .single();
      return PagoAvisoProgramado.fromJson(row);
    }
    final row = await _client
        .from('pago_avisos_programados')
        .update(payload)
        .eq('id', id)
        .select()
        .single();
    return PagoAvisoProgramado.fromJson(row);
  }

  Future<void> eliminar(String id) async {
    await _client.from('pago_avisos_programados').delete().eq('id', id);
  }

  /// Quienes aún deben colegiatura (ciclo no liquidado).
  Future<List<PadreAdeudoResumen>> padresPendientesCiclo() async {
    final rows = await _client.rpc('padres_con_adeudo_colegiatura');
    return (rows as List)
        .map((e) => PadreAdeudoResumen.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Solo saldo vencido (aviso de adeudo / recargo).
  Future<List<PadreAdeudoResumen>> padresConAdeudoVencido() async {
    try {
      final rows = await _client.rpc('padres_con_adeudo_vencido_colegiatura');
      return (rows as List)
          .map((e) => PadreAdeudoResumen.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      // Si aún no corrieron el SQL nuevo, cae al listado general.
      return padresPendientesCiclo();
    }
  }

  Future<List<PadreAdeudoResumen>> destinatariosPara(PagoAvisoProgramado aviso) {
    if (aviso.esAdeudo) return padresConAdeudoVencido();
    return padresPendientesCiclo();
  }

  @Deprecated('Usar padresPendientesCiclo')
  Future<List<PadreAdeudoResumen>> padresConAdeudo() => padresPendientesCiclo();

  /// Agrupa por padre: nombres de hijos y saldo total.
  Map<String, ({List<String> hijos, double saldo})> agruparPorPadre(
    List<PadreAdeudoResumen> filas,
  ) {
    final map = <String, ({List<String> hijos, double saldo})>{};
    for (final f in filas) {
      final prev = map[f.padreId];
      if (prev == null) {
        map[f.padreId] = (hijos: [f.alumnoNombre], saldo: f.saldo);
      } else {
        map[f.padreId] = (
          hijos: [...prev.hijos, f.alumnoNombre],
          saldo: prev.saldo + f.saldo,
        );
      }
    }
    return map;
  }

  static String personalizar({
    required String plantilla,
    required List<String> nombresHijos,
    required double saldo,
  }) {
    final nombres = nombresHijos.where((e) => e.trim().isNotEmpty).toList();
    final nombre = nombres.isEmpty
        ? 'tu hijo/a'
        : (nombres.length == 1 ? nombres.first : nombres.join(', '));
    // Pesos MX: $27,830.00 (miles + 2 decimales).
    final saldoTxt = PagoAvisoTipo.formatoMxn.format(saldo);
    return plantilla
        .replaceAll('{nombre_hijo}', nombre)
        .replaceAll('{nombres_hijos}', nombre)
        .replaceAll('{saldo}', saldoTxt);
  }

  Future<void> marcarEjecutado(String avisoId) async {
    final ymd = DateTime.now().toIso8601String().split('T').first;
    await _client.from('pago_avisos_programados').update({
      'last_run_ymd': ymd,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', avisoId);
  }

  Future<bool> yaEnviadoHoy({
    required String avisoId,
    required String padreId,
    required String canal,
  }) async {
    final ymd = DateTime.now().toIso8601String().split('T').first;
    final row = await _client
        .from('pago_avisos_envios')
        .select('id')
        .eq('aviso_id', avisoId)
        .eq('padre_id', padreId)
        .eq('ymd', ymd)
        .eq('canal', canal)
        .maybeSingle();
    return row != null;
  }

  Future<void> registrarEnvio({
    required String avisoId,
    required String padreId,
    required String canal,
  }) async {
    final ymd = DateTime.now().toIso8601String().split('T').first;
    try {
      await _client.from('pago_avisos_envios').insert({
        'aviso_id': avisoId,
        'padre_id': padreId,
        'ymd': ymd,
        'canal': canal,
      });
    } catch (_) {
      // unique → ya enviado
    }
  }
}
