import 'package:asset_picker/asset_picker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const asset = PickedAsset(
    name: 'a.pdf',
    path: '/tmp/a.pdf',
    mimeType: 'application/pdf',
    size: 10,
    assetType: AssetType.pdf,
  );

  test('cancelled result is empty and has no source', () {
    const result = AssetPickerResult.cancelled();
    expect(result.cancelled, isTrue);
    expect(result.isEmpty, isTrue);
    expect(result.hasAssets, isFalse);
    expect(result.single, isNull);
    expect(result.source, isNull);
  });

  test('success result exposes assets and source', () {
    const result = AssetPickerResult.success(
      assets: [asset],
      source: AssetSource.files,
    );
    expect(result.cancelled, isFalse);
    expect(result.hasAssets, isTrue);
    expect(result.single, asset);
    expect(result.source, AssetSource.files);
  });
}
