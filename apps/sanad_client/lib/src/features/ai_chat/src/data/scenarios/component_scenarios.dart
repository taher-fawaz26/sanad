/// One scripted turn per semantic component added for the current Figma set,
/// plus the state variants the design actually distinguishes.
///
/// These are the fixtures the dev scenario picker and the showcase route both
/// draw from, so every component in the catalog is reachable in a debug build
/// without a backend. They are deliberately not all happy paths: an order that
/// has been delivered and one still moving, a branch that is open and one
/// closed, a slot grid with a slot already taken.
///
/// Every semantic node carries a `fallbackText`. That is the whole
/// backward-compatibility story for a client older than the component.
library;

import 'package:ai_ui_protocol/ai_ui_protocol.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/scenarios/scenario_support.dart';

// ─── Entity cards ───────────────────────────────────────────────────────────

/// `order_card` ×2 — Figma's "active order tracking dashboard" is a stack.
const orderTrackingScenario = MockScenario(
  id: 'order_tracking',
  label: 'Order tracking',
  keywords: ['order', 'orders', 'tracking', 'delivery'],
  build: _buildOrderTracking,
);

List<AiChatEvent> _buildOrderTracking(String messageId) {
  const text = 'Here is your active order tracking dashboard:';
  return [
    scenarioStart(messageId),
    ...scenarioStream(messageId, text),
    scenarioEnd(messageId, text),
    scenarioUi(
      messageId,
      scenarioPayload([
        {
          'type': 'order_card',
          'id': 'o1',
          'orderId': 'ord_1042',
          'title': 'Order #1042',
          'statusText': 'Delivered',
          'amount': {'amount': 120, 'currency': 'AED'},
          'action': {'type': 'open_service', 'serviceId': 'svc_ac'},
          'fallbackText': 'Order #1042 — delivered — 120 AED',
        },
        {
          'type': 'order_card',
          'id': 'o2',
          'orderId': 'ord_1043',
          'title': 'Order #1043',
          'statusText': 'In progress',
          'status': 'Active',
          'statusTone': 'success',
          'amount': {'amount': 90, 'currency': 'AED'},
          'actions': [
            {
              'label': 'Track',
              'variant': 'outline',
              'action': {'type': 'send_message', 'text': 'Track order 1043'},
            },
          ],
          'fallbackText': 'Order #1043 — in progress — 90 AED',
        },
      ]),
    ),
  ];
}

/// `provider_card` — the assigned specialist, with Call and Message.
const assignedProviderScenario = MockScenario(
  id: 'assigned_provider',
  label: 'Assigned provider',
  keywords: ['provider', 'technician', 'who is coming'],
  build: _buildAssignedProvider,
);

List<AiChatEvent> _buildAssignedProvider(String messageId) {
  const text = 'Here is your assigned service provider:';
  return [
    scenarioStart(messageId),
    ...scenarioStream(messageId, text),
    scenarioEnd(messageId, text),
    scenarioUi(
      messageId,
      scenarioPayload([
        {
          'type': 'provider_card',
          'id': 'p1',
          'providerId': 'prv_ahmed',
          'name': 'Ahmed K.',
          'roleText': 'AC and plumbing specialist',
          'ratingValue': 4.8,
          // A portrait is dynamic media: no local asset stands in for a
          // person, so there is no `assetId` here. A failed download falls
          // back to the card's own person glyph.
          'image': {'url': 'https://picsum.photos/seed/ahmed/160/160'},
          'stats': [
            {'label': 'Completed jobs', 'value': '340+'},
            {'label': 'With CleanCo since', 'value': '2021'},
          ],
          'actions': [
            {
              'label': 'Call',
              'variant': 'outline',
              'action': {'type': 'call_phone', 'phone': '+971501234567'},
            },
            {
              'label': 'Message',
              'action': {
                'type': 'send_message',
                'text': 'Send a message to Ahmed',
              },
            },
          ],
          'fallbackText': 'Ahmed K. — AC and plumbing specialist — rated 4.8',
        },
      ]),
    ),
  ];
}

// ─── Summaries ──────────────────────────────────────────────────────────────

/// `booking_summary` — the confirm-or-go-back card.
const bookingSummaryScenario = MockScenario(
  id: 'booking_summary',
  label: 'Booking summary',
  keywords: ['summary', 'booking summary', 'estimate'],
  build: _buildBookingSummary,
);

