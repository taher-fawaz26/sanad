import 'package:design_system/src/components/app_button.dart';
import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:design_system/src/theme/tokens/button_tokens.dart';
import 'package:design_system/src/theme/tokens/stat_card_tokens.dart';
import 'package:design_system/src/theme/typography/app_typography.dart';
import 'package:flutter/material.dart';

/// Bordered KPI/stat card — Figma `kpi-card` (`1563:11021`).
///
/// Layout: `[icon circle] [count / label] …… [outline pill button]`.
class AppStatCard extends StatelessWidget {
  const AppStatCard({
    required this.icon,
    required this.iconBackgroundColor,
    required this.count,
    required this.label,
    required this.actionLabel,
    this.onActionTap,
    super.key,
  });

  final Widget icon;
  final Color iconBackgroundColor;
  final String count;
  final String label;
  final String actionLabel;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    final spec = StatCardTokens.resolve(
      colors: context.appColors,
      typography: context.appTypography,
    );

    return Container(
      padding: spec.padding,
      decoration: BoxDecoration(
        color: spec.backgroundColor,
        borderRadius: spec.borderRadius,
        border: Border.all(color: spec.borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: spec.iconCircleSize,
            height: spec.iconCircleSize,
            decoration: BoxDecoration(
              color: iconBackgroundColor,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: icon,
          ),
          SizedBox(width: spec.contentGap),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(count, style: spec.countStyle),
                SizedBox(height: spec.textGap),
                Text(label, style: spec.labelStyle),
              ],
            ),
          ),
          SizedBox(width: spec.contentGap),
          AppButtonPresets.outline(
            label: actionLabel,
            onPressed: onActionTap,
            size: AppButtonSize.small,
            icon: const Icon(Icons.arrow_forward, size: 16),
            iconPosition: AppButtonIconPosition.left,
          ),
        ],
      ),
    );
  }
}
