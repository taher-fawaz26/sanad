part of 'bottom_nav_controller.dart';

/// Binds an expandable adapter to [BottomNavController]. Package-internal.
void bindBottomNavExpandable(
  BottomNavController controller,
  BottomNavExpandable expandable,
) {
  controller._bindExpandable(expandable);
}

/// Unbinds the expandable adapter from [BottomNavController]. Package-internal.
void unbindBottomNavExpandable(BottomNavController controller) {
  controller._unbindExpandable();
}

/// Notifies [controller] that the menu opened. Package-internal.
void notifyBottomNavOpened(BottomNavController controller) {
  controller._handleOpen();
}

/// Notifies [controller] that the menu closed. Package-internal.
void notifyBottomNavClosed(BottomNavController controller) {
  controller._handleClose();
}
