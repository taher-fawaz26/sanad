import 'package:ai_ui_protocol/ai_ui_protocol.dart';
import 'package:ai_ui_renderer/ai_ui_renderer.dart';

/// Client-side policy for what an AI payload is allowed to ask for.
///
/// Every value here is consumed by `AiUiValidator`, which means anything
/// outside them is stripped *before* a widget exists — not checked at tap
/// time.
abstract final class AiChatConfig {
  /// Hosts an AI payload may reference from an `open_url` action.
  ///
  /// Empty, and it stays empty while `open_url` is absent from
  /// [supportedActions] — every URL is rejected. Images have their own policy
  /// ([imageUrlPolicy]) because opening a web page and showing a picture are
  /// different decisions.
  static const AiUiUrlPolicy urlPolicy = AiUiUrlPolicy.denyAll;

  /// Hosts an AI payload may load an **image** from.
  ///
  /// Any https origin. Dynamic business media — a service photo, a provider
  /// portrait — lives on whichever CDN the backend uses, so an allowlist here
  /// would mean shipping an image contract that renders nothing. The policy
  /// still rejects a non-https scheme, embedded userinfo and an unparseable
  /// URL, and the refused URL never reaches a widget or a request.
  ///
  /// **This is the one line to change to tighten it.** Naming the origins the
  /// backend actually serves from:
  ///
  /// ```dart
  /// static const AiUiUrlPolicy imageUrlPolicy = AiUiUrlPolicy(
  ///   allowedHosts: {'.trysanad.us'},
  /// );
  /// ```
  ///
  /// makes every other host's image drop during validation, with the node's
  /// `assetId` — if the agent sent one — used instead.
  static const AiUiUrlPolicy imageUrlPolicy = AiUiUrlPolicy.httpsAnyHost;

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
  /// `call_phone`, `open_map` and `request_permission` are here because the
  /// current component set needs them: a provider card's Call control, a
  /// request summary's maps row and a permission prompt's Allow button would
  /// each be a dead control without one. All three are bounded — a phone
  /// number that only pre-fills the dialer, a maps *query* rather than a URL,
  /// and a capability name rather than a platform permission string.
  ///
  /// `open_url`, `open_route` and `dismiss` are absent on purpose. There is no
  /// symbolic route map yet, `open_url` would let the agent send the user
  /// off-app, and `dismiss` has nothing for a handler to do that the card
  /// cannot do itself — declining a prompt collapses it locally.
  static const supportedActions = <AiUiActionType>{
    AiUiActionType.sendMessage,
    AiUiActionType.openService,
    AiUiActionType.openAppointment,
    AiUiActionType.openBranch,
    AiUiActionType.openDocument,
    AiUiActionType.copyText,
    AiUiActionType.requestLocationShare,
    AiUiActionType.requestImageUpload,
    AiUiActionType.requestPermission,
    AiUiActionType.callPhone,
    AiUiActionType.openMap,
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
        // Explicit for the same reason as the line above: a reader should see
        // which image policy this app runs, not have to know the default.
        // ignore: avoid_redundant_argument_values
        imageUrlPolicy: imageUrlPolicy,
        supportedActions: supportedActions,
        knownAssetIds: knownAssetIds,
        options: AiUiValidatorOptions(
          keepUnsupportedNodes: keepUnsupportedNodes,
        ),
      );
}
