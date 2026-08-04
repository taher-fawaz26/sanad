import 'dart:typed_data';

import 'package:asset_picker/asset_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:media/src/config/media_picker_config.dart';
import 'package:media/src/models/media_validation_error.dart';
import 'package:media/src/validation/media_validator.dart';

void main() {
  final validPng = Uint8List.fromList(
    img.encodePng(img.Image(width: 4, height: 4)),
  );

  PickedAsset asset({
    AssetType type = AssetType.image,
    String mime = 'image/png',
    int size = 1024,
    Uint8List? bytes,
  }) => PickedAsset(
    name: 'photo.png',
    path: '/tmp/photo.png',
    mimeType: mime,
    size: size,
    assetType: type,
    bytes: bytes ?? validPng,
  );

  const config = MediaPickerConfig(maxFileSize: 10 * 1024);

  test('accepts a valid image', () {
    expect(MediaValidator.validate(asset(), config), isNull);
  });

  test('rejects a non-image asset type', () {
    expect(
      MediaValidator.validate(asset(type: AssetType.video), config),
      MediaValidationError.unsupportedType,
    );
  });

  test('rejects a non-image mime type', () {
    expect(
      MediaValidator.validate(asset(mime: 'application/pdf'), config),
      MediaValidationError.unsupportedType,
    );
  });

  test('rejects an oversized file', () {
    expect(
      MediaValidator.validate(asset(size: 20 * 1024), config),
      MediaValidationError.tooLarge,
    );
  });

  test('rejects undecodable bytes', () {
    expect(
      MediaValidator.validate(
        asset(bytes: Uint8List.fromList([0, 1, 2, 3])),
        config,
      ),
      MediaValidationError.corrupted,
    );
  });
}
