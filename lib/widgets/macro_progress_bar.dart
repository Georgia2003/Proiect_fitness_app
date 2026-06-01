import 'package:flutter/material.dart';
import 'package:aura_fit/theme/app_theme.dart';

class MacroProgressBar extends StatelessWidget {
  const MacroProgressBar({
    super.key,
    required this.label,
    required this.current,
    required this.target,
    required this.unit,
    required this.color,
  });

  final String label;
  final double current;
  final double target;
  final String unit;
  final Color  color;

  @override
  Widget build(BuildContext context) {
    final ratio    = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
    final overshot = target > 0 && current > target;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color:      kTextMuted,
                  fontSize:   13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text:  '${current.toStringAsFixed(1)} ',
                      style: TextStyle(
                        color:      overshot ? kError : kTextPrimary,
                        fontSize:   13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextSpan(
                      text:  '/ ${target.toStringAsFixed(0)} $unit',
                      style: const TextStyle(
                        color:    kTextMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: TweenAnimationBuilder<double>(
              tween:    Tween(begin: 0, end: ratio),
              duration: const Duration(milliseconds: 800),
              curve:    Curves.easeOutCubic,
              builder:  (_, value, __) => LinearProgressIndicator(
                value:           value,
                minHeight:       10,
                backgroundColor: kCard,
                color:           overshot ? kError : color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}