import 'package:ai_ui_protocol/ai_ui_protocol.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/scenarios/component_scenarios.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/scenarios/scenario_support.dart';

Map<String, dynamic> _serviceCard({
  required String id,
  required String title,
  required String subtitle,
  required int price,
  Map<String, dynamic>? badge,
  bool selected = false,
  String? imageUrl,
}) => <String, dynamic>{
  'type': 'service_card',
  'id': 'svc_$id',
  'serviceId': id,
  'title': title,
  'subtitle': subtitle,
  'price': {'amount': price, 'currency': 'AED'},
  // A service photo is backend-owned media, so it travels as a `url`. The
  // `assetId` beside it is the client's own illustration, used only if the
  // download fails — which is the whole point of one image object with two
  // optional fields.
  if (imageUrl != null) 'image': {'url': imageUrl, 'assetId': 'service_tools'},
  if (badge != null) 'badge': badge,
  // Figma marks the service the conversation is currently about with an accent
  // border rather than a fill.
  if (selected) 'selected': true,
  'action': {'type': 'open_service', 'serviceId': id},
  // The card's own call to action, drawn inside its border — Figma's `Select`
  // pill. Posting the choice as a user turn keeps the agent in the loop.
  'actions': [
    {
      'label': 'Select',
      'variant': 'secondary',
      'intent': 'neutral',
      'action': {'type': 'send_message', 'text': 'I want $title'},
    },
  ],
  // Always set on a semantic node: this is the entire backward-compatibility
  // story for a client that predates the component.
  'fallbackText': '$title — $price AED',
};

const _plainText = MockScenario(
  id: 'plain_text',
  label: 'Plain streaming text',
  keywords: ['hello', 'hi', 'مرحبا'],
  build: _buildPlainText,
);

List<AiChatEvent> _buildPlainText(String messageId) => scenarioSay(
  messageId,
  'I can help you find services, check your bookings, and manage your '
  'appointments. What would you like to do?',
);

const _textAndCard = MockScenario(
  id: 'text_card',
  label: 'Text + card + button',
  keywords: ['confirm', 'confirmed'],
  build: _buildTextAndCard,
);

List<AiChatEvent> _buildTextAndCard(String messageId) {
  const text = 'Your appointment is confirmed.';
  return [
    scenarioStart(messageId),
    ...scenarioStream(messageId, text),
    scenarioUi(
      messageId,
      scenarioPayload([
        {
          'type': 'card',
          'id': 'c1',
          'title': 'AC Maintenance',
          'children': [
            {'type': 'text', 'id': 't1', 'text': 'Tomorrow at 10:00 AM'},
            {
              'type': 'text',
              'id': 't2',
              'text': 'Downtown branch',
              'style': 'caption',
              'emphasis': 'muted',
            },
            {
              'type': 'button',
              'id': 'b1',
              'label': 'View appointment',
              'size': 'small',
              'action': {
                'type': 'open_appointment',
                'appointmentId': 'apt_123',
              },
            },
          ],
        },
      ]),
    ),
    scenarioEnd(messageId, text),
  ];
}

const _serviceList = MockScenario(
  id: 'service_list',
  label: 'Semantic service cards',
  keywords: ['service', 'services', 'ac', 'clean'],
  build: _buildServiceList,
);

List<AiChatEvent> _buildServiceList(String messageId) {
  const text = 'Here are the available services matching your request:';
  return [
    scenarioStart(messageId),
    ...scenarioStream(messageId, text),
    scenarioUi(
      messageId,
      scenarioPayload([
        _serviceCard(
          id: 'svc_1',
          imageUrl: 'https://picsum.photos/seed/ac/640/360',
          title: 'AC Maintenance',
          subtitle:
              'Complete system cleaning, filter replacement, and airflow '
              'diagnostics.',
          price: 100,
          // `primary` is the brand tint Figma uses for POPULAR — the one tone
          // the design system's status badge has no equivalent for.
          badge: {'label': 'POPULAR', 'tone': 'primary'},
          selected: true,
        ),
        _serviceCard(
          id: 'svc_2',
          imageUrl: 'https://picsum.photos/seed/cleaning/640/360',
          title: 'Deep Cleaning',
          subtitle:
              'Full home sanitization including bedrooms, living rooms, and '
              'kitchen areas.',
          price: 250,
        ),
        _serviceCard(
          id: 'svc_3',
          imageUrl: 'https://picsum.photos/seed/plumbing/640/360',
          title: 'Plumbing Repair',
          subtitle:
              'Emergency callout for leaks, blockages, or fixture '
              'installations.',
          price: 180,
        ),
      ]),
    ),
    scenarioEnd(messageId, text),
  ];
}

