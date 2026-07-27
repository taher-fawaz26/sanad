import 'package:asset_picker/asset_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:testing/testing.dart';

PickedAsset _asset(AssetType type, {String name = 'file'}) => PickedAsset(
  name: name,
  path: '/tmp/$name',
  mimeType: 'application/octet-stream',
  size: 100,
  assetType: type,
);

void main() {
  group('AssetThumbnail', () {
    testWidgets('renders the PDF glyph for a pdf asset', (tester) async {
      await pumpDsWidget(
        tester,
        AssetThumbnail(asset: _asset(AssetType.pdf, name: 'a.pdf')),
      );

      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.icon, Icons.picture_as_pdf_outlined);
    });

    testWidgets('renders the document glyph for a document asset', (
      tester,
    ) async {
      await pumpDsWidget(
        tester,
        AssetThumbnail(asset: _asset(AssetType.document, name: 'a.docx')),
      );

      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.icon, Icons.description_outlined);
    });

    testWidgets('renders the generic glyph for an unknown asset', (
      tester,
    ) async {
      await pumpDsWidget(
        tester,
        AssetThumbnail(asset: _asset(AssetType.any, name: 'a.bin')),
      );

      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.icon, Icons.insert_drive_file_outlined);
    });

    testWidgets('honours a custom placeholder', (tester) async {
      await pumpDsWidget(
        tester,
        AssetThumbnail(
          asset: _asset(AssetType.pdf, name: 'a.pdf'),
          placeholder: const Text('PH'),
        ),
      );

      expect(find.text('PH'), findsOneWidget);
      expect(find.byType(Icon), findsNothing);
    });

    testWidgets('respects the requested size', (tester) async {
      await pumpDsWidget(
        tester,
        AssetThumbnail(asset: _asset(AssetType.any), size: 72),
      );

      final box = tester.widget<SizedBox>(
        find
            .descendant(
              of: find.byType(AssetThumbnail),
              matching: find.byType(SizedBox),
            )
            .first,
      );
      expect(box.width, 72);
      expect(box.height, 72);
    });
  });

  group('assetTypeGlyph', () {
    test('maps every AssetType to a glyph', () {
      for (final type in AssetType.values) {
        expect(assetTypeGlyph(type), isA<IconData>());
      }
    });
  });
}
