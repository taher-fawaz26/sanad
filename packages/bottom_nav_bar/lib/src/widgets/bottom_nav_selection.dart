import 'package:bottom_nav_bar/src/models/bottom_nav_action.dart';
import 'package:bottom_nav_bar/src/models/bottom_nav_destination.dart';
/// Shared selection helpers for bar and center widgets.
abstract final class BottomNavSelection {
  BottomNavSelection._();

  /// Whether [item] matches a center action (not a permanent destination).
  static bool isActionSelected<T>(
    T? item,
    List<BottomNavAction<T>> actions,
  ) {
    if (item == null) return false;
    for (final action in actions) {
      if (action.item == item) return true;
    }
    return false;
  }

  /// Whether [destination] should render as selected.
  static bool isDestinationSelected<T>(
    BottomNavDestination<T> destination,
    T? selectedItem,
    List<BottomNavAction<T>> actions,
  ) {
    if (selectedItem == null) return false;
    if (isActionSelected(selectedItem, actions)) return false;
    return destination.item == selectedItem;
  }

  /// Returns the matching action for [selectedItem], if any.
  static BottomNavAction<T>? findAction<T>(
    T? selectedItem,
    List<BottomNavAction<T>> actions,
  ) {
    if (selectedItem == null) return null;
    for (final action in actions) {
      if (action.item == selectedItem) return action;
    }
    return null;
  }
}
