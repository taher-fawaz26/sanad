import 'package:bottom_nav_bar/src/models/bottom_nav_destination.dart';
import 'package:bottom_nav_bar/src/theme/bottom_nav_theme_data.dart';
import 'package:bottom_nav_bar/src/widgets/bottom_nav_destination_tile.dart';
import 'package:bottom_nav_bar/src/widgets/bottom_nav_notch_painter.dart';
import 'package:flutter/material.dart';

/// Permanent bottom navigation bar.
///
/// When [BottomNavThemeData.centerGap] is `0`, renders a flat icon+label tab
/// bar (Figma `Bars / Tab Bars: Icon & Text`, `1526:12109`). Otherwise renders
/// a notched bar with a center gap for an expandable FAB.
class BottomNavBar<T> extends StatelessWidget {
  /// Creates a bottom navigation bar.
  const BottomNavBar({
    required this.destinations,
    required this.selectedItem,
    required this.onDestinationSelected,
    required this.theme,
    this.destinationKeys,
    super.key,
  });

  /// Permanent bar destinations.
  final List<BottomNavDestination<T>> destinations;

  /// Currently selected navigation item (destination or action).
  final T? selectedItem;

  /// Called when a permanent destination is tapped.
  final ValueChanged<T> onDestinationSelected;

  /// Visual configuration.
  final BottomNavThemeData theme;

  /// Optional [GlobalKey]s to attach to specific destination tiles, keyed by
  /// [BottomNavDestination.item] — lets callers measure a tile's on-screen
  /// position (e.g. to anchor a popover to it).
  final Map<T, GlobalKey>? destinationKeys;

  bool get _isFlat => theme.centerGap <= 0;

  @override
  Widget build(BuildContext context) {
    // Edge-to-edge Android reports system nav height in viewPadding (not
    // padding). Keep the floating bar above the system navigation/home bar.
    final safeBottom = MediaQuery.viewPaddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        theme.horizontalInset,
        0,
        theme.horizontalInset,
        theme.bottomInset + safeBottom,
      ),
      child: SizedBox(
        height: theme.barHeight,
        child: _isFlat ? _buildFlatBar(context) : _buildNotchedBar(context),
      ),
    );
  }

  Widget _buildFlatBar(BuildContext context) {
    final barColor = theme.resolveBarColor(context);
    final shadowColor = theme.resolveShadowColor(context);
    final radius = Radius.circular(theme.cornerRadius);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: barColor,
        borderRadius: BorderRadius.only(
          topLeft: radius,
          topRight: radius,
        ),
        boxShadow: theme.elevation > 0
            ? [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: theme.elevation,
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: theme.contentPadding),
        child: Row(
          children: [
            for (final destination in destinations)
              Expanded(
                child: BottomNavDestinationTile<T>(
                  key: destinationKeys?[destination.item],
                  destination: destination,
                  selected: destination.item == selectedItem,
                  theme: theme,
                  onTap: () => onDestinationSelected(destination.item),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotchedBar(BuildContext context) {
    final half = (destinations.length / 2).ceil();
    final left = destinations.sublist(0, half);
    final right = destinations.sublist(half);
    final barColor = theme.resolveBarColor(context);
    final shadowColor = theme.resolveShadowColor(context);

    return LayoutBuilder(
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
                        key: destinationKeys?[destination.item],
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
                        key: destinationKeys?[destination.item],
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
    );
  }
}
