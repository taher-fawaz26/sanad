import 'package:ai_ui_protocol/ai_ui_protocol.dart';
import 'package:ai_ui_renderer/ai_ui_renderer.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/renderer_test_support.dart';

/// The four cards the user answers.
///
/// The property that matters most here is the trust model: whatever the user
/// picks or types is substituted into a template the *agent* authored and
/// posted as a normal `send_message`. These tests assert the resulting text,
/// not just that a callback fired, because the text is the contract.
void main() {
  group('quick_reply', () {
    testWidgets('stacks one full-width pill per option', (tester) async {
      // Figma stacks these rather than flowing them as chips: a suggested
      // reply is a sentence, and a Wrap turned three sentences into a
      // paragraph of buttons.
      await pumpNodes(tester, [
        {
          'type': 'quick_reply',
          'id': 'q',
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
      ]);

      expect(find.byType(AppChip), findsNothing);
      expect(find.text('Yes, book it'), findsOneWidget);
      expect(find.text('Pick another time'), findsOneWidget);
      expect(find.text('Not now'), findsOneWidget);
    });

    testWidgets('accents the first option only', (tester) async {
      await pumpNodes(tester, [
        {
          'type': 'quick_reply',
          'id': 'q',
          'options': [
            {
              'label': 'Yes',
              'action': {'type': 'send_message', 'text': 'Yes'},
            },
            {
              'label': 'No',
              'action': {'type': 'send_message', 'text': 'No'},
            },
          ],
        },
      ]);

      final first = tester.widget<Text>(find.text('Yes'));
      final second = tester.widget<Text>(find.text('No'));
      expect(first.style!.color, isNot(second.style!.color));
    });

    testWidgets('tapping one posts it exactly as typed', (tester) async {
      final harness = await pumpNodes(tester, [
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
      ]);

      await tapText(tester, 'Yes, book it');

      expect(
        harness.callsTo(AiUiActionType.sendMessage).single.text,
        'Yes, book it',
      );
    });
  });

  group('time_slots', () {
    Map<String, dynamic> node({String? selectedSlotId}) => {
      'type': 'time_slots',
      'id': 't',
      'dateLabel': 'Tomorrow, September 3rd',
      'slots': [
        {'id': 's_0900', 'label': '9:00 AM'},
        {'id': 's_1030', 'label': '10:30 AM'},
        {'id': 's_1100', 'label': '11:00 AM', 'enabled': false},
      ],
      if (selectedSlotId != null) 'selectedSlotId': selectedSlotId,
      'confirmLabel': 'Confirm Time',
      'confirmTemplate': 'Book me the {slot} slot',
    };

    testWidgets('renders the date and one chip per slot', (tester) async {
      await pumpNodes(tester, [node()]);

      expect(find.text('Tomorrow, September 3rd'), findsOneWidget);
      expect(find.byType(AiSlotGrid), findsOneWidget);
      expect(find.text('9:00 AM'), findsOneWidget);
      expect(find.text('10:30 AM'), findsOneWidget);
      expect(find.text('11:00 AM'), findsOneWidget);
    });

    testWidgets('confirm is disabled until a slot is chosen', (tester) async {
      // Confirming nothing would post the template with an empty
      // substitution, which reads as a bug to whoever receives it.
      final harness = await pumpNodes(tester, [node()]);

      expect(
        tester.widget<AiCardButton>(find.byType(AiCardButton)).onTap,
        isNull,
      );

      await tapText(tester, 'Confirm Time');
      expect(harness.callsTo(AiUiActionType.sendMessage), isEmpty);
    });

    testWidgets('picking a slot then confirming posts the template', (
      tester,
    ) async {
      final harness = await pumpNodes(tester, [node()]);

      await tapText(tester, '10:30 AM');
      await tapText(tester, 'Confirm Time');

      expect(
        harness.callsTo(AiUiActionType.sendMessage).single.text,
        'Book me the 10:30 AM slot',
      );
    });

    testWidgets('a pre-selected slot is confirmable immediately', (
      tester,
    ) async {
      final harness = await pumpNodes(tester, [
        node(selectedSlotId: 's_0900'),
      ]);

      await tapText(tester, 'Confirm Time');

      expect(
        harness.callsTo(AiUiActionType.sendMessage).single.text,
        'Book me the 9:00 AM slot',
      );
    });

    testWidgets('a disabled slot cannot be chosen', (tester) async {
      final harness = await pumpNodes(tester, [node()]);

      await tapText(tester, '11:00 AM');
      await tapText(tester, 'Confirm Time');

      expect(harness.callsTo(AiUiActionType.sendMessage), isEmpty);
    });

    testWidgets('a template with no placeholder is sent verbatim', (
      tester,
    ) async {
      final harness = await pumpNodes(tester, [
        {
          'type': 'time_slots',
          'id': 't',
          'slots': [
            {'id': 'a', 'label': '9:00 AM'},
            {'id': 'b', 'label': '10:30 AM'},
          ],
          'confirmLabel': 'Confirm',
          'confirmTemplate': 'That time works for me',
        },
      ]);

      await tapText(tester, '9:00 AM');
      await tapText(tester, 'Confirm');

      expect(
        harness.callsTo(AiUiActionType.sendMessage).single.text,
        'That time works for me',
      );
    });

    testWidgets('mirrors under RTL without overflowing', (tester) async {
      await pumpNodes(tester, [node()], textDirection: TextDirection.rtl);

      expect(tester.takeException(), isNull);
    });
  });

  group('review_request', () {
    Map<String, dynamic> node() => {
      'type': 'review_request',
      'id': 'v',
      'serviceName': 'Deep Cleaning',
      'providerText': 'Provided by CleanCo Marina',
      'commentPlaceholder': 'Leave a comment (optional)...',
      'submitLabel': 'Submit Review',
      'submitTemplate': 'My review of Deep Cleaning: {comment}',
    };

    testWidgets('renders the service, the provider and the comment box', (
      tester,
    ) async {
      await pumpNodes(tester, [node()]);

      expect(find.text('Deep Cleaning'), findsOneWidget);
      expect(find.text('Provided by CleanCo Marina'), findsOneWidget);
      expect(find.text('Leave a comment (optional)...'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('typing then submitting substitutes the comment', (
      tester,
    ) async {
      final harness = await pumpNodes(tester, [node()]);

      await tester.enterText(find.byType(TextField), 'Spotless, thank you');
      await tester.pump();
      await tapText(tester, 'Submit Review');

      expect(
        harness.callsTo(AiUiActionType.sendMessage).single.text,
        'My review of Deep Cleaning: Spotless, thank you',
      );
    });

    testWidgets('submitting with no comment substitutes an empty string', (
      tester,
    ) async {
      // "Submit without commenting" is expressible by the template alone.
      final harness = await pumpNodes(tester, [node()]);

      await tapText(tester, 'Submit Review');

      expect(
        harness.callsTo(AiUiActionType.sendMessage).single.text,
        'My review of Deep Cleaning: ',
      );
    });

    testWidgets('trims surrounding whitespace off the comment', (tester) async {
      final harness = await pumpNodes(tester, [node()]);

      await tester.enterText(find.byType(TextField), '   Great   ');
      await tester.pump();
      await tapText(tester, 'Submit Review');

      expect(
        harness.callsTo(AiUiActionType.sendMessage).single.text,
        'My review of Deep Cleaning: Great',
      );
    });

    testWidgets('submits once, then disables itself', (tester) async {
      // The review has already been posted as a user turn; a second tap would
      // post it again.
      final harness = await pumpNodes(tester, [node()]);

      await tapText(tester, 'Submit Review');
      await tapText(tester, 'Submit Review');

      expect(harness.callsTo(AiUiActionType.sendMessage), hasLength(1));
    });

    testWidgets('honours the comment cap the agent asked for', (tester) async {
      await pumpNodes(tester, [
        {...node(), 'maxCommentLength': 10},
      ]);

      await tester.enterText(
        find.byType(TextField),
        'far longer than ten characters',
      );
      await tester.pump();

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.maxLength, 10);
    });
  });

  group('location_picker', () {
    Map<String, dynamic> node({
      bool withCurrent = true,
      bool withSaved = true,
      bool withSearch = true,
    }) => {
      'type': 'location_picker',
      'id': 'l',
      'title': 'Set your location',
      if (withSearch)
        'searchPlaceholder': 'Search for a neighborhood or city...',
      if (withCurrent) 'useCurrentLabel': 'Use current location',
      'savedLabel': 'Saved locations',
      if (withSaved)
        'savedLocations': [
          {
            'id': 'home',
            'name': 'Home',
            'addressText': 'Dubai Marina, Tower 5, Apt 1204',
          },
          {
            'id': 'office',
            'name': 'Office',
            'addressText': 'DIFC, The Gate District, Level 4',
          },
        ],
      'confirmLabel': 'Confirm',
      'confirmTemplate': 'Use {location} as my address',
    };

    testWidgets('renders the search field, the current row and the places', (
      tester,
    ) async {
      await pumpNodes(tester, [node()]);

      expect(find.text('Set your location'), findsOneWidget);
      expect(find.byType(AppSearchField), findsOneWidget);
      expect(find.text('Use current location'), findsOneWidget);
      expect(find.text('SAVED LOCATIONS'), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('DIFC, The Gate District, Level 4'), findsOneWidget);
    });

    testWidgets('picking a saved place then confirming posts its name', (
      tester,
    ) async {
      final harness = await pumpNodes(tester, [node()]);

      // The picker is taller than the test viewport, so both the place row
      // and the confirm button have to be scrolled to before they can be hit.
      await tapText(tester, 'Office');
      await tapText(tester, 'Confirm');

      expect(
        harness.callsTo(AiUiActionType.sendMessage).single.text,
        'Use Office as my address',
      );
    });

    testWidgets('a typed query fills the same slot as a saved place', (
      tester,
    ) async {
      // Searching real places needs a places API this layer has no business
      // reaching, so what the user types becomes the answer instead.
      final harness = await pumpNodes(tester, [node()]);

      await tester.enterText(find.byType(TextField), 'Deira');
      await tester.pump();
      await tapText(tester, 'Confirm');

      expect(
        harness.callsTo(AiUiActionType.sendMessage).single.text,
        'Use Deira as my address',
      );
    });

    testWidgets('confirm is disabled until there is something to send', (
      tester,
    ) async {
      final harness = await pumpNodes(tester, [node()]);

      await tapText(tester, 'Confirm');

      expect(harness.callsTo(AiUiActionType.sendMessage), isEmpty);
    });

    testWidgets('the current-location row asks the app, not the agent', (
      tester,
    ) async {
      final harness = await pumpNodes(tester, [node()]);

      await tapText(tester, 'Use current location');

      expect(
        harness.callsTo(AiUiActionType.requestLocationShare),
        hasLength(1),
      );
      expect(harness.callsTo(AiUiActionType.sendMessage), isEmpty);
    });

    testWidgets('renders with only a current-location row', (tester) async {
      await pumpNodes(tester, [node(withSaved: false, withSearch: false)]);

      expect(tester.takeException(), isNull);
      expect(find.text('Use current location'), findsOneWidget);
      expect(find.byType(AppSearchField), findsNothing);
    });

    testWidgets('mirrors under RTL without overflowing', (tester) async {
      await pumpNodes(tester, [node()], textDirection: TextDirection.rtl);

      expect(tester.takeException(), isNull);
    });
  });

  group('the interactive cards together', () {
    testWidgets('several render in one surface and stay independent', (
      tester,
    ) async {
      final harness = await pumpNodes(tester, [
        {'type': 'text', 'id': 't', 'text': 'A few things to settle:'},
        {
          'type': 'time_slots',
          'id': 'ts',
          'slots': [
            {'id': 'a', 'label': '9:00 AM'},
            {'id': 'b', 'label': '10:30 AM'},
          ],
          'confirmLabel': 'Confirm time',
          'confirmTemplate': 'Book {slot}',
        },
        {
          'type': 'review_request',
          'id': 'rv',
          'serviceName': 'Deep Cleaning',
          'submitLabel': 'Submit review',
          'submitTemplate': 'Review: {comment}',
        },
      ]);

      await tapText(tester, '9:00 AM');
      await tapText(tester, 'Confirm time');

      // The slot posted its own template; the review card is untouched.
      expect(
        harness.callsTo(AiUiActionType.sendMessage).single.text,
        'Book 9:00 AM',
      );
      expect(find.text('Submit review'), findsOneWidget);
    });
  });

  group('review_request with a rating', () {
    Map<String, dynamic> rated({bool required = true}) => {
      'type': 'review_request',
      'id': 'rv_rated',
      'serviceName': 'How was your experience?',
      'commentPlaceholder': 'Leave a comment (optional)...',
      'maxRating': 5,
      'ratingRequired': required,
      'submitLabel': 'Submit Review',
      'submitTemplate': '{rating} stars: {comment}',
    };

    testWidgets("draws one star per point of the agent's own scale", (
      tester,
    ) async {
      await pumpNodes(tester, [rated()]);

      expect(find.byIcon(Icons.star_outline_rounded), findsNWidgets(5));
      expect(find.byIcon(Icons.star_rounded), findsNothing);
    });

    testWidgets('a card with no scale draws no stars at all', (tester) async {
      await pumpNodes(tester, [
        {
          'type': 'review_request',
          'id': 'rv_plain',
          'serviceName': 'Deep Cleaning',
          'submitLabel': 'Submit',
          'submitTemplate': 'Review: {comment}',
        },
      ]);

      expect(find.byType(AiStarRating), findsNothing);
    });

    testWidgets('tapping a star fills it and the ones before it', (
      tester,
    ) async {
      await pumpNodes(tester, [rated()]);

      await tester.tap(find.byIcon(Icons.star_outline_rounded).at(3));
      await tester.pump();

      expect(find.byIcon(Icons.star_rounded), findsNWidgets(4));
      expect(find.byIcon(Icons.star_outline_rounded), findsOneWidget);
    });

    testWidgets('a required rating gates the submit control', (tester) async {
      await pumpNodes(tester, [rated()]);

      await tapText(tester, 'Submit Review');
      expect(find.text('Submit Review'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.star_outline_rounded).at(4));
      await tester.pump();
      await tapText(tester, 'Submit Review');

      expect(tester.takeException(), isNull);
    });

    testWidgets('an optional rating never blocks submitting', (tester) async {
      // Adding stars to an existing comment card must not make its button
      // unreachable for someone who only wants to leave words.
      final harness = await pumpNodes(
        tester,
        [rated(required: false)],
        harness: RendererHarness(recordInteractions: true),
      );

      await tapText(tester, 'Submit Review');

      expect(
        harness.submissions.single.value,
        const AiUiReviewValue(comment: ''),
      );
    });

    testWidgets('submitting carries the rating and the comment together', (
      tester,
    ) async {
      final harness = await pumpNodes(
        tester,
        [rated()],
        harness: RendererHarness(recordInteractions: true),
      );

      await tester.tap(find.byIcon(Icons.star_outline_rounded).at(3));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'Quick and tidy');
      await tapText(tester, 'Submit Review');

      final result = harness.submissions.single;
      expect(result.kind, AiUiInteractionKind.reviewSubmitted);
      expect(
        result.value,
        const AiUiReviewValue(rating: 4, comment: 'Quick and tidy'),
      );
      expect(result.text, '4 stars: Quick and tidy');
    });

    testWidgets('an unrated card still answers as plain text', (tester) async {
      // The v1 shape, kept so a backend reading `value.text` is unaffected by
      // stars existing.
      final harness = await pumpNodes(
        tester,
        [
          {
            'type': 'review_request',
            'id': 'rv_plain',
            'serviceName': 'Deep Cleaning',
            'submitLabel': 'Submit',
            'submitTemplate': 'Review: {comment}',
          },
        ],
        harness: RendererHarness(recordInteractions: true),
      );

      await tester.enterText(find.byType(TextField), 'Good');
      await tapText(tester, 'Submit');

      expect(harness.submissions.single.value, const AiUiTextValue('Good'));
    });

    testWidgets('the stars stop responding once the review has gone', (
      tester,
    ) async {
      final harness = await pumpNodes(
        tester,
        [rated(required: false)],
        harness: RendererHarness(recordInteractions: true),
      );

      await tapText(tester, 'Submit Review');
      await tester.tap(find.byIcon(Icons.star_outline_rounded).first);
      await tester.pump();

      expect(find.byIcon(Icons.star_rounded), findsNothing);
      expect(harness.submissions, hasLength(1));
    });

    testWidgets('it renders in both directions', (tester) async {
      await pumpNodes(tester, [rated()], textDirection: TextDirection.rtl);

      expect(find.text('How was your experience?'), findsOneWidget);
      expect(find.byType(AiStarRating), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
