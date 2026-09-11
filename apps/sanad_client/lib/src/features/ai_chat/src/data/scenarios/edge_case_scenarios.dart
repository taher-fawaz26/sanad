/// The conversational edge cases — Figma `edge cases` (`8550:35200`).
///
/// Every one of these is a *state the chat can be in*, not a screen. They are
/// scripted here as ordinary wire payloads so each reaches the UI the same way
/// a live reply would: `ui` event → `AiUiValidator` → `AiUiSurface` → the
/// registered renderer. Nothing in this file constructs a widget, and nothing
/// bypasses validation — a fixture that stopped validating would render as
/// nothing with a diagnostic beside it, which is the point.
///
/// ## The two that are not payloads
///
/// Six of the eight are. The other two are facts about the *device and the
/// transport*, which no `ui` event can express:
///
/// * **offline** — the radio is off. Its fixture is the dev picker's Offline
///   chip (`MockConnectivityService`), which flips the same signal a real
///   radio would and lets `AiChatBloc` queue the turn for real.
/// * **send failed** — the turn left and did not arrive. Its fixture is
///   [messageSendFailedScenario] below, which emits a real `error` frame so
///   the bloc marks the in-flight turn `failed` exactly as a dropped request
///   would.
///
/// Both run the real lifecycle. Neither is a mocked-up bubble.
library;

import 'package:ai_ui_protocol/ai_ui_protocol.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/scenarios/scenario_support.dart';

/// Case 1 — the user opened a second request inside a conversation that
/// already belongs to one.
const activeRequestDetectedScenario = MockScenario(
  id: 'active_request_detected',
  label: 'Active request detected',
  keywords: ['also need', 'another request', 'deep cleaning'],
  build: _buildActiveRequestDetected,
);

List<AiChatEvent> _buildActiveRequestDetected(String messageId) {
  const text = 'I can set that up — it just needs a conversation of its own.';
  return [
    scenarioStart(messageId),
    ...scenarioStream(messageId, text),
    scenarioEnd(messageId, text),
    scenarioUi(
      messageId,
      scenarioPayload([
        {
          'type': 'request_notice',
          'id': 'rn_active',
          'requestId': 'req_4821',
          'contextLabel': 'Tied to Active Request: Plumbing Repair (#SND-4821)',
          'title': 'New request detected',
          'body':
              'To keep your bids, schedules, and specialists organized '
              'correctly, each home service request needs its own separate '
              'conversation.',
          'draftLabel': 'Draft Saved',
          'draftText': '"I also need to book an AC deep cleaning..."',
          // A decision, not two send_messages: the agent needs to know which
          // conversation the user chose, correlated with the request it was
          // asked about, and the ledger has to stop a second tap opening a
          // second conversation.
          'confirm': {
            'confirmLabel': 'Start New Conversation',
            'cancelLabel': 'Continue Plumbing Conversation',
            'confirmTemplate':
                'Start a new conversation for the AC deep cleaning',
            'cancelTemplate': 'Carry on with the plumbing repair',
            'reference': 'req_4821',
          },
          'fallbackText':
              'That needs its own conversation — shall I start one?',
        },
      ]),
    ),
  ];
}

/// Case 2 — the provider cancelled.
const bookingCancelledScenario = MockScenario(
  id: 'booking_cancelled',
  label: 'Booking cancelled',
  keywords: ['cancelled my booking', 'why was it cancelled'],
  build: _buildBookingCancelled,
);

List<AiChatEvent> _buildBookingCancelled(String messageId) {
  const text = 'I am sorry — that booking has been cancelled.';
  return [
    scenarioStart(messageId),
    ...scenarioStream(messageId, text),
    scenarioEnd(messageId, text),
    scenarioUi(
      messageId,
      scenarioPayload([
        {
          'type': 'request_notice',
          'id': 'rn_cancelled',
          'requestId': 'req_4821',
          'reference': '#SND-4821',
          'status': {'label': 'Booking Cancelled', 'tone': 'error'},
          'title': 'Ahmed K. had to cancel',
          'body':
              'The provider canceled due to an unexpected emergency. '
              "We're sorry for the inconvenience.",
          // Re-matching is an answer about this request; support is a
          // different destination. Two mechanisms because they mean two
          // different things — see `AiUiRequestNoticeNode`.
          'confirm': {
            'confirmLabel': 'Auto-Match New Provider',
            'confirmTemplate': 'Find me another provider for #SND-4821',
            'reference': 'req_4821',
          },
          'actions': [
            {
              'label': 'Contact Sanad Support',
              'variant': 'outline',
              'action': {
                'type': 'send_message',
                'text':
                    'I would like to talk to Sanad support about '
                    '#SND-4821',
              },
            },
          ],
          'fallbackText': 'Your booking #SND-4821 was cancelled',
        },
      ]),
    ),
  ];
}

/// Case 3 — the provider has not turned up.
const providerLateScenario = MockScenario(
  id: 'provider_late',
  label: 'Provider is late',
  keywords: ['late', 'not arrived', 'where is the provider'],
  build: _buildProviderLate,
);

