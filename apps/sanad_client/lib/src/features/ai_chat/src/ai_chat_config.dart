import 'package:ai_ui_protocol/ai_ui_protocol.dart';
import 'package:ai_ui_renderer/ai_ui_renderer.dart';

/// Client-side policy for what an AI payload is allowed to ask for.
///
/// Both values are consumed by `AiUiValidator`, which means anything outside
/// them is stripped *before* a widget exists — not checked at tap time.
abstract final class AiChatConfig {
  /// Hosts an AI payload may reference from an `open_url` action.
  ///
  /// Empty, and it stays empty while `open_url` is absent from
  /// [supportedActions] — every URL is rejected. Images do not consult this at
  /// all: schemaVersion 1 is `assetId`-only.
  static const AiUiUrlPolicy urlPolicy = AiUiUrlPolicy.denyAll;

  /// Asset ids this app publishes to the agent.
  ///
  /// Handed to the validator so an id the app does not ship is dropped during
  /// validation rather than rendering as a placeholder.
  static Set<String> get knownAssetIds =>
      const AiAssetResolver.defaults().publishedIds;

  /// The actions this app implements.
  ///
  /// This is the single source of truth: `buildAiChatActionRegistry` registers
  /// handlers for exactly these, and the validator drops any node asking for
  /// something else. A test asserts the two stay in step, which is what
  /// prevents a button that renders but does nothing.
  ///
  /// `request_location_share` and `request_image_upload` are here because the
  /// live agent emits them: they ask the *app* to run a flow it owns, and
  /// grant the agent no device access of their own.
  ///
  /// `open_url` and `open_route` are absent on purpose — there is no symbolic
  /// route map yet, and adding `open_url` here would let the agent send the
  /// user off-app.
  static const supportedActions = <AiUiActionType>{
    AiUiActionType.sendMessage,
    AiUiActionType.openService,
    AiUiActionType.openAppointment,
    AiUiActionType.openBranch,
    AiUiActionType.openDocument,
    AiUiActionType.copyText,
    AiUiActionType.requestLocationShare,
    AiUiActionType.requestImageUpload,
  };

  /// Builds the validator this app holds every AI payload to.
  ///
  /// [keepUnsupportedNodes] should be `!kReleaseMode`: developers see a marker
  /// naming the component the agent asked for, users see nothing.
  static AiUiValidator validator({required bool keepUnsupportedNodes}) =>
      AiUiValidator(
        // Explicit even though it matches the default: this is a security
        // posture, not an omission.
        // ignore: avoid_redundant_argument_values
        urlPolicy: urlPolicy,
        supportedActions: supportedActions,
        knownAssetIds: knownAssetIds,
        options: AiUiValidatorOptions(
          keepUnsupportedNodes: keepUnsupportedNodes,
        ),
      );
}
