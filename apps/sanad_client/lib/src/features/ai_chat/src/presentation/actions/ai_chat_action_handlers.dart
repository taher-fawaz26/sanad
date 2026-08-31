import 'package:ai_ui_protocol/ai_ui_protocol.dart';
import 'package:ai_ui_renderer/ai_ui_renderer.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

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

/// The prototype's allowlist.
///
/// `open_url` and `open_route` are deliberately **absent**: the client has no
/// URL allowlist configured yet and no symbolic route map, and an action
/// registered here is an action the validator will let through. Leaving them
/// out is what makes a payload asking for either one get dropped rather than
/// half-handled.
AiActionRegistry buildAiChatActionRegistry({
  required void Function(String text) onSendMessage,
}) => AiActionRegistry([
  SendMessageHandler(onSendMessage),
  const ResolvedIntentHandler(AiUiActionType.openService, 'serviceId'),
  const ResolvedIntentHandler(AiUiActionType.openAppointment, 'appointmentId'),
  const ResolvedIntentHandler(AiUiActionType.openBranch, 'branchId'),
  const ResolvedIntentHandler(AiUiActionType.openDocument, 'documentId'),
  const CopyTextHandler(),
]);