List<AiChatEvent> _buildBookingSummary(String messageId) {
  const text = 'Please review the booking before I submit it:';
  return [
    scenarioStart(messageId),
    ...scenarioStream(messageId, text),
    scenarioEnd(messageId, text),
    scenarioUi(
      messageId,
      scenarioPayload([
        {
          'type': 'booking_summary',
          'id': 'bs1',
          'title': 'Booking Summary',
          'items': [
            {'label': 'Service', 'value': 'Deep Cleaning'},
            {'label': 'Provider', 'value': 'CleanCo Marina'},
            {
              'label': 'Estimated Cost',
              'value': '150 AED',
              'valueTone': 'primary',
            },
          ],
          'actions': [
            {
              'label': 'Go back',
              'variant': 'secondary',
              'intent': 'neutral',
              'action': {'type': 'send_message', 'text': 'Go back'},
            },
            {
              'label': 'Confirm',
              'action': {'type': 'send_message', 'text': 'Confirm the booking'},
            },
          ],
          'fallbackText': 'Deep Cleaning with CleanCo Marina — 150 AED',
        },
      ]),
    ),
  ];
}

/// `request_summary` — the full request read back, with a maps row.
const requestSummaryScenario = MockScenario(
  id: 'request_summary',
  label: 'Request summary',
  keywords: ['request', 'submit', 'my request'],
  build: _buildRequestSummary,
);

List<AiChatEvent> _buildRequestSummary(String messageId) {
  const text = 'This is what I have for your request:';
  return [
    scenarioStart(messageId),
    ...scenarioStream(messageId, text),
    scenarioEnd(messageId, text),
    scenarioUi(
      messageId,
      scenarioPayload([
        {
          'type': 'request_summary',
          'id': 'rs1',
          'items': [
            {'label': 'Service', 'value': 'Home Cleaning'},
            {'label': 'Date and time', 'value': 'Tomorrow, 10:00 AM'},
            {'label': 'Location', 'value': 'Home - Dubai Marina'},
          ],
          'summaryTitle': 'Summary',
          'summaryText':
              'A full home clean — three bedrooms, living room, kitchen and '
              'two bathrooms. Eco-friendly products preferred, and there is a '
              'pet in the house.',
          'location': {
            'label': 'Home - Dubai Marina',
            'addressText': 'Dubai Marina, Tower 5, Apt 1204',
            'action': {
              'type': 'open_map',
              'query': 'Dubai Marina, Tower 5, Dubai',
            },
          },
          'actions': [
            {
              'label': 'Cancel',
              'variant': 'secondary',
              'intent': 'neutral',
              'action': {'type': 'send_message', 'text': 'Cancel the request'},
            },
            {
              'label': 'Confirm',
              'action': {'type': 'send_message', 'text': 'Submit the request'},
            },
          ],
          'fallbackText': 'Home Cleaning tomorrow at 10:00 AM in Dubai Marina',
        },
      ]),
    ),
  ];
}

/// `payment_receipt` — a settled payment, with a reference id marked LTR.
const paymentReceiptScenario = MockScenario(
  id: 'payment_receipt',
  label: 'Payment receipt',
  keywords: ['payment', 'paid', 'receipt', 'invoice'],
  build: _buildPaymentReceipt,
);

List<AiChatEvent> _buildPaymentReceipt(String messageId) {
  const text =
      'Your payment was processed successfully. Here is your transaction '
      'receipt:';
  return [
    scenarioStart(messageId),
    ...scenarioStream(messageId, text),
    scenarioEnd(messageId, text),
    scenarioUi(
      messageId,
      scenarioPayload([
        {
          'type': 'payment_receipt',
          'id': 'pr1',
          'title': 'Payment Successful',
          'subtitle': 'Thank you for your order',
          'items': [
            // Marked LTR so the reference reads correctly in Arabic — the
            // SAN-770 class of bug.
            {
              'label': 'Transaction ID',
              'value': 'TXN-8829410',
              'isLtrValue': true,
            },
            {'label': 'Payment Method', 'value': 'Apple Pay (•••• 4920)'},
            {'label': 'Date and Time', 'value': 'Today, 10:42 AM'},
          ],
          'total': {
            'label': 'Amount Paid',
            'amount': {'amount': 150, 'currency': 'AED'},
          },
          'actions': [
            {
              'label': 'View Receipt',
              'variant': 'outline',
              'action': {'type': 'open_document', 'documentId': 'rcpt_8829410'},
            },
          ],
          'fallbackText': 'Payment successful — 150 AED — TXN-8829410',
        },
      ]),
    ),
  ];
}

// ─── Interactive ────────────────────────────────────────────────────────────

/// `time_slots` — a grid with one slot pre-selected and one already taken.
const timeSlotsScenario = MockScenario(
  id: 'time_slots',
  label: 'Time slots',
  keywords: ['slot', 'slots', 'time', 'when'],
  build: _buildTimeSlots,
);

