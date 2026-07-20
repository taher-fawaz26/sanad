import 'package:design_system/src/shared_ui/app_entity_list_item.dart';
import 'package:design_system/src/theme/tokens/list_card_tokens.dart';
import 'package:flutter/material.dart';

/// Backward-compatible alias for [AppEntityListItem].
///
/// Prefer [AppEntityListItem] in new code. Defaults to
/// [AppEntityListItemStyle.compact] (branch card density).
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
    this.style = AppEntityListItemStyle.compact,
  });

  final String title;
  final String? caption;
  final Widget? leading;
  final Widget? badge;
  final Widget? trailing;
  final VoidCallback? onTap;
  final TextStyle? captionStyle;
  final AppEntityListItemStyle style;

  @override
  Widget build(BuildContext context) {
    return AppEntityListItem(
      title: title,
      caption: caption,
      leading: leading,
      badge: badge,
      trailing: trailing,
      onTap: onTap,
      captionStyle: captionStyle,
      style: style,
    );
  }
}
