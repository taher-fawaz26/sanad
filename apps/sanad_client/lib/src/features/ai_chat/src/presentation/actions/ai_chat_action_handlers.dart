import 'package:ai_ui_protocol/ai_ui_protocol.dart';
import 'package:ai_ui_renderer/ai_ui_renderer.dart';
import 'package:design_system/design_system.dart';
import 'package:device/device.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/platform/attachments/permissions_ai_permission_gateway.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/services/ai_attachment_source.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/services/ai_permission_gateway.dart';
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
  ///
  /// Returns the outcome so the conversation can continue from it. Before
  /// results existed this ended in a snackbar and the agent was never told,
  /// which left it waiting for a location that was never coming.
  Future<AiUiPermissionOutcome> shareLocation(BuildContext context);

  /// Runs the app's own image picker / upload flow.
  ///
  /// [source] is the agent's *suggestion* of where to take media from — a
  /// `media_request` option. The app is free to ignore it; nothing about the
  /// agent's choice bypasses the permission gateway or the picker.
  Future<void> uploadImages(BuildContext context, {AiUiMediaSource? source});

  /// Ensures a device permission, naming the capability the conversation needs
  /// next. The app owns the rationale, the prompt and the settings redirect.
  ///
  /// Returns the outcome in *protocol* terms — never a `permission_handler`
  /// status — so the caller can hand it straight to the agent without the
  /// plugin's vocabulary leaking into the conversation.
  Future<AiUiPermissionOutcome> ensurePermission(
    BuildContext context,
    AiUiPermissionKind permission,
  );

  /// Opens the platform maps app at a bounded query — an address, or
  /// `"lat,lng"`. Never a URL.
  Future<void> openMap(BuildContext context, String query);

  /// Opens the dialer **pre-filled** with a number. The OS shows it before
  /// anything is dialled, and the user still has to press call.
  Future<void> callPhone(BuildContext context, String phoneNumber);
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
  ///
  /// [gateway] is injectable so a widget test can substitute a fake and assert
  /// the capability mapping without a platform channel.
  const ComposerAiChatCapabilities({
    this.gateway = const PermissionsAiPermissionGateway(),
  });

  /// The feature's single permission boundary.
  final AiPermissionGateway gateway;

  @override
  Future<void> uploadImages(
    BuildContext context, {
    AiUiMediaSource? source,
  }) async {
    context.read<AiComposerBloc>().add(
      AiComposerAttachmentRequested(_intentFor(source)),
    );
  }

  /// Reports honestly that this client cannot read the device position.
  ///
  /// `LocationService` exists, but only inside `packages/maps`, which would
  /// bring `google_maps_flutter`, a Maps API key and a DI bootstrap into an
  /// app that needs none of them for a conversation. Until that trade is worth
  /// making, the useful thing is to *say so in the protocol*: the agent gets
  /// `unavailable` and can ask the user to name the place instead, which is
  /// strictly better than the snackbar-and-silence this replaced.
  @override
  Future<AiUiPermissionOutcome> shareLocation(BuildContext context) async {
    showAppSnackbar(
      context: context,
      title: 'ai_chat.capability_unavailable'.tr(),
      caption: 'ai_chat.capability_location'.tr(),
    );
    return AiUiPermissionOutcome.unavailable;
  }

  @override
  Future<AiUiPermissionOutcome> ensurePermission(
    BuildContext context,
    AiUiPermissionKind permission,
  ) async {
    // Through the feature's existing permission boundary — the same gateway
    // the composer's paperclip uses — so an Allow tap on an AI card and a tap
    // on the paperclip cannot diverge, and `packages/permissions` stays
    // confined to that one adapter file.
    final outcome = await _ensure(gateway, permission);
    if (outcome == AiPermissionOutcome.granted || !context.mounted) {
      return outcome.asProtocolOutcome;
    }

    showAppSnackbar(
      context: context,
      title: outcome == AiPermissionOutcome.permanentlyDenied
          ? 'ai_chat.permission_denied_permanently'.tr()
          : 'ai_chat.permission_denied'.tr(),
    );
    return outcome.asProtocolOutcome;
  }

  @override
  Future<void> openMap(BuildContext context, String query) async {
    final launched = await Device.openMaps(query);
    if (launched || !context.mounted) return;
    showAppSnackbar(context: context, title: 'ai_chat.open_map_failed'.tr());
  }

  @override
  Future<void> callPhone(BuildContext context, String phoneNumber) async {
    final launched = await Device.openPhone(phoneNumber);
    if (launched || !context.mounted) return;
    showAppSnackbar(context: context, title: 'ai_chat.call_failed'.tr());
  }

  /// The agent names a *source*; the composer speaks in attachment intents.
  static AiAttachmentIntent _intentFor(AiUiMediaSource? source) =>
      switch (source) {
        AiUiMediaSource.camera => AiAttachmentIntent.camera,
        AiUiMediaSource.document => AiAttachmentIntent.document,
        // Video shares the gallery picker: the composer validates type and
        // size afterwards, so a separate intent would add nothing.
        AiUiMediaSource.video ||
        AiUiMediaSource.gallery ||
        null => AiAttachmentIntent.gallery,
      };

  /// Maps a protocol capability onto the gateway's own vocabulary.
  ///
  /// `location` resolves to while-in-use: the AI surface asks so it can find
  /// nearby branches mid-conversation, and a background grant would be larger
  /// than that justifies.
  static Future<AiPermissionOutcome> _ensure(
    AiPermissionGateway gateway,
    AiUiPermissionKind kind,
  ) => switch (kind) {
    AiUiPermissionKind.camera => gateway.ensureCamera(),
    AiUiPermissionKind.photos => gateway.ensureGallery(),
    AiUiPermissionKind.microphone => gateway.ensureMicrophone(),
    AiUiPermissionKind.location => gateway.ensureLocation(),
    AiUiPermissionKind.notifications => gateway.ensureNotifications(),
  };
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
  Future<AiUiPermissionOutcome> shareLocation(BuildContext context) async {
    showAppSnackbar(
      context: context,
      title: 'ai_chat.capability_unavailable'.tr(),
      caption: 'ai_chat.capability_location'.tr(),
    );
    return AiUiPermissionOutcome.unavailable;
  }

  @override
  Future<void> uploadImages(
    BuildContext context, {
    AiUiMediaSource? source,
  }) async => showAppSnackbar(
    context: context,
    title: 'ai_chat.capability_unavailable'.tr(),
    caption: 'ai_chat.capability_image_upload'.tr(),
  );

  @override
  Future<AiUiPermissionOutcome> ensurePermission(
    BuildContext context,
    AiUiPermissionKind permission,
  ) async {
    showAppSnackbar(
      context: context,
      title: 'ai_chat.capability_unavailable'.tr(),
      caption: permission.wire,
    );
    return AiUiPermissionOutcome.unavailable;
  }

  @override
  Future<void> openMap(BuildContext context, String query) async =>
      showAppSnackbar(
        context: context,
        title: 'ai_chat.capability_unavailable'.tr(),
        caption: query,
      );

  @override
  Future<void> callPhone(BuildContext context, String phoneNumber) async =>
      showAppSnackbar(
        context: context,
        title: 'ai_chat.capability_unavailable'.tr(),
        caption: phoneNumber,
      );
}

