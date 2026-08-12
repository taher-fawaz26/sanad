import 'package:flutter/material.dart';

/// Contract for a [PopupMenu] content layout (grid or list).
abstract class MenuLayout {
  /// Total content width, excluding the pointer triangle.
  double get width;

  /// Total content height, excluding the pointer triangle.
  double get height;

  /// Builds the menu content.
  Widget build();
}
