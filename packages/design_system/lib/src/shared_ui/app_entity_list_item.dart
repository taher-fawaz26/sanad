import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:design_system/src/theme/tokens/list_card_tokens.dart';
import 'package:design_system/src/theme/typography/app_typography.dart';
import 'package:flutter/material.dart';

/// Generic bordered entity row — Figma branch / worker / invitation cards
/// (`347:14361`, `1526:12324`, `1607:12287`).
///
/// Layout: `[leading] [title / caption] [badge] …… [trailing]`
/// on a `dark/50` surface with `dark/200` border.
///
/// Use [AppEntityListItemStyle.compact] for branch rows and
/// [AppEntityListItemStyle.standard] for worker / invitation rows.
class AppEntityListItem extends StatelessWidget {
  const AppEntityListItem({
    required this.title,
    super.key,
    this.caption,
    this.leading,
    this.badge,
    this.trailing,
    this.onTap,
    this.captionStyle,
    this.titleStyle,
    this.style = AppEntityListItemStyle.standard,
  });

  final String title;
  final String? caption;
  final Widget? leading;
  final Widget? badge;
  final Widget? trailing;
  final VoidCallback? onTap;

  /// Overrides token caption style (rarely needed — default is primary).
  final TextStyle? captionStyle;

  /// Overrides token title style.
  final TextStyle? titleStyle;

  /// Density / typography variant.
  final AppEntityListItemStyle style;

  @override
  Widget build(BuildContext context) {
    final spec = ListCardTokens.resolve(
      colors: context.appColors,
      typography: context.appTypography,
      style: style,
    );

    final content = ConstrainedBox(
      constraints: BoxConstraints(minHeight: spec.contentHeight),
      child: Row(
        children: [
          Expanded(
            child: Row(
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
                      Text(
                        title,
                        style: titleStyle ?? spec.titleStyle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (caption != null && caption!.isNotEmpty) ...[
                        SizedBox(height: spec.titleCaptionGap),
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
                if (badge != null) ...[
                  SizedBox(width: spec.contentGap),
                  badge!,
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
