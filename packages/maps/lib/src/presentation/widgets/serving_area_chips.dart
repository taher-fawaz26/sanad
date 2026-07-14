import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:maps/src/domain/entities/serving_area.dart';

class ServingAreaChips extends StatelessWidget {
  const ServingAreaChips({
    required this.areas,
    this.onRemoved,
    this.emptyMessage,
    super.key,
  });

  final List<ServingArea> areas;
  final ValueChanged<ServingArea>? onRemoved;
  final String? emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (areas.isEmpty) {
      return emptyMessage != null
          ? Padding(
              padding: EdgeInsets.symmetric(
                vertical: AppSpacing.md,
              ),
              child: Text(
                emptyMessage!,
                style: context.appTypography.smallNormal.copyWith(
                  color: context.appColors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            )
          : const SizedBox.shrink();
    }

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final area in areas)
          AppChip(
            label: area.name,
            style: AppChipStyle.outline,
            selected: true,
            iconPosition: AppChipIconPosition.right,
            icon: onRemoved != null
                ? Icon(
                    Icons.close,
                    size: AppDimension.iconCompact,
                    color: context.appColors.primary,
                  )
                : null,
            onTap: onRemoved != null
                ? () => onRemoved!(area)
                : null,
          ),
      ],
    );
  }
}
