import 'package:flutter/widgets.dart';

/// The thresholds that make hold-to-record feel deliberate.
///
/// Constants in one documented place rather than literals inside a gesture
/// callback: they are product decisions, they are asserted by tests, and the
/// two distances have to be reasoned about *together* — a lock that triggers
/// before cancel does is a very different control from one that does not.
abstract final class AiRecordingGesture {
  AiRecordingGesture._();

  /// How long the microphone must be held before a take begins.
  ///
  /// Deliberately shorter than Flutter's 500 ms `kLongPressTimeout`. The whole
  /// gesture — hold, then drag to lock or to cancel — cannot begin until this
  /// deadline passes, because `LongPressGestureRecognizer` only accepts the
  /// pointer at that point; anything longer and a quick flick upward to lock
  /// is rejected before it is ever seen, which reads as a broken control.
  ///
  /// Long enough that a brush against the button is a tap, not a recording.
  static const holdActivation = Duration(milliseconds: 280);

  /// Upward travel, in logical pixels, that locks the take hands-free.
  ///
  /// Direction-neutral: up is up in both text directions.
  static const double lockDistance = 64;

  /// Travel toward the layout's leading edge that discards the take.
  ///
  /// Larger than [lockDistance] because the outcomes are not symmetric —
  /// locking is recoverable, discarding is not.
  static const double cancelDistance = 96;

  /// Travel before the drag affordances start to follow the finger, so a
  /// hand that is merely unsteady does not make the rail twitch.
  static const double railDeadZone = 12;

  /// Whether [offset] has travelled far enough toward the leading edge of
  /// [direction] to mean "discard this".
  ///
  /// The cancel axis mirrors — leading is left under LTR and right under RTL —
  /// so the gesture reads as "push it back where it came from" in both. The
  /// lock axis does not, which is why only this one asks about direction.
  static bool cancels(Offset offset, TextDirection direction) =>
      cancelProgress(offset, direction) >= 1;

  /// How far along the cancel gesture [offset] is, 0..1.
  static double cancelProgress(Offset offset, TextDirection direction) {
    final towardsLeading =
        offset.dx * (direction == TextDirection.rtl ? 1 : -1);
    return (towardsLeading / cancelDistance).clamp(0.0, 1.0);
  }

  /// Whether [offset] has travelled far enough upward to lock the take.
  static bool locks(Offset offset) => lockProgress(offset) >= 1;

  /// How far along the lock gesture [offset] is, 0..1.
  static double lockProgress(Offset offset) =>
      (-offset.dy / lockDistance).clamp(0.0, 1.0);
}
