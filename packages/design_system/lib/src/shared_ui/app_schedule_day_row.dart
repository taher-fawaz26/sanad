import 'package:app_assets/app_assets.dart';
import 'package:design_system/src/components/app_svg_picture.dart';
import 'package:design_system/src/dimensions/responsive_dimension.dart';
import 'package:design_system/src/spacing/responsive_spacing.dart';
import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:design_system/src/theme/tokens/key_value_card_tokens.dart';
import 'package:design_system/src/theme/typography/app_typography.dart';
import 'package:flutter/material.dart';

/// Figma schedule row (`347:14680`, `3821:18513`) with optional delete action
/// (`347:14585`).
class AppScheduleDayRow extends StatelessWidget {
  const AppScheduleDayRow({
    required this.title,
    required this.value,
    super.key,
    this.valueColor,
    this.onDelete,
  });

  final String title;
  final String value;
  final Color? valueColor;
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
                  title,
                  style: spec.titleStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                value,
                style: spec.valueStyle.copyWith(color: valueColor),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
              ),
              if (onDelete != null) ...[
                SizedBox(width: AppSpacing.sm),
                IconButton(
                  onPressed: onDelete,
                  icon: AppSvgPicture.asset(
                    AppSvgs.trashBold,
                    width: AppDimension.iconLg,
                    height: AppDimension.iconLg,
                    colorFilter: ColorFilter.mode(
                      colors.error,
                      BlendMode.srcIn,
                    ),
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
