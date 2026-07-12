import 'package:branches/src/domain/entities/branch_availability_entity.dart';
import 'package:branches/src/presentation/utils/branch_schedule_formatter.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Figma schedule row (`347:14680`) with optional delete action (`347:14585`).
class BranchScheduleDayRow extends StatelessWidget {
  const BranchScheduleDayRow({
    required this.availability,
    super.key,
    this.onDelete,
  });

  final BranchAvailabilityEntity availability;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
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
      child: SizedBox(
        height: spec.height,
        width: double.infinity,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: spec.horizontalPadding),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  BranchScheduleFormatter.localizedDay(availability.day),
                  style: spec.titleStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                BranchScheduleFormatter.formatAvailability(availability),
                style: spec.valueStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
              ),
              if (onDelete != null) ...[
                SizedBox(width: AppSpacing.sm),
                IconButton(
                  onPressed: onDelete,
                  icon: Icon(
                    Icons.delete_outline,
                    size: AppDimension.iconLg,
                    color: colors.error,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 24,
                    minHeight: 24,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
