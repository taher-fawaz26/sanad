import 'package:ai_ui_protocol/ai_ui_protocol.dart';
import 'package:ai_ui_renderer/ai_ui_renderer.dart';
import 'package:design_system/design_system.dart';
import 'package:device/device.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maps/maps.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/platform/attachments/permissions_ai_permission_gateway.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/services/ai_attachment_source.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/services/ai_permission_gateway.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/bloc/ai_composer_bloc.dart';
import 'package:sanad_client/src/ui/location/client_location_picker.dart';

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

  /// Runs the app's own location flow and returns what the user resolved.
  ///
  /// `null` means the user backed out without confirming. That is a real
  /// answer — "not this way" — and is deliberately different from a failure:
  /// the caller re-opens the question rather than telling the agent anything.
  ///
  /// The return type is the **canonical** [LocationPickerResult] from
  /// `packages/maps`, not a protocol type, because this seam names what the
  /// app can do rather than what the agent can hear. Adapting it to the
  /// interaction contract happens once, at the boundary, in
  /// [AiChatCapabilityReporter.reportLocation].
  Future<LocationPickerResult?> shareLocation(BuildContext context);

  /// Runs the app's own image picker / upload flow and returns how many files
  /// the user actually staged.
  ///
  /// `null` means the user backed out without picking anything — the same
  /// distinction [shareLocation] draws, and for the same reason: "no photos"
  /// and "not this way" are different answers and the agent must be able to
  /// tell them apart. `0` is possible too, and means the picker ran and came
  /// back empty.
  ///
  /// [source] is the agent's *suggestion* of where to take media from — a
  /// `media_request` option. The app is free to ignore it; nothing about the
  /// agent's choice bypasses the permission gateway or the picker.
  Future<int?> uploadImages(BuildContext context, {AiUiMediaSource? source});

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
    this.initialLocation,
  });

  /// The feature's single permission boundary.
  final AiPermissionGateway gateway;

  /// Where the map opens when there is nothing better to centre on.
  ///
  /// Only a *camera* hint — the user still pans, searches and confirms, and
  /// the confirmed point is always the map's, never this. It exists so the
  /// demo can start over Dubai Marina instead of over the country default,
  /// which is presentation staging rather than a second location source.
  final LatLng? initialLocation;

  /// Dispatches into the composer's own picker, then waits for it to settle.
  ///
  /// The await is what closes a real gap rather than a demo one: this used to
  /// be fire-and-forget, so an agent could ask for photos through
  /// `request_image_upload` and never learn whether its question had been
  /// answered. The composer already publishes `isPicking`, so the outcome is
  /// observable without a second pipeline, a second picker or new bloc state —
  /// the flow, the permission gateway and the validation are untouched.
  ///
  /// Counting the *difference* rather than the total matters: the user may
  /// already have staged photos from the paperclip before the agent asked, and
  /// those are not an answer to this question.
  @override
  Future<int?> uploadImages(
    BuildContext context, {
    AiUiMediaSource? source,
  }) async {
    final composer = context.read<AiComposerBloc>()
      ..add(AiComposerAttachmentRequested(_intentFor(source)));
    final before = composer.state.attachments.length;

    // The bloc refuses outright when the staging area is full, in which case
    // `isPicking` never rises. Both ways that can end are handled, because
    // either would otherwise strand the card that asked: the stream going
    // quiet is the timeout's job, and the stream *closing* — the user left the
    // chat mid-pick and the bloc was disposed — is `orElse`'s. A bare
    // `firstWhere` throws on the second, from inside an action handler with
    // nowhere to put the error.
    final opened = await composer.stream
        .firstWhere((state) => state.isPicking, orElse: () => composer.state)
        .timeout(_pickerStartTimeout, onTimeout: () => composer.state);
    if (!opened.isPicking) return null;

    final settled = await composer.stream.firstWhere(
      (state) => !state.isPicking,
      orElse: () => composer.state,
    );
    final picked = settled.attachments.length - before;
    // Nothing new staged: either the sheet was dismissed or every candidate
    // was rejected by validation, and both are "the user did not answer".
    return picked > 0 ? picked : null;
  }

  /// How long to wait for the picker to open before concluding it will not.
  static const _pickerStartTimeout = Duration(seconds: 1);

  /// Opens the client's shared map picker.
  ///
  /// This used to report `unavailable` and show "coming soon", on the reasoning
  /// that pulling `packages/maps` into a conversation was not worth a Maps key
  /// and a DI bootstrap. That reasoning expired: `sanad_client` already
  /// registers `MapsModule` and already ships the key, so the capability was
  /// refusing to do something the app could do — the one thing a capability
  /// must never do.
  ///
  /// Nothing map-shaped lives here. [pickClientLocation] is the app's single
  /// front door, and the sheet behind it owns the camera, Places search,
  /// reverse geocoding, the permission prompts and its own disposal.
  @override
  Future<LocationPickerResult?> shareLocation(BuildContext context) =>
      pickClientLocation(context, initialLocation: initialLocation);

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

  /// Opens the same real picker the composer-backed capabilities do.
  ///
  /// Location is the one capability this stub can honour in full: the sheet
  /// needs a `BuildContext` and the app's DI, not a composer. Stubbing it
  /// would leave the showcase — the surface a designer actually taps — saying
  /// "coming soon" about a map the app ships.
  @override
  Future<LocationPickerResult?> shareLocation(BuildContext context) =>
      pickClientLocation(context);

  @override
  Future<int?> uploadImages(
    BuildContext context, {
    AiUiMediaSource? source,
  }) async {
    showAppSnackbar(
      context: context,
      title: 'ai_chat.capability_unavailable'.tr(),
      caption: 'ai_chat.capability_image_upload'.tr(),
    );
    // Never "zero photos": the picker did not run, so there is no answer to
    // report and the card stays where it was.
    return null;
  }

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
    this.ledger,
  });

  /// Where the results go. Defaults to the no-op so a preview or a test that
  /// wires no sink keeps the old snackbar-only behaviour.
  final AiUiInteractionSink sink;

  /// The conversation's answer lifecycle, when there is one.
  ///
  /// Needed for exactly one case, and it is not optional behaviour: dispatching
  /// a capability request *claims* the node — `requestCapability` calls
  /// `beginSubmission` — so a user who opens the map and backs out has left a
  /// card that is disabled forever and a conversation that cannot move.
  /// Releasing the claim is what makes cancel-then-retry work.
  final AiUiInteractionLedger? ledger;

  /// Reports the place a capability resolved, or releases the node when the
  /// user resolved none.
  ///
  /// This is the one place the canonical [LocationPickerResult] becomes the
  /// protocol's `location_selected`. Only fields the contract actually has are
  /// sent: the Places id as `id`, the resolved address as both the display
  /// `name` and `addressText`, and `map` as the source. The coordinates stay
  /// on the client — the protocol carries no lat/lng, and inventing a field
  /// for them is not this change's business.
  void reportLocation(AiUiAction action, LocationPickerResult? result) {
    final nodeId = action.params[AiUiInteractionParams.nodeId];
    if (nodeId == null || nodeId.isEmpty) return;

    if (result == null) {
      // Cancelled: say nothing to the agent, and hand the card back so the
      // user can try again. Submitting an "empty" location here would have the
      // agent act on a place the user never chose.
      ledger?.reset(nodeId);
      return;
    }

    sink.submit(
      AiUiInteraction(
        interactionId: mintAiUiInteractionId(),
        nodeId: nodeId,
        kind: AiUiInteractionKind.locationSelected,
        value: AiUiLocationValue(
          id: result.placeId,
          name: result.address,
          addressText: result.address,
          source: AiUiLocationSource.map,
        ),
        nodeType: AiUiNodeType.locationPicker,
        messageId: action.params[AiUiInteractionParams.messageId],
        createdAt: DateTime.now(),
      ),
    );
  }

  /// Reports how a `media_request` was answered, or releases the node when it
  /// was not answered at all.
  ///
  /// The counterpart of [reportLocation], and the reason a deterministic photo
  /// step needs no fixture sheet: the real picker's outcome becomes the real
  /// `media_result` the protocol already defines. The files themselves do not
  /// travel here — they are staged on the composer and ride the next turn's
  /// `attachments`, which is what `AiUiMediaValue` documents by carrying only
  /// a count.
  void reportMedia(
    AiUiAction action, {
    required int? count,
    AiUiMediaSource? source,
  }) {
    final nodeId = action.params[AiUiInteractionParams.nodeId];
    if (nodeId == null || nodeId.isEmpty) return;

    if (count == null) {
      // Backed out. Hand the card back so the user can try again, and tell the
      // agent it was declined rather than answered with zero — the two would
      // have it carry on down different branches.
      ledger?.reset(nodeId);
      sink.submit(
        AiUiInteraction(
          interactionId: mintAiUiInteractionId(),
          nodeId: nodeId,
          kind: AiUiInteractionKind.mediaResult,
          value: const AiUiMediaValue(count: 0),
          nodeType: AiUiNodeType.mediaRequest,
          messageId: action.params[AiUiInteractionParams.messageId],
          status: AiUiInteractionStatus.cancelled,
          createdAt: DateTime.now(),
        ),
      );
      return;
    }

    sink.submit(
      AiUiInteraction(
        interactionId: mintAiUiInteractionId(),
        nodeId: nodeId,
        kind: AiUiInteractionKind.mediaResult,
        value: AiUiMediaValue(count: count, source: source?.wire),
        nodeType: AiUiNodeType.mediaRequest,
        messageId: action.params[AiUiInteractionParams.messageId],
        createdAt: DateTime.now(),
      ),
    );
  }

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

