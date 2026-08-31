import 'package:ai_ui_protocol/ai_ui_protocol.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/renderer_test_support.dart';

void main() {
  group('service_card', () {
    testWidgets('renders title, subtitle and badge', (tester) async {
      await pumpNodes(tester, [
        {
          'type': 'service_card',
          'id': 's',
          'serviceId': 'svc_123',
          'title': 'AC Maintenance',
          'subtitle': 'Same-day service',
          'badge': {'label': 'Popular', 'tone': 'info'},
        },
      ]);

      expect(find.text('AC Maintenance'), findsOneWidget);
      expect(find.text('Same-day service'), findsOneWidget);
      expect(find.byType(AppStatusBadge), findsOneWidget);
    });

    testWidgets('formats the structured price client-side', (tester) async {
      // The agent sends {amount, currency}; the client decides how a dirham
      // looks. That is the whole reason price is not pre-formatted prose.
      await pumpNodes(tester, [
        {
          'type': 'service_card',
          'id': 's',
          'serviceId': 'svc_123',
          'title': 'AC Maintenance',
          'price': {'amount': 100, 'currency': 'AED'},
        },
      ]);

      expect(find.textContaining('100'), findsOneWidget);
      expect(find.textContaining('AED'), findsOneWidget);
    });

    testWidgets('drops trailing zeros on whole amounts', (tester) async {
      await pumpNodes(tester, [
        {
          'type': 'service_card',
          'id': 's',
          'serviceId': 'svc_123',
          'title': 'AC Maintenance',
          'price': {'amount': 100, 'currency': 'AED'},
        },
      ]);

      expect(find.textContaining('100.00'), findsNothing);
    });

    testWidgets('keeps two digits on a fractional amount', (tester) async {
      await pumpNodes(tester, [
        {
          'type': 'service_card',
          'id': 's',
          'serviceId': 'svc_123',
          'title': 'AC Maintenance',
          'price': {'amount': 99.5, 'currency': 'AED'},
        },
      ]);

      expect(find.textContaining('99.50'), findsOneWidget);
    });

    testWidgets('dispatches its action when tapped', (tester) async {
      final harness = await pumpNodes(tester, [
        {
          'type': 'service_card',
          'id': 's',
          'serviceId': 'svc_123',
          'title': 'AC Maintenance',
          'action': {'type': 'open_service', 'serviceId': 'svc_123'},
        },
      ]);

      await tester.tap(find.byType(InkWell));
      await tester.pump();

      expect(
        harness.callsTo(AiUiActionType.openService).single.serviceId,
        'svc_123',
      );
    });
  });

  group('appointment_card', () {
    testWidgets('formats the UTC instant in local time', (tester) async {
      await pumpNodes(tester, [
        {
          'type': 'appointment_card',
          'id': 'a',
          'appointmentId': 'apt_1',
          'title': 'AC Maintenance',
          'startsAt': '2026-09-01T06:00:00Z',
          'status': 'Confirmed',
          'statusTone': 'success',
        },
      ]);

      expect(find.text('AC Maintenance'), findsOneWidget);
      expect(find.text('Confirmed'), findsOneWidget);
      // 12-hour with AM/PM in both languages, per the localization rules —
      // never the device's 24-hour preference.
      expect(find.textContaining(RegExp('AM|PM')), findsOneWidget);
      expect(find.textContaining('Sep'), findsOneWidget);
    });
  });

  group('branch_card', () {
    testWidgets('formats a sub-kilometre distance in metres', (tester) async {
      await pumpNodes(tester, [
        {
          'type': 'branch_card',
          'id': 'b',
          'branchId': 'br_1',
          'name': 'Downtown',
          'addressText': 'Sheikh Zayed Road',
          'distanceMeters': 450,
        },
      ]);

      expect(find.text('Downtown'), findsOneWidget);
      expect(find.text('450 m'), findsOneWidget);
    });

    testWidgets('switches to kilometres past 1000 m', (tester) async {
      await pumpNodes(tester, [
        {
          'type': 'branch_card',
          'id': 'b',
          'branchId': 'br_1',
          'name': 'Marina',
          'distanceMeters': 4800,
        },
      ]);

      expect(find.text('4.8 km'), findsOneWidget);
    });
  });

  group('document_card', () {
    testWidgets('renders its status badge', (tester) async {
      await pumpNodes(tester, [
        {
          'type': 'document_card',
          'id': 'd',
          'documentId': 'doc_1',
          'title': 'Trade licence',
          'status': 'Expiring soon',
          'statusTone': 'warning',
        },
      ]);

      expect(find.text('Trade licence'), findsOneWidget);
      expect(find.text('Expiring soon'), findsOneWidget);
    });
  });

  group('quick_reply', () {
    testWidgets('renders one chip per option and posts the reply', (
      tester,
    ) async {
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

      expect(find.byType(AppChip), findsNWidgets(2));

      await tester.tap(find.text('Yes, book it'));
      await tester.pump();

      // Tapping a suggestion is indistinguishable from typing it.
      expect(
        harness.callsTo(AiUiActionType.sendMessage).single.text,
        'Yes, book it',
      );
    });
  });

  group('mixed message', () {
    testWidgets('text, semantic card and buttons render in one surface', (
      tester,
    ) async {
      await pumpNodes(tester, [
        {'type': 'text', 'id': 't', 'text': 'Your appointment is confirmed'},
        {
          'type': 'appointment_card',
          'id': 'a',
          'appointmentId': 'apt_1',
          'title': 'AC Maintenance',
          'startsAt': '2026-09-01T06:00:00Z',
        },
        {
          'type': 'row',
          'id': 'r',
          'children': [
            {
              'type': 'button',
              'id': 'b1',
              'label': 'Reschedule',
              'variant': 'outline',
              'size': 'small',
              'action': {'type': 'open_appointment', 'appointmentId': 'apt_1'},
            },
            {
              'type': 'button',
              'id': 'b2',
              'label': 'Done',
              'size': 'small',
              'action': {'type': 'send_message', 'text': 'Thanks'},
            },
          ],
        },
      ]);

      expect(find.text('Your appointment is confirmed'), findsOneWidget);
      expect(find.text('AC Maintenance'), findsOneWidget);
      expect(find.byType(AppButton), findsNWidgets(2));
    });
  });
}