List<AiChatEvent> _buildTimeSlots(String messageId) {
  const text = 'Available time slots for tomorrow:';
  return [
    scenarioStart(messageId),
    ...scenarioStream(messageId, text),
    scenarioEnd(messageId, text),
    scenarioUi(
      messageId,
      scenarioPayload([
        {
          'type': 'time_slots',
          'id': 'ts1',
          'dateLabel': 'Tomorrow, September 3rd',
          'slots': [
            {'id': 's_0900', 'label': '9:00 AM'},
            {'id': 's_1030', 'label': '10:30 AM'},
            {'id': 's_1200', 'label': '12:00 PM'},
            // Taken. Shown rather than omitted, so the user can see that
            // 2:00 PM exists and is gone.
            {'id': 's_1400', 'label': '2:00 PM', 'enabled': false},
            {'id': 's_1530', 'label': '3:30 PM'},
            {'id': 's_1700', 'label': '5:00 PM'},
          ],
          'selectedSlotId': 's_0900',
          'confirmLabel': 'Confirm Time',
          'confirmTemplate': 'Book me the {slot} slot tomorrow',
          'fallbackText':
              'Slots tomorrow: 9:00 AM, 10:30 AM, 12:00 PM, 3:30 PM, 5:00 PM',
        },
      ]),
    ),
  ];
}

/// `review_request` — a comment box whose text becomes the next user turn.
const reviewRequestScenario = MockScenario(
  id: 'review_request',
  label: 'Service review',
  keywords: ['review', 'rate', 'feedback', 'experience'],
  build: _buildReviewRequest,
);

List<AiChatEvent> _buildReviewRequest(String messageId) {
  const text = "How was your experience with today's service?";
  return [
    scenarioStart(messageId),
    ...scenarioStream(messageId, text),
    scenarioEnd(messageId, text),
    scenarioUi(
      messageId,
      scenarioPayload([
        {
          'type': 'review_request',
          'id': 'rv1',
          'serviceName': 'Deep Cleaning',
          'providerText': 'Provided by CleanCo Marina',
          'commentPlaceholder': 'Leave a comment (optional)...',
          'maxCommentLength': 300,
          'submitLabel': 'Submit Review',
          'submitTemplate': 'My review of the Deep Cleaning service: {comment}',
          'fallbackText': 'How was your Deep Cleaning service?',
        },
      ]),
    ),
  ];
}

/// `location_picker` — saved places plus the device's own location.
const locationPickerScenario = MockScenario(
  id: 'location_picker',
  label: 'Set location',
  keywords: ['set location', 'my address', 'where'],
  build: _buildLocationPicker,
);

List<AiChatEvent> _buildLocationPicker(String messageId) {
  const text = 'Where should the service happen?';
  return [
    scenarioStart(messageId),
    ...scenarioStream(messageId, text),
    scenarioEnd(messageId, text),
    scenarioUi(
      messageId,
      scenarioPayload([
        {
          'type': 'location_picker',
          'id': 'lp1',
          'title': 'Set your location',
          'searchPlaceholder': 'Search for a neighborhood or city...',
          'useCurrentLabel': 'Use current location',
          'savedLabel': 'Saved locations',
          'savedLocations': [
            {
              'id': 'home',
              'name': 'Home',
              'addressText': 'Dubai Marina, Tower 5, Apt 1204',
              'icon': 'fa-solid fa-house',
            },
            {
              'id': 'office',
              'name': 'Office',
              'addressText': 'DIFC, The Gate District, Level 4',
              'icon': 'fa-solid fa-briefcase',
            },
            {
              'id': 'gym',
              'name': 'Gym',
              'addressText': 'JBR, Rimal Sector, Ground Level',
            },
          ],
          'confirmLabel': 'Confirm',
          'confirmTemplate': 'Use {location} as the service address',
          'fallbackText': 'Which address should I use?',
        },
      ]),
    ),
  ];
}

// ─── Prompts ────────────────────────────────────────────────────────────────

/// `reminder_card` — the upcoming-appointment heads-up.
const reminderScenario = MockScenario(
  id: 'reminder',
  label: 'Appointment reminder',
  keywords: ['reminder', 'heads up', 'soon'],
  build: _buildReminder,
);

