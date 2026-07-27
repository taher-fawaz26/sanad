import 'package:asset_picker/asset_picker.dart';
import 'package:flutter_test/flutter_test.dart';

PickedAsset _asset({
  String name = 'photo.jpg',
  int size = 1000,
  String mimeType = 'image/jpeg',
  AssetType type = AssetType.image,
}) {
  return PickedAsset(
    name: name,
    path: '/tmp/$name',
    mimeType: mimeType,
    size: size,
    assetType: type,
  );
}

void main() {
  const validator = DefaultAssetValidator();

  test('accepts a valid selection', () {
    final errors = validator.validate([_asset()], const AssetPickerOptions());
    expect(errors, isEmpty);
  });

  test('flags too many assets', () {
    final errors = validator.validate(
      [_asset(name: 'a.jpg'), _asset(name: 'b.jpg')],
      const AssetPickerOptions(allowMultiple: true, maxSelection: 2),
    );
    expect(errors, isEmpty);

    final tooMany = validator.validate(
      [_asset(name: 'a.jpg'), _asset(name: 'b.jpg'), _asset(name: 'c.jpg')],
      const AssetPickerOptions(allowMultiple: true, maxSelection: 2),
    );
    expect(
      tooMany.single.type,
      AssetValidationErrorType.tooManyAssets,
    );
  });

  test('flags oversized files with a descriptive message', () {
    final errors = validator.validate(
      [_asset(size: 5 * 1024 * 1024)],
      const AssetPickerOptions(maxFileSize: 1024 * 1024),
    );
    expect(errors.single.type, AssetValidationErrorType.fileTooLarge);
    expect(errors.single.message, contains('exceeds'));
  });

  test('flags disallowed extension', () {
    final errors = validator.validate(
      [_asset(name: 'note.txt', mimeType: 'text/plain')],
      const AssetPickerOptions(allowedExtensions: ['jpg', 'png']),
    );
    expect(errors.single.type, AssetValidationErrorType.extensionNotAllowed);
  });

  test('flags disallowed mime type', () {
    final errors = validator.validate(
      [_asset(mimeType: 'image/gif')],
      const AssetPickerOptions(allowedMimeTypes: ['image/jpeg']),
    );
    expect(errors.single.type, AssetValidationErrorType.mimeTypeNotAllowed);
  });

  test('flags disallowed asset type', () {
    final errors = validator.validate(
      [_asset(name: 'clip.mp4', mimeType: 'video/mp4', type: AssetType.video)],
      const AssetPickerOptions(
        allowedAssetTypes: [AssetType.image, AssetType.pdf],
        // Widen extensions so only the asset-type rule fires.
        allowedExtensions: ['mp4', 'jpg', 'jpeg', 'pdf'],
      ),
    );
    expect(
      errors.map((e) => e.type),
      contains(AssetValidationErrorType.assetTypeNotAllowed),
    );
  });

  test('accumulates multiple errors', () {
    final errors = validator.validate(
      [_asset(name: 'big.txt', size: 999999, mimeType: 'text/plain')],
      const AssetPickerOptions(
        maxFileSize: 100,
        allowedAssetTypes: [AssetType.image],
      ),
    );
    expect(errors.length, greaterThanOrEqualTo(2));
  });
}
