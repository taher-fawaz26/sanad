import 'package:asset_picker/asset_picker.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:services/src/presentation/utils/service_image_picker_options.dart';

PickedAsset _imageOfSize(int size) => PickedAsset(
  name: 'photo.jpg',
  path: '/tmp/photo.jpg',
  mimeType: 'image/jpeg',
  size: size,
  assetType: AssetType.image,
);

void main() {
  group('serviceImagePickerOptions', () {
    test(
      'keeps compression ENABLED but defers it until after the size check '
      '(SAN-576) — compressImages stays true',
      () {
        final options = serviceImagePickerOptions(remaining: 3);

        expect(options.compressImages, isTrue);
        expect(options.shouldCompress, isTrue);
        expect(options.enforceSizeBeforeCompression, isTrue);
        // Acquisition returns the original; compression runs afterwards.
        expect(options.compressAtAcquisition, isFalse);
        expect(options.compressAfterValidation, isTrue);
      },
    );

    test('caps each file at the app-wide 5 MB ceiling', () {
      final options = serviceImagePickerOptions(remaining: 3);

      expect(options.maxFileSize, FileSizePolicy.maxBytes);
    });

    test('bounds a multi-select batch to the remaining free slots', () {
      final options = serviceImagePickerOptions(remaining: 2);

      expect(options.allowMultiple, isTrue);
      expect(options.maxSelection, 2);
      expect(options.effectiveMaxSelection, 2);
    });

    test('offers gallery/camera only — never the file browser', () {
      final options = serviceImagePickerOptions(remaining: 6);

      expect(options.allowFiles, isFalse);
    });

    group('the 5 MB rule is enforced on the ORIGINAL selected file', () {
      const validator = DefaultAssetValidator();

      test(
        'a ~7 MB original is rejected — even though compression would shrink '
        'it below 5 MB — because these options defer compression past '
        'validation (SAN-576)',
        () {
          final sevenMb = _imageOfSize(7 * 1024 * 1024);

          final errors = validator.validate(
            [sevenMb],
            serviceImagePickerOptions(remaining: 6),
          );

          expect(
            errors.map((e) => e.type),
            contains(AssetValidationErrorType.fileTooLarge),
          );
        },
      );

      test('a 5 MB-or-smaller original passes validation', () {
        final fiveMb = _imageOfSize(5 * 1024 * 1024);

        final errors = validator.validate(
          [fiveMb],
          serviceImagePickerOptions(remaining: 6),
        );

        expect(errors, isEmpty);
      });
    });
  });
}
