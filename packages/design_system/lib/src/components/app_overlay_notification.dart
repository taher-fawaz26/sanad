import 'dart:async';

import 'package:app_animations/app_animations.dart';
import 'package:design_system/src/components/app_snackbar.dart';
import 'package:design_system/src/spacing/responsive_spacing.dart';
import 'package:design_system/src/theme/tokens/snackbar_tokens.dart';
import 'package:flutter/material.dart';

// A single active notification, tracked at module scope so a new call replaces
// the previous one instead of stacking duplicates (e.g. a user repeatedly
// tapping an action that keeps failing). `_activeKey` is a fresh GlobalKey per
// call (never reused while a prior entry may still be mid-exit-animation), so
// `dismissAppOverlayNotification` can reach the still-showing widget's State
// to play its exit transition before removing it.
OverlayEntry? _activeEntry;
OverlayState? _activeOverlay;
GlobalKey<_TopNotificationState>? _activeKey;
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

  // Starts the previous notification (if any) sliding/fading out; it removes
  // itself asynchronously once that finishes, so it can briefly coexist with
  // the new one being inserted below rather than snapping away.
  dismissAppOverlayNotification();

  final key = GlobalKey<_TopNotificationState>();
  late final OverlayEntry entry;
  void handleAction() {
    dismissAppOverlayNotification();
    onAction?.call();
  }

  entry = OverlayEntry(
    builder: (context) => _TopNotification(
      key: key,
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
  _activeKey = key;
  overlay.insert(entry);
  _dismissTimer = Timer(duration, dismissAppOverlayNotification);
}

/// Dismisses the active overlay notification, if any — playing its exit
/// transition first, then removing it once that completes. Safe to call when
/// none is showing. Exposed so callers can dismiss on teardown.
void dismissAppOverlayNotification() {
  _dismissTimer?.cancel();
  _dismissTimer = null;
  final entry = _activeEntry;
  final overlay = _activeOverlay;
  final key = _activeKey;
  _activeEntry = null;
  _activeOverlay = null;
  _activeKey = null;
  if (entry == null) return;

  // Remove only while the host overlay is still alive. If the overlay itself
  // was torn down (its route/sheet closed), the entry is already gone with
  // it and removing again would throw.
  void remove() {
    if (overlay != null && overlay.mounted) entry.remove();
  }

  // An entry can be dismissed before its first build (a rapid replace), so
  // there may be no State to animate yet — fall back to an instant removal.
  final state = key?.currentState;
  if (state == null) {
    remove();
    return;
  }
  state.playExit(remove);
}

/// Top-anchored container with a short slide-and-fade entrance so the
/// notification reads as arriving from the top edge, above the modal.
class _TopNotification extends StatefulWidget {
  const _TopNotification({required this.child, super.key});

  final Widget child;

  @override
  State<_TopNotification> createState() => _TopNotificationState();
}

class _TopNotificationState extends State<_TopNotification>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotionDuration.fast,
  )..forward();

  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: AppMotionCurve.decelerated,
    reverseCurve: AppMotionCurve.accelerated,
  );
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, -0.25),
    end: Offset.zero,
  ).animate(_fade);

  /// Reverses the entrance transition, then calls [onComplete] — used by
  /// [dismissAppOverlayNotification] so the notification slides/fades back
  /// out instead of disappearing instantly. Functional motion (it
  /// communicates the notification leaving), so — matching this widget's own
  /// entrance — it is not gated by reduced motion; at
  /// [AppMotionDuration.fast] it is short enough not to be disruptive.
  void playExit(VoidCallback onComplete) {
    _controller.reverse().whenComplete(onComplete);
  }

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
