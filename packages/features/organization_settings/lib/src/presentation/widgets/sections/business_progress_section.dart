import 'dart:math' as math;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// One checklist item in [BusinessProgressSection] — a required field the
/// business must complete before it is visible to customers.
class BusinessProgressChecklistItem {
  const BusinessProgressChecklistItem({
    required this.label,
    required this.completed,
  });

  final String label;
  final bool completed;
}

/// Profile-completion summary card — Figma `business-visibility-card`
/// (`4253:26207`).
///
/// Pure presentation: [completionPercent] and [items] are computed by the
/// caller from whatever data is already available (session, local section
/// state); this widget owns no bloc and makes no API calls.
class BusinessProgressSection extends StatelessWidget {
  const BusinessProgressSection({
    required this.completionPercent,
    required this.items,
    super.key,
  });

  /// 0–100.
  final int completionPercent;
  final List<BusinessProgressChecklistItem> items;

  int get _completedCount => items.where((item) => item.completed).length;
  bool get _isComplete => items.isNotEmpty && _completedCount == items.length;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D101828),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 20,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 12,
                    children: [
                      Text(
                        'Business Profile',
                        style: typography.regularNone.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Track your progress and complete missing items.',
                        style: typography.smallNormal.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                _ProgressRing(percent: completionPercent),
              ],
            ),
            const AppDivider(),
            if (!_isComplete) ...[
              const _HiddenFromCustomersBadge(),
              Text(
                "Your business won't appear in customer search until all "
                'required information is completed.',
                style: typography.smallNormal.copyWith(
                  color: colors.textSecondary,
                  height: 18 / 13,
                ),
              ),
            ],
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 24,
              children: [
                for (final item in items) _ChecklistRow(item: item),
              ],
            ),
            const AppDivider(),
            Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 4,
              children: [
                Text(
                  '$_completedCount / ${items.length}',
                  style: typography.regularNormal.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Required Items Completed',
                  style: typography.regularNormal.copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({required this.percent});

  final int percent;

  static const double _size = 44;
  static const double _strokeWidth = 4;
  static const Color _trackColor = Color(0xFFEAECF0);
  static const Color _indicatorColor = Color(0xFF26A68C);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _size,
      height: _size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(_size, _size),
            painter: _RingPainter(
              fraction: (percent / 100).clamp(0.0, 1.0),
              trackColor: _trackColor,
              indicatorColor: _indicatorColor,
              strokeWidth: _strokeWidth,
            ),
          ),
          Text(
            '$percent%',
            style: const TextStyle(
              color: _indicatorColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.fraction,
    required this.trackColor,
    required this.indicatorColor,
    required this.strokeWidth,
  });

  final double fraction;
  final Color trackColor;
  final Color indicatorColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - strokeWidth) / 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, trackPaint);

    if (fraction <= 0) return;

    final indicatorPaint = Paint()
      ..color = indicatorColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * fraction,
      false,
      indicatorPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.fraction != fraction ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.indicatorColor != indicatorColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

class _HiddenFromCustomersBadge extends StatelessWidget {
  const _HiddenFromCustomersBadge();

  static const Color _background = Color(0xFFFEF2F2);
  static const Color _foreground = Color(0xFFFF5666);

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: [
            _Dot(color: _foreground, size: 8),
            Text(
              'Hidden from Customers',
              style: TextStyle(
                color: _foreground,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({required this.item});

  final BusinessProgressChecklistItem item;

  static const Color _completedColor = Color(0xFF26A68C);

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return Row(
      spacing: 12,
      children: [
        if (item.completed)
          const DecoratedBox(
            decoration: BoxDecoration(
              color: _completedColor,
              shape: BoxShape.circle,
            ),
            child: Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.check, size: 14, color: Colors.white),
            ),
          )
        else
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: colors.border, width: 1.5),
            ),
          ),
        Text(
          item.label,
          style: typography.regularNormal.copyWith(
            color: item.completed ? colors.textPrimary : colors.textMuted,
            fontWeight: item.completed ? FontWeight.w500 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