/// Maps the gateway's vocabulary onto the protocol's.
///
/// Two enums rather than one on purpose: the gateway's exists so no bloc or
/// widget names a `permission_handler` type, and the protocol's exists so the
/// agent never sees a platform concept. Collapsing them would put a plugin's
/// states on the wire.
extension AiPermissionOutcomeProtocol on AiPermissionOutcome {
  /// This outcome as the agent should hear it.
  AiUiPermissionOutcome get asProtocolOutcome => switch (this) {
    AiPermissionOutcome.granted => AiUiPermissionOutcome.granted,
    AiPermissionOutcome.denied => AiUiPermissionOutcome.denied,
    AiPermissionOutcome.permanentlyDenied =>
      AiUiPermissionOutcome.permanentlyDenied,
    AiPermissionOutcome.unavailable => AiUiPermissionOutcome.unavailable,
  };
}

/// Turns a capability outcome into an answer the agent can continue from.
///
/// Only reports when the request came from a *node* — the correlation params
/// the render scope attaches. A bare `request_permission` button asked no
/// question, so there is nothing for an outcome to be the answer *to*, and it
/// behaves exactly as it did before results existed.
final class AiChatCapabilityReporter {
  /// Creates a reporter that submits through [sink].
  const AiChatCapabilityReporter({
    this.sink = const NoopAiUiInteractionSink(),
  });

  /// Where the results go. Defaults to the no-op so a preview or a test that
  /// wires no sink keeps the old snackbar-only behaviour.
  final AiUiInteractionSink sink;