List<AiChatEvent> _buildReminder(String messageId) {
  const text = 'Quick heads-up about your upcoming appointment:';
  return [
    scenarioStart(messageId),
    ...scenarioStream(messageId, text),
    scenarioEnd(messageId, text),
    scenarioUi(
      messageId,
      scenarioPayload([
        {
          'type': 'reminder_card',
          'id': 'rm1',
          'title': 'Reminder',
          'subtitle': 'AC Maintenance',
          'body':
              'Your appointment is in 30 minutes. Please make sure someone is '
              'home to grant access.',
          'tone': 'warning',
          'actions': [
            {
              'label': 'Reschedule',
              'variant': 'outline',
              'action': {
                'type': 'send_message',
                'text': 'Reschedule my appointment',
              },
            },
            {
              'label': "I'm ready",
              'action': {'type': 'send_message', 'text': "I'm ready"},
            },
          ],
          'fallbackText': 'Reminder: AC Maintenance in 30 minutes',
        },
      ]),
    ),
  ];
}

/// `media_request` — three ways to supply a photo or video.
const mediaRequestScenario = MockScenario(
  id: 'media_request',
  label: 'Add photos or video',
  keywords: ['photo', 'photos', 'picture', 'video', 'upload'],
  build: _buildMediaRequest,
);

List<AiChatEvent> _buildMediaRequest(String messageId) {
  const text = 'A photo of the problem would help me route this correctly.';
  return [
    scenarioStart(messageId),
    ...scenarioStream(messageId, text),
    scenarioEnd(messageId, text),
    scenarioUi(
      messageId,
      scenarioPayload([
        {
          'type': 'media_request',
          'id': 'mr1',
          'title': 'Add photos or video',
          'body':
              'Sanad only requests camera or photo access when you choose one '
              'of these options.',
          'options': [
            {'label': 'Take a photo', 'source': 'camera'},
            {'label': 'Choose photos', 'source': 'gallery'},
            {'label': 'Add a short video', 'source': 'video'},
          ],
          'cancelLabel': 'Cancel',
          'fallbackText': 'Send a photo or a short video of the problem',
        },
      ]),
    ),
  ];
}

/// `permission_request` — the camera variant, with no illustration.
const cameraPermissionScenario = MockScenario(
  id: 'camera_permission',
  label: 'Camera permission',
  keywords: ['camera', 'camera access'],
  build: _buildCameraPermission,
);

List<AiChatEvent> _buildCameraPermission(String messageId) {
  const text = 'I need the camera for that.';
  return [
    scenarioStart(messageId),
    ...scenarioStream(messageId, text),
    scenarioEnd(messageId, text),
    scenarioUi(
      messageId,
      scenarioPayload([
        {
          'type': 'permission_request',
          'id': 'perm_cam',
          'permission': 'camera',
          'title': 'Allow camera access?',
          'body':
              'Sanad needs your camera to take photos for this request. You '
              'can change this later in settings.',
          'allowLabel': 'Allow camera',
          'denyLabel': 'Not now',
          'fallbackText': 'Sanad needs camera access to continue',
        },
      ]),
    ),
  ];
}

/// `permission_request` — the location variant, with the map illustration.
const locationPermissionScenario = MockScenario(
  id: 'location_permission',
  label: 'Location permission',
  keywords: ['location access', 'allow location'],
  build: _buildLocationPermission,
);

List<AiChatEvent> _buildLocationPermission(String messageId) {
  const text = 'I can find what is nearby once I know where you are.';
  return [
    scenarioStart(messageId),
    ...scenarioStream(messageId, text),
    scenarioEnd(messageId, text),
    scenarioUi(
      messageId,
      scenarioPayload([
        {
          'type': 'permission_request',
          'id': 'perm_loc',
          'permission': 'location',
          'title': 'Allow location access',
          'body':
              'Sanad needs your location to find nearby services and provide '
              'accurate recommendations.',
          // Genuinely static: the client's own map illustration. A backend
          // that has a real static map for the place would send a `url` here
          // instead, and this asset would become its fallback.
          'image': {'assetId': 'ai_map_preview'},
          'allowLabel': 'Allow while using the app',
          'denyLabel': "Don't allow",
          'fallbackText': 'Sanad needs your location to find nearby services',
        },
      ]),
    ),
  ];
}

/// `location_confirm` — an address read back before it is used.
const locationConfirmScenario = MockScenario(
  id: 'location_confirm',
  label: 'Confirm location',
  keywords: ['confirm location', 'is this right'],
  build: _buildLocationConfirm,
);

List<AiChatEvent> _buildLocationConfirm(String messageId) {
  const text = 'Is this the right address?';
  return [
    scenarioStart(messageId),
    ...scenarioStream(messageId, text),
    scenarioEnd(messageId, text),
    scenarioUi(
      messageId,
      scenarioPayload([
        {
          'type': 'location_confirm',
          'id': 'lc1',
          'title': 'Confirm your location',
          'image': {'assetId': 'ai_map_preview'},
          'addressText': 'Dubai Marina',
          'confirmLabel': 'Confirm location',
          'changeLabel': 'Change location',
          'fallbackText': 'Is Dubai Marina the right address?',
        },
      ]),
    ),
  ];
}

