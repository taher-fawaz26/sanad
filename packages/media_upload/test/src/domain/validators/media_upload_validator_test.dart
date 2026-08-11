import 'package:asset_picker/asset_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:media_upload/media_upload.dart';

PickedAsset _asset({
  String name = 'photo.jpg',
  String mimeType = 'image/jpeg',
  int size = 1024,
}) => PickedAsset(
  name: name,
  path: '/tmp/$name',
  mimeType: mimeType,
  size: size,
  assetType: AssetType.image,
);

void main() {
  group('MediaUploadValidator.validateAsset', () {
    test('allows a file within every configured limit', () {
      final failure = MediaUploadValidator.validateAsset(
        asset: _asset(),
        config: const MediaUploadConfig(
          maxFiles: 5,
          maxFileSize: 2048,
          allowedMimeTypes: ['image/jpeg'],
          allowedExtensions: ['jpg'],
        ),
        currentCount: 1,
      );

      expect(failure, isNull);
    });

    test('rejects when currentCount already reached maxFiles', () {
      final failure = MediaUploadValidator.validateAsset(
        asset: _asset(),
        config: const MediaUploadConfig(maxFiles: 3),
        currentCount: 3,
      );

      expect(failure, isA<MaxFilesExceededFailure>());
    });

    test('rejects a file larger than maxFileSize', () {
      final failure = MediaUploadValidator.validateAsset(
        asset: _asset(size: 5000),
        config: const MediaUploadConfig(maxFileSize: 1000),
        currentCount: 0,
      );

      expect(failure, isA<FileTooLargeFailure>());
    });

    test('rejects a disallowed MIME type', () {
      final failure = MediaUploadValidator.validateAsset(
        asset: _asset(mimeType: 'application/pdf'),
        config: const MediaUploadConfig(allowedMimeTypes: ['image/jpeg']),
        currentCount: 0,
      );

      expect(failure, isA<UnsupportedTypeFailure>());
    });

    test('rejects a disallowed extension', () {
      final failure = MediaUploadValidator.validateAsset(
        asset: _asset(name: 'doc.pdf'),
        config: const MediaUploadConfig(allowedExtensions: ['jpg', 'png']),
        currentCount: 0,
      );

      expect(failure, isA<UnsupportedTypeFailure>());
    });

    test('an empty allow-list means any MIME type/extension is accepted', () {
      final failure = MediaUploadValidator.validateAsset(
        asset: _asset(mimeType: 'application/pdf', name: 'doc.pdf'),
        config: const MediaUploadConfig(),
        currentCount: 0,
      );

      expect(failure, isNull);
    });
  });

  group('MediaUploadValidator.canAddMore', () {
    test('true when maxFiles is null', () {
      expect(
        MediaUploadValidator.canAddMore(
          config: const MediaUploadConfig(),
          currentCount: 999,
        ),
        isTrue,
      );
    });

    test('false once currentCount reaches maxFiles', () {
      expect(
        MediaUploadValidator.canAddMore(
          config: const MediaUploadConfig(maxFiles: 2),
          currentCount: 2,
        ),
        isFalse,
      );
    });
  });
}
