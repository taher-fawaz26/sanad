import 'dart:math' as math;

import 'package:app_animations/app_animations.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
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
/// Pure presentation: every value is computed by the caller from
/// `GET service-provider/completion` (see `ProviderCompletionEntity`) —
/// this widget owns no bloc and makes no API calls, and never re-derives
/// completeness itself.
///
/// **Collapsed by default.** The card opens showing only a concise summary —
/// the title/subtitle, the completion [_ProgressRing], and the
/// `requiredCompleted / requiredTotal` footer. Tapping anywhere on the card (or
/// its bottom chevron) animates the full body open/closed: the hidden-from-
/// customers notice and the per-item [_ChecklistRow] list. The only local state
/// is [_expanded]; all displayed values remain caller-driven. Motion uses the
/// shared [AppMotionDuration]/[AppMotionCurve] tokens and collapses to
/// `Duration.zero` under [AppMotion.reduceMotionOf] (reduced motion / a11y),
/// so the toggle still works instantly without animation.
class BusinessProgressSection extends StatefulWidget {
  const BusinessProgressSection({
    required this.completionPercent,
    required this.items,
    required this.visibleToCustomers,
    required this.requiredCompleted,
    required this.requiredTotal,
    super.key,
  });

  /// 0–100, straight from `ProviderCompletionEntity.percentage`.
  final int completionPercent;
  final List<BusinessProgressChecklistItem> items;

  /// Straight from `ProviderCompletionEntity.visibleToCustomers` — `true`
  /// only when every required step is complete.
  final bool visibleToCustomers;
  final int requiredCompleted;
  final int requiredTotal;

  @override
  State<BusinessProgressSection> createState() =>
      _BusinessProgressSectionState();
}

class _BusinessProgressSectionState extends State<BusinessProgressSection> {
  bool _expanded = false;

  void _toggle() => setState(() => _expanded = !_expanded);

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    // Functional expand/collapse: under reduced motion we skip the implicit
    // AnimatedSize/AnimatedRotation entirely and render the final state, so the
    // toggle is an instant cut (a zero-duration implicit animation would notify
    // its controller mid-layout) while the affordance itself is preserved.
    final reduceMotion = AppMotion.reduceMotionOf(context);
    const motionDuration = AppMotionDuration.quick;

    var body = _expanded
        ? _ExpandedBody(
            items: widget.items,
            visibleToCustomers: widget.visibleToCustomers,
          )
        : const SizedBox.shrink();
    if (!reduceMotion) {
      body = AnimatedSize(
        duration: motionDuration,
        curve: AppMotionCurve.standard,
        alignment: Alignment.topCenter,
        child: body,
      );
    }

    Widget chevron = Icon(
      Icons.keyboard_arrow_down,
      color: colors.textSecondary,
      size: AppDimension.iconMenu,
    );
    chevron = reduceMotion
        ? Transform.rotate(
            angle: _expanded ? math.pi : 0,
            child: chevron,
          )
        : AnimatedRotation(
            turns: _expanded ? 0.5 : 0.0,
            duration: motionDuration,
            curve: AppMotionCurve.standard,
            child: chevron,
          );

    return Semantics(
      button: true,
      expanded: _expanded,
      label: 'settings.business_progress_title'.tr(),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _toggle,
        child: DecoratedBox(
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
            padding: EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Collapsed summary — always visible.
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: AppSpacing.md,
                        children: [
                          Text(
                            'settings.business_progress_title'.tr(),
                            style: typography.regularNone.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'settings.business_progress_subtitle'.tr(),
                            style: typography.smallNormal.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _ProgressRing(percent: widget.completionPercent),
                  ],
                ),
                // Expandable body — hidden-from-customers notice + checklist.
                body,
                SizedBox(height: AppSpacing.xl),
                const AppDivider(),
                SizedBox(height: AppSpacing.xl),
                Row(
                  spacing: AppSpacing.xs,
                  children: [
                    Text(
                      '${widget.requiredCompleted} / ${widget.requiredTotal}',
                      style: typography.regularNormal.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        'settings.business_progress_required_completed'.tr(),
                        style: typography.regularNormal.copyWith(
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.md),
                Center(child: chevron),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The collapsible portion of [BusinessProgressSection]: a leading divider,
/// the hidden-from-customers notice (only while the profile is not yet visible
/// to customers), and the per-item checklist. Extracted so [AnimatedSize] swaps
/// between this and an empty box on toggle.
class _ExpandedBody extends StatelessWidget {
  const _ExpandedBody({
    required this.items,
    required this.visibleToCustomers,
  });

  final List<BusinessProgressChecklistItem> items;
  final bool visibleToCustomers;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: AppSpacing.xl),
        const AppDivider(),
        SizedBox(height: AppSpacing.xl),
        if (!visibleToCustomers) ...[
          const _HiddenFromCustomersBadge(),
          SizedBox(height: AppSpacing.xl),
          Text(
            'settings.business_progress_hidden_notice'.tr(),
            style: typography.smallNormal.copyWith(
              color: colors.textSecondary,
              height: 18 / 13,
            ),
          ),
          SizedBox(height: AppSpacing.xl),
        ],
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.xxl,
          children: [
            for (final item in items) _ChecklistRow(item: item),
          ],
        ),
      ],
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: [
            const _Dot(color: _foreground, size: 8),
            Text(
              'settings.business_progress_hidden_badge'.tr(),
              style: const TextStyle(
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
