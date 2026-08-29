import 'package:asset_picker/asset_picker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AssetPickerOptions', () {
    test('defaults describe a single-image single-selection pick', () {
      const options = AssetPickerOptions();
      expect(options.allowMultiple, isFalse);
      expect(options.effectiveMaxSelection, 1);
      expect(options.shouldCompress, isTrue);
      expect(options.hasAnySource, isTrue);
    });

    test('effectiveMaxSelection collapses to 1 when not multiple', () {
      const options = AssetPickerOptions(maxSelection: 5);
      expect(options.effectiveMaxSelection, 1);
    });

    test('effectiveMaxSelection honours maxSelection when multiple', () {
      const options = AssetPickerOptions(allowMultiple: true, maxSelection: 5);
      expect(options.effectiveMaxSelection, 5);
    });

    test('hasSingleSource detects exactly one enabled source', () {
      const options = AssetPickerOptions(
        allowGallery: false,
        allowFiles: false,
      );
      expect(options.hasSingleSource, isTrue);
    });

    group('resolvedAllowedExtensions', () {
      test('is null when unconstrained', () {
        expect(const AssetPickerOptions().resolvedAllowedExtensions, isNull);
      });

      test('normalises explicit extensions', () {
        const options = AssetPickerOptions(
          allowedExtensions: ['.PDF', 'Png'],
        );
        expect(options.resolvedAllowedExtensions, {'pdf', 'png'});
      });

      test('merges asset-type default extensions', () {
        const options = AssetPickerOptions(
          allowedAssetTypes: [AssetType.pdf],
          allowedExtensions: ['png'],
        );
        expect(options.resolvedAllowedExtensions, containsAll(['pdf', 'png']));
      });

      test('ignores AssetType.any', () {
        const options = AssetPickerOptions(allowedAssetTypes: [AssetType.any]);
        expect(options.resolvedAllowedExtensions, isNull);
      });
    });

    test('copyWith overrides only provided fields', () {
      const base = AssetPickerOptions();
      final updated = base.copyWith(allowMultiple: true, maxSelection: 3);
      expect(updated.allowMultiple, isTrue);
      expect(updated.maxSelection, 3);
      expect(updated.allowCamera, base.allowCamera);
    });

    group('enforceSizeBeforeCompression', () {
      test('defaults to off — compression happens at acquisition', () {
        const options = AssetPickerOptions();
        expect(options.enforceSizeBeforeCompression, isFalse);
        expect(options.compressAtAcquisition, isTrue);
        expect(options.compressAfterValidation, isFalse);
      });

      test(
        'when set, defers compression to after validation without disabling '
        'it',
        () {
          const options = AssetPickerOptions(
            enforceSizeBeforeCompression: true,
          );
          // compressImages is still on — compression is deferred, not removed.
          expect(options.shouldCompress, isTrue);
          expect(options.compressAtAcquisition, isFalse);
          expect(options.compressAfterValidation, isTrue);
        },
      );

      test('compressAfterValidation is false when compression is off', () {
        const options = AssetPickerOptions(
          compressImages: false,
          enforceSizeBeforeCompression: true,
        );
        expect(options.compressAfterValidation, isFalse);
        expect(options.compressAtAcquisition, isFalse);
      });

      test('is carried through copyWith', () {
        const base = AssetPickerOptions();
        final updated = base.copyWith(enforceSizeBeforeCompression: true);
        expect(updated.enforceSizeBeforeCompression, isTrue);
        expect(base.enforceSizeBeforeCompression, isFalse);
      });
    });
  });
}
