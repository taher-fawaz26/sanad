import 'package:ai_ui_protocol/ai_ui_protocol.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/renderer_test_support.dart';

/// The one image contract, asserted through every node that carries one.
///
/// ```text
/// url  >  assetId  >  the node's own no-image state
/// ```
///
/// Each case goes through the real validator and the real renderer, so what is
/// asserted is what a live payload produces — including that a URL reaches
/// `AppNetworkImage`, the app's existing cached-network-image widget, rather
/// than some second image path invented for the AI surface.
///
/// `AppNetworkImage` is only *constructed* here. It never issues a request in
/// a widget test: `CachedNetworkImage` resolves against a fake HTTP client
/// that returns a 400, which is why these tests assert on the widget rather
/// than on pixels.
void main() {
  const url = 'https://cdn.trysanad.us/services/ac.jpg';
  const asset = 'service_tools';

  /// Every image-bearing node, as a payload that puts [image] in the right
  /// field. The point of the table is that one contract covers all six.
  List<Map<String, dynamic>> nodesWith(Map<String, dynamic>? image) => [
    <String, dynamic>{
      'type': 'image',
      'id': 'im',
      'alt': 'AC unit',
      if (image != null) ...image,
    },
    <String, dynamic>{
      'type': 'list',
      'id': 'l',
      'children': [
        <String, dynamic>{
          'type': 'list_item',
          'id': 'li',
          'title': 'Order #1042',
          if (image != null) 'leadingImage': image,
        },
      ],
    },
    <String, dynamic>{
      'type': 'service_card',
      'id': 'sc',
      'serviceId': 'svc_1',
      'title': 'AC Maintenance',
      if (image != null) 'image': image,
    },
    <String, dynamic>{
      'type': 'provider_card',
      'id': 'pc',
      'providerId': 'prv_1',
      'name': 'Ahmed K.',
      if (image != null) 'image': image,
    },
    <String, dynamic>{
      'type': 'permission_request',
      'id': 'pr',
      'permission': 'location',
      'title': 'Allow location access',
      'allowLabel': 'Allow',
      if (image != null) 'image': image,
    },
    <String, dynamic>{
      'type': 'location_confirm',
      'id': 'lc',
      'title': 'Confirm your location',
      'addressText': 'Dubai Marina',
      'confirmLabel': 'Confirm',
      if (image != null) 'image': image,
    },
  ];

  group('a url', () {
    testWidgets('renders through the app network image widget', (tester) async {
      await pumpNodes(tester, [
        {'type': 'image', 'id': 'im', 'url': url, 'alt': 'AC unit'},
      ]);

      expect(find.byType(AppNetworkImage), findsOneWidget);
      final widget = tester.widget<AppNetworkImage>(
        find.byType(AppNetworkImage),
      );
      expect(widget.url, url);
    });

    testWidgets('reaches every image-bearing node', (tester) async {
      // Six nodes, one code path — pumped one at a time so the per-message
      // image cap is not what is being measured. A renderer that grew its own
      // asset-only handling shows up here as a missing network image.
      for (final node in nodesWith({'url': url})) {
        await pumpNodes(tester, [node]);
        expect(
          find.byType(AppNetworkImage),
          findsOneWidget,
          reason: node['type'].toString(),
        );
      }
    });

    testWidgets('wins over an assetId beside it', (tester) async {
      for (final node in nodesWith({'url': url, 'assetId': asset})) {
        await pumpNodes(tester, [node]);
        expect(
          find.byType(AppNetworkImage),
          findsOneWidget,
          reason: node['type'].toString(),
        );
        // The network widget holds the URL, not the asset: `assetId` beside a
        // usable URL is a render-time fallback, never an override.
        expect(
          tester.widget<AppNetworkImage>(find.byType(AppNetworkImage)).url,
          url,
          reason: '${node['type']}',
        );
      }
    });
  });

  group('an assetId', () {
    testWidgets('renders the bundled asset when there is no url', (
      tester,
    ) async {
      await pumpNodes(tester, [
        {'type': 'image', 'id': 'im', 'assetId': asset, 'alt': 'AC unit'},
      ]);

      expect(find.byType(AppNetworkImage), findsNothing);
      expect(_assetPaths(tester), contains(contains('service_tools')));
    });

    testWidgets('wins over an empty url', (tester) async {
      // `{"url": "", "assetId": "..."}` is a backend template that had no
      // dynamic image for this row. It must show the local one, not a hole.
      await pumpNodes(tester, [
        {
          'type': 'image',
          'id': 'im',
          'url': '',
          'assetId': asset,
          'alt': 'AC unit',
        },
      ]);

      expect(find.byType(AppNetworkImage), findsNothing);
      expect(_assetPaths(tester), contains(contains('service_tools')));
    });

    testWidgets('wins over a url the policy refused', (tester) async {
      await pumpNodes(tester, [
        {
          'type': 'image',
          'id': 'im',
          'url': 'http://cdn.trysanad.us/services/ac.jpg',
          'assetId': asset,
          'alt': 'AC unit',
        },
      ]);

      expect(find.byType(AppNetworkImage), findsNothing);
      expect(_assetPaths(tester), contains(contains('service_tools')));
    });

    testWidgets('an unpublished id renders nothing and is reported', (
      tester,
    ) async {
      final harness = await pumpNodes(tester, [
        {
          'type': 'image',
          'id': 'im',
          'assetId': 'not_a_shipped_asset',
          'alt': 'AC unit',
        },
        {'type': 'text', 'id': 't', 'text': 'reply continues'},
      ]);

      // Dropped during validation, so no widget and no request — and the rest
      // of the reply is untouched.
      expect(_assetPaths(tester), isEmpty);
      expect(find.text('reply continues'), findsOneWidget);
      expect(
        harness.diagnostics.hasCode(AiUiDiagnosticCode.unknownAssetId),
        isTrue,
      );
    });
  });

  group('neither', () {
    testWidgets('each node shows its own no-image state', (tester) async {
      await pumpNodes(tester, nodesWith(null));

      // The `image` primitive is the one node that exists only to show a
      // picture, so validation drops it; the other five render without one.
      expect(find.byType(AppNetworkImage), findsNothing);
      expect(find.text('Order #1042'), findsOneWidget);
      expect(find.text('AC Maintenance'), findsOneWidget);
      expect(find.text('Ahmed K.'), findsOneWidget);
      expect(find.text('Allow location access'), findsOneWidget);
      expect(find.text('Confirm your location'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a provider card falls back to its person glyph', (
      tester,
    ) async {
      await pumpNodes(tester, [
        {
          'type': 'provider_card',
          'id': 'pc',
          'providerId': 'prv_1',
          'name': 'Ahmed K.',
        },
      ]);

      expect(find.byIcon(Icons.person_outline_rounded), findsOneWidget);
    });

    testWidgets('an explicit null pair is the same as an absent image', (
      tester,
    ) async {
      await pumpNodes(tester, [
        {
          'type': 'service_card',
          'id': 'sc',
          'serviceId': 'svc_1',
          'title': 'AC Maintenance',
          'image': <String, dynamic>{'url': null, 'assetId': null},
        },
      ]);

      expect(find.text('AC Maintenance'), findsOneWidget);
      expect(find.byType(AppNetworkImage), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('the protocol cannot carry a local path', () {
    testWidgets('not through url, not through assetId', (tester) async {
      // The renderer never sees a path: `assetId` is matched against the
      // host's published catalog, and a non-https `url` is refused. There is
      // no field in which `assets/…` or `packages/…` means anything.
      for (final image in <Map<String, dynamic>>[
        {'url': 'assets/images/secret.png'},
        {'url': 'file:///data/data/com.sanad.client/secret.png'},
        {'assetId': 'assets/images/secret.png'},
        {'assetId': 'packages/app_assets/assets/images/logo.png'},
      ]) {
        await pumpNodes(tester, [
          <String, dynamic>{
            'type': 'image',
            'id': 'im',
            ...image,
            'alt': 'AC unit',
          },
          {'type': 'text', 'id': 't', 'text': 'reply continues'},
        ]);

        expect(find.byType(AppNetworkImage), findsNothing, reason: '$image');
        expect(_assetPaths(tester), isEmpty, reason: '$image');
        expect(find.text('reply continues'), findsOneWidget, reason: '$image');
      }
    });
  });
}

/// Asset paths actually drawn, ignoring the design system's own placeholder.
///
/// `AppNetworkImage` renders `AppImagePlaceholder` while a download fails,
/// which is itself an asset image — so counting `Image` widgets would conflate
/// "the protocol's asset rendered" with "the network fallback rendered".
List<String> _assetPaths(WidgetTester tester) => tester
    .widgetList<Image>(find.byType(Image))
    .map((widget) => widget.image)
    .whereType<AssetImage>()
    .map((provider) => provider.assetName)
    .where((name) => !name.contains('placeholder'))
    .toList();
