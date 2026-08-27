import 'package:app_assets/app_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:shared_ui/src/widgets/app_schedule_day_row.dart';

/// One rendered time slot within an [AppWeeklyScheduleDayGroup].
///
/// [onDelete] is null in view (read-only) mode and non-null in edit mode —
/// deletes just this slot, never the whole day.
class AppWeeklyScheduleSlotRow {
  const AppWeeklyScheduleSlotRow({
    required this.hoursLabel,
    this.onDelete,
    this.deleteSemanticLabel,
  });

  /// Fully-formatted, locale-aware label — e.g. `9:00 AM – 3:00 PM` /
  /// `9:00 ص – 3:00 م`.
  final String hoursLabel;
  final VoidCallback? onDelete;

  /// Accessibility label for the delete action. Falls back to the day label
  /// when omitted — callers should pass a real localized label.
  final String? deleteSemanticLabel;
}

/// One day rendered by [AppWeeklyScheduleDayCard] — the grouping unit shared
/// by every weekly-schedule view (working hours, branch hours, ...), so
/// they all render the exact same "one container per day" shell.
class AppWeeklyScheduleDayGroup {
  const AppWeeklyScheduleDayGroup({
    required this.dayLabel,
    required this.slots,
  });

  /// Localized weekday label (e.g. `Saturday` / `السبت`).
  final String dayLabel;

  /// Slots in chronological order. Never empty by convention — a day with
  /// zero slots is not emitted.
  final List<AppWeeklyScheduleSlotRow> slots;
}

/// One day's worth of rows — the single "day container" building block for
/// any weekly recurring schedule (working hours, branch hours, ...).
///
/// A single-slot day renders as the plain, unchanged [AppScheduleDayRow]
/// (title + time, with [AppWeeklyScheduleSlotRow.onDelete] passed straight
/// through as that row's existing delete action). A multi-slot day renders
/// as ONE [KeyValueCardTokens]-styled container — the exact same
/// background/border/radius/typography [AppScheduleDayRow] uses — holding a
/// day header (with an expand/collapse chevron) and its slot rows separated
/// by [AppDivider], each with its own delete action. There is never more
/// than one outer border per day.
class AppWeeklyScheduleDayCard extends StatelessWidget {
  const AppWeeklyScheduleDayCard({required this.group, super.key});

  final AppWeeklyScheduleDayGroup group;

  @override
  Widget build(BuildContext context) {
    if (group.slots.length <= 1) {
      final slot = group.slots.isEmpty ? null : group.slots.first;
      return AppScheduleDayRow(
        title: group.dayLabel,
        value: slot?.hoursLabel ?? '',
        onDelete: slot?.onDelete,
        deleteSemanticLabel: slot?.deleteSemanticLabel,
      );
    }
    return _MultiSlotDayGroupCard(group: group);
  }
}

/// Expand/collapse is pure presentation state — local to this card, never
/// mutating the underlying slot data — so a small [StatefulWidget] here is
/// the correct, minimal tool (no cubit/bloc needed for a UI-only toggle).
class _MultiSlotDayGroupCard extends StatefulWidget {
  const _MultiSlotDayGroupCard({required this.group});

  final AppWeeklyScheduleDayGroup group;

  @override
  State<_MultiSlotDayGroupCard> createState() => _MultiSlotDayGroupCardState();
}

class _MultiSlotDayGroupCardState extends State<_MultiSlotDayGroupCard> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    // Same token resolver AppScheduleDayRow uses internally — identical
    // background/border/radius/typography, just applied to a
    // variable-height container instead of one fixed-height row.
    final spec = KeyValueCardTokens.resolve(
      colors: colors,
      typography: typography,
      brightness: Theme.of(context).brightness,
    );

    return Material(
      color: spec.backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: spec.borderRadius,
        side: BorderSide(color: spec.borderColor),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: spec.horizontalPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.group.dayLabel,
                        style: spec.titleStyle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 150),
                      child: AppSvgPicture.asset(
                        AppSvgs.chevronDown,
                        width: AppDimension.iconMd,
                        height: AppDimension.iconMd,
                        colorFilter: ColorFilter.mode(
                          colors.textSecondary,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_expanded)
              for (final slot in widget.group.slots) ...[
                const AppDivider(),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          slot.hoursLabel,
                          style: spec.valueStyle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                        ),
                      ),
                      if (slot.onDelete != null) ...[
                        SizedBox(width: AppSpacing.sm),
                        AppIconButton(
                          onTap: slot.onDelete,
                          iconAsset: AppSvgs.trashBold,
                          size: AppIconButtonSize.small,
                          intent: AppButtonIntent.destructive,
                          semanticLabel:
                              slot.deleteSemanticLabel ?? widget.group.dayLabel,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
          ],
        ),
      ),
    );
  }
}
