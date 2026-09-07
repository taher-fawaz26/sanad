import 'package:ai_ui_protocol/ai_ui_protocol.dart';
import 'package:ai_ui_renderer/ai_ui_renderer.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/services/ai_attachment_source.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/bloc/ai_composer_bloc.dart';

/// Posts the agent's suggested text back as a user turn.
///
/// This is what makes a `quick_reply` chip indistinguishable from typing: the
/// agent does not get to inject a message, it asks the app to send one, and the
/// app routes it through exactly the same path as the composer.
final class SendMessageHandler extends AiActionHandler {
  /// Creates a handler that routes suggested text through [onSend].
  const SendMessageHandler(this.onSend);

  /// Receives the agent's suggested text as if the user had typed it.
  final void Function(String text) onSend;

  @override
  AiUiActionType get type => AiUiActionType.sendMessage;

  @override
  void handle(BuildContext context, AiUiAction action) {
    final text = action.text;
    if (text != null && text.isNotEmpty) onSend(text);
  }
}

/// Stands in for navigation while the client's destination screens do not
/// exist yet.
///
/// The point of the prototype is to prove *dispatch* — that a tap reaches an
/// app-owned handler carrying the right typed payload — not to prove routing.
/// Replacing this with `context.push(ClientRoutes.…)` is a one-line change per
/// action once those routes land.
final class ResolvedIntentHandler extends AiActionHandler {
  /// Creates a handler for [type] that surfaces the value at [idKey].
  const ResolvedIntentHandler(this.type, this.idKey);

  @override
  final AiUiActionType type;

  /// Which action param carries the entity id, for the confirmation caption.
  final String idKey;

  @override
  void handle(BuildContext context, AiUiAction action) {
    showAppSnackbar(
      context: context,
      title: 'ai_chat.action_resolved'.tr(
        namedArgs: {'action': type.wire},
      ),
      caption: action.params[idKey],
    );
  }
}

/// Copies the action's text to the clipboard.
final class CopyTextHandler extends AiActionHandler {
  /// Creates the handler.
  const CopyTextHandler();

  @override
  AiUiActionType get type => AiUiActionType.copyText;

  @override
  Future<void> handle(BuildContext context, AiUiAction action) async {
    final text = action.text;
    if (text == null || text.isEmpty) return;

    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    showAppSnackbar(context: context, title: 'ai_chat.copied'.tr());
  }
}

/// The device capabilities the agent may *ask* for.
///
/// The agent gets no device access from an action. It states an intent —
/// "the user could share their location here" — and this seam is the app code
/// that owns the permission prompt, the picker, and the decision to refuse.
/// Keeping it an interface means the day these are implemented, the protocol,
/// the validator and the renderer do not change at all.
abstract class AiChatCapabilities {
  /// Creates a capability set.
  const AiChatCapabilities();

  /// Runs the app's own location-sharing flow.
  Future<void> shareLocation(BuildContext context);

  /// Runs the app's own image picker / upload flow.
  Future<void> uploadImages(BuildContext context);
}

/// Routes the agent's request into the composer's own attachment flow.
///
/// This is what the capability seam was built for. The agent states an intent —
/// "the user could send a photo here" — and the app answers with the flow it
/// already owns: the same permission gateway, the same picker, the same
/// validation and the same staged attachment a tap on the paperclip produces.
/// The agent gets no device access of its own, and there is no second image
/// pipeline to keep in step.
final class ComposerAiChatCapabilities extends AiChatCapabilities {
  /// Creates capabilities backed by the composer above the calling context.
  const ComposerAiChatCapabilities();

  @override
  Future<void> uploadImages(BuildContext context) async {
    context.read<AiComposerBloc>().add(
      const AiComposerAttachmentRequested(AiAttachmentIntent.gallery),
    );
  }

  @override
  Future<void> shareLocation(BuildContext context) async => showAppSnackbar(
    context: context,
    title: 'ai_chat.capability_unavailable'.tr(),
    caption: 'ai_chat.capability_location'.tr(),
  );
}

/// Acknowledges a request without touching a sensor or the filesystem.
///
/// Kept as the default so a surface that has no composer — a test, a preview —
/// still gets a handler that says something rather than a button that silently
/// does nothing.
final class StubAiChatCapabilities extends AiChatCapabilities {
  /// Creates the stub.
  const StubAiChatCapabilities();

  @override
  Future<void> shareLocation(BuildContext context) async => showAppSnackbar(
    context: context,
    title: 'ai_chat.capability_unavailable'.tr(),
    caption: 'ai_chat.capability_location'.tr(),
  );

  @override
  Future<void> uploadImages(BuildContext context) async => showAppSnackbar(
    context: context,
    title: 'ai_chat.capability_unavailable'.tr(),
    caption: 'ai_chat.capability_image_upload'.tr(),
  );
}

/// Routes a capability request to app-owned code.
final class CapabilityRequestHandler extends AiActionHandler {
  /// Creates a handler for [type], invoking [run] on the capability set.
  const CapabilityRequestHandler(this.type, this.capabilities, this.run);

  @override
  final AiUiActionType type;

  /// The app code that actually owns the device interaction.
  final AiChatCapabilities capabilities;

  /// Which capability [type] maps to.
  final Future<void> Function(AiChatCapabilities, BuildContext) run;

  @override
  Future<void> handle(BuildContext context, AiUiAction action) =>
      run(capabilities, context);
}

/// The prototype's allowlist.
///
/// `open_url` and `open_route` are deliberately **absent**: the client has no
/// URL allowlist configured yet and no symbolic route map, and an action
/// registered here is an action the validator will let through. Leaving them
/// out is what makes a payload asking for either one get dropped rather than
/// half-handled.
AiActionRegistry buildAiChatActionRegistry({
  required void Function(String text) onSendMessage,
  AiChatCapabilities capabilities = const StubAiChatCapabilities(),
}) => AiActionRegistry([
  SendMessageHandler(onSendMessage),
  const ResolvedIntentHandler(AiUiActionType.openService, 'serviceId'),
  const ResolvedIntentHandler(AiUiActionType.openAppointment, 'appointmentId'),
  const ResolvedIntentHandler(AiUiActionType.openBranch, 'branchId'),
  const ResolvedIntentHandler(AiUiActionType.openDocument, 'documentId'),
  const CopyTextHandler(),
  CapabilityRequestHandler(
    AiUiActionType.requestLocationShare,
    capabilities,
    (c, context) => c.shareLocation(context),
  ),
  CapabilityRequestHandler(
    AiUiActionType.requestImageUpload,
    capabilities,
    (c, context) => c.uploadImages(context),
  ),
]);
