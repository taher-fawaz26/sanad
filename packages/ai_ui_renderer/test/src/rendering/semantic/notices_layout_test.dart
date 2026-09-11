import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/renderer_test_support.dart';

/// The one layout property of the notice cards that a device found wrong, as a
/// regression test.
///
/// A `request_notice` header shares one row between a status pill and a
/// reference. Sharing it *evenly* — two `Flexible`s of equal flex — cut
/// "Booking Cancelled" down to "Booking Cance…" on a 393dp device while two
/// thirds of the row sat empty, because two flex children split the row by
/// their flex rather than by what they need.
///
/// The assertion is **painted width against intrinsic width**, because the
/// obvious alternatives do not work: `find.text` matches the string a `Text`
/// was *given* rather than what was drawn, so it passes happily on an
/// ellipsized label, and `RenderParagraph.didExceedMaxLines` reads true even
/// for a single-line paragraph that fits. A paragraph laid out narrower than
/// it wants is the one unambiguous signal that something was cut off.
///
/// Its own file so the surface is a phone before the first pump: the default
/// 800×600 test window is wider than any device the design targets, and a row
/// that only fits there is exactly what this is guarding against.
void main() {
  void expectWhole(WidgetTester tester, String label) {
    final paragraph = tester.renderObject<RenderParagraph>(find.text(label));
    expect(
      paragraph.size.width,
      closeTo(paragraph.getMaxIntrinsicWidth(double.infinity), 0.5),
      reason: '"$label" was laid out narrower than it needs',
    );
  }

  testWidgets('the status label is not squeezed by its reference', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393 * 3, 852 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpNodes(tester, [
      {
        'type': 'request_notice',
        'id': 'rn_layout',
        'status': {'label': 'Booking Cancelled', 'tone': 'error'},
        'reference': '#SND-4821',
        'requestId': 'req_4821',
        'title': 'Ahmed K. had to cancel',
        'body':
            'The provider canceled due to an unexpected emergency. '
            "We're sorry for the inconvenience.",
        'confirm': {
          'confirmLabel': 'Auto-Match New Provider',
          'confirmTemplate': 'Find me another provider',
          'reference': 'req_4821',
        },
        'actions': [
          {
            'label': 'Contact Sanad Support',
            'variant': 'outline',
            'action': {
              'type': 'send_message',
              'text': 'Connect me to support',
            },
          },
        ],
      },
    ]);

    // The status is the sentence and the reference is a short fixed-format id,
    // so the status is the half that must survive intact. The reference is
    // deliberately *not* asserted here: it is allowed to ellipsize when an
    // agent sends an unusually long one, which is the trade the 3:1 split
    // makes explicit.
    expectWhole(tester, 'Booking Cancelled');
    expect(tester.takeException(), isNull);
  });

  testWidgets('an exhausted search keeps its controls readable at 360dp', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpNodes(tester, [
      {
        'type': 'provider_search',
        'id': 'ps_layout',
        'state': 'exhausted',
        'title': 'No Specialists Available',
        'body':
            'No active providers could match your AC Cleaning request for '
            'tomorrow at 10 AM.',
        'confirm': {
          'confirmLabel': 'Change Time Slot',
          'cancelLabel': 'Cancel',
        },
      },
    ]);

    expectWhole(tester, 'Change Time Slot');
    expectWhole(tester, 'Cancel');
    expect(tester.takeException(), isNull);
  });

  testWidgets('a coverage notice keeps its control readable at 360dp', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpNodes(tester, [
      {
        'type': 'service_area_notice',
        'id': 'sa_layout',
        'title': 'Location outside service area',
        'addressText': 'Al Ruwais, Western Region, Abu Dhabi',
        'body': 'This address is currently outside our service area:',
        'changeLabel': 'Change Location',
      },
    ]);

    expectWhole(tester, 'Change Location');
    expect(tester.takeException(), isNull);
  });
}
