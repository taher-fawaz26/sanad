import 'package:ai_ui_protocol/ai_ui_protocol.dart';
import 'package:core/core.dart';

/// A scripted assistant turn.
///
/// Scenarios build *wire-shaped* events — the same envelope a WebSocket would
/// deliver — so replacing this source with a real one changes nothing above it.
/// Several are deliberately broken: proving the chat survives a hostile payload
/// matters more than proving it renders a nice card.
final class MockScenario {
  /// Creates a scenario.
  const MockScenario({
    required this.id,
    required this.label,
    required this.build,
    this.keywords = const [],
  });

  /// Stable identifier, used by the dev scenario picker.
  final String id;

  /// Human-readable name shown in the picker.
  final String label;

  /// Keywords that select this scenario from the user's message, so the
  /// prototype feels conversational rather than menu-driven.
  final List<String> keywords;

  /// Produces the scripted events for one assistant turn.
  final List<AiChatEvent> Function(String messageId) build;
}

Map<String, dynamic> _payload(List<Map<String, dynamic>> blocks) =>
    <String, dynamic>{'schemaVersion': 1, 'blocks': blocks};

AiChatEvent _start(String messageId) => AiChatMessageStartEvent(
  eventId: 'evt_${generateUuidV4()}',
  messageId: messageId,
);

AiChatEvent _delta(String messageId, String delta) => AiChatTextDeltaEvent(
  eventId: 'evt_${generateUuidV4()}',
  messageId: messageId,
  delta: delta,
);

AiChatEvent _end(String messageId, String text) => AiChatMessageEndEvent(
  eventId: 'evt_${generateUuidV4()}',
  messageId: messageId,
  text: text,
);

AiChatEvent _ui(String messageId, Map<String, dynamic> payload) =>
    AiChatUiEvent(
      eventId: 'evt_${generateUuidV4()}',
      messageId: messageId,
      payload: payload,
    );

/// Splits [text] into word-sized deltas so streaming looks like streaming.
List<AiChatEvent> _stream(String messageId, String text) {
  final words = text.split(' ');
  return [
    for (var i = 0; i < words.length; i++)
      _delta(messageId, i == 0 ? words[i] : ' ${words[i]}'),
  ];
}

List<AiChatEvent> _say(String messageId, String text) => [
  _start(messageId),
  ..._stream(messageId, text),
  _end(messageId, text),
];

