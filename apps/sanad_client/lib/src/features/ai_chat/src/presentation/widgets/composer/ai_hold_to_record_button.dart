import 'package:app_assets/app_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/bloc/ai_composer_bloc.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/widgets/ai_circle_icon_button.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/widgets/composer/ai_recording_gesture.dart';

/// The composer's primary microphone: press and hold to record a voice
/// message, drag up to lock it hands-free, drag toward the leading edge to
/// discard it.
///
/// ## What it owns
///
/// Only its own pointer sequence. It dispatches intents — started, locked,
/// stopped, cancelled — and reads nothing back: whether a take is actually
/// running is [AiComposerBloc]'s answer, and the surface that draws the
/// waveform and the clock asks the bloc, not this widget. The two booleans
/// here exist because `onLongPressCancel` is ambiguous (see below), not
/// because the widget is keeping score.
///
/// ## Why the local bookkeeping is not optional
///
/// `LongPressGestureRecognizer` fires `onLongPressCancel` in two unrelated
/// situations: a quick tap that never became a long press, and the system
/// taking the pointer away from a press that *had* already started — the
/// first-ever microphone permission dialog does exactly this. `_started`
/// separates them. Without it, a stray tap while a finished take is in preview
/// would dispatch a cancellation and silently delete the user's voice message.
///
/// `_resolved` is the other half: exactly one terminal intent per sequence. A
/// cancel-drag followed by the finger lifting would otherwise dispatch both a
/// cancellation and a stop, and those are different event types, so the bloc
/// runs them concurrently. (The bloc defends itself against this too — see
/// `_releaseInFlight` — but a widget that dispatches contradictory intents is
/// a bug regardless of who catches it.)
///
/// ## Accessibility
///
/// Holding a control for the length of a message is not an interaction every
/// user can perform. When a screen reader is active the long-press recognizer
/// is not installed at all and a plain tap starts a take that is *already*
/// locked, so the explicit stop and delete controls are the whole interaction
/// and no gesture is required to reach any function. The drag path stays
/// available to everyone else — it is the default, never the only way in.
class AiHoldToRecordButton extends StatefulWidget {
  /// Creates the microphone.
  const AiHoldToRecordButton({required this.onDragUpdate, super.key});

  /// Reports how far the live gesture has travelled, so the recording surface
  /// can draw the cancel and lock rails following the finger.
  ///
  /// A callback carrying a raw offset rather than bloc state: this moves with
  /// every pointer frame, which is the one thing that must never become an
  /// `emit`. `Offset.zero` means the gesture is over.
  final ValueChanged<Offset> onDragUpdate;

  @override
  State<AiHoldToRecordButton> createState() => _AiHoldToRecordButtonState();
}

class _AiHoldToRecordButtonState extends State<AiHoldToRecordButton> {
  /// Whether this sequence got as far as asking for a take.
  bool _started = false;

  /// Whether this sequence has already dispatched a terminal intent.
  bool _resolved = false;

  /// Whether this sequence locked the take, so releasing must do nothing.
  bool _locked = false;

