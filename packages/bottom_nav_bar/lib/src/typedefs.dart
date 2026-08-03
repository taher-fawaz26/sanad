import 'package:bottom_nav_bar/src/models/bottom_nav_action.dart';
import 'package:bottom_nav_bar/src/theme/bottom_nav_theme_data.dart';
import 'package:flutter/material.dart';

/// Builds a destination or action icon for the given selection state.
typedef BottomNavIconBuilder = Widget Function(
  BuildContext context, {
  required bool selected,
});

/// Builds the center expandable control face.
typedef BottomNavFabBuilder<T> = Widget Function(
  BuildContext context, {
  required T? selectedItem,
  required bool isExpanded,
  required VoidCallback onPressed,
  required BottomNavThemeData theme,
  required List<BottomNavAction<T>> actions,
});
