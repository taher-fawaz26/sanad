import 'package:bottom_nav_bar/src/typedefs.dart';
import 'package:flutter/foundation.dart';

/// An expandable center navigation action.
@immutable
class BottomNavAction<T> {
  /// Creates a center expandable action.
  const BottomNavAction({
    required this.item,
    required this.iconBuilder,
    this.label,
    this.semanticLabel,
  });

  /// Application-defined identifier (enum, int, String, etc.).
  final T item;

  /// Builds the action icon.
  final BottomNavIconBuilder iconBuilder;

  /// Optional visible label (future use / accessibility).
  final String? label;

  /// Accessibility label; defaults to [label].
  final String? semanticLabel;
}