  /// Reports a capability outcome against the node that asked for it.
  void reportPermission(
    AiUiAction action, {
    required String permission,
    required AiUiPermissionOutcome outcome,
    AiUiNodeType? nodeType,
  }) {
    final nodeId = action.params[AiUiInteractionParams.nodeId];
    if (nodeId == null || nodeId.isEmpty) return;

    sink.submit(
      AiUiInteraction(
        interactionId: mintAiUiInteractionId(),
        nodeId: nodeId,
        kind: AiUiInteractionKind.permissionResult,
        value: AiUiPermissionValue(
          permission: permission,
          outcome: outcome,
        ),
        nodeType: nodeType,
        messageId: action.params[AiUiInteractionParams.messageId],
        status: outcome.isGranted
            ? AiUiInteractionStatus.submitted
            : AiUiInteractionStatus.cancelled,
        createdAt: DateTime.now(),
      ),
    );
  }
}

/// Runs a permission request and reports how it ended.
final class PermissionRequestHandler extends AiActionHandler {
  /// Creates the handler.
  const PermissionRequestHandler(this.capabilities, this.reporter);

  /// The app code that owns the platform prompt.
  final AiChatCapabilities capabilities;

  /// Where the outcome goes.
  final AiChatCapabilityReporter reporter;

  @override
  AiUiActionType get type => AiUiActionType.requestPermission;

  @override
  Future<void> handle(BuildContext context, AiUiAction action) async {
    final wire = action.params['permission'] ?? '';
    final kind = AiUiPermissionKind.tryFromWire(wire);
    // The validator already dropped a card naming an unknown capability, so
    // this is belt-and-braces rather than a reachable path.
    if (kind == null) return;

    final outcome = await capabilities.ensurePermission(context, kind);
    reporter.reportPermission(
      action,
      permission: kind.wire,
      outcome: outcome,
      nodeType: AiUiNodeType.permissionRequest,
    );
  }
}

/// Runs the location-sharing flow and reports how it ended.
///
/// The outcome is reported as a *location permission* result rather than a
/// place: this client reads no device position, so claiming to have one would
/// be a lie the agent would act on. Telling it `unavailable` lets it ask the
/// user to name the place instead.
final class LocationShareHandler extends AiActionHandler {
  /// Creates the handler.
  const LocationShareHandler(this.capabilities, this.reporter);

  /// The app code that owns the device.
  final AiChatCapabilities capabilities;

  /// Where the outcome goes.
  final AiChatCapabilityReporter reporter;

  @override
  AiUiActionType get type => AiUiActionType.requestLocationShare;

  @override
  Future<void> handle(BuildContext context, AiUiAction action) async {
    final outcome = await capabilities.shareLocation(context);
    reporter.reportPermission(
      action,
      permission: AiUiPermissionKind.location.wire,
      outcome: outcome,
    );
  }
}

/// Routes a capability request to app-owned code.
final class CapabilityRequestHandler extends AiActionHandler {
  /// Creates a handler for [type], invoking [run] on the capability set.
  const CapabilityRequestHandler(this.type, this.capabilities, this.run);

  @override
  final AiUiActionType type;

  /// The app code that actually owns the device interaction.
  final AiChatCapabilities capabilities;

  /// Which capability [type] maps to. Receives the action too, so a handler
  /// can read its params — the media source, the capability, the query.
  final Future<void> Function(AiChatCapabilities, BuildContext, AiUiAction) run;

  @override
  Future<void> handle(BuildContext context, AiUiAction action) =>
      run(capabilities, context, action);
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
  AiUiInteractionSink interactions = const NoopAiUiInteractionSink(),
}) => AiActionRegistry([
  SendMessageHandler(onSendMessage),
  const ResolvedIntentHandler(AiUiActionType.openService, 'serviceId'),
  const ResolvedIntentHandler(AiUiActionType.openAppointment, 'appointmentId'),
  const ResolvedIntentHandler(AiUiActionType.openBranch, 'branchId'),
  const ResolvedIntentHandler(AiUiActionType.openDocument, 'documentId'),
  const CopyTextHandler(),
  LocationShareHandler(
    capabilities,
    AiChatCapabilityReporter(sink: interactions),
  ),
  CapabilityRequestHandler(
    AiUiActionType.requestImageUpload,
    capabilities,
    (c, context, action) => c.uploadImages(
      context,
      source: AiUiMediaSource.tryFromWire(action.params['source'] ?? ''),
    ),
  ),
  PermissionRequestHandler(
    capabilities,
    AiChatCapabilityReporter(sink: interactions),
  ),
  CapabilityRequestHandler(
    AiUiActionType.openMap,
    capabilities,
    (c, context, action) => c.openMap(context, action.params['query'] ?? ''),
  ),
  CapabilityRequestHandler(
    AiUiActionType.callPhone,
    capabilities,
    (c, context, action) => c.callPhone(context, action.params['phone'] ?? ''),
  ),
]);