// ─── Cross-component ────────────────────────────────────────────────────────

/// Several semantic components in one reply.
///
/// The property this exercises is that one bubble can carry a mixed document —
/// prose, an entity card, a summary and a suggestion set — and that each part
/// keeps its own state and its own actions.
const mixedComponentsScenario = MockScenario(
  id: 'mixed_components',
  label: 'Mixed components',
  keywords: ['mixed', 'everything'],
  build: _buildMixedComponents,
);

List<AiChatEvent> _buildMixedComponents(String messageId) {
  const text = 'Here is everything about tomorrow:';
  return [
    scenarioStart(messageId),
    ...scenarioStream(messageId, text),
    scenarioEnd(messageId, text),
    scenarioUi(
      messageId,
      scenarioPayload([
        {
          'type': 'appointment_card',
          'id': 'mx_apt',
          'appointmentId': 'apt_9001',
          'title': 'AC Maintenance',
          'startsAt': '2026-09-02T06:00:00Z',
          'whereText': 'Downtown Branch',
          'status': 'Confirmed',
          'statusTone': 'success',
          'actions': [
            {
              'label': 'Reschedule',
              'variant': 'outline',
              'action': {'type': 'send_message', 'text': 'Reschedule'},
            },
            {
              'label': 'Cancel',
              'variant': 'outline',
              'intent': 'destructive',
              'action': {
                'type': 'send_message',
                'text': 'Cancel my appointment',
              },
            },
          ],
          'fallbackText': 'AC Maintenance, 2 September at 10:00 AM',
        },
        {
          'type': 'provider_card',
          'id': 'mx_prv',
          'providerId': 'prv_ahmed',
          'name': 'Ahmed K.',
          'roleText': 'AC and plumbing specialist',
          'ratingValue': 4.8,
          'actions': [
            {
              'label': 'Call',
              'variant': 'outline',
              'action': {'type': 'call_phone', 'phone': '+971501234567'},
            },
          ],
          'fallbackText': 'Ahmed K. — rated 4.8',
        },
        {
          'type': 'reminder_card',
          'id': 'mx_rem',
          'title': 'Reminder',
          'subtitle': 'AC Maintenance',
          'body': 'Someone needs to be home to grant access.',
          'fallbackText': 'Someone needs to be home to grant access',
        },
        {
          'type': 'quick_reply',
          'id': 'mx_qr',
          'options': [
            {
              'label': 'That all works',
              'action': {'type': 'send_message', 'text': 'That all works'},
            },
            {
              'label': 'Change the time',
              'action': {'type': 'send_message', 'text': 'Change the time'},
            },
          ],
        },
      ]),
    ),
  ];
}


// ─── The offer, status and confirmation set ─────────────────────────────────

/// `provider_search` — the compact "we are looking" state.
const providerSearchScenario = MockScenario(
  id: 'provider_search',
  label: 'Searching for providers',
  keywords: ['find a provider', 'searching', 'find providers'],
  build: _buildProviderSearch,
);

List<AiChatEvent> _buildProviderSearch(String messageId) {
  const text = 'Let me find someone near you.';
  return [
    scenarioStart(messageId),
    ...scenarioStream(messageId, text),
    scenarioEnd(messageId, text),
    scenarioUi(
      messageId,
      scenarioPayload([
        {
          'type': 'provider_search',
          'id': 'ps1',
          'statusLabel': 'Finding providers...',
          'title': 'Searching nearby providers',
          'body':
              "We're matching your request with available providers in your "
              'area.',
          // No `progress`: a provider search has no meaningful percentage, and
          // inventing one would be a number the backend cannot back up.
          'fallbackText': 'Searching for providers near you',
        },
      ]),
    ),
  ];
}

/// `provider_card` as an offer — the compact reading, with Accept and Decline.
const providerOfferScenario = MockScenario(
  id: 'provider_offer',
  label: 'Provider offer',
  keywords: ['offer', 'accept offer', 'who can come'],
  build: _buildProviderOffer,
);

List<AiChatEvent> _buildProviderOffer(String messageId) {
  const text = 'Ahmed can take this one:';
  return [
    scenarioStart(messageId),
    ...scenarioStream(messageId, text),
    scenarioEnd(messageId, text),
    scenarioUi(messageId, scenarioPayload([_providerOfferBlock()])),
  ];
}

