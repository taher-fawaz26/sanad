import 'dart:typed_data';

import 'package:asset_picker/asset_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:testing/testing.dart';

const _pdf = PickedAsset(
  name: 'contract.pdf',
  path: '/tmp/contract.pdf',
  mimeType: 'application/pdf',
  size: 2048,
  assetType: AssetType.pdf,
);

void main() {
  group('AssetPreviewContent', () {
    testWidgets('shows a document card with name for non-image assets', (
      tester,
    ) async {
      await pumpDsWidget(tester, const AssetPreviewContent(asset: _pdf));

      expect(find.text('contract.pdf'), findsOneWidget);
      expect(find.byType(AssetThumbnail), findsOneWidget);
      expect(find.byType(InteractiveViewer), findsNothing);
    });

    testWidgets('shows an Open action only when onOpen is provided', (
      tester,
    ) async {
      var opened = false;
      await pumpDsWidget(
        tester,
        AssetPreviewContent(
          asset: _pdf,
          openLabel: 'Open file',
          onOpen: (_) => opened = true,
        ),
      );

      final openButton = find.text('Open file');
      expect(openButton, findsOneWidget);
      await tester.tap(openButton);
      expect(opened, isTrue);
    });

    testWidgets('uses an interactive image view for image assets', (
      tester,
    ) async {
      final image = PickedAsset(
        name: 'p.jpg',
        path: '',
        bytes: Uint8List.fromList([1, 2, 3]),
        mimeType: 'image/jpeg',
        size: 3,
        assetType: AssetType.image,
      );

      await pumpDsWidget(tester, AssetPreviewContent(asset: image));

      expect(find.byType(InteractiveViewer), findsOneWidget);
    });

    testWidgets('previewBuilder overrides non-image rendering', (tester) async {
      await pumpDsWidget(
        tester,
        AssetPreviewContent(
          asset: _pdf,
          previewBuilder: (_, _) => const Text('custom-pdf'),
        ),
      );

      expect(find.text('custom-pdf'), findsOneWidget);
      expect(find.byType(AssetThumbnail), findsNothing);
    });
  });

  group('AssetPreviewDialog', () {
    testWidgets('renders the asset name in its header', (tester) async {
      await pumpDsWidget(tester, const AssetPreviewDialog(asset: _pdf));
      expect(find.text('contract.pdf'), findsWidgets);
    });
  });
}
