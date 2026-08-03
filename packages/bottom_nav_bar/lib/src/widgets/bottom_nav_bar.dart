import 'package:bottom_nav_bar/src/models/bottom_nav_destination.dart';
import 'package:bottom_nav_bar/src/theme/bottom_nav_theme_data.dart';
import 'package:bottom_nav_bar/src/widgets/bottom_nav_destination_tile.dart';
import 'package:flutter/material.dart';

/// Permanent bottom navigation bar with a center notch gap.
class BottomNavBar<T> extends StatelessWidget {
  /// Creates a bottom navigation bar.
  const BottomNavBar({
    required this.destinations,
    required this.selectedItem,
    required this.onDestinationSelected,
    required this.theme,
    super.key,
  });

  /// Permanent bar destinations (typically split around the center gap).
  final List<BottomNavDestination<T>> destinations;

  /// Currently selected navigation item (destination or action).
  final T? selectedItem;

  /// Called when a permanent destination is tapped.
  final ValueChanged<T> onDestinationSelected;

  /// Visual configuration.
  final BottomNavThemeData theme;

  @override
  Widget build(BuildContext context) {
    final half = (destinations.length / 2).ceil();
    final left = destinations.sublist(0, half);
    final right = destinations.sublist(half);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        theme.horizontalInset,
        0,
        theme.horizontalInset,
        theme.bottomInset,
      ),
      child: Material(
        elevation: theme.elevation,
        shadowColor: theme.resolveShadowColor(context),
        borderRadius: BorderRadius.circular(theme.cornerRadius),
        clipBehavior: Clip.antiAlias,
        color: theme.resolveBarColor(context),
        child: BottomAppBar(
          elevation: 0,
          height: theme.barHeight,
          padding: EdgeInsets.symmetric(horizontal: theme.contentPadding),
          color: theme.resolveBarColor(context),
          shape: const CircularNotchedRectangle(),
          notchMargin: theme.notchMargin,
          child: Row(
            children: [
              for (final destination in left)
                Expanded(
                  child: BottomNavDestinationTile<T>(
                    destination: destination,
                    selected: destination.item == selectedItem,
                    theme: theme,
                    onTap: () => onDestinationSelected(destination.item),
                  ),
                ),
              SizedBox(width: theme.centerGap),
              for (final destination in right)
                Expanded(
                  child: BottomNavDestinationTile<T>(
                    destination: destination,
                    selected: destination.item == selectedItem,
                    theme: theme,
                    onTap: () => onDestinationSelected(destination.item),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
