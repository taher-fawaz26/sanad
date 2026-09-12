import 'package:ai_ui_protocol/ai_ui_protocol.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/journey/ai_journey_fixtures.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/journey/ai_journey_step.dart';

/// Builders for the answers the renderer really produces.
///
/// Hand-built rather than driven through widgets on purpose: these tests are
/// about the agent *reading the structured value*, so the value has to be
/// written out in full where the assertion can see it. The widget tests beside
/// them cover the other half — that the renderer mints these shapes.

/// The `location_selected` a confirmed map pick produces.
///
/// `source: map` is the one the client's own capability reporter sends, which
/// is the path the walkthrough actually takes.
AiUiInteraction locationSelected({
  String name = AiJourneyFixtures.locationAddress,
  AiUiLocationSource source = AiUiLocationSource.map,
  String nodeId = 'journey_location_picker',
}) => AiUiInteraction(
  interactionId: 'int_location',
  nodeId: nodeId,
  kind: AiUiInteractionKind.locationSelected,
  nodeType: AiUiNodeType.locationPicker,
  value: AiUiLocationValue(
    id: 'place_1',
    name: name,
    addressText: name,
    source: source,
  ),
);

/// The `permission_result` the platform dialog produces.
AiUiInteraction permissionResult({
  AiUiPermissionKind permission = AiUiPermissionKind.camera,
  AiUiPermissionOutcome outcome = AiUiPermissionOutcome.granted,
}) => AiUiInteraction(
  interactionId: 'int_permission',
  nodeId: 'journey_permission_camera',
  kind: AiUiInteractionKind.permissionResult,
  nodeType: AiUiNodeType.permissionRequest,
  value: AiUiPermissionValue(
    permission: permission.wire,
    outcome: outcome,
  ),
  status: outcome.isGranted
      ? AiUiInteractionStatus.submitted
      : AiUiInteractionStatus.cancelled,
);

/// The `media_result` the composer's picker produces through the capability.
AiUiInteraction mediaResult({int count = 3}) => AiUiInteraction(
  interactionId: 'int_media',
  nodeId: 'journey_media_request',
  kind: AiUiInteractionKind.mediaResult,
  nodeType: AiUiNodeType.mediaRequest,
  value: AiUiMediaValue(count: count, source: AiUiMediaSource.gallery.wire),
);

/// The `offer_resolved` a provider card's Accept or Decline produces.
AiUiInteraction offerResolved({
  AiUiOfferDecision decision = AiUiOfferDecision.accepted,
  int index = 0,
}) => AiUiInteraction(
  interactionId: 'int_offer_$index',
  nodeId: 'journey_provider_offer_$index',
  kind: AiUiInteractionKind.offerResolved,
  nodeType: AiUiNodeType.providerCard,
  value: AiUiOfferValue(
    decision: decision,
    providerId: AiJourneyFixtures.providerId,
    offerId: AiJourneyFixtures.offerId,
  ),
);

/// The `confirmation_resolved` a `confirm_prompt` produces.
AiUiInteraction confirmationResolved({
  bool confirmed = true,
  String nodeId = 'journey_booking_confirm',
  AiUiNodeType nodeType = AiUiNodeType.confirmPrompt,
}) => AiUiInteraction(
  interactionId: 'int_confirm',
  nodeId: nodeId,
  kind: AiUiInteractionKind.confirmationResolved,
  nodeType: nodeType,
  value: AiUiConfirmationValue(confirmed: confirmed),
);

/// The `review_submitted` a `review_request` produces.
AiUiInteraction reviewSubmitted({int rating = 5, String comment = ''}) =>
    AiUiInteraction(
      interactionId: 'int_review',
      nodeId: 'journey_review_request',
      kind: AiUiInteractionKind.reviewSubmitted,
      nodeType: AiUiNodeType.reviewRequest,
      value: AiUiReviewValue(rating: rating, comment: comment),
    );

/// Every node type the given steps put on screen, in order.
///
/// The assertion these tests are really about: what the mock produces has to be
/// drawn from the existing semantic catalog, so the test reads the `type`
/// strings straight off the wire payloads.
List<String> typesOf(List<AiJourneyStep> steps) => [
  for (final step in steps)
    for (final block in step.ui ?? const <Map<String, dynamic>>[])
      block['type']! as String,
];