const _appointment = MockScenario(
  id: 'appointment',
  label: 'Appointment card + actions',
  keywords: ['appointment', 'booking', 'reschedule'],
  build: _buildAppointment,
);

List<AiChatEvent> _buildAppointment(String messageId) {
  const text = 'Here is your next appointment:';
  return [
    scenarioStart(messageId),
    ...scenarioStream(messageId, text),
    scenarioUi(
      messageId,
      scenarioPayload([
        {
          'type': 'appointment_card',
          'id': 'apt',
          'appointmentId': 'apt_123',
          'title': 'AC Maintenance',
          // Structured UTC — the client formats it for the reader's locale and
          // clock, so the agent never guesses AM/PM or Arabic numerals.
          'startsAt': '2026-09-02T06:00:00Z',
          'whereText': 'Downtown branch',
          'status': 'Confirmed',
          'statusTone': 'success',
          'action': {'type': 'open_appointment', 'appointmentId': 'apt_123'},
          // Attached to the card rather than sent as sibling `row` + `button`
          // primitives: Figma draws them inside the card's own border, sharing
          // its padding. The primitive shape still validates and still
          // renders — it just renders as a separate block underneath.
          'actions': [
            {
              'label': 'Reschedule',
              'variant': 'outline',
              'action': {
                'type': 'open_appointment',
                'appointmentId': 'apt_123',
              },
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
          'fallbackText': 'AC Maintenance, tomorrow at 10:00 AM',
        },
      ]),
    ),
    scenarioEnd(messageId, text),
  ];
}

const _branches = MockScenario(
  id: 'branches',
  label: 'Branch list with badges',
  keywords: ['branch', 'branches', 'near', 'location'],
  build: _buildBranches,
);

List<AiChatEvent> _buildBranches(String messageId) {
  const text = 'Here are your nearest branches:';
  return [
    scenarioStart(messageId),
    ...scenarioStream(messageId, text),
    scenarioUi(
      messageId,
      scenarioPayload([
        {
          'type': 'branch_card',
          'id': 'br1',
          'branchId': 'br_1',
          'name': 'Downtown',
          'addressText': 'Sheikh Zayed Road',
          'distanceMeters': 450,
          'status': 'OPEN',
          'statusTone': 'success',
          // Prose, not a structured instant: what the reader needs is the
          // relative phrase, and which day it resolves to depends on the
          // branch's own calendar.
          'hoursText': 'Closes 9:00 PM',
          'action': {'type': 'open_branch', 'branchId': 'br_1'},
          'fallbackText': 'Downtown — 450 m — open until 9:00 PM',
        },
        {
          'type': 'branch_card',
          'id': 'br2',
          'branchId': 'br_2',
          'name': 'Marina',
          'addressText': 'Dubai Marina Walk',
          'distanceMeters': 4800,
          'status': 'CLOSED',
          'statusTone': 'error',
          'hoursText': 'Opens tomorrow 8:00 AM',
          'action': {'type': 'open_branch', 'branchId': 'br_2'},
          'fallbackText': 'Marina — 4.8 km — opens tomorrow 8:00 AM',
        },
      ]),
    ),
    scenarioEnd(messageId, text),
  ];
}

const _primitives = MockScenario(
  id: 'primitives',
  label: 'Primitive layout sampler',
  keywords: ['sampler', 'primitives'],
  build: _buildPrimitives,
);

List<AiChatEvent> _buildPrimitives(String messageId) {
  const text = 'Every primitive the protocol defines:';
  return [
    scenarioStart(messageId),
    ...scenarioStream(messageId, text),
    scenarioUi(
      messageId,
      scenarioPayload([
        {
          'type': 'rich_text',
          'id': 'rt',
          'spans': [
            {'text': 'Emphasis works '},
            {'text': 'inline', 'emphasis': 'strong'},
            {'text': ' without Markdown.', 'emphasis': 'muted'},
          ],
        },
        {'type': 'divider', 'id': 'd1'},
        {
          'type': 'row',
          'id': 'chips',
          'wrap': true,
          'children': [
            {
              'type': 'chip',
              'id': 'c1',
              'label': 'Cleaning',
              'tone': 'success',
            },
            {'type': 'chip', 'id': 'c2', 'label': 'Repairs'},
            {'type': 'chip', 'id': 'c3', 'label': 'Moving'},
          ],
        },
        {
          'type': 'row',
          'id': 'icons',
          'gap': 'md',
          'children': [
            {'type': 'icon', 'id': 'i1', 'name': 'fa-solid fa-calendar'},
            {
              'type': 'icon',
              'id': 'i2',
              'name': 'fa-solid fa-location-dot',
              'tone': 'primary',
            },
            {
              'type': 'icon',
              'id': 'i3',
              'name': 'fa-solid fa-circle-check',
              'tone': 'success',
            },
          ],
        },
        {
          'type': 'progress',
          'id': 'p',
          'value': 0.65,
          'label': 'Booking progress',
        },
        {
          'type': 'list',
          'id': 'l',
          'children': [
            {
              'type': 'list_item',
              'id': 'li1',
              'title': 'Order #1042',
              'subtitle': 'Delivered',
              // Row artwork is backend-owned too, so it travels as a `url`
              // like any other dynamic image.
              'leadingImage': {
                'url': 'https://picsum.photos/seed/order1042/96/96',
              },
              'badge': {'label': 'Done', 'tone': 'success'},
              'trailingText': 'AED 120',
            },
            {
              'type': 'list_item',
              'id': 'li2',
              'title': 'Order #1043',
              'subtitle': 'In progress',
              'leadingImage': {
                'url': 'https://picsum.photos/seed/order1043/96/96',
              },
              'badge': {'label': 'Active', 'tone': 'info'},
              'trailingText': 'AED 90',
            },
          ],
        },
      ]),
    ),
    scenarioEnd(messageId, text),
  ];
}

const _quickReply = MockScenario(
  id: 'quick_reply',
  label: 'Quick replies',
  keywords: ['book', 'yes'],
  build: _buildQuickReply,
);

List<AiChatEvent> _buildQuickReply(String messageId) {
  const text = 'Would you like to book AC Maintenance for tomorrow at 10 AM?';
  return [
    scenarioStart(messageId),
    ...scenarioStream(messageId, text),
    scenarioUi(
      messageId,
      scenarioPayload([
        {
          'type': 'quick_reply',
          'id': 'qr',
          'options': [
            {
              'label': 'Yes, book it',
              'action': {'type': 'send_message', 'text': 'Yes, book it'},
            },
            {
              'label': 'Pick another time',
              'action': {'type': 'send_message', 'text': 'Pick another time'},
            },
            {
              'label': 'Not now',
              'action': {'type': 'send_message', 'text': 'Not now'},
            },
          ],
        },
      ]),
    ),
    scenarioEnd(messageId, text),
  ];
}

// ─── Failure scenarios — the ones that actually matter ─────────────────────

const _unknownNode = MockScenario(
  id: 'unknown_node',
  label: 'Unsupported component',
  keywords: ['unsupported', 'future'],
  build: _buildUnknownNode,
);

List<AiChatEvent> _buildUnknownNode(String messageId) {
  const text = 'This reply uses a component your app does not know yet.';
  return [
    scenarioStart(messageId),
    ...scenarioStream(messageId, text),
    scenarioUi(
      messageId,
      scenarioPayload([
        // Degrades to its fallback text.
        {
          'type': 'service_carousel_v2',
          'id': 'x1',
          'fallbackText': 'AC Maintenance, Deep Cleaning, Plumbing Repair',
        },
        // No fallback: dropped in release, marked in a dev build.
        {'type': 'holographic_map', 'id': 'x2'},
        {
          'type': 'text',
          'id': 'ok',
          'text': 'The rest of the reply still renders.',
        },
      ]),
    ),
    scenarioEnd(messageId, text),
  ];
}

const _unknownAction = MockScenario(
  id: 'unknown_action',
  label: 'Unsupported + unsafe actions',
  keywords: ['delete', 'unsafe'],
  build: _buildUnknownAction,
);

List<AiChatEvent> _buildUnknownAction(String messageId) {
  const text = 'This reply asks for things the app will not do.';
  return [
    scenarioStart(messageId),
    ...scenarioStream(messageId, text),
    scenarioUi(
      messageId,
      scenarioPayload([
        // Not in the action catalog at all — the whole button is dropped.
        {
          'type': 'button',
          'id': 'bad1',
          'label': 'Delete my account',
          'action': {'type': 'delete_account'},
        },
        // A real action type, but pointed at a host outside the allowlist.
        {
          'type': 'button',
          'id': 'bad2',
          'label': 'Open offer',
          'action': {'type': 'open_url', 'url': 'https://evil.example/steal'},
        },
        // Remote images are admitted, but only through the image policy: this
        // one is not https, so it is refused during validation and the app
        // never issues the request.
        {
          'type': 'image',
          'id': 'bad3',
          'url': 'http://tracker.example/pixel.gif',
          'alt': 'tracking pixel',
        },
        // An asset id the client does not publish. There is no field in which
        // a local path means anything, so this resolves to nothing.
        {
          'type': 'image',
          'id': 'bad4',
          'assetId': 'assets/images/secret.png',
          'alt': 'invented local file',
        },
        {
          'type': 'button',
          'id': 'ok',
          'label': 'This one is allowed',
          'size': 'small',
          'action': {'type': 'send_message', 'text': 'Thanks'},
        },
      ]),
    ),
    scenarioEnd(messageId, text),
  ];
}

const _malformed = MockScenario(
  id: 'malformed',
  label: 'Malformed payload',
  keywords: ['malformed', 'broken'],
  build: _buildMalformed,
);

List<AiChatEvent> _buildMalformed(String messageId) {
  const text = 'The structured part of this reply is broken.';
  return [
    scenarioStart(messageId),
    ...scenarioStream(messageId, text),
    // Wrong schemaVersion type, blocks not an array, nodes that are not
    // objects — all at once.
    scenarioUi(messageId, <String, dynamic>{
      'schemaVersion': '1',
      'blocks': 'not-an-array',
    }),
    scenarioEnd(messageId, text),
  ];
}

const _oversized = MockScenario(
  id: 'oversized',
  label: 'Oversized / over-deep payload',
  keywords: ['oversized', 'huge'],
  build: _buildOversized,
);

List<AiChatEvent> _buildOversized(String messageId) {
  const text = 'This reply exceeds every limit the protocol sets.';

  var deep = <String, dynamic>{'type': 'text', 'id': 'leaf', 'text': 'buried'};
  for (var i = 0; i < 30; i++) {
    deep = <String, dynamic>{
      'type': 'column',
      'id': 'deep_$i',
      'children': [deep],
    };
  }

  return [
    scenarioStart(messageId),
    ...scenarioStream(messageId, text),
    scenarioUi(
      messageId,
      scenarioPayload([
        {
          'type': 'text',
          'id': 'first',
          'text': 'Content within the limits still renders.',
        },
        deep,
        {
          'type': 'list',
          'id': 'big',
          'children': [
            for (var i = 0; i < 60; i++)
              {'type': 'list_item', 'id': 'i$i', 'title': 'Item $i'},
          ],
        },
        for (var i = 0; i < 30; i++)
          {'type': 'text', 'id': 'pad_$i', 'text': 'Padding block $i'},
      ]),
    ),
    scenarioEnd(messageId, text),
  ];
}

const _longConversation = MockScenario(
  id: 'long_conversation',
  label: 'Long conversation (performance)',
  keywords: ['performance', 'long'],
  build: _buildLongConversation,
);

List<AiChatEvent> _buildLongConversation(String messageId) => [
  scenarioStart(messageId),
  ...scenarioStream(
    messageId,
    'Here is a deliberately long reply so the streaming path can be watched '
    'under load. Each word arrives as its own text_delta event. None of them '
    'emit bloc state, so the conversation list is not rebuilt even once while '
    'this sentence is being written. Only the bubble you are reading right '
    'now is rebuilding, because it listens to the active stream controller '
    'directly rather than to the chat state.',
  ),
  scenarioUi(
    messageId,
    scenarioPayload([
      _serviceCard(
        id: 'svc_9',
        title: 'AC Maintenance',
        subtitle: 'Rendered after 60 deltas',
        price: 100,
      ),
    ]),
  ),
  scenarioEnd(
    messageId,
    'Here is a deliberately long reply so the streaming path can be watched '
    'under load. Each word arrives as its own text_delta event. None of them '
    'emit bloc state, so the conversation list is not rebuilt even once while '
    'this sentence is being written. Only the bubble you are reading right '
    'now is rebuilding, because it listens to the active stream controller '
    'directly rather than to the chat state.',
  ),
];

/// Every scenario, in the order the dev menu shows them.
const mockScenarios = <MockScenario>[
  // Prose and the primitives.
  _plainText,
  _textAndCard,
  _primitives,

  // The entity cards and suggestion set that predate the current Figma
  // component library, reworked to its card language.
  _serviceList,
  _appointment,
  _branches,
  _quickReply,

  // One per component the current library added, plus its state variants.
  ...componentScenarios,

  // Payload hostility. These stay last because they are the ones a developer
  // reaches for deliberately, not by keyword.
  _unknownNode,
  _unknownAction,
  _malformed,
  _oversized,
  _longConversation,
];

/// Builds a plain streamed reply: `message_start`, word-sized deltas, then an
/// authoritative `message_end`.
///
/// Exposed so the multimodal scenarios can produce the same shape without
/// duplicating the pacing helpers — the point of the mock is that every reply
/// travels the real event path, whatever prompted it.
List<AiChatEvent> mockSay(String messageId, String text) =>
    scenarioSay(messageId, text);

/// Picks a scenario from what the user typed, falling back to the card demo.
MockScenario scenarioFor(String message) {
  final lower = message.toLowerCase();
  for (final scenario in mockScenarios) {
    if (scenario.keywords.any(lower.contains)) return scenario;
  }
  return _textAndCard;
}
