import 'package:ai_ui_protocol/ai_ui_protocol.dart';
import 'package:ai_ui_renderer/ai_ui_renderer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/renderer_test_support.dart';

/// The four cards that ask for a decision or a capability.
///
/// The recurring property under test: an *allow* control reaches the app's
/// handler with the capability named, while a *decline* control collapses the
/// card locally and dispatches nothing. Declining is a client concern — the
/// agent learns the answer from what the user does next.
void main() {
  group('reminder_card', () {
    Map<String, dynamic> node({String tone = 'warning'}) => {
      'type': 'reminder_card',
      'id': 'r',
      'title': 'Reminder',
      'subtitle': 'AC Maintenance',
      'body':
          'Your appointment is in 30 minutes. Please make sure someone '
          'is home to grant access.',
      'tone': tone,
      'actions': [
        {
          'label': 'Reschedule',
          'variant': 'outline',
          'action': {'type': 'send_message', 'text': 'Reschedule'},
        },
        {
          'label': "I'm ready",
          'action': {'type': 'send_message', 'text': "I'm ready"},
        },
      ],
    };

    testWidgets('renders the disc, the title, the subject and the body', (
      tester,
    ) async {
      await pumpNodes(tester, [node()]);

      expect(find.byType(AiToneDisc), findsOneWidget);
      expect(find.text('Reminder'), findsOneWidget);
      expect(find.text('AC Maintenance'), findsOneWidget);
      expect(find.textContaining('in 30 minutes'), findsOneWidget);
      expect(find.byType(AiCardButton), findsNWidgets(2));
    });

    testWidgets('the glyph follows the tone', (tester) async {
      await pumpNodes(tester, [node()]);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);

      await pumpNodes(tester, [node(tone: 'error')]);
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    });

    testWidgets('its actions dispatch independently', (tester) async {
      final harness = await pumpNodes(tester, [node()]);

      await tapText(tester, "I'm ready");

      expect(
        harness.callsTo(AiUiActionType.sendMessage).single.text,
        "I'm ready",
      );
    });
  });

  group('media_request', () {
    Map<String, dynamic> node({bool withCancel = true}) => {
      'type': 'media_request',
      'id': 'm',
      'title': 'Add photos or video',
      'body':
          'Sanad only requests camera or photo access when you choose '
          'one of these options.',
      'options': [
        {'label': 'Take a photo', 'source': 'camera'},
        {'label': 'Choose photos', 'source': 'gallery'},
        {'label': 'Add a short video', 'source': 'video'},
      ],
      if (withCancel) 'cancelLabel': 'Cancel',
    };

    testWidgets('renders the headline, the body and one row per option', (
      tester,
    ) async {
      await pumpNodes(tester, [node()]);

      expect(find.text('Add photos or video'), findsOneWidget);
      expect(find.textContaining('only requests camera'), findsOneWidget);
      expect(find.byType(AiOptionRow), findsNWidgets(3));
      expect(find.byIcon(Icons.photo_camera_outlined), findsOneWidget);
      expect(find.byIcon(Icons.videocam_outlined), findsOneWidget);
    });

    testWidgets('each option asks the app for its own source', (tester) async {
      final harness = await pumpNodes(tester, [node()]);

      await tapText(tester, 'Add a short video');

      final call = harness.callsTo(AiUiActionType.requestImageUpload).single;
      expect(call.params['source'], 'video');
    });

    testWidgets('cancel collapses the card and dispatches nothing', (
      tester,
    ) async {
      // Declining is a client concern; there is nothing for a handler to do
      // that the widget cannot do itself.
      final harness = await pumpNodes(tester, [node()]);

      await tapText(tester, 'Cancel');

      expect(find.text('Add photos or video'), findsNothing);
      expect(harness.callsTo(AiUiActionType.requestImageUpload), isEmpty);
    });

    testWidgets('renders without a cancel control', (tester) async {
      await pumpNodes(tester, [node(withCancel: false)]);

      expect(find.byType(AiPromptButton), findsNothing);
      expect(find.byType(AiOptionRow), findsNWidgets(3));
    });
  });

  group('permission_request', () {
    Map<String, dynamic> node({
      String permission = 'location',
      bool withImage = true,
      bool withDeny = true,
    }) => {
      'type': 'permission_request',
      'id': 'p',
      'permission': permission,
      'title': 'Allow location access',
      'body': 'Sanad needs your location to find nearby services.',
      if (withImage) 'image': {'assetId': 'service_tools'},
      'allowLabel': 'Allow while using the app',
      if (withDeny) 'denyLabel': "Don't allow",
    };

    testWidgets('renders the headline, the body and both controls', (
      tester,
    ) async {
      await pumpNodes(tester, [node()]);

      expect(find.text('Allow location access'), findsOneWidget);
      expect(find.textContaining('nearby services'), findsOneWidget);
      expect(find.text('Allow while using the app'), findsOneWidget);
      expect(find.text("Don't allow"), findsOneWidget);
      expect(find.byType(AiMapPreview), findsOneWidget);
    });

    testWidgets('allow reaches the app with the capability named', (
      tester,
    ) async {
      // The node names a capability, never a platform permission string, and
      // the app owns the prompt that follows.
      final harness = await pumpNodes(tester, [node()]);

      await tapText(tester, 'Allow while using the app');

      expect(
        harness
            .callsTo(AiUiActionType.requestPermission)
            .single
            .params['permission'],
        'location',
      );
    });

    testWidgets('the camera variant asks for the camera', (tester) async {
      final harness = await pumpNodes(tester, [
        {
          'type': 'permission_request',
          'id': 'p',
          'permission': 'camera',
          'title': 'Allow camera access?',
          'allowLabel': 'Allow camera',
          'denyLabel': 'Not now',
        },
      ]);

      await tapText(tester, 'Allow camera');

      expect(
        harness
            .callsTo(AiUiActionType.requestPermission)
            .single
            .params['permission'],
        'camera',
      );
    });

    testWidgets('declining collapses the card and dispatches nothing', (
      tester,
    ) async {
      final harness = await pumpNodes(tester, [node()]);

      await tapText(tester, "Don't allow");

      expect(find.text('Allow location access'), findsNothing);
      expect(harness.callsTo(AiUiActionType.requestPermission), isEmpty);
    });

    testWidgets('renders without an illustration', (tester) async {
      await pumpNodes(tester, [node(withImage: false)]);

      expect(find.byType(AiMapPreview), findsNothing);
      expect(find.text('Allow location access'), findsOneWidget);
    });

    testWidgets('renders with only the allow control', (tester) async {
      await pumpNodes(tester, [node(withDeny: false)]);

      expect(find.byType(AiPromptButton), findsOneWidget);
    });
  });

  group('location_confirm', () {
    Map<String, dynamic> node({bool withChange = true}) => {
      'type': 'location_confirm',
      'id': 'lc',
      'title': 'Confirm your location',
      'image': {'assetId': 'service_tools'},
      'addressText': 'Dubai Marina',
      'confirmLabel': 'Confirm location',
      if (withChange) 'changeLabel': 'Change location',
    };

    testWidgets('renders the map, the address and both controls', (
      tester,
    ) async {
      await pumpNodes(tester, [node()]);

      expect(find.text('Confirm your location'), findsOneWidget);
      expect(find.byType(AiMapPreview), findsOneWidget);
      expect(find.text('Dubai Marina'), findsOneWidget);
      expect(find.text('Confirm location'), findsOneWidget);
      expect(find.text('Change location'), findsOneWidget);
    });

    testWidgets('confirming posts the address as a user turn', (tester) async {
      final harness = await pumpNodes(tester, [node()]);

      await tapText(tester, 'Confirm location');

      expect(
        harness.callsTo(AiUiActionType.sendMessage).single.text,
        'Dubai Marina',
      );
    });

    testWidgets('changing it asks the app to run its location flow again', (
      tester,
    ) async {
      final harness = await pumpNodes(tester, [node()]);

      await tapText(tester, 'Change location');

      expect(
        harness.callsTo(AiUiActionType.requestLocationShare),
        hasLength(1),
      );
      expect(harness.callsTo(AiUiActionType.sendMessage), isEmpty);
    });
  });

  group('layout under pressure', () {
    testWidgets('every prompt mirrors under RTL without overflowing', (
      tester,
    ) async {
      await pumpNodes(
        tester,
        [
          {
            'type': 'reminder_card',
            'id': 'r',
            'title': 'تذكير',
            'subtitle': 'صيانة المكيف',
            'body': 'موعدك بعد ٣٠ دقيقة.',
          },
          {
            'type': 'media_request',
            'id': 'm',
            'title': 'أضف صورًا أو فيديو',
            'options': [
              {'label': 'التقط صورة', 'source': 'camera'},
            ],
            'cancelLabel': 'إلغاء',
          },
          {
            'type': 'permission_request',
            'id': 'p',
            'permission': 'location',
            'title': 'السماح بالوصول إلى الموقع',
            'allowLabel': 'السماح',
            'denyLabel': 'لا تسمح',
          },
          {
            'type': 'location_confirm',
            'id': 'lc',
            'title': 'تأكيد موقعك',
            'addressText': 'دبي مارينا',
            'confirmLabel': 'تأكيد الموقع',
          },
        ],
        textDirection: TextDirection.rtl,
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('a long body wraps rather than overflowing', (tester) async {
      await pumpNodes(tester, [
        {
          'type': 'permission_request',
          'id': 'p',
          'permission': 'camera',
          'title': 'Allow camera access to continue with this request',
          'body':
              'Sanad needs your camera to take photos for this request. '
              'You can change this later in settings, and nothing is uploaded '
              'until you choose to send it.',
          'allowLabel': 'Allow camera',
        },
      ]);

      expect(tester.takeException(), isNull);
    });
  });
}
