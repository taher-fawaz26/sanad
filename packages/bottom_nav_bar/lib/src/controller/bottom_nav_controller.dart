import 'package:bottom_nav_bar/src/expandable/bottom_nav_expandable.dart';
import 'package:flutter/foundation.dart';

part 'bottom_nav_controller_binding.dart';

/// Owns expandable center UI state (expanded / collapsed).
///
/// Navigation state stays in the host application.
class BottomNavController extends ChangeNotifier {
  /// Creates a bottom navigation controller.
  BottomNavController();

  final ValueNotifier<bool> _isExpanded = ValueNotifier<bool>(false);
  BottomNavExpandable? _expandable;

  /// Listenable expanded flag for overlay / interaction gating.
  ValueListenable<bool> get isExpanded => _isExpanded;

  /// Whether the center menu is expanded.
  bool get expanded => _isExpanded.value;

  /// Opens the center menu.
  void expand() => _expandable?.expand();

  /// Closes the center menu.
  void collapse() => _expandable?.collapse();

  /// Toggles the center menu.
  void toggle() => _expandable?.toggle();

  void _bindExpandable(BottomNavExpandable expandable) {
    _expandable = expandable;
  }

  void _unbindExpandable() {
    _expandable = null;
  }

  void _handleOpen() {
    if (_isExpanded.value) return;
    _isExpanded.value = true;
    notifyListeners();
  }

  void _handleClose() {
    if (!_isExpanded.value) return;
    _isExpanded.value = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _unbindExpandable();
    _isExpanded.dispose();
    super.dispose();
  }
}