List<AiChatEvent> _buildProviderLate(String messageId) {
  const text = 'I checked — they have not arrived yet.';
  return [
    scenarioStart(messageId),
    ...scenarioStream(messageId, text),
    scenarioEnd(messageId, text),
    scenarioUi(
      messageId,
      scenarioPayload([
        {
          'type': 'request_notice',
          'id': 'rn_late',
          'requestId': 'req_4821',
          'reference': '#SND-4821',
          'status': {'label': 'Provider is late', 'tone': 'warning'},
          'title': 'Scheduled arrival: 10:00 AM',
          'body':
              'We checked the scheduled arrival time and confirmed the '
              'provider has not arrived. You can create a replacement '
              'request.',
          // A confirm rather than a card action, and this is the case where
          // the difference matters most: creating a replacement is a mutation
          // the AI performs on the user's say-so, and the ledger is what stops
          // a double tap opening two of them.
          'confirm': {
            'confirmLabel': 'Create replacement request',
            'confirmTemplate': 'Create a replacement request for #SND-4821',
            'reference': 'req_4821',
          },
          'fallbackText': 'Your provider is late — create a replacement?',
        },
      ]),
    ),
  ];
}

/// Case 4 — the match is running.
const providerSearchingScenario = MockScenario(
  id: 'provider_searching',
  label: 'Searching for providers',
  keywords: ['home cleaning tomorrow', 'find someone', 'match my request'],
  build: _buildProviderSearching,
);

List<AiChatEvent> _buildProviderSearching(String messageId) {
  const text =
      "I'll notify you as soon as providers respond with their availability.";
  return [
    scenarioStart(messageId),
    ...scenarioStream(messageId, text),
    scenarioEnd(messageId, text),
    scenarioUi(
      messageId,
      scenarioPayload([
        {
          'type': 'provider_search',
          'id': 'ps_running',
          'statusLabel': 'Finding providers...',
          'title': 'Searching nearby providers',
          'body':
              "We're matching your request with available providers in your "
              'area.',
          // No `progress`: a provider search has no meaningful percentage,
          // and inventing one would be a number the backend cannot back up.
          // Indeterminate is the default the renderer draws.
          'confirm': {
            'confirmLabel': 'Continue in Background',
            'confirmTemplate': 'Keep looking in the background and let me know',
            'reference': 'req_4821',
          },
          'fallbackText': 'Searching for providers near you',
        },
      ]),
    ),
  ];
}

/// Case 5 — the same search, finished with nothing.
const noSpecialistsAvailableScenario = MockScenario(
  id: 'no_specialists_available',
  label: 'No specialists available',
  keywords: ['no specialists', 'nobody available'],
  build: _buildNoSpecialistsAvailable,
);

List<AiChatEvent> _buildNoSpecialistsAvailable(String messageId) {
  const text = 'I could not find anyone for that slot.';
  return [
    scenarioStart(messageId),
    ...scenarioStream(messageId, text),
    scenarioEnd(messageId, text),
    scenarioUi(
      messageId,
      scenarioPayload([
        {
          // The same node as the running search, in its other state — one
          // component, one concept, two readings.
          'type': 'provider_search',
          'id': 'ps_exhausted',
          'state': 'exhausted',
          'title': 'No Specialists Available',
          'body':
              'No active providers could match your AC Cleaning request for '
              'tomorrow at 10 AM.',
          'confirm': {
            'confirmLabel': 'Change Time Slot',
            'cancelLabel': 'Cancel',
            'confirmTemplate': 'Let us try a different time',
            'cancelTemplate': 'Cancel this request',
            'reference': 'req_4821',
          },
          'fallbackText': 'No specialists are available for that slot',
        },
      ]),
    ),
  ];
}

/// Case 8 — the address is outside coverage.
const locationOutsideServiceAreaScenario = MockScenario(
  id: 'location_outside_service_area',
  label: 'Location outside service area',
  keywords: ['al ruwais', 'outside', 'service area'],
  build: _buildLocationOutsideServiceArea,
);

List<AiChatEvent> _buildLocationOutsideServiceArea(String messageId) {
  const text = 'We do not cover that address yet.';
  return [
    scenarioStart(messageId),
    ...scenarioStream(messageId, text),
    scenarioEnd(messageId, text),
    scenarioUi(
      messageId,
      scenarioPayload([
        {
          'type': 'service_area_notice',
          'id': 'sa_out',
          'title': 'Location outside service area',
          'body': 'This address is currently outside our service area:',
          'addressText': 'Al Ruwais, Western Region, Abu Dhabi',
          // Runs the app's own location flow, exactly as `location_confirm`'s
          // Change control does — not a second location model.
          'changeLabel': 'Change Location',
          'fallbackText': 'Al Ruwais is outside our service area',
        },
      ]),
    ),
  ];
}

/// Case 7 — the turn did not reach the agent.
///
/// The one scenario whose payload is *no payload*: it emits an `error` frame
/// and nothing else, so the bloc moves the in-flight user turn to
/// `AiChatMessageStatus.failed` and the bubble draws its undelivered state
/// with Retry. Selecting it and sending anything reproduces the reference
/// screen, and tapping Retry re-sends the same turn rather than appending a
/// copy of it.
const messageSendFailedScenario = MockScenario(
  id: 'message_send_failed',
  label: 'Message failed to send',
  keywords: ['fail my message'],
  build: _buildMessageSendFailed,
);

List<AiChatEvent> _buildMessageSendFailed(String messageId) => [
  scenarioError(
    'transport_error',
    message: 'ai_chat.transport_request_failed',
  ),
];

/// The edge-case set, in the order the dev picker shows them.
///
/// `offline_message_pending` is absent on purpose — it is the Offline chip,
/// for the reason given in this library's own doc comment.
const edgeCaseScenarios = <MockScenario>[
  activeRequestDetectedScenario,
  bookingCancelledScenario,
  providerLateScenario,
  providerSearchingScenario,
  noSpecialistsAvailableScenario,
  locationOutsideServiceAreaScenario,
  messageSendFailedScenario,
];
