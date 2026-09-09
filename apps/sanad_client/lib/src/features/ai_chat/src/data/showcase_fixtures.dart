/// The catalogue the showcase route renders — every semantic node type, as
/// raw wire JSON.
///
/// Raw JSON on purpose. Each entry goes through `AiChatConfig.validator` and
/// the real `AiUiSurface`, exactly as a payload from the agent would, so the
/// showcase can never drift from what the app actually renders. A fixture that
/// stops validating shows up as a diagnostic on screen rather than a widget
/// that only exists in the showcase.
///
/// It draws on `componentScenarios` for the components those already cover,
/// so there is one set of fixtures rather than two that disagree.
library;

import 'package:ai_ui_protocol/ai_ui_protocol.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/mock_scenarios.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/scenarios/scenario_support.dart';

/// One entry in the showcase.
final class ShowcaseFixture {
  /// Creates a fixture.
  const ShowcaseFixture({
    required this.title,
    required this.blocks,
    this.note,
    this.degrades = false,
  });

  /// Shown above the rendered blocks.
  final String title;

  /// One line on what the fixture is exercising — a state, an edge case.
  final String? note;

  /// The `blocks` array of a `ui` payload.
  final List<Map<String, dynamic>> blocks;

  /// Set when the payload is *supposed* to be refused in part — a rejected
  /// image URL, an unknown asset id, an unknown node type. The showcase test
  /// holds every other fixture to zero diagnostics, so this flag is what
  /// keeps that guard meaningful instead of title-matched.
  final bool degrades;

  /// The full payload, ready for the validator.
  Map<String, dynamic> get payload => <String, dynamic>{
    'schemaVersion': AiUiDocument.currentSchemaVersion,
    'blocks': blocks,
  };
}

/// A titled run of fixtures.
final class ShowcaseGroup {
  /// Creates a group.
  const ShowcaseGroup({required this.title, required this.fixtures});

  /// Section heading.
  final String title;

  /// The fixtures in display order.
  final List<ShowcaseFixture> fixtures;
}

/// Pulls the `ui` payload out of a scenario's scripted events.
///
/// Lets the showcase reuse the mock scenarios verbatim instead of restating
/// their payloads, so the two cannot disagree about what a component looks
/// like.
List<Map<String, dynamic>> _blocksOf(MockScenario scenario) {
  final ui = scenario.build('showcase').whereType<AiChatUiEvent>().lastOrNull;
  if (ui == null) return const [];

  final Object? blocks = ui.payload['blocks'];
  // A scenario whose payload is deliberately malformed still belongs in the
  // showcase — it renders as nothing, with its diagnostics beside it.
  if (blocks is! List) return const [];
  return blocks.whereType<Map<String, dynamic>>().toList();
}

