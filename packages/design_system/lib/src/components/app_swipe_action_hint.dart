import 'dart:async';

import 'package:app_animations/app_animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

/// Drives a one-time "peek" animation on a single `AppSwipeActions` row to
/// teach first-time users that swipe actions exist, without ever invoking
/// one (actions only fire on tap, never on swipe).
///
/// Wrap exactly one list item — normally the first row — and thread
/// [builder]'s [SlidableController] into that item's `AppSwipeActions`
/// (e.g. via a feature-local `hintController` field). When [enabled] turns
/// true, the widget waits [initialDelay], nudges the row's end action pane
/// open to [peekFraction] of its extent, holds, then closes it — [repeats]
/// times. [onShown] fires exactly once, either after the sequence completes
/// or as soon as the user starts a real interaction (tap/scroll/swipe),
/// whichever comes first — the caller uses it to persist "seen" so the hint
/// never plays again.
///
/// Respects reduced motion (`AppMotion.reduceMotionOf`) by skipping the
/// animation outright and calling [onShown] immediately — screen-reader
/// users reach actions through the per-action `Semantics` tree, not swipe.
class AppSwipeActionHint extends StatefulWidget {
  const AppSwipeActionHint({
    required this.enabled,
    required this.builder,
    required this.onShown,
    super.key,
    this.peekFraction = 0.55,
    this.initialDelay = const Duration(milliseconds: 450),
    this.revealDuration = AppMotionDuration.normal,
    this.hold = const Duration(milliseconds: 700),
    this.closeDuration = AppMotionDuration.normal,
    this.repeats = 1,
  }) : assert(
         peekFraction > 0 && peekFraction <= 1,
         'peekFraction must be within (0, 1].',
       ),
       assert(repeats >= 1, 'repeats must be at least 1.');

  /// Whether the hint should attempt to play. The caller resolves
  /// eligibility (already seen? loading? empty list?) before flipping this
  /// to true.
  final bool enabled;

  /// Builds the wrapped list item, given the controller to thread into its
  /// `AppSwipeActions`.
  final Widget Function(BuildContext context, SlidableController controller)
  builder;

  /// Fired exactly once — after the sequence finishes normally, is skipped
  /// (reduce-motion/screen-reader/not swipeable), or is cancelled by a real
  /// user interaction. Use this to persist "hint seen".
  final VoidCallback onShown;

  /// Fraction of the row's own end-action-pane extent to reveal — a fraction
  /// of the pane, never more, so the peek can't overshoot into an action.
  final double peekFraction;

  final Duration initialDelay;
  final Duration revealDuration;
  final Duration hold;
  final Duration closeDuration;

  /// Number of reveal→hold→close cycles to play.
  final int repeats;

  /// Pause between the end of one cycle's close and the start of the next,
  /// when [repeats] is greater than 1.
  static const Duration betweenRepeatsDelay = Duration(milliseconds: 250);

  @override
  State<AppSwipeActionHint> createState() => _AppSwipeActionHintState();
}

class _AppSwipeActionHintState extends State<AppSwipeActionHint>
    with SingleTickerProviderStateMixin {
  late final SlidableController _controller = SlidableController(this);
  final List<Timer> _timers = [];
  bool _done = false;
  bool _armed = false;

  @override
  void initState() {
    super.initState();
    if (widget.enabled) _arm();
  }

  @override
  void didUpdateWidget(covariant AppSwipeActionHint oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled && !oldWidget.enabled) _arm();
  }

  void _arm() {
    if (_armed || _done) return;
    _armed = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeStart());
  }

  Future<void> _maybeStart() async {
    if (_done || !mounted) return;

    if (AppMotion.reduceMotionOf(context)) {
      _finish();
      return;
    }

    // A row with no actions never attaches an `endActionPane` — see
    // `AppSwipeActions`'s empty-actions early return — so this stays 0.
    if (_controller.endActionPaneExtentRatio <= 0) {
      _finish();
      return;
    }

    for (var i = 0; i < widget.repeats; i++) {
      if (_done || !mounted) return;
      final gap = i == 0
          ? widget.initialDelay
          : AppSwipeActionHint.betweenRepeatsDelay;
      if (!await _delay(gap)) return;

      if (_done || !mounted) return;
      // Mirrors `SlidableController.openEndActionPane`'s own priming step
      // (same sign, same branch) so the correct side opens in both LTR and
      // RTL — only the target magnitude (a peek, not the full extent)
      // differs from what that method would drive to.
      if (_controller.actionPaneType.value != ActionPaneType.end) {
        _controller.direction.value = _controller.isLeftToRight ? -1 : 1;
        _controller.ratio = 0;
      }
      final peek = widget.peekFraction * _controller.endActionPaneExtentRatio;
      await _controller.openTo(
        -peek,
        duration: widget.revealDuration,
        curve: AppMotionCurve.standard,
      );

      if (_done || !mounted) return;
      if (!await _delay(widget.hold)) return;

      if (_done || !mounted) return;
      await _controller.close(
        duration: widget.closeDuration,
        curve: AppMotionCurve.standard,
      );
    }

    _finish();
  }

  /// Waits for [duration], or returns `false` immediately if cancelled.
  Future<bool> _delay(Duration duration) {
    final completer = Completer<bool>();
    late final Timer timer;
    timer = Timer(duration, () {
      _timers.remove(timer);
      if (!completer.isCompleted) completer.complete(!_done && mounted);
    });
    _timers.add(timer);
    return completer.future;
  }

  void _cancel(PointerDownEvent event) {
    if (_done) return;
    unawaited(_controller.close());
    _finish();
  }

  void _finish() {
    if (_done) return;
    _done = true;
    for (final timer in _timers) {
      timer.cancel();
    }
    _timers.clear();
    widget.onShown();
  }

  @override
  void dispose() {
    for (final timer in _timers) {
      timer.cancel();
    }
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Non-capturing: `Listener` observes pointer-down without joining the
    // gesture arena, so it never competes with the row's own tap/scroll/
    // swipe handling. Programmatic `openTo`/`close` drive the
    // `AnimationController` directly and emit no pointer events, so they
    // never trigger this callback themselves.
    return Listener(
      onPointerDown: _cancel,
      child: widget.builder(context, _controller),
    );
  }
}
