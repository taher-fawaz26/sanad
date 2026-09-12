import 'package:ai_ui_protocol/ai_ui_protocol.dart';
import 'package:flutter/foundation.dart';

/// Where one semantic node is in its answer lifecycle.
///
/// ```text
/// active ──► pending ──► submitted
///   │           │
///   ▼           ▼
/// cancelled   failed ──► active   (retryable — never a dead card)
/// ```
///
/// `expired` and `superseded` are deliberately **not** modelled. Nothing in
/// the protocol carries a TTL, and in a scrollback an older card staying
/// answerable is the honest behaviour: the user scrolling back to a question
/// they skipped should be able to answer it, and the agent is the only party
/// that knows whether the answer is still useful.
enum AiUiNodeInteractionState {
  /// Nobody has answered. The controls are live.
  active,

  /// A submission is in flight. Controls are disabled — this is what stops
  /// the second tap of a double tap.
  pending,

  /// Answered. Terminal for this node.
  submitted,

  /// The user declined or dismissed. Terminal for this node.
  cancelled,

  /// The submission did not reach the agent. Controls come back, because a
  /// network blip must not leave the user staring at a card they cannot use.
  failed
  ;

  /// Whether a fresh submission is allowed right now.
  bool get acceptsSubmission =>
      this == AiUiNodeInteractionState.active ||
      this == AiUiNodeInteractionState.failed;

  /// Whether the node's controls should be enabled.
  bool get isInteractive => acceptsSubmission;
}

/// Tracks the answer lifecycle of every semantic node on screen.
///
/// ## Why the lifecycle is not widget state
///
/// It used to be: `_ReviewRequestState._submitted` guarded exactly one of the
/// three interactive cards, and `time_slots` and `location_picker` had no
/// guard at all. Widget state is also the wrong owner for a value that has to
/// survive a rebuild and be readable by a *transport* callback — the ledger is
/// what lets the chat bloc mark a submission failed and have the right card
/// re-enable itself.
///
/// ## Why a listenable per node, not one ChangeNotifier
///
/// The conversation is a `ListView` of bubbles. If answering one card
/// notified a single shared listenable, every card on screen would rebuild;
/// if it went through bloc state, the whole list would. [watch] hands out one
/// [ValueListenable] per node id, so a slot selection rebuilds exactly the
/// button that changed. This is the same reasoning as `ActiveStreamController`
/// for streaming tokens.
class AiUiInteractionLedger {
  final Map<String, ValueNotifier<AiUiNodeInteractionState>> _states = {};
  bool _disposed = false;

  /// The current state of [nodeId]. Unknown nodes are [
  /// AiUiNodeInteractionState.active] — a node nobody has touched is
  /// answerable, which is what makes the ledger safe to consult before
  /// anything has been recorded.
  AiUiNodeInteractionState stateOf(String nodeId) =>
      _states[nodeId]?.value ?? AiUiNodeInteractionState.active;

  /// A listenable scoped to [nodeId], created on first use.
  ///
  /// Safe to call from `build`: the notifier is memoised per id, so repeated
  /// builds return the same instance and do not churn listeners.
  ValueListenable<AiUiNodeInteractionState> watch(String nodeId) =>
      _notifier(nodeId);

  /// Whether [nodeId] may submit right now.
  bool canSubmit(String nodeId) => stateOf(nodeId).acceptsSubmission;

  /// Claims [nodeId] for a submission.
  ///
  /// Returns `false` when the node is already pending or terminal, which is
  /// the single place duplicate submission is prevented. Callers must not
  /// send anything when this returns `false`.
  bool beginSubmission(String nodeId) {
    if (_disposed || !canSubmit(nodeId)) return false;
    _notifier(nodeId).value = AiUiNodeInteractionState.pending;
    return true;
  }

  /// Records that the agent received the answer.
  void markSubmitted(String nodeId) =>
      _set(nodeId, AiUiNodeInteractionState.submitted);

  /// Records that the user declined or dismissed.
  void markCancelled(String nodeId) =>
      _set(nodeId, AiUiNodeInteractionState.cancelled);

  /// Records a failed send. The node becomes answerable again.
  void markFailed(String nodeId) =>
      _set(nodeId, AiUiNodeInteractionState.failed);

  /// Returns [nodeId] to [AiUiNodeInteractionState.active].
  ///
  /// Used when a surface is torn down with a node still pending — a voice
  /// session ending mid-question — so the card is not left permanently
  /// disabled by a submission that can no longer complete.
  void reset(String nodeId) => _set(nodeId, AiUiNodeInteractionState.active);

  void _set(String nodeId, AiUiNodeInteractionState state) {
    if (_disposed) return;
    _notifier(nodeId).value = state;
  }

  ValueNotifier<AiUiNodeInteractionState> _notifier(String nodeId) =>
      _states.putIfAbsent(
        nodeId,
        () => ValueNotifier(AiUiNodeInteractionState.active),
      );

  /// Resolves [nodeId] from the status the answer carried.
  ///
  /// The one place the mapping lives. Both transports resolve a node the
  /// moment their send returns, and a cancellation that resolved as
  /// `submitted` would leave a declined card on screen — which is exactly the
  /// bug this method exists to make unrepresentable.
  void resolve(String nodeId, AiUiInteractionStatus status) {
    switch (status) {
      case AiUiInteractionStatus.submitted:
        markSubmitted(nodeId);
      case AiUiInteractionStatus.cancelled:
        markCancelled(nodeId);
      case AiUiInteractionStatus.failed:
        markFailed(nodeId);
    }
  }

  /// Releases every notifier. Idempotent, because a `ValueNotifier` asserts on
  /// a second dispose and the owning bloc's `close()` can run twice under a
  /// hot restart.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    for (final notifier in _states.values) {
      notifier.dispose();
    }
    _states.clear();
  }
}