/// Every semantic type, grouped the way the protocol groups them.
///
/// `document_card` appears under its own heading: it is a supported contract
/// that the current Figma set does not include, and the showcase is where that
/// distinction should be visible rather than buried in a doc.
List<ShowcaseGroup> showcaseGroups() => [
  ShowcaseGroup(
    title: 'Entity cards',
    fixtures: [
      ShowcaseFixture(
        title: 'service_card',
        note: 'Three services; the first is the selected one',
        blocks: _blocksOf(_scenario('service_list')),
      ),
      ShowcaseFixture(
        title: 'appointment_card',
        note: 'Confirmed, with an attached action row',
        blocks: _blocksOf(_scenario('appointment')),
      ),
      const ShowcaseFixture(
        title: 'appointment_card — no actions, no status',
        note: "Figma's plain ticket card",
        blocks: [
          {
            'type': 'appointment_card',
            'id': 'sc_apt_plain',
            'appointmentId': 'apt_plain',
            'title': 'AC Maintenance',
            'startsAt': '2026-09-02T06:00:00Z',
            'whereText': 'Downtown Branch',
            'fallbackText': 'AC Maintenance on 2 September',
          },
        ],
      ),
      ShowcaseFixture(
        title: 'branch_card',
        note: 'Open and closed, each with its opening hours',
        blocks: _blocksOf(_scenario('branches')),
      ),
      ShowcaseFixture(
        title: 'order_card',
        note: 'Delivered and active',
        blocks: _blocksOf(_scenario('order_tracking')),
      ),
      ShowcaseFixture(
        title: 'provider_card',
        blocks: _blocksOf(_scenario('assigned_provider')),
      ),
    ],
  ),
  ShowcaseGroup(
    title: 'Summaries',
    fixtures: [
      ShowcaseFixture(
        title: 'booking_summary',
        blocks: _blocksOf(_scenario('booking_summary')),
      ),
      ShowcaseFixture(
        title: 'request_summary',
        note: 'Value tiles, the agent’s recap, and a maps row',
        blocks: _blocksOf(_scenario('request_summary')),
      ),
      ShowcaseFixture(
        title: 'payment_receipt',
        note: 'Reference id marked LTR so RTL cannot reorder it',
        blocks: _blocksOf(_scenario('payment_receipt')),
      ),
      const ShowcaseFixture(
        title: 'payment_receipt — failed',
        note: 'The disc glyph follows the tone',
        blocks: [
          {
            'type': 'payment_receipt',
            'id': 'sc_receipt_failed',
            'title': 'Payment declined',
            'subtitle': 'Your bank refused the charge',
            'statusTone': 'error',
            'items': [
              {'label': 'Payment Method', 'value': 'Visa (•••• 4920)'},
            ],
            'total': {
              'label': 'Amount due',
              'amount': {'amount': 150, 'currency': 'AED'},
            },
            'fallbackText': 'Payment declined — 150 AED still due',
          },
        ],
      ),
    ],
  ),
  ShowcaseGroup(
    title: 'Interactive',
    fixtures: [
      ShowcaseFixture(
        title: 'quick_reply',
        note: 'Stacked pills; the first is accented',
        blocks: _blocksOf(_scenario('quick_reply')),
      ),
      ShowcaseFixture(
        title: 'time_slots',
        note: 'One pre-selected, one already taken',
        blocks: _blocksOf(_scenario('time_slots')),
      ),
      ShowcaseFixture(
        title: 'review_request',
        note: 'Typing then submitting posts the comment as a user turn',
        blocks: _blocksOf(_scenario('review_request')),
      ),
      ShowcaseFixture(
        title: 'location_picker',
        blocks: _blocksOf(_scenario('location_picker')),
      ),
    ],
  ),
  ShowcaseGroup(
    title: 'Prompts',
    fixtures: [
      ShowcaseFixture(
        title: 'reminder_card',
        blocks: _blocksOf(_scenario('reminder')),
      ),
      const ShowcaseFixture(
        title: 'reminder_card — overdue',
        note: 'The error tone tints the border and the disc',
        blocks: [
          {
            'type': 'reminder_card',
            'id': 'sc_reminder_error',
            'title': 'Missed appointment',
            'subtitle': 'AC Maintenance',
            'body': 'The technician could not get access. Shall I rebook?',
            'tone': 'error',
            'actions': [
              {
                'label': 'Rebook',
                'action': {'type': 'send_message', 'text': 'Rebook it'},
              },
            ],
            'fallbackText': 'The technician could not get access',
          },
        ],
      ),
      ShowcaseFixture(
        title: 'media_request',
        blocks: _blocksOf(_scenario('media_request')),
      ),
      ShowcaseFixture(
        title: 'permission_request — camera',
        note: 'No illustration; declining collapses the card',
        blocks: _blocksOf(_scenario('camera_permission')),
      ),
      ShowcaseFixture(
        title: 'permission_request — location',
        note: 'With the map preview',
        blocks: _blocksOf(_scenario('location_permission')),
      ),
      ShowcaseFixture(
        title: 'location_confirm',
        blocks: _blocksOf(_scenario('location_confirm')),
      ),
    ],
  ),
  const ShowcaseGroup(
    title: 'Supported, not in the current Figma set',
    fixtures: [
      ShowcaseFixture(
        title: 'document_card',
        note: 'Kept because the backend contract already publishes it',
        blocks: [
          {
            'type': 'document_card',
            'id': 'sc_doc',
            'documentId': 'doc_1',
            'title': 'Trade licence',
            'status': 'Expiring soon',
            'statusTone': 'warning',
            'action': {'type': 'open_document', 'documentId': 'doc_1'},
            'fallbackText': 'Trade licence — expiring soon',
          },
        ],
      ),
    ],
  ),
  const ShowcaseGroup(
    title: 'Images: url > assetId > fallback',
    fixtures: [
      ShowcaseFixture(
        title: 'url only',
        note: 'Dynamic, backend-owned media through the app cache',
        blocks: [
          {
            'type': 'service_card',
            'id': 'sc_img_url',
            'serviceId': 'svc_img_1',
            'title': 'AC Maintenance',
            'subtitle': 'The photo comes from the backend.',
            'price': {'amount': 100, 'currency': 'AED'},
            'image': {'url': 'https://picsum.photos/seed/ac/640/360'},
            'fallbackText': 'AC Maintenance — 100 AED',
          },
        ],
      ),
      ShowcaseFixture(
        title: 'assetId only',
        note: 'A client-published static illustration',
        blocks: [
          {
            'type': 'location_confirm',
            'id': 'sc_img_asset',
            'title': 'Confirm your location',
            'addressText': 'Dubai Marina',
            'image': {'assetId': 'ai_map_preview'},
            'confirmLabel': 'Confirm location',
            'changeLabel': 'Change location',
            'fallbackText': 'Is Dubai Marina the right place?',
          },
        ],
      ),
      ShowcaseFixture(
        title: 'both — the url wins',
        note: 'The asset is the render-time fallback, never an override',
        blocks: [
          {
            'type': 'provider_card',
            'id': 'sc_img_both',
            'providerId': 'prv_img',
            'name': 'Ahmed K.',
            'roleText': 'AC and plumbing specialist',
            'image': {
              'url': 'https://picsum.photos/seed/ahmed/160/160',
              'assetId': 'image_placeholder',
            },
            'fallbackText': 'Ahmed K., your assigned specialist',
          },
        ],
      ),
      ShowcaseFixture(
        title: 'empty url — the asset wins',
        note: 'A backend template with nothing dynamic for this row',
        blocks: [
          {
            'type': 'image',
            'id': 'sc_img_empty',
            'url': '',
            'assetId': 'service_tools',
            'alt': 'Service tools',
          },
        ],
      ),
      ShowcaseFixture(
        title: 'refused url — the asset wins',
        note: 'Not https, so the URL is dropped during validation',
        degrades: true,
        blocks: [
          {
            'type': 'image',
            'id': 'sc_img_refused',
            'url': 'http://cdn.example.com/insecure.jpg',
            'assetId': 'service_tools',
            'alt': 'Service tools',
          },
        ],
      ),
      ShowcaseFixture(
        title: 'unknown assetId, no url',
        note: 'No local path is reachable through the protocol — node dropped',
        degrades: true,
        blocks: [
          {
            'type': 'image',
            'id': 'sc_img_unknown',
            'assetId': 'assets/images/secret.png',
            'alt': 'Invented local file',
          },
          {
            'type': 'text',
            'id': 'sc_img_unknown_prose',
            'text': 'The rest of the reply still renders.',
          },
        ],
      ),
      ShowcaseFixture(
        title: 'neither',
        note: "Each node's own no-image state",
        blocks: [
          {
            'type': 'provider_card',
            'id': 'sc_img_none_p',
            'providerId': 'prv_none',
            'name': 'Ahmed K.',
            'roleText': 'No portrait available',
            'fallbackText': 'Ahmed K.',
          },
          {
            'type': 'location_confirm',
            'id': 'sc_img_none_l',
            'title': 'Confirm your location',
            'addressText': 'Dubai Marina',
            'confirmLabel': 'Confirm location',
            'fallbackText': 'Is Dubai Marina the right place?',
          },
        ],
      ),
    ],
  ),
  ShowcaseGroup(
    title: 'Together, and under pressure',
    fixtures: [
      ShowcaseFixture(
        title: 'Several components in one reply',
        blocks: _blocksOf(_scenario('mixed_components')),
      ),
      const ShowcaseFixture(
        title: 'Long content',
        note: 'Every string long enough to need truncating',
        blocks: [
          {
            'type': 'service_card',
            'id': 'sc_long',
            'serviceId': 'svc_long',
            'title': 'A service whose name is far longer than the card is wide',
            'subtitle':
                'A description long enough to run past the two lines the card '
                'gives it, so the ellipsis and the price row below it can be '
                'checked at the same time as the title.',
            'price': {'amount': 1234.56, 'currency': 'AED'},
            'badge': {'label': 'A rather long badge', 'tone': 'primary'},
            'actions': [
              {
                'label': 'A long action label',
                'action': {'type': 'send_message', 'text': 'Long'},
              },
            ],
            'fallbackText': 'A long service',
          },
          {
            'type': 'booking_summary',
            'id': 'sc_long_summary',
            'title': 'A summary heading long enough to be truncated on its own',
            'items': [
              {
                'label': 'A label that is itself unusually long',
                'value': 'And a value beside it that is also unusually long',
              },
            ],
            'fallbackText': 'A long summary',
          },
        ],
      ),
      const ShowcaseFixture(
        title: 'Degradation',
        note: 'An unknown type with fallbackText, and one without',
        degrades: true,
        blocks: [
          {
            'type': 'service_carousel_v2',
            'id': 'sc_unknown_fallback',
            'fallbackText':
                'A component this build does not know, rendered as its '
                'fallback text.',
          },
          {'type': 'holographic_map', 'id': 'sc_unknown_bare'},
          {
            'type': 'text',
            'id': 'sc_after_unknown',
            'text': 'The rest of the payload still renders.',
          },
        ],
      ),
    ],
  ),
];

/// Looks a scenario up by id.
///
/// Throws when the id is unknown, which is what should happen: a showcase that
/// silently rendered nothing for a component would be worse than one that
/// fails to build in debug.
MockScenario _scenario(String id) =>
    mockScenarios.firstWhere((scenario) => scenario.id == id);
