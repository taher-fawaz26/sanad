import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:design_system/src/theme/tokens/key_value_card_tokens.dart';
import 'package:design_system/src/theme/typography/app_typography.dart';
import 'package:flutter/material.dart';

/// Figma schedule info row (`347:14680`) — bordered key/value card.
class AppKeyValueCard extends StatelessWidget {
  const AppKeyValueCard({
    required this.title,
    required this.value,
    super.key,
    this.valueColor,
    this.onTap,
  });

  final String title;
  final String value;
  final Color? valueColor;
  final VoidCallback? onTap;

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
      child: InkWell(
        onTap: onTap,
        borderRadius: spec.borderRadius,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
