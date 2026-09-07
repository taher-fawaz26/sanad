import 'dart:async';

import 'package:design_system/src/components/app_snackbar.dart';
import 'package:design_system/src/spacing/responsive_spacing.dart';
import 'package:design_system/src/theme/tokens/snackbar_tokens.dart';
import 'package:flutter/material.dart';

// A single active notification, tracked at module scope so a new call replaces
// the previous one instead of stacking duplicates (e.g. a user repeatedly
// tapping an action that keeps failing).
OverlayEntry? _activeEntry;
OverlayState? _activeOverlay;
Timer? _dismissTimer;

/// Shows a transient notification anchored to the **top** of the screen in the
/// **root** overlay, so it renders *above* modal routes (bottom sheets,
/// dialogs) where a [ScaffoldMessenger] snackbar would be hidden behind the
/// modal. Reuses the design-system [AppSnackbar] visual — this is a new
/// *presentation surface* for the existing component, not a new notification
/// style.
///
/// A new call replaces any notification still showing (no stacking); the entry
/// auto-dismisses after [duration], or when its action is tapped.
void showAppOverlayNotification({
  required BuildContext context,
  required String title,
  String? caption,
  AppSnackbarColor color = AppSnackbarColor.error,
  AppSnackbarAction action = AppSnackbarAction.none,
  String? actionLabel,
  VoidCallback? onAction,
  Duration duration = const Duration(seconds: 4),
}) {
  // rootOverlay: true climbs to the Navigator's root overlay, which sits above
  // any pushed modal route — the reason a ScaffoldMessenger snackbar (anchored
  // to the underlying page's Scaffold) is hidden behind the sheet.
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;

  dismissAppOverlayNotification();

  late final OverlayEntry entry;
  void handleAction() {
    dismissAppOverlayNotification();
    onAction?.call();
  }

  entry = OverlayEntry(
    builder: (context) => _TopNotification(
      child: AppSnackbar(
        title: title,
        caption: caption,
        color: color,
        action: action,
        actionLabel: actionLabel,
        onAction: action == AppSnackbarAction.text ? handleAction : null,
      ),
    ),
  );

  _activeEntry = entry;
  _activeOverlay = overlay;
  overlay.insert(entry);
  _dismissTimer = Timer(duration, dismissAppOverlayNotification);
}

/// Removes the active overlay notification, if any. Safe to call when none is
/// showing. Exposed so callers can dismiss on teardown.
void dismissAppOverlayNotification() {
  _dismissTimer?.cancel();
  _dismissTimer = null;
  final entry = _activeEntry;
  final overlay = _activeOverlay;
  _activeEntry = null;
  _activeOverlay = null;
  if (entry == null) return;
  // Remove only while the host overlay is still alive. An inserted entry can
  // be removed before its first build (a rapid replace), so we can't gate on
  // `entry.mounted`; but if the overlay itself was torn down (its route/sheet
  // closed), the entry is already gone with it and removing again would throw.
  if (overlay != null && overlay.mounted) entry.remove();
}

/// Top-anchored container with a short slide-and-fade entrance so the
/// notification reads as arriving from the top edge, above the modal.
class _TopNotification extends StatefulWidget {
  const _TopNotification({required this.child});

  final Widget child;

  @override
  State<_TopNotification> createState() => _TopNotificationState();
}

class _TopNotificationState extends State<_TopNotification>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  )..forward();

  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, -0.25),
    end: Offset.zero,
  ).animate(_fade);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: FadeTransition(
            opacity: _fade,
            child: SlideTransition(
              position: _slide,
              // A raw OverlayEntry builds under the root Overlay, which carries
              // the app Theme/Directionality/Localizations/MediaQuery but has
              // NO Material ancestor. Without one, Text falls back to
              // WidgetsApp's error DefaultTextStyle (the yellow, underlined
              // "no Material" style), which is why the notification rendered
              // underlined/hyperlink-like. A transparent Material restores the
              // theme's DefaultTextStyle so [AppSnackbar] renders exactly as it
              // does inside a Scaffold — same layer fix, no style duplication.
              child: Material(
                type: MaterialType.transparency,
                child: Align(child: widget.child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