/// Opens the app's location flow and reports the place the user resolved.
///
/// It reports a *place* now, not a permission outcome. The old shape existed
/// only because the client could not read a position, so the honest thing to
/// send was "unavailable"; with the shared map wired up there is a real
/// location to hand over, and `location_selected` is the interaction the
/// protocol already has for it.
final class LocationShareHandler extends AiActionHandler {
  /// Creates the handler.
  const LocationShareHandler(this.capabilities, this.reporter);

  /// The app code that owns the map.
  final AiChatCapabilities capabilities;

  /// Where the result goes.
  final AiChatCapabilityReporter reporter;

  @override
  AiUiActionType get type => AiUiActionType.requestLocationShare;

  @override
  Future<void> handle(BuildContext context, AiUiAction action) async {
    final result = await capabilities.shareLocation(context);
    reporter.reportLocation(action, result);
  }
}

/// Opens the app's own picker and reports what the user staged.
///
/// The media twin of [LocationShareHandler]. Before this existed the capability
/// was fire-and-forget, so a `media_request` could be answered on the device
/// and the agent would keep waiting for photos it had already been sent.
final class MediaRequestHandler extends AiActionHandler {
  /// Creates the handler.
  const MediaRequestHandler(this.capabilities, this.reporter);

  /// The app code that owns the permission prompt and the picker.
  final AiChatCapabilities capabilities;