/// The same offer opened out — distance, description, services and photos.
const providerOfferExpandedScenario = MockScenario(
  id: 'provider_offer_expanded',
  label: 'Provider offer — expanded',
  keywords: ['tell me about ahmed', 'provider details'],
  build: _buildProviderOfferExpanded,
);

List<AiChatEvent> _buildProviderOfferExpanded(String messageId) {
  const text = 'Here is everything about Ahmed:';
  return [
    scenarioStart(messageId),
    ...scenarioStream(messageId, text),
    scenarioEnd(messageId, text),
    scenarioUi(
      messageId,
      scenarioPayload([_providerOfferBlock(expanded: true)]),
    ),
  ];
}

/// One block builder for both readings, because they are one node.
///
/// The payload is **identical apart from `presentation`** — which is the point
/// Figma's two frames make: the collapsed card is the same provider with the
/// same detail, not a smaller payload. Sending the detail either way is also
/// what earns the card its chevron; a compact card with nothing behind it
/// would show a control that does nothing.
Map<String, dynamic> _providerOfferBlock({bool expanded = false}) =>
    <String, dynamic>{
      'type': 'provider_card',
      'id': expanded ? 'po_expanded' : 'po_compact',
      'providerId': 'prv_ahmed',
      'name': 'Ahmed K',
      'roleText': 'AC & Plumbing Specialist',
      'verified': true,
      'presentation': expanded ? 'expanded' : 'compact',
      'image': {'url': 'https://picsum.photos/seed/ahmed/160/160'},
      'proposedTimeLabel': 'Proposed Time',
      // Structured and in UTC: the client converts to device time and formats
      // it, so "Thursday · 5:00 PM" is never something the agent typed.
      'proposedTime': '2026-11-19T13:00:00Z',
      'distanceMeters': 2500,
      'description':
          'Premium eco-friendly yacht & vehicle cleaning specialist. '
          'Utilizing high-gloss marine coatings and protective waxes. '
          'Frequently servicing vessels docked around the Marina.',
      'services': ['Interior clean', 'Polishing'],
      'servicesLabel': 'Services',
      'photos': [
        {'url': 'https://picsum.photos/seed/work1/240/240'},
        {'url': 'https://picsum.photos/seed/work2/240/240'},
        {'url': 'https://picsum.photos/seed/work3/240/240'},
      ],
      'offer': {
        'offerId': 'off_77',
        'acceptLabel': 'Accept Offer',
        'declineLabel': 'Decline',
        'acceptTemplate': "I'll take Ahmed's offer",
        'declineTemplate': 'Not this one, thanks',
      },
      'fallbackText': 'Ahmed K offers Thursday at 5:00 PM — accept or decline',
    };

/// `booking_summary` carrying an outcome and a provider — Figma's
/// booking-confirmed card.
const bookingConfirmedScenario = MockScenario(
  id: 'booking_confirmed',
  label: 'Booking confirmed',
  keywords: ['booking confirmed', 'is it booked'],
  build: _buildBookingConfirmed,
);

List<AiChatEvent> _buildBookingConfirmed(String messageId) {
  const text = 'All set.';
  return [
    scenarioStart(messageId),
    ...scenarioStream(messageId, text),
    scenarioEnd(messageId, text),
    scenarioUi(
      messageId,
      scenarioPayload([
        {
          'type': 'booking_summary',
          'id': 'bc1',
          'statusText': 'Booking Confirmed!',
          'statusTone': 'success',
          'provider': {
            'providerId': 'prv_ahmed',
            'name': 'Ahmed K',
            'roleText': 'AC & Plumbing Specialist',
            'image': {'url': 'https://picsum.photos/seed/ahmed/160/160'},
            'verified': true,
          },
          'items': [
            {'label': 'Date', 'value': 'Thursday, Oct 24'},
            {'label': 'Time', 'value': '5:00 PM'},
            {'label': 'Location', 'value': '91 Orchard St, New York'},
            {
              'label': 'Booking Reference',
              'value': '#SND-8829-AQ',
              // Marked LTR so the leading hash stays at the visual start in
              // Arabic rather than reordering to the far end.
              'isLtrValue': true,
            },
          ],
          'fallbackText': 'Booking confirmed with Ahmed K — #SND-8829-AQ',
        },
      ]),
    ),
  ];
}

/// `service_timeline` — the job lifecycle, mid-flight.
const serviceTimelineScenario = MockScenario(
  id: 'service_timeline',
  label: 'Service timeline',
  keywords: ['timeline', 'where is my provider', 'status'],
  build: _buildServiceTimeline,
);

