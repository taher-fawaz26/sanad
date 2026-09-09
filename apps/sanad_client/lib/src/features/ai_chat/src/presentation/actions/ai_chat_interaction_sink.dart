import 'package:ai_ui_protocol/ai_ui_protocol.dart';
import 'package:ai_ui_renderer/ai_ui_renderer.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/bloc/ai_chat_bloc.dart';

/// Carries a semantic card's answer into the conversation.
///
/// The only Chat-specific piece of the interaction architecture. Everything
/// above it — the result model, the lifecycle, the renderers that produce
/// answers — is shared with live voice, which supplies its own sink over its
/// own transport. That is the whole point of the seam: the transports differ,
/// the semantics do not.
final class AiChatBlocInteractionSink implements AiUiInteractionSink {
  /// Creates a sink that posts answers into [bloc].
  const AiChatBlocInteractionSink(this.bloc);

  /// Owns the conversation and the ledger this sink resolves.
  final AiChatBloc bloc;

  @override
  void submit(AiUiInteraction interaction) =>
      bloc.add(AiChatInteractionSubmitted(withInteractionProse(interaction)));
}

/// Fills in the sentence for a result the agent wrote no template for.
///
/// The interactive cards already carry one — `"Book me the {slot} slot"` is
/// the agent's own words with the user's choice substituted. A permission
/// outcome has no template, because the agent never authored "you declined";
/// that is client copy, in the user's language, and `ai_ui_renderer` holds no
/// translations by design.
///
/// So the rule is: **the agent's template wins where there is one, and the app
/// supplies the words where there is not.** Either way the sentence and the
/// structured result travel together, and the bubble reads like something a
/// person said.
AiUiInteraction withInteractionProse(AiUiInteraction interaction) {
  if (interaction.text != null && interaction.text!.isNotEmpty) {
    return interaction;
  }

  final prose = _proseFor(interaction);
  if (prose == null) return interaction;

  return AiUiInteraction(
    interactionId: interaction.interactionId,
    nodeId: interaction.nodeId,
    kind: interaction.kind,
    value: interaction.value,
    nodeType: interaction.nodeType,
    messageId: interaction.messageId,
    status: interaction.status,
    text: prose,
    createdAt: interaction.createdAt,
  );
}

String? _proseFor(AiUiInteraction interaction) {
  final value = interaction.value;

  if (value is AiUiPermissionValue) {
    final capability = _capabilityName(value.permission);
    final key = switch (value.outcome) {
      AiUiPermissionOutcome.granted => 'ai_chat.interaction_permission_granted',
      AiUiPermissionOutcome.denied => 'ai_chat.interaction_permission_denied',
      AiUiPermissionOutcome.permanentlyDenied =>
        'ai_chat.interaction_permission_blocked',
      AiUiPermissionOutcome.unavailable =>
        'ai_chat.interaction_permission_unavailable',
      AiUiPermissionOutcome.cancelled =>
        'ai_chat.interaction_permission_denied',
    };
    return key.tr(namedArgs: {'capability': capability});
  }

  if (interaction.status == AiUiInteractionStatus.cancelled) {
    return 'ai_chat.interaction_cancelled'.tr();
  }

  return null;
}

/// The user-facing word for a capability.
///
/// Falls back to the wire value rather than an empty string: an unlocalized
/// `camera` reads better in a bubble than a sentence with a hole in it, and
/// the validator already dropped anything outside the catalog.
String _capabilityName(String wire) {
  final kind = AiUiPermissionKind.tryFromWire(wire);
  if (kind == null) return wire;

  return switch (kind) {
    AiUiPermissionKind.camera => 'ai_chat.capability_camera'.tr(),
    AiUiPermissionKind.photos => 'ai_chat.capability_photos'.tr(),
    AiUiPermissionKind.microphone => 'ai_chat.capability_microphone'.tr(),
    AiUiPermissionKind.location => 'ai_chat.capability_location_name'.tr(),
    AiUiPermissionKind.notifications =>
      'ai_chat.capability_notifications'.tr(),
  };
}
