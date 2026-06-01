import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:aura_fit/database/app_database.dart';
import 'package:aura_fit/theme/app_theme.dart';
// Hide intl's TextDirection so it doesn't shadow dart:ui's TextDirection.
import 'package:intl/intl.dart' hide TextDirection;

/// 7-day calorie adherence bar chart rendered with CustomPainter.
class NutritionHistoryChart extends StatelessWidget {
  const NutritionHistoryChart({
    super.key,
    required this.logs,
    required this.calorieTarget,
  });

  final List<NutritionLog> logs;
  final double             calorieTarget;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: CustomPaint(
        painter: _ChartPainter(logs: logs, target: calorieTarget),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter({required this.logs, required this.target});

  final List<NutritionLog> logs;
  final double             target;

  @override
  void paint(Canvas canvas, Size size) {
    final now   = DateTime.now();
    final days  = List.generate(7, (i) => DateTime(now.year, now.month, now.day - (6 - i)));

    // Sum calories per day
    final Map<String, double> dayTotals = {};
    for (final d in days) {
      dayTotals[_key(d)] = 0;
    }
    for (final l in logs) {
      final k = _key(l.date);
      if (dayTotals.containsKey(k)) dayTotals[k] = dayTotals[k]! + l.calories;
    }

    final maxVal   = math.max(target * 1.3, 100.0);
    final barW     = (size.width - 32) / 7 * 0.6;
    final spacing  = (size.width - 32) / 7;
    const padL     = 16.0;
    const padB     = 36.0;
    final chartH   = size.height - padB - 16;

    final gridP = Paint()
      ..color      = kTextMuted.withValues(alpha: 0.15)
      ..strokeWidth = 1;
    final targetP = Paint()
      ..color      = kAccent.withValues(alpha: 0.5)
      ..strokeWidth = 1.5
      ..strokeCap   = StrokeCap.round;

    // Grid lines
    for (int i = 0; i <= 4; i++) {
      final y = 16 + chartH - (i / 4) * chartH;
      canvas.drawLine(Offset(padL, y), Offset(size.width - 16, y), gridP);
    }

    // Target line
    final targetY = 16 + chartH - (target / maxVal).clamp(0, 1) * chartH;
    const dashW   = 8.0;
    var   dashX   = padL;
    while (dashX < size.width - 16) {
      canvas.drawLine(
        Offset(dashX, targetY),
        Offset(math.min(dashX + dashW, size.width - 16), targetY),
        targetP,
      );
      dashX += dashW * 2;
    }

    // "Target" label
    final tStyle = TextStyle(color: kAccent.withValues(alpha: 0.8), fontSize: 9);
    _drawText(canvas, 'TARGET', Offset(size.width - 50, targetY - 12), tStyle);

    // Bars
    for (int i = 0; i < 7; i++) {
      final day  = days[i];
      final cal  = dayTotals[_key(day)] ?? 0;
      final ratio = (cal / maxVal).clamp(0.0, 1.0);

      final barX  = padL + i * spacing + (spacing - barW) / 2;
      final barH  = ratio * chartH;
      final barY  = 16 + chartH - barH;

      final isToday = _key(day) == _key(now);
      final over    = target > 0 && cal > target;

      final barColor = over
          ? kError
          : isToday
              ? kAccent
              : kIndigo.withValues(alpha: 0.7);

      // Bar glow
      if (barH > 2) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(barX - 2, barY - 2, barW + 4, barH + 4),
            const Radius.circular(6),
          ),
          Paint()
            ..color      = barColor.withValues(alpha: 0.2)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
      }

      // Bar fill
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(barX, barY, barW, barH),
          const Radius.circular(5),
        ),
        Paint()..color = barColor,
      );

      // Day label
      final dayLabel = DateFormat('E').format(day).substring(0, 1);
      final labelStyle = TextStyle(
        color:      isToday ? kAccent : kTextMuted,
        fontSize:   10,
        fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
      );
      _drawText(
        canvas,
        dayLabel,
        Offset(barX + barW / 2 - 4, size.height - padB + 6),
        labelStyle,
      );

      // Value label above bar
      if (cal > 0) {
        _drawText(
          canvas,
          cal.toStringAsFixed(0),
          Offset(barX + barW / 2 - 10, barY - 14),
          TextStyle(color: barColor, fontSize: 8, fontWeight: FontWeight.w600),
        );
      }
    }
  }

  void _drawText(Canvas canvas, String text, Offset offset, TextStyle style) {
    final tp = TextPainter(
      text:          TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, offset);
  }

  String _key(DateTime d) => '${d.year}-${d.month}-${d.day}';

  @override
  bool shouldRepaint(_ChartPainter old) =>
      old.logs != logs || old.target != target;
}