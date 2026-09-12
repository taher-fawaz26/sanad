import 'package:ai_ui_protocol/src/domain/ai_ui_node_type.dart';
import 'package:ai_ui_protocol/src/domain/interaction/ai_ui_interaction_value.dart';
import 'package:equatable/equatable.dart';

/// What the user did.
///
/// The mirror of `AiUiActionType`: that enum is the closed catalog of things
/// an agent may *request*, this one is the closed catalog of results a client
/// may *return*. Keeping them separate is what makes "the agent asks, the
/// client answers" structural — an action can never be smuggled back as a
/// result, and a result can never be executed.
enum AiUiInteractionKind {
  /// A `quick_reply` option was tapped.
  quickReplySelected('quick_reply_selected'),

  /// A `time_slots` selection was confirmed.
  slotSelected('slot_selected'),

  /// A `review_request` comment was submitted.
  reviewSubmitted('review_submitted'),

  /// A `location_picker` choice was confirmed.
  locationSelected('location_selected'),

  /// A `location_confirm` address was accepted.
  locationConfirmed('location_confirmed'),

  /// A capability request resolved — from a `permission_request` node or from
  /// a bare `request_permission` / `request_location_share` action.
  permissionResult('permission_result'),

  /// A `media_request` resolved.
  mediaResult('media_result'),

  /// A yes-or-no the agent asked was answered — the `confirm` block on a
  /// `request_summary`, a `confirm_prompt`, a `location_confirm`'s cancel.
  ///
  /// One kind for all three rather than one per card: the agent asked "shall
  /// I?", and what comes back is whether it may. Which card carried the
  /// question is already in [AiUiInteraction.nodeType].
  confirmationResolved('confirmation_resolved'),

  /// A `provider_card` offer was accepted or declined.
  offerResolved('offer_resolved')
  ;

  const AiUiInteractionKind(this.wire);

  /// The exact JSON value on the wire.
  final String wire;

  /// Resolves [value], or `null` when it names no member.
  static AiUiInteractionKind? tryFromWire(String value) {
    for (final candidate in values) {
      if (candidate.wire == value) return candidate;
    }
    return null;
  }
}

/// How the interaction ended.
///
/// A cancellation is *sent*, not swallowed: an agent that asked a question and
/// hears nothing back cannot tell "the user declined" from "the client is
/// broken", and would either wait forever or repeat itself.
enum AiUiInteractionStatus {
  /// The user answered.
  submitted('submitted'),

  /// The user declined, dismissed, or backed out.
  cancelled('cancelled'),

  /// The client could not complete the interaction. The card stays
  /// answerable — see the lifecycle in `AiUiInteractionLedger`.
  failed('failed')
  ;

  const AiUiInteractionStatus(this.wire);

  /// The exact JSON value on the wire.
  final String wire;

  /// Resolves [value], or `null` when it names no member.
  static AiUiInteractionStatus? tryFromWire(String value) {
    for (final candidate in values) {
      if (candidate.wire == value) return candidate;
    }
    return null;
  }
}

/// One structured answer travelling client → agent.
///
/// ## Why this exists next to the template mechanism
///
/// The interactive cards already post a sentence built from an agent-supplied
/// template (`"Book me for {slot}"`). That sentence stays — it is what the
/// conversation reads like, and it is what a backend that has not implemented
/// this type still understands. What it cannot carry is *which* node was
/// answered, *which* message asked, or whether the answer already arrived.
/// This type carries exactly that, alongside the prose in [text].
///
/// ## Correlation
///
/// [nodeId] is `AiUiNode.id` — agent-supplied, or derived by the validator
/// from the node's path in the document. [messageId] is the `AiChatEvent`
/// that delivered the node. The conversation is identified by the turn body
/// that wraps this, not repeated here.
///
/// [interactionId] is the only genuinely new identifier, and it exists for
/// idempotency: a key has to be minted by the client *before* the request
/// leaves, so a retry can be recognised as the same answer. Nothing that
/// already exists can play that role.
///
/// The same type crosses both transports. Chat sends it as a field on the
/// turn body; live voice sends it over the session's own channel. Neither
/// owns it.
final class AiUiInteraction extends Equatable {
  /// Creates an interaction result.
  const AiUiInteraction({
    required this.interactionId,
    required this.nodeId,
    required this.kind,
    required this.value,
    this.nodeType,
    this.messageId,
    this.status = AiUiInteractionStatus.submitted,
    this.text,
    this.createdAt,
  });

  /// Client-minted idempotency key. Stable across retries of the same answer.
  final String interactionId;

  /// The node the user answered.
  final String nodeId;

  /// The node's type, when it is known. Absent for a result produced by a
  /// bare action rather than by a node.
  final AiUiNodeType? nodeType;

  /// The assistant message that carried the node.
  final String? messageId;

  /// What the user did.
  final AiUiInteractionKind kind;

  /// How it ended.
  final AiUiInteractionStatus status;

  /// The typed payload.
  final AiUiInteractionValue value;

  /// The human-readable half — the agent's own template with the user's value
  /// substituted, or client copy for a result the agent wrote no template for
  /// (a permission outcome). This is what appears in the conversation and
  /// what a backend that ignores this object still receives.
  final String? text;

  /// When the client resolved the interaction.
  final DateTime? createdAt;

  /// Whether the user actually answered, as opposed to declining or failing.
  bool get isSubmitted => status == AiUiInteractionStatus.submitted;

  /// The wire object. `createdAt` is normalised to UTC ISO-8601, matching
  /// `AiChatEvent.baseJson`.
  Map<String, dynamic> toJson() => <String, dynamic>{
    'interactionId': interactionId,
    'nodeId': nodeId,
    if (nodeType != null) 'nodeType': nodeType!.wire,
    if (messageId != null) 'messageId': messageId,
    'kind': kind.wire,
    'status': status.wire,
    'value': value.toJson(),
    if (text != null) 'text': text,
    if (createdAt != null) 'createdAt': createdAt!.toUtc().toIso8601String(),
  };

  /// Returns a copy with [status] replaced. Used when a submission that was
  /// already built turns out to have failed.
  AiUiInteraction withStatus(AiUiInteractionStatus next) => AiUiInteraction(
    interactionId: interactionId,
    nodeId: nodeId,
    kind: kind,
    value: value,
    nodeType: nodeType,
    messageId: messageId,
    status: next,
    text: text,
    createdAt: createdAt,
  );

  @override
  List<Object?> get props => [
    interactionId,
    nodeId,
    nodeType,
    messageId,
    kind,
    status,
    value,
    text,
    createdAt,
  ];
}