  /// Captured in [didChangeDependencies] rather than read in [dispose].
  ///
  /// By the time `dispose` runs the element is being unmounted and the
  /// provider above it may already be gone, so `context.read` there is not
  /// reliable — and `dispose` is exactly where an abandoned take has to be
  /// released.
  late AiComposerBloc _bloc;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _bloc = context.read<AiComposerBloc>();
  }

  @override
  void dispose() {
    // The composer went away with a finger still down and an unlocked take
    // running. Nothing will ever release it, and an unlocked take with nobody
    // holding it is by definition abandoned — but a *locked* take is
    // hands-free on purpose and must survive, so it is deliberately not
    // cancelled here.
    if (_started && !_locked && !_resolved) {
      _bloc.add(const AiComposerRecordingCancelled());
    }
    super.dispose();
  }

  /// Puts the drag affordances back where they started.
  ///
  /// Deliberately does **not** clear [_started], [_resolved] or [_locked]: they
  /// describe the sequence that just ended, and the events that end a sequence
  /// can arrive after the one that resolved it — a cancel-drag is followed by
  /// the finger lifting. Clearing them here re-armed the widget mid-sequence
  /// and let that release dispatch a second, contradicting intent. They are
  /// reset when the *next* sequence begins, which is the only moment they are
  /// meaningless.
  void _clearDrag() => widget.onDragUpdate(Offset.zero);

  void _onPressStart(LongPressStartDetails details) {
    _started = true;
    _resolved = false;
    _locked = false;
    _bloc.add(const AiComposerRecordingStarted());
  }

  void _onPressMove(LongPressMoveUpdateDetails details) {
    if (_resolved) return;
    final offset = details.offsetFromOrigin;

    if (AiRecordingGesture.cancels(offset, Directionality.of(context))) {
      _resolved = true;
      _bloc.add(const AiComposerRecordingCancelled());
      _clearDrag();
      return;
    }

    if (!_locked && AiRecordingGesture.locks(offset)) {
      _locked = true;
      _bloc.add(const AiComposerRecordingLocked());
      // The rails stop following: from here the take is hands-free and the
      // finger's position no longer means anything.
      widget.onDragUpdate(Offset.zero);
      return;
    }

    if (!_locked) widget.onDragUpdate(offset);
  }

  void _onPressEnd(LongPressEndDetails details) {
    if (_resolved) return;
    // Locked takes ignore the release — that is the whole point of locking.
    // The take now ends at the surface's explicit stop control.
    if (_locked) {
      _resolved = true;
      _clearDrag();
      return;
    }
    _resolved = true;
    _bloc.add(const AiComposerRecordingStopped());
    _clearDrag();
  }

  void _onPressCancel() {
    // Ambiguous callback: either a tap that never became a hold, or the system
    // taking a live press away. Only the second is a cancellation.
    if (!_started || _resolved) {
      _clearDrag();
      return;
    }
    _resolved = true;
    _bloc.add(const AiComposerRecordingCancelled());
    _clearDrag();
  }

  /// A tap is not a short recording — it is a miss.
  ///
  /// Dispatched from a real `TapGestureRecognizer` rather than inferred from
  /// `onLongPressCancel`, which also fires when the system steals a live
  /// press. Guessing between the two would occasionally answer a stolen
  /// gesture with a coaching hint.
  void _onTap() => _bloc.add(const AiComposerRecordingHintRequested());

  @override
  Widget build(BuildContext context) {
    // A screen reader is active: tap starts an already-locked take and the
    // gesture is not installed. The hint would be wrong here — tap *is* the
    // gesture — so it is not wired either.
    if (MediaQuery.of(context).accessibleNavigation) {
      return AiCircleIconButton(
        svgAsset: AppSvgs.aiChatComposerMic,
        semanticLabel: 'ai_chat.record_start'.tr(),
        iconColor: context.appColors.textPrimary,
        onTap: () =>
            _bloc.add(const AiComposerRecordingStarted(autoLock: true)),
      );
    }

    return Semantics(
      button: true,
      label: 'ai_chat.record_start'.tr(),
      // Announced separately: a screen-reader user is on the branch above, but
      // switch access and other assistive paths still land here, and the
      // long-press is otherwise undiscoverable.
      onLongPress: () =>
          _bloc.add(const AiComposerRecordingStarted(autoLock: true)),
      child: RawGestureDetector(
        gestures: <Type, GestureRecognizerFactory>{
          LongPressGestureRecognizer:
              GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
                // `RawGestureDetector` rather than `GestureDetector`: the
                // activation deadline is a product decision that belongs in a
                // token, and `GestureDetector` gives no way to set it.
                //
                // `postAcceptSlopTolerance` is left null so the drag is
                // unbounded — a bounded slop would reject the very movement
                // the lock and cancel gestures are made of.
                () => LongPressGestureRecognizer(
                  duration: AiRecordingGesture.holdActivation,
                  debugOwner: this,
                ),
                (recognizer) => recognizer
                  ..onLongPressStart = _onPressStart
                  ..onLongPressMoveUpdate = _onPressMove
                  ..onLongPressEnd = _onPressEnd
                  ..onLongPressCancel = _onPressCancel,
              ),
          TapGestureRecognizer:
              GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
                () => TapGestureRecognizer(debugOwner: this),
                (recognizer) => recognizer.onTap = _onTap,
              ),
        },
        child: ExcludeSemantics(
          child: AiCircleIconButton(
            svgAsset: AppSvgs.aiChatComposerMic,
            semanticLabel: 'ai_chat.record_start'.tr(),
            iconColor: context.appColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
