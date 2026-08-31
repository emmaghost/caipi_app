import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../utils/portage_stats.dart';

/// Gráfica de línea con puntos (evolución de logrados).
class PortageLineChart extends StatelessWidget {
  final List<PortagePuntoSerie> serie;

  const PortageLineChart({super.key, required this.serie});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _PortageLineChartPainter(serie: serie),
      child: const SizedBox.expand(),
    );
  }
}

class _PortageLineChartPainter extends CustomPainter {
  final List<PortagePuntoSerie> serie;

  _PortageLineChartPainter({required this.serie});

  @override
  void paint(Canvas canvas, Size size) {
    if (serie.isEmpty) return;

    const left = 36.0;
    const right = 12.0;
    const top = 16.0;
    const bottom = 44.0;
    final chartW = size.width - left - right;
    final chartH = size.height - top - bottom;

    final maxY = serie
        .map((p) => p.total == 0 ? p.logrados : p.total)
        .fold<int>(1, (a, b) => a > b ? a : b)
        .toDouble();
    final step = maxY <= 10 ? 2.0 : (maxY <= 30 ? 5.0 : 10.0);
    final yMax = ((maxY / step).ceil() * step).clamp(step, double.infinity);

    final gridPaint = Paint()
      ..color = const Color(0xFFE0E0E0)
      ..strokeWidth = 1;
    final axisPaint = Paint()
      ..color = const Color(0xFF9E9E9E)
      ..strokeWidth = 1.2;
    final linePaint = Paint()
      ..color = const Color(0xFFE53935)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;
    final pointPaint = Paint()
      ..color = const Color(0xFFE53935)
      ..style = PaintingStyle.fill;

    final labelStyle = TextPainter(
      textAlign: TextAlign.right,
      textDirection: ui.TextDirection.ltr,
    );

    for (double y = 0; y <= yMax + 0.01; y += step) {
      final py = top + chartH * (1 - y / yMax);
      canvas.drawLine(
        Offset(left, py),
        Offset(left + chartW, py),
        gridPaint,
      );
      labelStyle.text = TextSpan(
        text: y.toInt().toString(),
        style: const TextStyle(fontSize: 10, color: Color(0xFF757575)),
      );
      labelStyle.layout();
      labelStyle.paint(
        canvas,
        Offset(left - 6 - labelStyle.width, py - labelStyle.height / 2),
      );
    }
    canvas.drawLine(
      Offset(left, top),
      Offset(left, top + chartH),
      axisPaint,
    );
    canvas.drawLine(
      Offset(left, top + chartH),
      Offset(left + chartW, top + chartH),
      axisPaint,
    );

    Offset pointAt(int i, double value) {
      final n = serie.length;
      final x = n == 1 ? left + chartW / 2 : left + chartW * (i / (n - 1));
      final y = top + chartH * (1 - (value / yMax).clamp(0.0, 1.0));
      return Offset(x, y);
    }

    final path = Path();
    for (var i = 0; i < serie.length; i++) {
      final o = pointAt(i, serie[i].logrados.toDouble());
      if (i == 0) {
        path.moveTo(o.dx, o.dy);
      } else {
        path.lineTo(o.dx, o.dy);
      }
    }
    canvas.drawPath(path, linePaint);

    for (var i = 0; i < serie.length; i++) {
      final o = pointAt(i, serie[i].logrados.toDouble());
      final diamond = Path()
        ..moveTo(o.dx, o.dy - 5)
        ..lineTo(o.dx + 5, o.dy)
        ..lineTo(o.dx, o.dy + 5)
        ..lineTo(o.dx - 5, o.dy)
        ..close();
      canvas.drawPath(diamond, pointPaint);

      final fecha = DateFormat('dd/MM').format(serie[i].fecha);
      final tp = TextPainter(
        text: TextSpan(
          text: fecha,
          style: const TextStyle(fontSize: 9, color: Color(0xFF616161)),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      canvas.save();
      canvas.translate(o.dx, top + chartH + 8);
      canvas.rotate(-0.6);
      tp.paint(canvas, Offset(-tp.width / 2, 0));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _PortageLineChartPainter oldDelegate) =>
      oldDelegate.serie != serie;
}