List<AiChatEvent> _buildServiceTimeline(String messageId) {
  const text = 'Here is where your service has got to:';
  return [
    scenarioStart(messageId),
    ...scenarioStream(messageId, text),
    scenarioEnd(messageId, text),
    scenarioUi(
      messageId,
      scenarioPayload([
        {
          'type': 'service_timeline',
          'id': 'tl1',
          'title': 'Timeline',
          'status': 'In Progress',
          'statusTone': 'success',
          // Each step carries a closed state alongside its prose, so the client
          // decides the rail glyph and the agent can answer "where are we?"
          // from its own payload.
          'items': [
            {
              'state': 'completed',
              'title': 'Booking Confirmed',
              'description': 'Your booking has been confirmed',
              'at': '2026-11-17T09:45:00Z',
            },
            {
              'state': 'completed',
              'title': 'Provider Assigned',
              'description': 'Ahmed K has been assigned',
              'at': '2026-11-17T09:52:00Z',
            },
            {
              'state': 'active',
              'title': 'En Route',
              'description': 'Provider is on the way',
              'at': '2026-11-17T10:45:00Z',
            },
            {
              'state': 'pending',
              'title': 'Service In Progress',
              'description': 'Provider is working on your service',
            },
            {
              'state': 'pending',
              'title': 'Service Completed',
              'description': 'Awaiting service completion',
            },
          ],
          'actions': [
            {
              'label': 'Mark as Complete',
              'action': {
                'type': 'send_message',
                'text': 'The service is complete',
              },
            },
          ],
          'fallbackText': 'Your service is in progress — Ahmed is on the way',
        },
      ]),
    ),
  ];
}

/// `verification_code` — the completion code the user shows the provider.
const verificationCodeScenario = MockScenario(
  id: 'verification_code',
  label: 'Verification code',
  keywords: ['code', 'completion code', 'verification code'],
  build: _buildVerificationCode,
);

List<AiChatEvent> _buildVerificationCode(String messageId) {
  const text = 'Here is your completion code.';
  return [
    scenarioStart(messageId),
    ...scenarioStream(messageId, text),
    scenarioEnd(messageId, text),
    scenarioUi(
      messageId,
      scenarioPayload([
        {
          'type': 'verification_code',
          'id': 'vc1',
          'label': 'verification code',
          'body':
              'Share this code with the service provider after completing the '
              'service for confirmation',
          'code': '65066',
          'actions': [
            {
              'label': 'Copy code',
              'variant': 'outline',
              'action': {'type': 'copy_text', 'text': '65066'},
            },
          ],
          'fallbackText': 'Your completion code is 65066',
        },
      ]),
    ),
  ];
}

/// `confirm_prompt` — the destructive yes-or-no.
const cancelConfirmScenario = MockScenario(
  id: 'cancel_confirm',
  label: 'Cancel confirmation',
  keywords: ['cancel my booking', 'cancel it'],
  build: _buildCancelConfirm,
);

List<AiChatEvent> _buildCancelConfirm(String messageId) {
  const text = 'Before I do that —';
  return [
    scenarioStart(messageId),
    ...scenarioStream(messageId, text),
    scenarioEnd(messageId, text),
    scenarioUi(
      messageId,
      scenarioPayload([
        {
          'type': 'confirm_prompt',
          'id': 'cp1',
          'title': 'Are you sure you want to cancel?',
          'subjectTitle': 'AC Maintenance',
          'subjectSubtitle': 'Lina M • Tomorrow 10:00 AM',
          'tone': 'error',
          'confirm': {
            'confirmLabel': 'Yes, Cancel',
            'cancelLabel': 'Keep It',
            'confirmTemplate': 'Yes, cancel my AC Maintenance booking',
            'cancelTemplate': 'Keep it',
            'reference': 'req_1042',
            // Confirming is the damaging choice here, so it leads and is drawn
            // destructive — the safe option takes the trailing position.
            'destructive': true,
          },
          'fallbackText': 'Cancel your AC Maintenance booking?',
        },
      ]),
    ),
  ];
}

/// `location_confirm` reading a chosen place back, with a structured cancel.
const selectedLocationScenario = MockScenario(
  id: 'selected_location',
  label: 'Selected delivery location',
  keywords: ['delivery location', 'selected location'],
  build: _buildSelectedLocation,
);

