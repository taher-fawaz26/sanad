import 'package:bottom_nav_bar/src/typedefs.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// A permanent bottom navigation bar item.
@immutable
class BottomNavDestination<T> {
  /// Creates a bottom navigation destination.
  const BottomNavDestination({
    required this.item,
    required this.label,
    required this.iconBuilder,
    this.selectedIconBuilder,
    this.badgeBuilder,
    this.enabled = true,
    this.semanticLabel,
  });

  /// Application-defined identifier (enum, int, String, etc.).
  final T item;

  /// Visible label — already localized by the host app.
  final String label;

  /// Builds the icon for unselected and default selected states.
  final BottomNavIconBuilder iconBuilder;

  /// Optional icon when selected; falls back to [iconBuilder].
  final BottomNavIconBuilder? selectedIconBuilder;

  /// Optional badge widget above or beside the icon.
  final WidgetBuilder? badgeBuilder;

  /// Whether this destination accepts taps.
  final bool enabled;

  /// Accessibility label; defaults to [label].
  final String? semanticLabel;
}
