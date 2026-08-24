import 'package:flutter_test/flutter_test.dart';
import 'package:media/src/models/media_validation_error.dart';

void main() {
  group('MediaValidationError.messageKey', () {
    test(
      'tooLarge reuses the one shared "file too large" message — the same '
      'key every upload surface in the app resolves via FileSizePolicy, '
      'not a media-package-local copy of the same idea',
      () {
        expect(
          MediaValidationError.tooLarge.messageKey,
          'errors.media_upload.file_too_large',
        );
      },
    );

    test('unsupportedType and corrupted keep their own media.* keys', () {
      expect(
        MediaValidationError.unsupportedType.messageKey,
        'media.validation.unsupported_type',
      );
      expect(
        MediaValidationError.corrupted.messageKey,
        'media.validation.corrupted',
      );
    });
  });
}
