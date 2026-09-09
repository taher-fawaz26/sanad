import 'package:ai_ui_protocol/ai_ui_protocol.dart';
import 'package:ai_ui_renderer/ai_ui_renderer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/renderer_test_support.dart';

/// What the interactive and prompt cards send *back*.
///
/// The sibling suites (`semantic/interactive_test.dart`,
/// `semantic/prompts_test.dart`) pin the fallback: with no sink, a card posts
/// the agent's sentence as a `send_message` exactly as it always did. This one
/// pins the other half — with a sink present, the same tap also produces a
/// typed result naming the node, the choice and the message that asked.
///
/// Both halves matter. Losing the first is a silent regression for every host
/// that has not adopted results; losing the second is the feature.
void main() {
  Map<String, dynamic> timeSlots() => {
    'type': 'time_slots',
    'id': 'slots_1',
    'slots': [
      {'id': 's_0900', 'label': '9:00 AM'},
      {'id': 's_1030', 'label': '10:30 AM'},
    ],
    'confirmLabel': 'Confirm Time',
    'confirmTemplate': 'Book me the {slot} slot',
  };

  Map<String, dynamic> reviewRequest() => {
    'type': 'review_request',
    'id': 'review_1',
    'serviceName': 'AC Maintenance',
    'submitLabel': 'Submit',
    'submitTemplate': 'My review: {comment}',
  };

  Map<String, dynamic> locationPicker() => {
    'type': 'location_picker',
    'id': 'loc_1',
    'title': 'Where should I look?',
    'searchPlaceholder': 'Search',
    'useCurrentLabel': 'Use current location',
    'savedLabel': 'Saved',
    'savedLocations': [
      {'id': 'home', 'name': 'Home', 'addressText': 'Marina Tower 3'},
    ],
    'confirmLabel': 'Confirm',
    'confirmTemplate': 'Use this location: {location}',
  };

  Map<String, dynamic> permissionRequest() => {
    'type': 'permission_request',
    'id': 'perm_1',
    'permission': 'camera',
    'title': 'Camera access',
    'allowLabel': 'Allow',
    'denyLabel': 'Not now',
  };

  Map<String, dynamic> mediaRequest() => {
    'type': 'media_request',
    'id': 'media_1',
    'title': 'Add a photo',
    'options': [
      {'label': 'Take a photo', 'source': 'camera'},
    ],
    'cancelLabel': 'Cancel',
  };

  Map<String, dynamic> locationConfirm() => {
    'type': 'location_confirm',
    'id': 'confirm_1',
    'title': 'Is this right?',
    'addressText': 'Marina Tower 3, Dubai',
    'confirmLabel': 'Confirm',
    'changeLabel': 'Change',
  };

  Map<String, dynamic> quickReply() => {
    'type': 'quick_reply',
    'id': 'qr_1',
    'options': [
      {
        'label': 'Yes, book it',
        'action': {'type': 'send_message', 'text': 'Yes, book it'},
      },
      {
        'label': 'Show me the service',
        'action': {'type': 'open_service', 'serviceId': 'svc_1'},
      },
    ],
  };

  RendererHarness recording() => RendererHarness(recordInteractions: true);

  group('time_slots', () {
    testWidgets('confirming names the slot by id and by label', (tester) async {
      final harness = await pumpNodes(
        tester,
        [timeSlots()],
        harness: recording(),
        messageId: 'msg_7',
      );

      await tapText(tester, '10:30 AM');
      await tapText(tester, 'Confirm Time');

      final result = harness.submissions.single;
      expect(result.kind, AiUiInteractionKind.slotSelected);
      expect(result.nodeId, 'slots_1');
      expect(result.nodeType, AiUiNodeType.timeSlots);
      expect(result.messageId, 'msg_7');
      expect(result.status, AiUiInteractionStatus.submitted);
      expect(
        result.value,
        const AiUiSelectionValue(id: 's_1030', label: '10:30 AM'),
      );
    });

    testWidgets('the sentence still travels alongside the result', (
      tester,
    ) async {
      final harness = await pumpNodes(
        tester,
        [timeSlots()],
        harness: recording(),
      );

      await tapText(tester, '9:00 AM');
      await tapText(tester, 'Confirm Time');

      expect(harness.submissions.single.text, 'Book me the 9:00 AM slot');
    });

    testWidgets('a second confirm sends nothing', (tester) async {
      final harness = await pumpNodes(
        tester,
        [timeSlots()],
        harness: recording(),
      );

      await tapText(tester, '9:00 AM');
      await tapText(tester, 'Confirm Time');
      await tapText(tester, 'Confirm Time');

      expect(harness.submissions, hasLength(1));
      expect(harness.stateOf('slots_1'), AiUiNodeInteractionState.submitted);
    });

    testWidgets('a failed send leaves the card answerable', (tester) async {
      final harness = await pumpNodes(
        tester,
        [timeSlots()],
        harness: recording(),
      );
      harness.interactions!.failNext = true;

      await tapText(tester, '9:00 AM');
      await tapText(tester, 'Confirm Time');
      expect(harness.stateOf('slots_1'), AiUiNodeInteractionState.failed);

      await tapText(tester, 'Confirm Time');

      expect(harness.submissions, hasLength(2));
    });

    testWidgets('the slot grid stops responding once answered', (tester) async {
      final harness = await pumpNodes(
        tester,
        [timeSlots()],
        harness: recording(),
      );

      await tapText(tester, '9:00 AM');
      await tapText(tester, 'Confirm Time');
      await tapText(tester, '10:30 AM');

      // The card is a record of what was chosen, not a control any more.
      expect(harness.submissions, hasLength(1));
    });
  });

  group('review_request', () {
    testWidgets('submits the typed comment as a typed value', (tester) async {
      final harness = await pumpNodes(
        tester,
        [reviewRequest()],
        harness: recording(),
      );

      await tester.enterText(find.byType(TextField), '  This was very good  ');
      await tapText(tester, 'Submit');

      final result = harness.submissions.single;
      expect(result.kind, AiUiInteractionKind.reviewSubmitted);
      expect(result.value, const AiUiTextValue('This was very good'));
      expect(result.text, 'My review: This was very good');
    });

    testWidgets('an empty comment is a legitimate answer', (tester) async {
      final harness = await pumpNodes(
        tester,
        [reviewRequest()],
        harness: recording(),
      );

      await tapText(tester, 'Submit');

      expect(harness.submissions.single.value, const AiUiTextValue(''));
      expect(
        harness.submissions.single.status,
        AiUiInteractionStatus.submitted,
      );
    });
  });

  group('location_picker', () {
    testWidgets('a saved place keeps its id and address', (tester) async {
      final harness = await pumpNodes(
        tester,
        [locationPicker()],
        harness: recording(),
      );

      await tapText(tester, 'Home');
      await tapText(tester, 'Confirm');

      final result = harness.submissions.single;
      expect(result.kind, AiUiInteractionKind.locationSelected);
      expect(
        result.value,
        const AiUiLocationValue(
          id: 'home',
          name: 'Home',
          addressText: 'Marina Tower 3',
          source: AiUiLocationSource.saved,
        ),
      );
      expect(result.text, 'Use this location: Home');
    });

    testWidgets('a typed query is marked as typed, not as a saved place', (
      tester,
    ) async {
      final harness = await pumpNodes(
        tester,
        [locationPicker()],
        harness: recording(),
      );

      await tester.enterText(find.byType(TextField).first, 'Al Barsha');
      await tester.pump();
      await tapText(tester, 'Confirm');

      expect(
        harness.submissions.single.value,
        const AiUiLocationValue(
          name: 'Al Barsha',
          source: AiUiLocationSource.typed,
        ),
      );
    });

    testWidgets('use-current asks the app and carries the correlation', (
      tester,
    ) async {
      final harness = await pumpNodes(
        tester,
        [locationPicker()],
        harness: recording(),
        messageId: 'msg_9',
      );

      await tapText(tester, 'Use current location');

      // Not an answer — the app owns the device and produces the result.
      expect(harness.submissions, isEmpty);

      final call = harness.callsTo(AiUiActionType.requestLocationShare).single;
      expect(call.params[AiUiInteractionParams.nodeId], 'loc_1');
      expect(call.params[AiUiInteractionParams.messageId], 'msg_9');
    });

    testWidgets('use-current claims the node so a double tap asks once', (
      tester,
    ) async {
      final harness = await pumpNodes(
        tester,
        [locationPicker()],
        harness: recording(),
      );

      await tapText(tester, 'Use current location');
      await tapText(tester, 'Use current location');

      expect(
        harness.callsTo(AiUiActionType.requestLocationShare),
        hasLength(1),
      );
      expect(harness.stateOf('loc_1'), AiUiNodeInteractionState.pending);
    });
  });

  group('permission_request', () {
    testWidgets('allow states the intent and names the node', (tester) async {
      final harness = await pumpNodes(
        tester,
        [permissionRequest()],
        harness: recording(),
        messageId: 'msg_3',
      );

      await tapText(tester, 'Allow');

      expect(harness.submissions, isEmpty);
      final call = harness.callsTo(AiUiActionType.requestPermission).single;
      expect(call.params['permission'], 'camera');
      expect(call.params[AiUiInteractionParams.nodeId], 'perm_1');
      expect(call.params[AiUiInteractionParams.messageId], 'msg_3');
    });

    testWidgets('deny tells the agent instead of only collapsing the card', (
      tester,
    ) async {
      final harness = await pumpNodes(
        tester,
        [permissionRequest()],
        harness: recording(),
      );

      await tapText(tester, 'Not now');

      final result = harness.submissions.single;
      expect(result.kind, AiUiInteractionKind.permissionResult);
      expect(result.status, AiUiInteractionStatus.cancelled);
      expect(
        result.value,
        const AiUiPermissionValue(
          permission: 'camera',
          outcome: AiUiPermissionOutcome.denied,
        ),
      );
      // No prose: "you declined" is client copy, and this package holds no
      // translations. The host fills it in.
      expect(result.text, isNull);
    });

    testWidgets('a declined card stays declined across a rebuild', (
      tester,
    ) async {
      // The regression this guards: answering appends a turn, the conversation
      // list rebuilds, and `AiDismissible`'s widget-local collapse does not
      // survive it — so the card the user just declined came straight back,
      // underneath the agent's reply to that decline. Pumping the same nodes
      // through the same harness reproduces exactly that: a fresh widget tree
      // over a ledger that remembers.
      final harness = recording();
      await pumpNodes(tester, [permissionRequest()], harness: harness);

      await tapText(tester, 'Not now');
      await tester.pumpAndSettle();

      await pumpNodes(tester, [permissionRequest()], harness: harness);
      await tester.pump();

      expect(find.text('Camera access'), findsNothing);
      expect(harness.stateOf('perm_1'), AiUiNodeInteractionState.cancelled);
    });

    testWidgets('an answered card is disabled but still readable', (
      tester,
    ) async {
      // Only a *decline* collapses. An answered question stays on screen as
      // the record of what was asked and chosen.
      final harness = recording();
      await pumpNodes(tester, [timeSlots()], harness: harness);

      await tapText(tester, '9:00 AM');
      await tapText(tester, 'Confirm Time');
      await pumpNodes(tester, [timeSlots()], harness: harness);

      expect(find.text('Confirm Time'), findsOneWidget);
      expect(
        tester.widget<AiCardButton>(find.byType(AiCardButton)).onTap,
        isNull,
      );
    });

    testWidgets('deny still collapses the card', (tester) async {
      await pumpNodes(
        tester,
        [permissionRequest()],
        harness: recording(),
      );

      await tapText(tester, 'Not now');
      await tester.pumpAndSettle();

      expect(find.text('Camera access'), findsNothing);
    });
  });

  group('media_request', () {
    testWidgets('an option asks the app, correlated by node', (tester) async {
      final harness = await pumpNodes(
        tester,
        [mediaRequest()],
        harness: recording(),
      );

      await tapText(tester, 'Take a photo');

      final call = harness.callsTo(AiUiActionType.requestImageUpload).single;
      expect(call.params['source'], 'camera');
      expect(call.params[AiUiInteractionParams.nodeId], 'media_1');
    });

    testWidgets('cancel reports a zero-count result', (tester) async {
      final harness = await pumpNodes(
        tester,
        [mediaRequest()],
        harness: recording(),
      );

      await tapText(tester, 'Cancel');

      final result = harness.submissions.single;
      expect(result.kind, AiUiInteractionKind.mediaResult);
      expect(result.status, AiUiInteractionStatus.cancelled);
      expect(result.value, const AiUiMediaValue(count: 0));
    });
  });

  group('location_confirm', () {
    testWidgets('confirming produces a place, not just a sentence', (
      tester,
    ) async {
      final harness = await pumpNodes(
        tester,
        [locationConfirm()],
        harness: recording(),
      );

      await tapText(tester, 'Confirm');

      final result = harness.submissions.single;
      expect(result.kind, AiUiInteractionKind.locationConfirmed);
      expect(result.text, 'Marina Tower 3, Dubai');
      expect(
        result.value,
        const AiUiLocationValue(
          name: 'Marina Tower 3, Dubai',
          source: AiUiLocationSource.saved,
        ),
      );
    });

    testWidgets('change asks the app to run its location flow again', (
      tester,
    ) async {
      final harness = await pumpNodes(
        tester,
        [locationConfirm()],
        harness: recording(),
      );

      await tapText(tester, 'Change');

      expect(harness.submissions, isEmpty);
      expect(
        harness
            .callsTo(AiUiActionType.requestLocationShare)
            .single
            .params[AiUiInteractionParams.nodeId],
        'confirm_1',
      );
    });
  });

  group('quick_reply', () {
    testWidgets('a send_message option becomes a named selection', (
      tester,
    ) async {
      final harness = await pumpNodes(
        tester,
        [quickReply()],
        harness: recording(),
      );

      await tapText(tester, 'Yes, book it');

      final result = harness.submissions.single;
      expect(result.kind, AiUiInteractionKind.quickReplySelected);
      expect(result.value, const AiUiSelectionValue(label: 'Yes, book it'));
      expect(result.text, 'Yes, book it');
    });

    testWidgets('an option that navigates stays a plain dispatch', (
      tester,
    ) async {
      final harness = await pumpNodes(
        tester,
        [quickReply()],
        harness: recording(),
      );

      await tapText(tester, 'Show me the service');

      expect(harness.submissions, isEmpty);
      expect(
        harness.callsTo(AiUiActionType.openService).single.serviceId,
        'svc_1',
      );
    });

    testWidgets('picking one reply retires the rest', (tester) async {
      final harness = await pumpNodes(
        tester,
        [quickReply()],
        harness: recording(),
      );

      await tapText(tester, 'Yes, book it');
      await tapText(tester, 'Show me the service');

      expect(harness.submissions, hasLength(1));
      expect(harness.callsTo(AiUiActionType.openService), isEmpty);
    });
  });

  group('the idempotency key', () {
    testWidgets('is unique per submission', (tester) async {
      final harness = await pumpNodes(
        tester,
        [timeSlots(), reviewRequest()],
        harness: recording(),
      );

      await tapText(tester, '9:00 AM');
      await tapText(tester, 'Confirm Time');
      await tapText(tester, 'Submit');

      final ids = harness.submissions.map((i) => i.interactionId).toSet();
      expect(ids, hasLength(2));
      expect(ids.every((id) => id.isNotEmpty), isTrue);
    });

    testWidgets('cards on one surface answer independently', (tester) async {
      final harness = await pumpNodes(
        tester,
        [timeSlots(), reviewRequest()],
        harness: recording(),
      );

      await tapText(tester, '9:00 AM');
      await tapText(tester, 'Confirm Time');

      expect(harness.stateOf('slots_1'), AiUiNodeInteractionState.submitted);
      expect(harness.stateOf('review_1'), AiUiNodeInteractionState.active);
    });
  });
}
