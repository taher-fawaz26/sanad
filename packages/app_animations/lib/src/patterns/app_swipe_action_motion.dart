import 'package:app_animations/src/motion/app_motion.dart';
import 'package:app_animations/src/motion/app_motion_curve.dart';
import 'package:app_animations/src/motion/app_motion_duration.dart';
import 'package:flutter/widgets.dart';

/// The shared motion vocabulary for swipe-to-reveal action panes.
///
/// Swipe actions are the one interaction in the app whose motion is **not**
/// owned by a controller of ours: the pane's opening is driven by the user's
/// finger, and the underlying `Slidable` exposes that travel as a `0 → 1`
/// animation. What a feature still has to decide is how the *contents* of
/// each action behave on the way in, and how hard a press reads — and those
/// decisions were previously nowhere, which is how a feature ends up writing
/// `Duration(milliseconds: 180)` next to its list row.
///
/// Everything here resolves to an existing token in
/// [AppMotionDuration]/[AppMotionCurve]; nothing new was invented. The value
/// of the class is that there is now one place naming which of them a swipe
/// action uses, so Conversation History and the provider's list rows cannot
/// drift apart.
abstract final class AppSwipeActionMotion {
  AppSwipeActionMotion._();

  /// How long the icon/label inside an action takes to settle once the pane
  /// has been dragged open.
  ///
  /// [AppMotionDuration.quick] — the same 200ms the segmented-control thumb
  /// and the search-field expand use. Only reached when the pane is *snapped*
  /// open; while the finger is down the reveal tracks the drag directly (see
  /// [AppSwipeActionReveal]), which is what makes it feel native rather than
  /// animated-at.
  static const Duration reveal = AppMotionDuration.quick;

  /// Settling curve for the reveal — fast out of the gate, easing to rest.
  static const Curve revealCurve = AppMotionCurve.decelerated;

  /// How long the pane takes to close itself after an action is chosen.
  ///
  /// Shorter than [reveal] on purpose: closing is an acknowledgement, not a
  /// presentation, and the dialog the action opens is what the user is
  /// actually waiting for.
  static const Duration close = AppMotionDuration.fast;

  /// Closing curve — symmetric in/out, so a pane that closes on its own reads
  /// the same as one flicked shut.
  static const Curve closeCurve = AppMotionCurve.standard;

  /// Scale applied to an action while it is held down.
  ///
  /// Deliberately shallower than `AppButtonFeedback`'s own 0.96 default: an
  /// action cell is a flush tile in a contiguous strip, and a visible shrink
  /// would open a gap against its neighbour — exactly the disconnected look
  /// the grouped pane exists to avoid.
  static const double pressedScale = 0.98;

  /// The fraction of the pane's travel that passes before the icon and label
  /// begin to appear.
  ///
  /// The cells themselves are visible from the first pixel of the drag — they
  /// are the surface being revealed. Their contents wait until the pane is a
  /// third open so that a small accidental drag shows a hint of colour rather
  /// than a sliver of half-clipped text.
  static const double contentRevealStart = 0.35;

  /// How far, in logical pixels, an action's contents travel on the way in.
  ///
  /// Small by design. The brief is "settle naturally", not "fly in": this is
  /// roughly one line-gap of movement, enough to read as arrival and not
  /// enough to read as a separate animation running on top of the drag.
  static const double contentRevealOffset = 8;
}

/// Restrained press feedback for one action cell.
///
/// A [Listener], not a `GestureDetector`: the tap itself belongs to the
/// button the cell is built from (`CustomSlidableAction` → `OutlinedButton`,
/// which already contributes its own pressed overlay). Entering the gesture
/// arena here would mean competing with that button *and* with the row's own
/// horizontal drag recogniser — so this only watches raw pointer events and
/// never claims them. Nothing about the interaction changes; only the scale
/// does, and only while a finger is down.
///
/// Under [AppMotion.reduceMotionOf] the scale is dropped and the cell stays
/// fully interactive — the feedback is decorative, the press is not.
class AppSwipeActionPress extends StatefulWidget {
  /// Wraps [child] with the press scale.
  const AppSwipeActionPress({required this.child, super.key});

  /// The action's contents.
  final Widget child;

  @override
  State<AppSwipeActionPress> createState() => _AppSwipeActionPressState();
}

class _AppSwipeActionPressState extends State<AppSwipeActionPress> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = AppMotion.reduceMotionOf(context);
    final scale = _pressed && !reduceMotion
        ? AppSwipeActionMotion.pressedScale
        : 1.0;

    return Listener(
      // Translucent, not the default `deferToChild`: an icon-and-caption
      // column has no hit-testable box of its own, so deferring would mean
      // never seeing a pointer. Translucent adds this to the hit path without
      // taking anything away from the button above it.
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: scale,
        duration: AppMotionDuration.fast,
        curve: AppSwipeActionMotion.closeCurve,
        child: widget.child,
      ),
    );
  }
}

/// Fades and settles an action's contents in step with the pane that reveals
/// them.
///
/// [progress] is the pane's own `0 → 1` opening value — `Slidable`'s
/// controller animation, not a ticker of ours. Driving the reveal from it is
/// the whole point: the contents track the finger on the way out and on the
/// way back, so there is no second animation to get out of sync with the
/// drag, nothing to cancel when the user changes their mind mid-swipe, and no
/// controller to leak when the row scrolls out of the list.
///
/// The group therefore settles as **one** surface rather than each action
/// popping in on its own schedule: every cell reads the same [progress], so
/// they are in lockstep by construction.
///
/// Under [AppMotion.reduceMotionOf] the contents are simply present — the
/// interaction is unchanged, only the fade/translate is dropped.
class AppSwipeActionReveal extends StatelessWidget {
  /// Wraps [child] with the reveal driven by [progress].
  const AppSwipeActionReveal({
    required this.progress,
    required this.child,
    super.key,
  });

  /// The enclosing pane's opening value: 0 closed, 1 fully revealed.
  final Animation<double> progress;

  /// The action's icon/label stack.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (AppMotion.reduceMotionOf(context)) return child;

    // Contents arrive from the direction the pane opens *from*, which is the
    // trailing edge in LTR and the leading one in RTL. Reading it off the
    // ambient directionality keeps that mirroring automatic.
    final sign = Directionality.of(context) == TextDirection.rtl ? -1.0 : 1.0;

    return AnimatedBuilder(
      animation: progress,
      // The icon/label subtree is built once and passed through, so a tick
      // rebuilds only the opacity/transform wrappers.
      child: child,
      builder: (context, child) {
        final t = _settle(progress.value);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(
              (1 - t) * AppSwipeActionMotion.contentRevealOffset * sign,
              0,
            ),
            child: child,
          ),
        );
      },
    );
  }

  /// Maps raw pane travel onto the contents' own eased `0 → 1`.
  static double _settle(double value) {
    const start = AppSwipeActionMotion.contentRevealStart;
    final raw = ((value.clamp(0.0, 1.0) - start) / (1 - start)).clamp(0.0, 1.0);
    return AppSwipeActionMotion.revealCurve.transform(raw);
  }
}
