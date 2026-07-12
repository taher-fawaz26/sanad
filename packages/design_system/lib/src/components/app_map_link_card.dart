import 'package:design_system/src/spacing/responsive_spacing.dart';
import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:design_system/src/theme/tokens/map_link_card_tokens.dart';
import 'package:design_system/src/theme/typography/app_typography.dart';
import 'package:flutter/material.dart';

/// Figma location row — pin, address, "Open in Maps", external link (`194:2647`).
class AppMapLinkCard extends StatelessWidget {
  const AppMapLinkCard({
    required this.title,
    required this.caption,
    super.key,
    this.leading,
    this.onTap,
  });

  final String title;
  final String caption;
  final Widget? leading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final brightness = Theme.of(context).brightness;
    final spec = MapLinkCardTokens.resolve(
      colors: colors,
      typography: typography,
      brightness: brightness,
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
        child: Padding(
          padding: spec.padding,
          child: Row(
            children: [
              if (leading != null) ...[
                SizedBox(
                  width: spec.iconSize,
                  height: spec.iconSize,
                  child: leading,
                ),
                SizedBox(width: spec.contentGap),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: spec.titleStyle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: AppSpacing.xs),
                    Text(
                      caption,
                      style: spec.captionStyle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              SizedBox(width: spec.contentGap),
              Icon(
                Icons.open_in_new,
                size: spec.trailingIconSize,
                color: spec.trailingIconColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
