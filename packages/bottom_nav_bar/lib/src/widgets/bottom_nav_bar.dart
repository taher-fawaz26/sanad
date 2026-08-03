import 'package:bottom_nav_bar/src/models/bottom_nav_destination.dart';
import 'package:bottom_nav_bar/src/theme/bottom_nav_theme_data.dart';
import 'package:bottom_nav_bar/src/widgets/bottom_nav_destination_tile.dart';
import 'package:bottom_nav_bar/src/widgets/bottom_nav_notch_painter.dart';
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
    final barColor = theme.resolveBarColor(context);
    final shadowColor = theme.resolveShadowColor(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        theme.horizontalInset,
        0,
        theme.horizontalInset,
        theme.bottomInset,
      ),
      child: SizedBox(
        height: theme.barHeight,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final notchCX = constraints.maxWidth / 2;

            return Stack(
              fit: StackFit.expand,
              children: [
                CustomPaint(
                  painter: BottomNavNotchPainter(
                    theme: theme,
                    barColor: barColor,
                    shadowColor: shadowColor,
                    notchCX: notchCX,
                    notchR: theme.notchRadius,
                    fabSink: theme.resolveFabSink(),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    theme.contentPadding,
                    0,
                    theme.contentPadding,
                    theme.contentPadding / 2,
                  ),
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
              ],
            );
          },
        ),
      ),
    );
  }
}
