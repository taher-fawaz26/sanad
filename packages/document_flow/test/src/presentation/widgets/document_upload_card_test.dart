import 'package:asset_picker/asset_picker.dart';
import 'package:design_system/design_system.dart';
import 'package:document_flow/document_flow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:testing/testing.dart';

/// Wraps the card in a [Scaffold] + scroll view — the card's raw content can
/// exceed the default test viewport, and [pumpDsWidget] otherwise puts it
/// directly under [MaterialApp] with no bounded/scrollable ancestor.
Widget _wrap(Widget card) => Scaffold(body: SingleChildScrollView(child: card));

void main() {
  const asset = PickedAsset(
    name: 'trade-license.jpg',
    path: '/tmp/trade-license.jpg',
    mimeType: 'image/jpeg',
    size: 2048,
    assetType: AssetType.image,
  );

  const labels = DocumentUploadCardLabels(
    chooseUpload: 'Choose how to upload',
    chooseUploadHint: 'Capture, scan, or select',
    uploading: 'Uploading...',
    uploadFailed: 'Upload failed',
    replaceDocument: 'Replace',
    removeDocument: 'Remove',
    upload: 'Upload',
    retryUpload: 'Retry',
    checkingDocument: 'Checking document...',
  );

  testWidgets(
    'renders the checking-document state while the slot is validating, '
    'not the Replace/Remove actions',
    (tester) async {
      final uploadable = asset.toUploadable().markValidating();

      await pumpDsWidget(
        tester,
        _wrap(
          DocumentUploadCard(
            title: 'Trade License',
            labels: labels,
            uploadable: uploadable,
            onUpload: () {},
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Checking document...'), findsOneWidget);
      expect(find.text('Replace'), findsNothing);
      expect(find.text('Remove'), findsNothing);
    },
  );

  testWidgets(
    'the Upload button is disabled while validating',
    (tester) async {
      final uploadable = asset.toUploadable().markValidating();

      await pumpDsWidget(
        tester,
        _wrap(
          DocumentUploadCard(
            title: 'Trade License',
            labels: labels,
            uploadable: uploadable,
            onUpload: () {},
          ),
        ),
      );
      await tester.pump();

      final button = tester.widget<AppButton>(find.byType(AppButton));
      expect(button.onPressed, isNull);
    },
  );

  group(
    'a prefilled slot (renewal resuming with an already-stored document)',
    () {
      const prefilled = PickedAsset(
        name: 'trade-license.png',
        path: '',
        mimeType: 'image/png',
        size: 0,
        assetType: AssetType.image,
      );

      testWidgets(
        'renders a network image from the remote URL, not a blank box',
        (tester) async {
          final uploadable = prefilled.toUploadable().markUploaded(
            remoteId: 'media-1',
            remoteUrl: 'https://cdn.example.com/trade-license.png',
          );

          await pumpDsWidget(
            tester,
            _wrap(
              DocumentUploadCard(
                title: 'Trade License',
                labels: labels,
                uploadable: uploadable,
                onUpload: () {},
              ),
            ),
          );
          await tester.pump();

          expect(find.byType(AppNetworkImage), findsOneWidget);
        },
      );

      testWidgets(
        'hides the size line instead of showing a fabricated "0 KB" — the '
        "backend never reports a stored document's byte size",
        (tester) async {
          final uploadable = prefilled.toUploadable().markUploaded(
            remoteId: 'media-1',
            remoteUrl: 'https://cdn.example.com/trade-license.png',
          );

          await pumpDsWidget(
            tester,
            _wrap(
              DocumentUploadCard(
                title: 'Trade License',
                labels: labels,
                uploadable: uploadable,
                onUpload: () {},
              ),
            ),
          );
          await tester.pump();

          expect(find.textContaining('KB'), findsNothing);
          expect(find.textContaining('MB'), findsNothing);
        },
      );
    },
  );

  testWidgets(
    'a real locally-picked upload still shows its real size — the '
    'prefilled-only fix must not hide it for a genuine upload',
    (tester) async {
      final uploadable = asset.toUploadable().markUploaded(
        remoteId: 'media-1',
        remoteUrl: 'https://cdn.example.com/x.jpg',
      );

      await pumpDsWidget(
        tester,
        _wrap(
          DocumentUploadCard(
            title: 'Trade License',
            labels: labels,
            uploadable: uploadable,
            onUpload: () {},
          ),
        ),
      );
      await tester.pump();

      expect(find.textContaining('KB'), findsOneWidget);
    },
  );
}