List<AiChatEvent> _buildSelectedLocation(String messageId) {
  const text = 'I have this as your delivery address:';
  return [
    scenarioStart(messageId),
    ...scenarioStream(messageId, text),
    scenarioEnd(messageId, text),
    scenarioUi(
      messageId,
      scenarioPayload([
        {
          'type': 'location_confirm',
          'id': 'lc_sel',
          'title': 'Selected Delivery Location',
          'addressText': 'Tahrir St, Downtown, Cairo',
          'confirmLabel': 'Confirm location',
          // A structured refusal rather than silence: the agent hears "not
          // this one" and can offer another.
          'cancelLabel': 'Cancel',
          'fallbackText': 'Deliver to Tahrir St, Downtown, Cairo?',
        },
      ]),
    ),
  ];
}

/// `review_request` with the star rating Figma added.
const ratedReviewScenario = MockScenario(
  id: 'rated_review',
  label: 'Review with a rating',
  keywords: ['rate', 'how was it', 'leave a review'],
  build: _buildRatedReview,
);

List<AiChatEvent> _buildRatedReview(String messageId) {
  const text = 'One last thing —';
  return [
    scenarioStart(messageId),
    ...scenarioStream(messageId, text),
    scenarioEnd(messageId, text),
    scenarioUi(
      messageId,
      scenarioPayload([
        {
          'type': 'review_request',
          'id': 'rv_rated',
          'serviceName': 'How was your experience?',
          'commentPlaceholder': 'Leave a comment (optional)...',
          'maxRating': 5,
          'ratingRequired': true,
          'submitLabel': 'Submit Review',
          'submitTemplate': '{rating} stars: {comment}',
          'fallbackText': 'How was your experience?',
        },
      ]),
    ),
  ];
}

/// `request_summary` with attachments and a structured submit — Figma's full
/// service summary.
const serviceSummaryScenario = MockScenario(
  id: 'service_summary',
  label: 'Service summary',
  keywords: ['summary', 'review my request', 'submit my request'],
  build: _buildServiceSummary,
);

List<AiChatEvent> _buildServiceSummary(String messageId) {
  const text = 'Here is your request. Shall I send it?';
  return [
    scenarioStart(messageId),
    ...scenarioStream(messageId, text),
    scenarioEnd(messageId, text),
    scenarioUi(
      messageId,
      scenarioPayload([
        {
          'type': 'request_summary',
          'id': 'ss1',
          'items': [
            {'label': 'Service', 'value': 'Home Cleaning'},
            {'label': 'Date & time', 'value': 'Tomorrow · 10:00 AM'},
            {'label': 'Location', 'value': 'Home - Dubai Marina'},
          ],
          'summaryTitle': 'Summary',
          'summaryText':
              'The customer requested a full home cleaning service. Agreed on '
              'cleaning the entire apartment (3 bedrooms, living room, '
              'kitchen, 2 bathrooms). Prefers eco-friendly cleaning products. '
              'Preferred time: next Saturday morning. Note: there is a pet in '
              'the house.',
          'photosLabel': 'photos',
          'photos': [
            {'url': 'https://picsum.photos/seed/req1/240/240'},
            {'url': 'https://picsum.photos/seed/req2/240/240'},
            {'url': 'https://picsum.photos/seed/req3/240/240'},
          ],
          'location': {
            'label': 'Home - Dubai Marina',
            'addressText': 'Home - Dubai Marina',
            'action': {'type': 'open_map', 'query': 'Dubai Marina'},
          },
          // The decision travels as a structured answer correlated with this
          // node, not as a sentence the agent would have to re-read.
          'confirm': {
            'confirmLabel': 'Confirm',
            'cancelLabel': 'Cancel',
            'confirmTemplate': 'Yes, submit my request',
            'cancelTemplate': 'Not yet — let me change something',
            'reference': 'req_1042',
          },
          'fallbackText': 'Home Cleaning tomorrow at 10:00 AM — confirm?',
        },
      ]),
    ),
  ];
}

/// Every scenario in this file, in the order the dev picker shows them.
const componentScenarios = <MockScenario>[
  orderTrackingScenario,
  assignedProviderScenario,
  bookingSummaryScenario,
  requestSummaryScenario,
  paymentReceiptScenario,
  timeSlotsScenario,
  reviewRequestScenario,
  locationPickerScenario,
  reminderScenario,
  mediaRequestScenario,
  cameraPermissionScenario,
  locationPermissionScenario,
  locationConfirmScenario,

  // The offer, status and confirmation set the current Figma frames added.
  providerSearchScenario,
  providerOfferScenario,
  providerOfferExpandedScenario,
  bookingConfirmedScenario,
  serviceTimelineScenario,
  verificationCodeScenario,
  cancelConfirmScenario,
  selectedLocationScenario,
  ratedReviewScenario,
  serviceSummaryScenario,

  mixedComponentsScenario,
];
