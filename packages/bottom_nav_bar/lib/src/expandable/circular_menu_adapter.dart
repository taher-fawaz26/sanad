import 'package:bottom_nav_bar/src/expandable/bottom_nav_expandable.dart';
import 'package:bottom_nav_bar/src/widgets/circular_menu.dart';
import 'package:flutter/material.dart';

/// Adapts [CircularMenuState] to [BottomNavExpandable].
class CircularMenuAdapter implements BottomNavExpandable {
  CircularMenuAdapter(this._key);

  final GlobalKey<CircularMenuState> _key;

  @override
  bool get isExpanded => _key.currentState?.isOpen ?? false;

  @override
  void expand() => _key.currentState?.forwardAnimation();

  @override
  void collapse() => _key.currentState?.reverseAnimation();

  @override
  void toggle() => _key.currentState?.toggle();
}