  /// Where the result goes.
  final AiChatCapabilityReporter reporter;

  @override
  AiUiActionType get type => AiUiActionType.requestImageUpload;

  @override
  Future<void> handle(BuildContext context, AiUiAction action) async {
    final source = AiUiMediaSource.tryFromWire(action.params['source'] ?? '');
    final count = await capabilities.uploadImages(context, source: source);
    reporter.reportMedia(action, count: count, source: source);
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
  AiUiInteractionLedger? ledger,
}) => AiActionRegistry([
  SendMessageHandler(onSendMessage),
  const ResolvedIntentHandler(AiUiActionType.openService, 'serviceId'),
  const ResolvedIntentHandler(AiUiActionType.openAppointment, 'appointmentId'),
  const ResolvedIntentHandler(AiUiActionType.openBranch, 'branchId'),
  const ResolvedIntentHandler(AiUiActionType.openDocument, 'documentId'),
  const CopyTextHandler(),
  LocationShareHandler(
    capabilities,
    // The ledger travels with this one because a cancelled map has to give the
    // card back; the permission handler below never needs it, because a
    // platform dialog always ends in an outcome it can report.
    AiChatCapabilityReporter(sink: interactions, ledger: ledger),
  ),
  MediaRequestHandler(
    capabilities,
    // Same pairing as location: the ledger travels because a dismissed picker
    // has to give the card back.
    AiChatCapabilityReporter(sink: interactions, ledger: ledger),
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
