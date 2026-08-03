import 'package:bottom_nav_bar/src/models/bottom_nav_destination.dart';
import 'package:bottom_nav_bar/src/theme/bottom_nav_theme_data.dart';
import 'package:flutter/material.dart';

/// Internal tile for one permanent destination.
class BottomNavDestinationTile<T> extends StatelessWidget {
  const BottomNavDestinationTile({
    required this.destination,
    required this.selected,
    required this.theme,
    required this.onTap,
    super.key,
  });

  final BottomNavDestination<T> destination;
  final bool selected;
  final BottomNavThemeData theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = destination.semanticLabel ?? destination.label;
    final enabled = destination.enabled;

    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      label: label,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (destination.badgeBuilder != null) destination.badgeBuilder!(context),
            _buildIcon(context),
            SizedBox(height: theme.contentPadding / 3),
            Text(
              destination.label,
              style: theme.resolveLabelStyle(context, selected: selected),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(BuildContext context) {
    final builder = selected && destination.selectedIconBuilder != null
        ? destination.selectedIconBuilder!
        : destination.iconBuilder;
    return builder(context, selected: selected);
  }
}
