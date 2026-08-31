import 'package:ai_ui_protocol/ai_ui_protocol.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/renderer_test_support.dart';

void main() {
  group('text', () {
    testWidgets('renders its content', (tester) async {
      await pumpNodes(tester, [
        {'type': 'text', 'id': 't', 'text': 'I found 3 services near you.'},
      ]);

      expect(find.text('I found 3 services near you.'), findsOneWidget);
    });

    testWidgets('applies the typography token for its style', (tester) async {
      await pumpNodes(tester, [
        {'type': 'text', 'id': 't', 'text': 'Heading', 'style': 'title'},
        {'type': 'text', 'id': 'b', 'text': 'Body'},
      ]);

      final context = tester.element(find.text('Body'));
      final heading = tester.widget<Text>(find.text('Heading'));
      final body = tester.widget<Text>(find.text('Body'));

      expect(heading.style, context.appTypography.title3.merge(heading.style));
      expect(heading.style?.fontSize, context.appTypography.title3.fontSize);
      expect(
        body.style?.fontSize,
        context.appTypography.regularNormal.fontSize,
      );
    });

    testWidgets('muted emphasis uses the muted colour token', (tester) async {
      await pumpNodes(tester, [
        {'type': 'text', 'id': 't', 'text': 'Muted', 'emphasis': 'muted'},
      ]);

      final context = tester.element(find.text('Muted'));
      expect(
        tester.widget<Text>(find.text('Muted')).style?.color,
        context.appColors.textMuted,
      );
    });

    testWidgets(
      'wraps an inherently-LTR value in bidi isolates under RTL',
      (tester) async {
        // The recurring SAN-770/771/775 bug: a leading `+` is bidi-neutral, so
        // without isolation it renders at the visual end under Arabic.
        await pumpNodes(
          tester,
          [
            {
              'type': 'text',
              'id': 't',
              'text': '+971 50 123 4567',
              'direction': 'ltrValue',
            },
          ],
          textDirection: TextDirection.rtl,
        );

        expect(find.text('+971 50 123 4567'.ltrIsolated), findsOneWidget);
        expect(find.text('+971 50 123 4567'), findsNothing);
      },
    );

    testWidgets('leaves auto-direction text untouched', (tester) async {
      await pumpNodes(
        tester,
        [
          {'type': 'text', 'id': 't', 'text': '+971 50 123 4567'},
        ],
        textDirection: TextDirection.rtl,
      );

      expect(find.text('+971 50 123 4567'), findsOneWidget);
    });
  });

  group('rich_text', () {
    testWidgets('renders every span', (tester) async {
      await pumpNodes(tester, [
        {
          'type': 'rich_text',
          'id': 'rt',
          'spans': [
            {'text': 'Tap '},
            {
              'text': 'here',
              'emphasis': 'strong',
              'action': {'type': 'open_service', 'serviceId': 'svc_1'},
            },
          ],
        },
      ]);

      expect(find.textContaining('Tap '), findsOneWidget);
      expect(find.textContaining('here'), findsOneWidget);
    });

    testWidgets('disposes its tap recognizers', (tester) async {
      // A TapGestureRecognizer on a TextSpan owns native resources; leaking one
      // per rebuild on a chat surface adds up fast.
      final harness = await pumpNodes(tester, [
        {
          'type': 'rich_text',
          'id': 'rt',
          'spans': [
            {
              'text': 'link',
              'action': {'type': 'open_service', 'serviceId': 'svc_1'},
            },
          ],
        },
      ]);

      await pumpNodes(tester, [
        {'type': 'text', 'id': 't', 'text': 'replaced'},
      ], harness: harness);

      expect(find.text('replaced'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('button', () {
    testWidgets('renders an AppButton and dispatches its action', (
      tester,
    ) async {
      final harness = await pumpNodes(tester, [
        {
          'type': 'button',
          'id': 'b',
          'label': 'View appointment',
          'action': {'type': 'open_appointment', 'appointmentId': 'apt_1'},
        },
      ]);

      expect(find.byType(AppButton), findsOneWidget);
      await tester.tap(find.byType(AppButton));
      await tester.pump();

      final calls = harness.callsTo(AiUiActionType.openAppointment);
      expect(calls, hasLength(1));
      expect(calls.single.appointmentId, 'apt_1');
    });

    testWidgets('maps variant, intent and size onto the design system', (
      tester,
    ) async {
      await pumpNodes(tester, [
        {
          'type': 'button',
          'id': 'b',
          'label': 'Cancel booking',
          'variant': 'outline',
          'intent': 'destructive',
          'size': 'small',
          'action': {'type': 'open_service', 'serviceId': 's'},
        },
      ]);

      final button = tester.widget<AppButton>(find.byType(AppButton));
      expect(button.variant, AppButtonVariant.outline);
      expect(button.intent, AppButtonIntent.destructive);
      expect(button.size, AppButtonSize.small);
    });

    testWidgets('enabled:false yields a genuinely disabled button', (
      tester,
    ) async {
      final harness = await pumpNodes(tester, [
        {
          'type': 'button',
          'id': 'b',
          'label': 'Book',
          'enabled': false,
          'action': {'type': 'open_service', 'serviceId': 's'},
        },
      ]);

      // A null callback is what makes it disabled to assistive tech, not just
      // visually greyed.
      expect(
        tester.widget<AppButton>(find.byType(AppButton)).onPressed,
        isNull,
      );

      await tester.tap(find.byType(AppButton), warnIfMissed: false);
      await tester.pump();
      expect(harness.callsTo(AiUiActionType.openService), isEmpty);
    });

    testWidgets('a button with an unhandled action never reaches the tree', (
      tester,
    ) async {
      final harness = await pumpNodes(tester, [
        {
          'type': 'button',
          'id': 'b',
          'label': 'Delete everything',
          'action': {'type': 'delete_everything'},
        },
        {'type': 'text', 'id': 't', 'text': 'still here'},
      ]);

      expect(find.byType(AppButton), findsNothing);
      expect(find.text('still here'), findsOneWidget);
      expect(
        harness.diagnostics.hasCode(AiUiDiagnosticCode.unknownActionType),
        isTrue,
      );
    });
  });

  group('chip', () {
    testWidgets('renders and dispatches', (tester) async {
      final harness = await pumpNodes(tester, [
        {
          'type': 'chip',
          'id': 'c',
          'label': 'Yes',
          'action': {'type': 'send_message', 'text': 'Yes'},
        },
      ]);

      expect(find.byType(AppChip), findsOneWidget);
      await tester.tap(find.byType(AppChip));
      await tester.pump();

      expect(harness.callsTo(AiUiActionType.sendMessage).single.text, 'Yes');
    });

    testWidgets('an unresolvable action leaves a non-tappable chip', (
      tester,
    ) async {
      await pumpNodes(tester, [
        {
          'type': 'chip',
          'id': 'c',
          'label': 'Popular',
          'action': {'type': 'not_a_thing'},
        },
      ]);

      expect(find.text('Popular'), findsOneWidget);
      expect(tester.widget<AppChip>(find.byType(AppChip)).onTap, isNull);
    });
  });

  group('layout', () {
    testWidgets('column renders its children in order', (tester) async {
      await pumpNodes(tester, [
        {
          'type': 'column',
          'id': 'col',
          'children': [
            {'type': 'text', 'id': 'a', 'text': 'first'},
            {'type': 'text', 'id': 'b', 'text': 'second'},
          ],
        },
      ]);

      final first = tester.getTopLeft(find.text('first'));
      final second = tester.getTopLeft(find.text('second'));
      expect(first.dy, lessThan(second.dy));
    });

    testWidgets('row lays out horizontally', (tester) async {
      await pumpNodes(tester, [
        {
          'type': 'row',
          'id': 'r',
          'children': [
            {'type': 'text', 'id': 'a', 'text': 'left'},
            {'type': 'text', 'id': 'b', 'text': 'right'},
          ],
        },
      ]);

      expect(
        tester.getTopLeft(find.text('left')).dx,
        lessThan(tester.getTopLeft(find.text('right')).dx),
      );
    });

    testWidgets('row mirrors under RTL without the payload changing', (
      tester,
    ) async {
      await pumpNodes(
        tester,
        [
          {
            'type': 'row',
            'id': 'r',
            'children': [
              {'type': 'text', 'id': 'a', 'text': 'first'},
              {'type': 'text', 'id': 'b', 'text': 'second'},
            ],
          },
        ],
        textDirection: TextDirection.rtl,
      );

      // Same JSON, mirrored result: the protocol says `start`, the renderer
      // owns what that means.
      expect(
        tester.getTopLeft(find.text('first')).dx,
        greaterThan(tester.getTopLeft(find.text('second')).dx),
      );
    });

    testWidgets('row can wrap', (tester) async {
      await pumpNodes(tester, [
        {
          'type': 'row',
          'id': 'r',
          'wrap': true,
          'children': [
            {'type': 'text', 'id': 'a', 'text': 'one'},
          ],
        },
      ]);

      expect(find.byType(Wrap), findsOneWidget);
    });

    testWidgets('card renders a section card with its title and children', (
      tester,
    ) async {
      await pumpNodes(tester, [
        {
          'type': 'card',
          'id': 'c',
          'title': 'Your appointment',
          'children': [
            {'type': 'text', 'id': 't', 'text': 'Tomorrow at 10:00 AM'},
          ],
        },
      ]);

      expect(find.text('Your appointment'), findsOneWidget);
      expect(find.text('Tomorrow at 10:00 AM'), findsOneWidget);
    });

    testWidgets('a tappable card announces as a single button', (tester) async {
      final harness = await pumpNodes(tester, [
        {
          'type': 'card',
          'id': 'c',
          'title': 'AC Maintenance',
          'action': {'type': 'open_service', 'serviceId': 'svc_9'},
          'children': [
            {'type': 'text', 'id': 't', 'text': 'From 100 AED'},
          ],
        },
      ]);

      expect(find.byType(InkWell), findsOneWidget);
      await tester.tap(find.byType(InkWell));
      await tester.pump();

      expect(
        harness.callsTo(AiUiActionType.openService).single.serviceId,
        'svc_9',
      );
    });

    testWidgets('list renders one row per item and is not scrollable', (
      tester,
    ) async {
      await pumpNodes(tester, [
        {
          'type': 'list',
          'id': 'l',
          'children': [
            for (var i = 0; i < 3; i++)
              {'type': 'list_item', 'id': 'i$i', 'title': 'Branch $i'},
          ],
        },
      ]);

      expect(find.text('Branch 0'), findsOneWidget);
      expect(find.text('Branch 2'), findsOneWidget);
      // A chat bubble must never contain a second scroll axis: the list is a
      // bounded Column, kept safe by the item cap in AiUiLimits. (The single
      // Scrollable here is the harness standing in for the message list.)
      expect(find.byType(ListView), findsNothing);
      expect(find.byType(Scrollable), findsOneWidget);
    });

    testWidgets('divider and spacer render', (tester) async {
      await pumpNodes(tester, [
        {'type': 'divider', 'id': 'd'},
        {'type': 'spacer', 'id': 's', 'size': 'lg'},
      ]);

      expect(find.byType(AppDivider), findsOneWidget);
    });
  });

  group('progress and loading', () {
    testWidgets('determinate progress renders a bar', (tester) async {
      await pumpNodes(tester, [
        {'type': 'progress', 'id': 'p', 'value': 0.5, 'label': 'Booking'},
      ]);

      expect(find.byType(AppProgressBar), findsOneWidget);
      expect(find.text('Booking'), findsOneWidget);
    });

    testWidgets('indeterminate progress degrades to an activity indicator', (
      tester,
    ) async {
      await pumpNodes(tester, [
        {'type': 'progress', 'id': 'p'},
      ]);

      expect(find.byType(AppProgressBar), findsNothing);
      expect(find.byType(AppLoadingIndicator), findsOneWidget);
    });

    testWidgets('loading renders with its label', (tester) async {
      await pumpNodes(tester, [
        {'type': 'loading', 'id': 'l', 'label': 'Thinking'},
      ]);

      expect(find.byType(AppLoadingIndicator), findsOneWidget);
      expect(find.text('Thinking'), findsOneWidget);
    });
  });

  group('icon', () {
    testWidgets('drops an unresolvable icon and says so', (tester) async {
      final harness = await pumpNodes(tester, [
        {'type': 'icon', 'id': 'i', 'name': 'not-an-icon'},
        {'type': 'text', 'id': 't', 'text': 'still here'},
      ]);

      expect(find.text('still here'), findsOneWidget);
      expect(
        harness.diagnostics.hasCode(AiUiDiagnosticCode.invalidProperty),
        isTrue,
      );
    });

    testWidgets('renders a Font Awesome icon from a CSS class', (tester) async {
      await pumpNodes(tester, [
        {'type': 'icon', 'id': 'i', 'name': 'fa-solid fa-store'},
      ]);

      expect(find.byType(FaIcon), findsOneWidget);
    });
  });

  group('accessibility', () {
    testWidgets('a11yLabel overrides the derived label', (tester) async {
      // Disposed explicitly rather than via addTearDown: the framework
      // verifies no handle is outstanding *before* tear-downs run.
      final handle = tester.ensureSemantics();

      await pumpNodes(tester, [
        {
          'type': 'text',
          'id': 't',
          'text': '+971501234567',
          'a11yLabel': 'Phone number',
        },
      ]);

      // A merged label would append the raw digits after the override, which
      // is exactly the reading the override exists to prevent.
      expect(find.bySemanticsLabel('Phone number'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('an image exposes its alt text to assistive tech', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();

      await pumpNodes(tester, [
        {
          'type': 'image',
          'id': 'i',
          'assetId': 'service_tools',
          'alt': 'Service tools',
        },
      ]);

      expect(find.bySemanticsLabel('Service tools'), findsOneWidget);
      handle.dispose();
    });
  });
}
