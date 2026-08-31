import '../models/pago.dart';

/// Lógica pura de pagos (sin UI ni Supabase) para pruebas unitarias.
class PagoHelpers {
  PagoHelpers._();

  static const List<String> mesesEs = [
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ];

  /// Etiqueta de periodo a partir de una fecha (ej. "Marzo 2026").
  static String etiquetaPeriodo(DateTime fecha) {
    return '${mesesEs[fecha.month - 1]} ${fecha.year}';
  }

  /// Monto a cobrar tras descuento. Nunca negativo.
  static double montoNeto({
    required double montoBruto,
    double descuento = 0,
  }) {
    if (montoBruto < 0) {
      throw ArgumentError('El monto no puede ser negativo');
    }
    if (descuento < 0) {
      throw ArgumentError('El descuento no puede ser negativo');
    }
    if (descuento > montoBruto) {
      throw ArgumentError('El descuento no puede ser mayor al monto');
    }
    return montoBruto - descuento;
  }

  /// Solo se pueden borrar cargos sin abonos (monto_pagado == 0 y no pagado/parcial).
  static bool puedeEliminarse(Pago pago) {
    if (pago.estaPagado || pago.estaParcial) return false;
    if (pago.montoPagado > 0) return false;
    if (pago.estatus == 'cancelado') return false;
    return true;
  }

  /// Filtra IDs seleccionados que sí son borrables.
  static List<String> idsEliminables(
    Iterable<Pago> pagos,
    Iterable<String> seleccionados,
  ) {
    final set = seleccionados.toSet();
    return pagos
        .where((p) => set.contains(p.id) && puedeEliminarse(p))
        .map((p) => p.id)
        .toList();
  }

  /// Texto de notas combinando descuento + notas libres.
  static String? notasConDescuento({
    required double montoBruto,
    required double descuento,
    String? notasUsuario,
  }) {
    final partes = <String>[];
    if (descuento > 0) {
      partes.add(
        'Descuento \$${descuento.toStringAsFixed(2)} '
        '(bruto \$${montoBruto.toStringAsFixed(2)})',
      );
    }
    final n = notasUsuario?.trim();
    if (n != null && n.isNotEmpty) partes.add(n);
    if (partes.isEmpty) return null;
    return partes.join(' · ');
  }

  /// Año de inicio del ciclo escolar (agosto–julio). Ago–Dic → ese año; Ene–Jul → año anterior.
  static int anioInicioCiclo(DateTime fecha) {
    return fecha.month >= 8 ? fecha.year : fecha.year - 1;
  }

  /// Normaliza plan a 10, 11 o 12 (default 12).
  static int normalizarPlan(int planPagos) {
    if (planPagos == 10 || planPagos == 11 || planPagos == 12) {
      return planPagos;
    }
    return 12;
  }

  /// Último mes calendario del ciclo: 10→Mayo, 11→Junio, 12→Julio.
  static int ultimoMesPlan(int planPagos) {
    switch (normalizarPlan(planPagos)) {
      case 10:
        return 5;
      case 11:
        return 6;
      default:
        return 7;
    }
  }

  /// Etiqueta legible del rango del plan.
  static String etiquetaRangoPlan(int planPagos) {
    switch (normalizarPlan(planPagos)) {
      case 10:
        return 'Agosto - Mayo';
      case 11:
        return 'Agosto - Junio';
      default:
        return 'Agosto - Julio';
    }
  }

  /// Inscripción/seguro de kínder no van en el cuadro; inscripción de estimulación sí.
  static bool esTipoCuadroPagos(String? tipoPago, {String? concepto}) {
    final t = (tipoPago ?? '').toLowerCase();
    if (t == 'seguro') return false;
    if (t == 'inscripcion') {
      final c = (concepto ?? '').toLowerCase();
      return c.contains('estimul');
    }
    return true;
  }

  /// Fechas de vencimiento (día 5) del plan 10/11/12.
  /// Solo incluye meses desde el mes de [fechaIngreso] en adelante.
  static List<DateTime> fechasMensualidadesPlan({
    required int planPagos,
    required DateTime fechaIngreso,
  }) {
    final startYear = anioInicioCiclo(fechaIngreso);
    final fechas = <DateTime>[];
    final ultimoMes = ultimoMesPlan(planPagos);

    for (var m = 8; m <= 12; m++) {
      fechas.add(DateTime(startYear, m, 5));
    }
    for (var m = 1; m <= ultimoMes; m++) {
      fechas.add(DateTime(startYear + 1, m, 5));
    }

    final desde = DateTime(fechaIngreso.year, fechaIngreso.month, 1);
    return fechas
        .where((f) => !DateTime(f.year, f.month, 1).isBefore(desde))
        .toList();
  }

  /// ¿Ya pasaron [diasGracia] días desde el vencimiento sin liquidar?
  /// Ej.: vence 5 mar, gracia 5 → bloqueo desde el 11 mar.
  static bool debeBloquearAccesoApp({
    required DateTime fechaVencimiento,
    required bool pagado,
    DateTime? hoy,
    int diasGracia = 5,
  }) {
    if (pagado) return false;
    final ref = hoy ?? DateTime.now();
    final hoySolo = DateTime(ref.year, ref.month, ref.day);
    final limite = DateTime(
      fechaVencimiento.year,
      fechaVencimiento.month,
      fechaVencimiento.day,
    );
    final umbral = limite.add(Duration(days: diasGracia));
    return hoySolo.isAfter(umbral);
  }

  /// Texto para recordatorio de colegiaturas vencidas (chat o WhatsApp).
  static String mensajeRecordatorioAdeudo({
    required String nombreAlumno,
    required List<Pago> pagosVencidos,
    String Function(double monto)? formatearMonto,
  }) {
    final fmt = formatearMonto ??
        (m) => '\$${m.toStringAsFixed(2)}';
    final lineas = pagosVencidos.map((p) {
      final periodo = p.mes ?? p.concepto ?? 'Colegiatura';
      return '• $periodo: ${fmt(p.saldoPendiente)}';
    }).toList();
    final total =
        pagosVencidos.fold<double>(0, (s, p) => s + p.saldoPendiente);
    final buffer = StringBuffer()
      ..writeln('⚠️ Recordatorio de adeudo — CAIPI')
      ..writeln()
      ..writeln('$nombreAlumno tiene colegiatura(s) pendiente(s):')
      ..writeln();
    for (final linea in lineas) {
      buffer.writeln(linea);
    }
    buffer
      ..writeln()
      ..write('Total pendiente: ${fmt(total)}')
      ..writeln()
      ..writeln()
      ..write(
        'Favor de regularizar en caja. Si ya pagaste, avísanos por este chat.',
      );
    return buffer.toString();
  }
}
