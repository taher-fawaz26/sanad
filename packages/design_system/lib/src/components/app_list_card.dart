import 'package:design_system/src/spacing/responsive_spacing.dart';
import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:design_system/src/theme/tokens/list_card_tokens.dart';
import 'package:design_system/src/theme/typography/app_typography.dart';
import 'package:flutter/material.dart';

/// Bordered list card — Figma branch row (`347:14378`).
///
/// Layout: `[Avatar] [Title + Badge / Caption] …… [trailing]`
/// on a `dark/50` surface with 8 dp radius and `dark/200` border.
class AppListCard extends StatelessWidget {
  const AppListCard({
    required this.title,
    super.key,
    this.caption,
    this.leading,
    this.badge,
    this.trailing,
    this.onTap,
    this.captionStyle,
  });

  final String title;
  final String? caption;
  final Widget? leading;
  final Widget? badge;
  final Widget? trailing;
  final VoidCallback? onTap;

  /// Overrides [ListCardTokens] caption style (e.g. primary role label).
  final TextStyle? captionStyle;

  @override
  Widget build(BuildContext context) {
    final spec = ListCardTokens.resolve(
      colors: context.appColors,
      typography: context.appTypography,
    );

    final content = ConstrainedBox(
      constraints: BoxConstraints(minHeight: spec.contentHeight),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (leading != null) ...[
            leading!,
            SizedBox(width: spec.contentGap),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        title,
                        style: spec.titleStyle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (badge != null) ...[
                      SizedBox(width: spec.contentGap),
                      Expanded(flex: 4, child: badge!),
                    ],
                  ],
                ),
                if (caption != null && caption!.isNotEmpty) ...[
                  SizedBox(height: AppSpacing.xs),
                  Text(
                    caption!,
                    style: captionStyle ?? spec.captionStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            SizedBox(width: spec.contentGap),
            trailing!,
          ],
        ],
      ),
    );

    return Material(
      color: spec.backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: spec.borderRadius,
        side: BorderSide(color: spec.borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashFactory: onTap == null ? NoSplash.splashFactory : null,
        highlightColor: Colors.transparent,
        child: Padding(
          padding: spec.padding,
          child: content,
        ),
      ),
    );
  }
}