Map<String, dynamic> _serviceCard({
  required String id,
  required String title,
  required String subtitle,
  required int price,
  Map<String, dynamic>? badge,
}) => <String, dynamic>{
  'type': 'service_card',
  'id': 'svc_$id',
  'serviceId': id,
  'title': title,
  'subtitle': subtitle,
  'price': {'amount': price, 'currency': 'AED'},
  if (badge != null) 'badge': badge,
  'action': {'type': 'open_service', 'serviceId': id},
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

List<AiChatEvent> _buildPlainText(String messageId) => _say(
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
    _start(messageId),
    ..._stream(messageId, text),
    _ui(
      messageId,
      _payload([
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
    _end(messageId, text),
  ];
}

const _serviceList = MockScenario(
  id: 'service_list',
  label: 'Semantic service cards',
  keywords: ['service', 'services', 'ac', 'clean'],
  build: _buildServiceList,
);

List<AiChatEvent> _buildServiceList(String messageId) {
  const text = 'I found 3 services near you.';
  return [
    _start(messageId),
    ..._stream(messageId, text),
    _ui(
      messageId,
      _payload([
        _serviceCard(
          id: 'svc_1',
          title: 'AC Maintenance',
          subtitle: 'Same-day service',
          price: 100,
          badge: {'label': 'Popular', 'tone': 'info'},
        ),
        _serviceCard(
          id: 'svc_2',
          title: 'Deep Cleaning',
          subtitle: '3 hours, 2 cleaners',
          price: 250,
        ),
        _serviceCard(
          id: 'svc_3',
          title: 'Plumbing Repair',
          subtitle: 'Emergency callout',
          price: 180,
        ),
      ]),
    ),
    _end(messageId, text),
  ];
}

const _appointment = MockScenario(
  id: 'appointment',
  label: 'Appointment card + actions',
  keywords: ['appointment', 'booking', 'reschedule'],
  build: _buildAppointment,
);

List<AiChatEvent> _buildAppointment(String messageId) {
  const text = 'Here is your next appointment.';
  return [
    _start(messageId),
    ..._stream(messageId, text),
    _ui(
      messageId,
      _payload([
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
          'fallbackText': 'AC Maintenance, tomorrow at 10:00 AM',
        },
        {
          'type': 'row',
          'id': 'actions',
          'gap': 'sm',
          'children': [
            {
              'type': 'button',
              'id': 'b1',
              'label': 'Reschedule',
              'variant': 'outline',
              'size': 'small',
              'action': {
                'type': 'open_appointment',
                'appointmentId': 'apt_123',
              },
            },
            {
              'type': 'button',
              'id': 'b2',
              'label': 'Cancel',
              'variant': 'outline',
              'intent': 'destructive',
              'size': 'small',
              'action': {
                'type': 'send_message',
                'text': 'Cancel my appointment',
              },
            },
          ],
        },
      ]),
    ),
    _end(messageId, text),
  ];
}

const _branches = MockScenario(
  id: 'branches',
  label: 'Branch list with badges',
  keywords: ['branch', 'branches', 'near', 'location'],
  build: _buildBranches,
);

List<AiChatEvent> _buildBranches(String messageId) {
  const text = 'Here are your nearest branches.';
  return [
    _start(messageId),
    ..._stream(messageId, text),
    _ui(
      messageId,
      _payload([
        {
          'type': 'branch_card',
          'id': 'br1',
          'branchId': 'br_1',
          'name': 'Downtown',
          'addressText': 'Sheikh Zayed Road',
          'distanceMeters': 450,
          'status': 'Open',
          'statusTone': 'success',
          'action': {'type': 'open_branch', 'branchId': 'br_1'},
          'fallbackText': 'Downtown — 450 m — Open',
        },
        {
          'type': 'branch_card',
          'id': 'br2',
          'branchId': 'br_2',
          'name': 'Marina',
          'addressText': 'Dubai Marina Walk',
          'distanceMeters': 4800,
          'status': 'Closed',
          'statusTone': 'error',
          'action': {'type': 'open_branch', 'branchId': 'br_2'},
          'fallbackText': 'Marina — 4.8 km — Closed',
        },
      ]),
    ),
    _end(messageId, text),
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
    _start(messageId),
    ..._stream(messageId, text),
    _ui(
      messageId,
      _payload([
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
              'badge': {'label': 'Done', 'tone': 'success'},
              'trailingText': 'AED 120',
            },
            {
              'type': 'list_item',
              'id': 'li2',
              'title': 'Order #1043',
              'subtitle': 'In progress',
              'badge': {'label': 'Active', 'tone': 'info'},
              'trailingText': 'AED 90',
            },
          ],
        },
      ]),
    ),
    _end(messageId, text),
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
    _start(messageId),
    ..._stream(messageId, text),
    _ui(
      messageId,
      _payload([
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
    _end(messageId, text),
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
    _start(messageId),
    ..._stream(messageId, text),
    _ui(
      messageId,
      _payload([
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
    _end(messageId, text),
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
    _start(messageId),
    ..._stream(messageId, text),
    _ui(
      messageId,
      _payload([
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
        // schemaVersion 1 is assetId-only, so a remote image URL is refused
        // outright — the app never issues the request.
        {
          'type': 'image',
          'id': 'bad3',
          'url': 'https://tracker.example/pixel.gif',
          'alt': 'tracking pixel',
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
    _end(messageId, text),
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
    _start(messageId),
    ..._stream(messageId, text),
    // Wrong schemaVersion type, blocks not an array, nodes that are not
    // objects — all at once.
    _ui(messageId, <String, dynamic>{
      'schemaVersion': '1',
      'blocks': 'not-an-array',
    }),
    _end(messageId, text),
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
    _start(messageId),
    ..._stream(messageId, text),
    _ui(
      messageId,
      _payload([
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
    _end(messageId, text),
  ];
}

const _longConversation = MockScenario(
  id: 'long_conversation',
  label: 'Long conversation (performance)',
  keywords: ['performance', 'long'],
  build: _buildLongConversation,
);

List<AiChatEvent> _buildLongConversation(String messageId) => [
  _start(messageId),
  ..._stream(
    messageId,
    'Here is a deliberately long reply so the streaming path can be watched '
    'under load. Each word arrives as its own text_delta event. None of them '
    'emit bloc state, so the conversation list is not rebuilt even once while '
    'this sentence is being written. Only the bubble you are reading right '
    'now is rebuilding, because it listens to the active stream controller '
    'directly rather than to the chat state.',
  ),
  _ui(
    messageId,
    _payload([
      _serviceCard(
        id: 'svc_9',
        title: 'AC Maintenance',
        subtitle: 'Rendered after 60 deltas',
        price: 100,
      ),
    ]),
  ),
  _end(
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
  _plainText,
  _textAndCard,
  _serviceList,
  _appointment,
  _branches,
  _primitives,
  _quickReply,
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
    _say(messageId, text);

/// Picks a scenario from what the user typed, falling back to the card demo.
MockScenario scenarioFor(String message) {
  final lower = message.toLowerCase();
  for (final scenario in mockScenarios) {
    if (scenario.keywords.any(lower.contains)) return scenario;
  }
  return _textAndCard;
}
