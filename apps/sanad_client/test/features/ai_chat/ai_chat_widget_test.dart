import 'package:ai_ui_protocol/ai_ui_protocol.dart';
import 'package:ai_ui_renderer/ai_ui_renderer.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_client/src/features/ai_chat/src/ai_chat_config.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/ai_chat_message.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/enums/ai_attachment_status.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/actions/ai_chat_action_handlers.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/bloc/active_stream_controller.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/widgets/ai_chat_bubble.dart';
import 'package:testing/testing.dart';

import 'support/attachment_fixtures.dart';

/// Widget-level behaviour of the chat surface: what an AI payload actually
/// looks like once it reaches a bubble, and what a tap on it reaches.
///
/// Every payload here goes through the **real** `AiChatConfig.validator` — the
/// same instance the app builds, with the same action allowlist and asset
/// allowlist — so a widget can only be reached the way a live payload would
/// reach it. Nothing constructs an `AiUiDocument` by hand.
///
/// Scope note: this file deliberately does not drive the bloc. `AiChatBloc`
/// creates its stream subscription inside whichever zone constructs it, and
/// `testWidgets` runs the body in a FakeAsync zone that is gone by the time
/// `tearDown` runs — mixing the two makes closes hang. Event-sequencing
/// behaviour (`message_end` authority, agent errors, recovery, the
/// no-state-per-token guarantee) is covered in `ai_chat_bloc_test.dart`, which
/// is plain `test()` and has no such constraint. What is left for here is
/// rendering and dispatch, and those need no bloc.
void main() {
  late List<AiUiAction> dispatched;
  late List<String> sentMessages;
  late AiUiEnvironment environment;

  final validator = AiChatConfig.validator(keepUnsupportedNodes: false);

  /// Runs [blocks] through the real validator, exactly as the bloc does on a
  /// `ui` event.
  AiUiParseResult parse(List<Map<String, dynamic>> blocks) =>
      validator.validate({'schemaVersion': 1, 'blocks': blocks});

  AiChatMessage assistant({
    String text = '',
    List<Map<String, dynamic>>? blocks,
    AiChatMessageStatus status = AiChatMessageStatus.complete,
    String id = 'msg_1',
  }) => AiChatMessage(
    id: id,
    role: AiChatRole.assistant,
    text: text,
    document: blocks == null ? null : parse(blocks).document,
    status: status,
  );

  setUp(() {
    dispatched = [];
    sentMessages = [];
    environment = AiUiEnvironment(
      registry: defaultRendererRegistry(),
      actions: AiActionRegistry([
        SendMessageHandler(sentMessages.add),
        for (final type in const [
          AiUiActionType.openService,
          AiUiActionType.openAppointment,
          AiUiActionType.openBranch,
          AiUiActionType.openDocument,
          // The capability actions the refreshed cards introduced. Recorded
          // rather than executed: what this file asserts is that the tap
          // arrives with the right payload, and what the app then does with it
          // is `ai_chat_capabilities_test.dart`.
          AiUiActionType.requestPermission,
          AiUiActionType.requestImageUpload,
          AiUiActionType.callPhone,
          AiUiActionType.openMap,
        ])
          _RecordingHandler(type, dispatched),
      ]),
    );
  });

  Future<ActiveStreamController> pumpBubbles(
    WidgetTester tester,
    List<AiChatMessage> messages, {
    ActiveStreamController? stream,
  }) async {
    // Only dispose what this helper created — a caller-supplied controller
    // registers its own teardown, and a ValueNotifier asserts on double
    // dispose.
    final controller = stream ?? ActiveStreamController();
    if (stream == null) addTearDown(controller.dispose);

    await pumpDsWidget(
      tester,
      AiUiHost(
        environment: environment,
        child: Material(
          // Scrollable because that is where a bubble lives — inside the
          // message list, with unbounded height. Without it a tall reply
          // overflows the test viewport and reports a layout error that says
          // nothing about the chat.
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final message in messages)
                  RepaintBoundary(
                    key: ValueKey(message.id),
                    child: AiChatBubble(
                      message: message,
                      activeStream: controller,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    return controller;
  }

  group('mixed text + structured UI', () {
    testWidgets('prose and a card render inside one assistant bubble', (
      tester,
    ) async {
      await pumpBubbles(tester, [
        assistant(
          text: 'Your appointment is confirmed.',
          blocks: [
            {
              'type': 'card',
              'id': 'c',
              'title': 'AC Maintenance',
              'children': [
                {'type': 'text', 'id': 't', 'text': 'Tomorrow at 10:00 AM'},
                {
                  'type': 'button',
                  'id': 'b',
                  'label': 'View appointment',
                  'size': 'small',
                  'action': {
                    'type': 'open_appointment',
                    'appointmentId': 'apt_1',
                  },
                },
              ],
            },
          ],
        ),
      ]);

      expect(find.byType(AiChatBubble), findsOneWidget);
      expect(find.text('Your appointment is confirmed.'), findsOneWidget);
      expect(find.text('AC Maintenance'), findsOneWidget);
      expect(find.text('Tomorrow at 10:00 AM'), findsOneWidget);
      expect(find.byType(AppButton), findsOneWidget);

      // Structured UI is part of the reply, not a separate surface bolted
      // underneath it.
      expect(
        find.descendant(
          of: find.byType(AiChatBubble),
          matching: find.byType(AiUiSurface),
        ),
        findsOneWidget,
      );
    });

    testWidgets('a semantic card renders client-formatted values', (
      tester,
    ) async {
      await pumpBubbles(tester, [
        assistant(
          text: 'I found a service.',
          blocks: [
            {
              'type': 'service_card',
              'id': 's',
              'serviceId': 'svc_1',
              'title': 'AC Maintenance',
              'price': {'amount': 100, 'currency': 'AED'},
            },
          ],
        ),
      ]);

      expect(find.text('AC Maintenance'), findsOneWidget);
      // The agent sent {amount, currency}; the client formatted the money.
      expect(find.textContaining('100'), findsOneWidget);
      expect(find.textContaining('AED'), findsOneWidget);
    });

    testWidgets('a bubble with only structured UI renders no empty text', (
      tester,
    ) async {
      await pumpBubbles(tester, [
        assistant(
          blocks: [
            {'type': 'text', 'id': 't', 'text': 'Only structured content'},
          ],
        ),
      ]);

      expect(find.text('Only structured content'), findsOneWidget);
      expect(find.text(''), findsNothing);
    });
  });

  group('the refreshed component set', () {
    testWidgets('several semantic cards render together in one reply', (
      tester,
    ) async {
      // The shape the agent actually sends for a status update: prose, then
      // the order, then who is coming, then what to do next. If these only
      // worked one card per reply the protocol would be useless.
      await pumpBubbles(tester, [
        assistant(
          text: 'Here is where your booking stands.',
          blocks: [
            {
              'type': 'order_card',
              'id': 'o',
              'orderId': 'ord_4471',
              'title': 'Order #4471 · Deep Cleaning',
              'statusText': 'On the way',
              'status': 'Active',
              'statusTone': 'info',
              'amount': {'amount': 240, 'currency': 'AED'},
            },
            {
              'type': 'provider_card',
              'id': 'p',
              'providerId': 'prv_9',
              'name': 'Ahmed Hassan',
              'roleText': 'Cleaning specialist',
              'ratingValue': 4.8,
              'actions': [
                {
                  'label': 'Call',
                  'action': {'type': 'call_phone', 'phone': '+971500000000'},
                },
              ],
            },
            {
              'type': 'reminder_card',
              'id': 'r',
              'title': 'Someone must be home',
              'body': 'The team needs access to the water supply.',
            },
          ],
        ),
      ]);

      expect(find.byType(AiChatBubble), findsOneWidget);
      expect(find.text('Here is where your booking stands.'), findsOneWidget);
      expect(find.text('Order #4471 · Deep Cleaning'), findsOneWidget);
      expect(find.text('On the way'), findsOneWidget);
      expect(find.text('Ahmed Hassan'), findsOneWidget);
      expect(find.text('Someone must be home'), findsOneWidget);
      // One surface, three cards - not three surfaces stacked.
      expect(find.byType(AiUiSurface), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a card action reaches an app handler with its payload', (
      tester,
    ) async {
      await pumpBubbles(tester, [
        assistant(
          blocks: [
            {
              'type': 'provider_card',
              'id': 'p',
              'providerId': 'prv_9',
              'name': 'Ahmed Hassan',
              'actions': [
                {
                  'label': 'Call',
                  'action': {'type': 'call_phone', 'phone': '+971500000000'},
                },
              ],
            },
          ],
        ),
      ]);

      await tester.ensureVisible(find.text('Call'));
      await tester.pump();
      await tester.tap(find.text('Call'));
      await tester.pump();

      expect(dispatched, hasLength(1));
      expect(dispatched.single.type, AiUiActionType.callPhone);
      expect(dispatched.single.params['phone'], '+971500000000');
    });

    testWidgets('an unimplemented card action drops its own button only', (
      tester,
    ) async {
      // `actions[]` degrades exactly like a sibling `button` does: the dead
      // control disappears, the card and its other action stay.
      await pumpBubbles(tester, [
        assistant(
          blocks: [
            {
              'type': 'order_card',
              'id': 'o',
              'orderId': 'ord_4471',
              'title': 'Deep Cleaning',
              'actions': [
                {
                  'label': 'Track on the web',
                  'action': {
                    'type': 'open_url',
                    'url': 'https://trysanad.us/orders/4471',
                  },
                },
                {
                  'label': 'Ask about it',
                  'action': {'type': 'send_message', 'text': 'Where is it?'},
                },
              ],
            },
          ],
        ),
      ]);

      expect(find.text('Deep Cleaning'), findsOneWidget);
      expect(find.text('Track on the web'), findsNothing);
      expect(find.text('Ask about it'), findsOneWidget);
    });

    testWidgets('a permission prompt asks the app, not the platform', (
      tester,
    ) async {
      await pumpBubbles(tester, [
        assistant(
          blocks: [
            {
              'type': 'permission_request',
              'id': 'pr',
              'permission': 'camera',
              'title': 'Allow camera access',
              'body': 'So you can photograph the problem.',
              'allowLabel': 'Allow',
              'denyLabel': 'Not now',
            },
          ],
        ),
      ]);

      await tester.ensureVisible(find.text('Allow'));
      await tester.pump();
      await tester.tap(find.text('Allow'));
      await tester.pump();

      expect(dispatched, hasLength(1));
      expect(dispatched.single.type, AiUiActionType.requestPermission);
      expect(dispatched.single.params['permission'], 'camera');
    });

    testWidgets('an interactive card sends the user value, never code', (
      tester,
    ) async {
      // The trust model that lets a card own an input: the agent supplies a
      // template, the widget substitutes the user's choice, and what travels
      // back is a sentence indistinguishable from typing.
      await pumpBubbles(tester, [
        assistant(
          blocks: [
            {
              'type': 'time_slots',
              'id': 'ts',
              'dateLabel': 'Tomorrow',
              'confirmLabel': 'Confirm',
              'confirmTemplate': 'Book me for {slot}',
              'slots': [
                {'id': 'am', 'label': '10:00 AM'},
                {'id': 'pm', 'label': '2:00 PM'},
              ],
            },
          ],
        ),
      ]);

      await tester.ensureVisible(find.text('2:00 PM'));
      await tester.pump();
      await tester.tap(find.text('2:00 PM'));
      await tester.pump();
      await tester.ensureVisible(find.text('Confirm'));
      await tester.pump();
      await tester.tap(find.text('Confirm'));
      await tester.pump();

      expect(sentMessages, ['Book me for 2:00 PM']);
    });
  });

  group('streaming', () {
    testWidgets('a streaming bubble follows the controller', (tester) async {
      final controller = ActiveStreamController()..start('msg_2');
      addTearDown(controller.dispose);

      await pumpBubbles(tester, [
        assistant(text: 'first reply'),
        assistant(status: AiChatMessageStatus.streaming, id: 'msg_2'),
      ], stream: controller);

      controller.append('I found ');
      await tester.pump();
      expect(find.text('I found '), findsOneWidget);

      controller.append('3 services');
      await tester.pump();
      expect(find.text('I found 3 services'), findsOneWidget);

      // The completed sibling is untouched throughout: the streaming bubble
      // listens to the controller directly, so nothing above it rebuilds.
      expect(find.text('first reply'), findsOneWidget);
      expect(find.byType(AiChatBubble), findsNWidgets(2));
    });

    testWidgets('a streaming bubble with no text yet shows an indicator', (
      tester,
    ) async {
      final controller = ActiveStreamController()..start('msg_1');
      addTearDown(controller.dispose);

      await pumpBubbles(tester, [
        assistant(status: AiChatMessageStatus.streaming),
      ], stream: controller);

      expect(find.byType(AppLoadingIndicator), findsOneWidget);
    });

    testWidgets('a completed bubble ignores the controller entirely', (
      tester,
    ) async {
      final controller = ActiveStreamController()..start('other');
      addTearDown(controller.dispose);

      await pumpBubbles(tester, [
        assistant(text: 'final text'),
      ], stream: controller);

      controller.append('leaked?');
      await tester.pump();

      expect(find.text('final text'), findsOneWidget);
      expect(find.textContaining('leaked?'), findsNothing);
    });
  });

  group('actions', () {
    testWidgets('a quick reply posts its text back as a user turn', (
      tester,
    ) async {
      await pumpBubbles(tester, [
        assistant(
          text: 'Would you like to book?',
          blocks: [
            {
              'type': 'quick_reply',
              'id': 'q',
              'options': [
                {
                  'label': 'Yes, book it',
                  'action': {'type': 'send_message', 'text': 'Yes, book it'},
                },
                {
                  'label': 'Not now',
                  'action': {'type': 'send_message', 'text': 'Not now'},
                },
              ],
            },
          ],
        ),
      ]);

      // Figma stacks suggested replies as full-width pills rather than
      // flowing them as chips — a suggested reply is a sentence, not a tag.
      expect(find.byType(AppChip), findsNothing);
      expect(find.text('Yes, book it'), findsOneWidget);
      expect(find.text('Not now'), findsOneWidget);

      await tester.tap(find.text('Yes, book it'));
      await tester.pump();

      // The agent cannot inject a message; it asks the app to send one.
      expect(sentMessages, ['Yes, book it']);
    });

    testWidgets('a button reaches an app handler with its typed payload', (
      tester,
    ) async {
      await pumpBubbles(tester, [
        assistant(
          blocks: [
            {
              'type': 'button',
              'id': 'b',
              'label': 'View service',
              'size': 'small',
              'action': {'type': 'open_service', 'serviceId': 'svc_9'},
            },
          ],
        ),
      ]);

      await tester.tap(find.byType(AppButton));
      await tester.pump();

      expect(dispatched, hasLength(1));
      expect(dispatched.single.type, AiUiActionType.openService);
      expect(dispatched.single.serviceId, 'svc_9');
    });

    testWidgets('a whole-card tap dispatches once, not once per child', (
      tester,
    ) async {
      await pumpBubbles(tester, [
        assistant(
          blocks: [
            {
              'type': 'card',
              'id': 'c',
              'title': 'AC Maintenance',
              'action': {'type': 'open_service', 'serviceId': 'svc_3'},
              'children': [
                {'type': 'text', 'id': 't', 'text': 'From 100 AED'},
              ],
            },
          ],
        ),
      ]);

      await tester.tap(find.byType(InkWell));
      await tester.pump();

      expect(dispatched, hasLength(1));
      expect(dispatched.single.serviceId, 'svc_3');
    });

    testWidgets('a semantic card tap carries its entity id', (tester) async {
      await pumpBubbles(tester, [
        assistant(
          blocks: [
            {
              'type': 'branch_card',
              'id': 'b',
              'branchId': 'br_7',
              'name': 'Downtown',
              'distanceMeters': 450,
              'action': {'type': 'open_branch', 'branchId': 'br_7'},
            },
          ],
        ),
      ]);

      expect(find.text('Distance: 450 m'), findsOneWidget);
      await tester.tap(find.text('Downtown'));
      await tester.pump();

      expect(dispatched.single.type, AiUiActionType.openBranch);
      expect(dispatched.single.branchId, 'br_7');
    });
  });

  group('degradation', () {
    testWidgets('an unknown node falls back to its text', (tester) async {
      final result = parse([
        {
          'type': 'service_carousel_v2',
          'id': 'x',
          'fallbackText': 'AC Maintenance, Deep Cleaning',
        },
      ]);

      await pumpBubbles(tester, [
        assistant(
          text: 'Here are your services.',
          blocks: [
            {
              'type': 'service_carousel_v2',
              'id': 'x',
              'fallbackText': 'AC Maintenance, Deep Cleaning',
            },
          ],
        ),
      ]);

      expect(find.text('AC Maintenance, Deep Cleaning'), findsOneWidget);
      expect(find.text('Here are your services.'), findsOneWidget);
      expect(
        result.diagnostics.map((d) => d.code),
        contains(AiUiDiagnosticCode.unknownNodeType),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('an unknown node with no fallback is invisible', (
      tester,
    ) async {
      await pumpBubbles(tester, [
        assistant(
          text: 'Some of this reply is too new for your app.',
          blocks: [
            {'type': 'holographic_map', 'id': 'x'},
            {'type': 'text', 'id': 't', 'text': 'The rest still renders.'},
          ],
        ),
      ]);

      expect(find.text('The rest still renders.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('an unsupported action drops only its own control', (
      tester,
    ) async {
      await pumpBubbles(tester, [
        assistant(
          blocks: [
            {
              'type': 'button',
              'id': 'bad',
              'label': 'Delete my account',
              'action': {'type': 'delete_account'},
            },
            {'type': 'text', 'id': 't', 'text': 'The rest still renders.'},
          ],
        ),
      ]);

      expect(find.text('Delete my account'), findsNothing);
      expect(find.byType(AppButton), findsNothing);
      expect(find.text('The rest still renders.'), findsOneWidget);
      expect(dispatched, isEmpty);
      expect(tester.takeException(), isNull);
    });

    testWidgets('an action this app does not implement is dropped', (
      tester,
    ) async {
      // `open_url` is a real protocol action, deliberately absent from
      // AiChatConfig.supportedActions. The validator drops the whole button.
      await pumpBubbles(tester, [
        assistant(
          blocks: [
            {
              'type': 'button',
              'id': 'b',
              'label': 'Open offer',
              'action': {
                'type': 'open_url',
                'url': 'https://cdn.trysanad.us/offer',
              },
            },
            {'type': 'text', 'id': 't', 'text': 'Prose survives.'},
          ],
        ),
      ]);

      expect(find.text('Open offer'), findsNothing);
      expect(find.text('Prose survives.'), findsOneWidget);
    });

    testWidgets('a malformed payload leaves the prose alone', (tester) async {
      final rejected = validator.validate({
        'schemaVersion': '1',
        'blocks': 'not-an-array',
      });
      expect(rejected.hasRenderableUi, isFalse);

      await pumpBubbles(tester, [
        AiChatMessage(
          id: 'msg_1',
          role: AiChatRole.assistant,
          text: 'The structured part is broken.',
          document: rejected.document,
        ),
      ]);

      expect(find.text('The structured part is broken.'), findsOneWidget);
      expect(find.byType(AiUiSurface), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('an oversized payload is capped and still renders', (
      tester,
    ) async {
      var deep = <String, dynamic>{
        'type': 'text',
        'id': 'leaf',
        'text': 'buried',
      };
      for (var i = 0; i < 30; i++) {
        deep = <String, dynamic>{
          'type': 'column',
          'id': 'd$i',
          'children': [deep],
        };
      }

      await pumpBubbles(tester, [
        assistant(
          blocks: [
            {'type': 'text', 'id': 'keep', 'text': 'Within the limits.'},
            deep,
            for (var i = 0; i < 30; i++)
              {'type': 'text', 'id': 'pad$i', 'text': 'Padding $i'},
          ],
        ),
      ]);

      expect(find.text('Within the limits.'), findsOneWidget);
      expect(find.text('buried'), findsNothing);
      // Truncated at the block cap rather than dropped wholesale.
      expect(find.text('Padding 0'), findsOneWidget);
      expect(find.text('Padding 29'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a dynamic image renders through the app image cache', (
      tester,
    ) async {
      // The app's real config admits any https image host, and the URL
      // reaches `AppNetworkImage` — the same cached-network-image widget the
      // rest of the app uses, not a second image stack for the AI surface.
      final result = parse([
        {
          'type': 'service_card',
          'id': 's',
          'serviceId': 'svc_1',
          'title': 'AC Maintenance',
          'image': {
            'url': 'https://cdn.trysanad.us/services/ac.jpg',
            'assetId': 'service_tools',
          },
        },
      ]);

      await pumpBubbles(tester, [
        AiChatMessage(
          id: 'msg_1',
          role: AiChatRole.assistant,
          document: result.document,
        ),
      ]);

      expect(result.diagnostics, isEmpty);
      expect(find.byType(AppNetworkImage), findsOneWidget);
      expect(
        tester.widget<AppNetworkImage>(find.byType(AppNetworkImage)).url,
        'https://cdn.trysanad.us/services/ac.jpg',
      );
    });

    testWidgets('an image url the policy refuses issues no request', (
      tester,
    ) async {
      final result = parse([
        {
          // Not https. Refused during validation, so no widget and no
          // request — the prose is untouched.
          'type': 'image',
          'id': 'i',
          'url': 'http://cdn.trysanad.us/services/ac.jpg',
          'alt': 'AC unit',
        },
        {'type': 'text', 'id': 't', 'text': 'Prose survives.'},
      ]);

      await pumpBubbles(tester, [
        AiChatMessage(
          id: 'msg_1',
          role: AiChatRole.assistant,
          document: result.document,
        ),
      ]);

      expect(find.byType(AppNetworkImage), findsNothing);
      expect(find.text('Prose survives.'), findsOneWidget);
      expect(
        result.diagnostics.map((d) => d.code),
        contains(AiUiDiagnosticCode.invalidProperty),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('markdown prose', () {
    // The streaming endpoint emits no `ui` event at all, so prose is the only
    // channel — and the live agent's prose is heavily Markdown. Rendering it
    // literally would show the reader raw asterisks.
    testWidgets('bold markup renders formatted, not literally', (tester) async {
      await pumpBubbles(tester, [
        assistant(text: 'Pick **Car Insurance** to continue.'),
      ]);

      expect(find.textContaining('**'), findsNothing);
      expect(
        find.textContaining('Car Insurance', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('a numbered list renders as rows, not one literal blob', (
      tester,
    ) async {
      await pumpBubbles(tester, [
        assistant(text: 'Options:\n\n1. Car cover\n2. Home cover'),
      ]);

      const raw = 'Options:\n\n1. Car cover\n2. Home cover';
      expect(find.text(raw), findsNothing);
      expect(
        find.textContaining('Car cover', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining('Home cover', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('plain prose stays on the plain Text path', (tester) async {
      await pumpBubbles(tester, [assistant(text: 'Just plain prose.')]);

      // No markup means `AiUiMarkdown.build` returns null and the bubble keeps
      // its own `Text`, preserving overflow behaviour.
      expect(find.text('Just plain prose.'), findsOneWidget);
    });

    testWidgets('a user message is never parsed as markdown', (tester) async {
      await pumpBubbles(tester, [
        const AiChatMessage.user(id: 'u1', text: 'why **this** syntax?'),
      ]);

      // The person typed those asterisks. Rendering them as bold would put
      // words in their mouth.
      expect(find.text('why **this** syntax?'), findsOneWidget);
    });

    testWidgets('markdown renders while the message is still streaming', (
      tester,
    ) async {
      final controller = ActiveStreamController()..start('msg_1');
      addTearDown(controller.dispose);

      await pumpBubbles(tester, [
        assistant(status: AiChatMessageStatus.streaming),
      ], stream: controller);

      controller.append('Pick **Car Insurance**');
      await tester.pump();

      expect(find.textContaining('**'), findsNothing);
      expect(
        find.textContaining('Car Insurance', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('a half-arrived markdown token degrades without throwing', (
      tester,
    ) async {
      final controller = ActiveStreamController()..start('msg_1');
      addTearDown(controller.dispose);

      await pumpBubbles(tester, [
        assistant(status: AiChatMessageStatus.streaming),
      ], stream: controller);

      // Every prefix of a bolded run arrives at some point mid-stream; none of
      // them may throw.
      for (final delta in ['Pick ', '*', '*', 'Car', '*', '*', ' now']) {
        controller.append(delta);
        await tester.pump();
        expect(tester.takeException(), isNull);
      }

      expect(
        find.textContaining('Car', findRichText: true),
        findsOneWidget,
      );
    });
  });

  group('conversation shape', () {
    testWidgets('user and assistant bubbles sit on opposite sides', (
      tester,
    ) async {
      await pumpBubbles(tester, [
        const AiChatMessage.user(id: 'u1', text: 'find me a service'),
        assistant(text: 'I found 3 services'),
      ]);

      expect(find.byType(AiChatBubble), findsNWidgets(2));

      final user = tester.getCenter(find.text('find me a service'));
      final reply = tester.getCenter(find.text('I found 3 services'));
      // The user turn is aligned to the end, the reply to the start.
      expect(user.dx, greaterThan(reply.dx));
    });
  });

  group('a user turn carries images and documents, never audio', () {
    // AI Chat retired recorded audio, so no message can hold a voice note and
    // no bubble can draw one. What a turn with attachments renders is tiles,
    // and these assertions are what stops an audio row reappearing under one.
    testWidgets('each attachment renders as a read-only tile', (
      tester,
    ) async {
      await pumpBubbles(tester, [
        AiChatMessage.user(
          id: 'u1',
          text: 'what do these say?',
          // Delivered, so the tiles are at rest: no upload spinner and
          // nothing left to remove.
          status: AiChatMessageStatus.complete,
          attachments: [
            imageFixture(status: AiAttachmentStatus.ready),
            documentFixture(status: AiAttachmentStatus.ready),
          ],
        ),
      ]);

      expect(find.text('what do these say?'), findsOneWidget);
      // The document tile names its extension.
      expect(find.text('PDF'), findsOneWidget);
      // Read-only really means read-only: a sent turn is not editable, so the
      // remove control is absent rather than present and inert (A-21).
      expect(find.byIcon(Icons.close_rounded), findsNothing);
    });

    testWidgets('no playback or waveform affordance exists in a bubble', (
      tester,
    ) async {
      await pumpBubbles(tester, [
        AiChatMessage.user(
          id: 'u1',
          text: 'have a look',
          attachments: [imageFixture(status: AiAttachmentStatus.ready)],
        ),
      ]);

      // The controls a voice note used to draw. None of them has a widget
      // left to come from.
      expect(find.byIcon(Icons.play_arrow_rounded), findsNothing);
      expect(find.byIcon(Icons.pause_rounded), findsNothing);
      expect(find.byIcon(Icons.graphic_eq_rounded), findsNothing);
    });
  });
}

class _RecordingHandler extends AiActionHandler {
  const _RecordingHandler(this.type, this.calls);

  @override
  final AiUiActionType type;

  final List<AiUiAction> calls;

  @override
  void handle(BuildContext context, AiUiAction action) => calls.add(action);
}
