import 'package:activity_logs/src/domain/entities/activity_log_entry.dart';
import 'package:activity_logs/src/presentation/utils/activity_log_time_formatter.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// One timeline row: a dot + connecting line, timestamp, title (the
/// localized `name`), and an optional subtitle (`subject.name`).
///
/// Figma `Activity Log List - V2` (`6902:24787`). The dot is uniform across
/// all rows in this design — not per-action — so no icon resolver is needed
/// here.
class ActivityLogRow extends StatelessWidget {
  const ActivityLogRow({
    required this.entry,
    required this.showLine,
    super.key,
  });

  final ActivityLogEntry entry;

  /// Whether to draw the connecting line below this row's dot — false for
  /// the last row in the timeline.
  final bool showLine;

  static const _dotSize = 14.0;
  static const _dotColumnWidth = 42.0;
  static const _lineWidth = 1.5;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final locale = context.locale.toString();
    final subtitle = entry.subject?.name?.trim();

    return Padding(
      padding: EdgeInsetsDirectional.only(bottom: AppSpacing.xxl),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: responsiveDimension(_dotColumnWidth),
              child: Column(
                children: [
                  Container(
                    width: responsiveDimension(_dotSize),
                    height: responsiveDimension(_dotSize),
                    decoration: BoxDecoration(
                      color: colors.palettes.sky.shade300,
                      shape: BoxShape.circle,
                    ),
                  ),
                  if (showLine)
                    Expanded(
                      child: Center(
                        child: Container(
                          width: responsiveDimension(_lineWidth),
                          color: colors.border,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    ActivityLogTimeFormatter.format(
                      entry.timestamp,
                      locale: locale,
                    ),
                    style: typography.smallNormal.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  SizedBox(height: AppSpacing.xs),
                  Text(
                    entry.name,
                    style: typography
                        .bold(typography.regularNormal)
                        .copyWith(color: colors.primary),
                  ),
                  if (subtitle != null && subtitle.isNotEmpty) ...[
                    SizedBox(height: AppSpacing.xs),
                    Text(
                      subtitle,
                      style: typography.smallNormal.copyWith(
                        color: colors.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
