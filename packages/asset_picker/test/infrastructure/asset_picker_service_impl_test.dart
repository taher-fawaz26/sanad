import 'package:asset_picker/asset_picker.dart';
import 'package:asset_picker/src/infrastructure/compression/asset_image_compressor.dart';
import 'package:asset_picker/src/infrastructure/services/asset_picker_service_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockCameraProvider extends Mock implements CameraProvider {}

class _MockGalleryProvider extends Mock implements GalleryProvider {}

class _MockFileProvider extends Mock implements FileProvider {}

PickedAsset _asset() => const PickedAsset(
  name: 'photo.jpg',
  path: '/tmp/photo.jpg',
  mimeType: 'image/jpeg',
  size: 100,
  assetType: AssetType.image,
);

void main() {
  setUpAll(() => registerFallbackValue(const AssetPickerOptions()));

  late _MockCameraProvider camera;
  late _MockGalleryProvider gallery;
  late _MockFileProvider file;

  setUp(() {
    camera = _MockCameraProvider();
    gallery = _MockGalleryProvider();
    file = _MockFileProvider();
  });

  AssetPickerServiceImpl build() => AssetPickerServiceImpl(
    cameraProvider: camera,
    galleryProvider: gallery,
    fileProvider: file,
  );

  test('returns success when a provider yields assets', () async {
    when(() => camera.capture(any())).thenAnswer((_) async => [_asset()]);

    final result = await build().pickCamera();

    expect(result.cancelled, isFalse);
    expect(result.source, AssetSource.camera);
    expect(result.single, _asset());
  });

  test('returns cancelled when a provider yields nothing', () async {
    when(() => gallery.pick(any())).thenAnswer((_) async => const []);

    final result = await build().pickGallery();

    expect(result.cancelled, isTrue);
    expect(result.isEmpty, isTrue);
  });

  test(
    'throws AssetSourceUnavailableException for an unregistered source',
    () async {
      // No scanner provider registered.
      expect(
        () => build().scanDocument(),
        throwsA(isA<AssetSourceUnavailableException>()),
      );
    },
  );

  test('throws AssetValidationException on validation failure', () async {
    when(() => file.pick(any())).thenAnswer(
      (_) async => const [
        PickedAsset(
          name: 'huge.jpg',
          path: '/tmp/huge.jpg',
          mimeType: 'image/jpeg',
          size: 10 * 1024 * 1024,
          assetType: AssetType.image,
        ),
      ],
    );

    const options = AssetPickerOptions(maxFileSize: 1024);
    expect(
      () => build().pickFile(options: options),
      throwsA(isA<AssetValidationException>()),
    );
  });

  test('respects a custom validator', () async {
    when(() => camera.capture(any())).thenAnswer((_) async => [_asset()]);

    final service = AssetPickerServiceImpl(
      cameraProvider: camera,
      validator: const _RejectingValidator(),
    );

    expect(
      service.pickCamera,
      throwsA(isA<AssetValidationException>()),
    );
  });

  group('deferred compression (enforceSizeBeforeCompression)', () {
    late _SpyCompressor compressor;

    AssetPickerServiceImpl buildWithCompressor() => AssetPickerServiceImpl(
      cameraProvider: camera,
      galleryProvider: gallery,
      fileProvider: file,
      compressor: compressor,
    );

    setUp(() => compressor = _SpyCompressor());

    test(
      'does NOT compress by default — the provider already compressed at '
      'acquisition',
      () async {
        when(() => camera.capture(any())).thenAnswer((_) async => [_asset()]);

        final result = await buildWithCompressor().pickCamera();

        expect(compressor.calls, 0);
        expect(result.single, _asset());
      },
    );

    test(
      'validation runs BEFORE compression — an oversized original is rejected '
      'and never reaches the compressor (SAN-576)',
      () async {
        when(() => gallery.pick(any())).thenAnswer(
          (_) async => const [
            PickedAsset(
              name: 'huge.jpg',
              path: '/tmp/huge.jpg',
              mimeType: 'image/jpeg',
              size: 7 * 1024 * 1024,
              assetType: AssetType.image,
            ),
          ],
        );

        await expectLater(
          buildWithCompressor().pickGallery(
            options: const AssetPickerOptions(
              maxFileSize: 5 * 1024 * 1024,
              enforceSizeBeforeCompression: true,
            ),
          ),
          throwsA(isA<AssetValidationException>()),
        );
        expect(compressor.calls, 0);
      },
    );

    test(
      'a valid original IS compressed after validation, and the compressed '
      'asset is what gets delivered',
      () async {
        when(() => gallery.pick(any())).thenAnswer((_) async => [_asset()]);

        final result = await buildWithCompressor().pickGallery(
          options: const AssetPickerOptions(
            maxFileSize: 5 * 1024 * 1024,
            enforceSizeBeforeCompression: true,
          ),
        );

        expect(compressor.calls, 1);
        expect(result.assets.single.name, 'compressed.jpg');
      },
    );
  });
}

/// Records how many assets it was asked to compress and returns a marker so the
/// test can prove the compressed output (not the original) is delivered.
class _SpyCompressor implements AssetImageCompressor {
  int calls = 0;

  @override
  Future<PickedAsset> compress(
    PickedAsset asset, {
    required int quality,
  }) async {
    calls++;
    return asset.copyWith(name: 'compressed.jpg', mimeType: 'image/jpeg');
  }
}

class _RejectingValidator implements AssetValidator {
  const _RejectingValidator();

  @override
  List<AssetValidationError> validate(
    List<PickedAsset> assets,
    AssetPickerOptions options,
  ) => const [
    AssetValidationError(
      type: AssetValidationErrorType.assetTypeNotAllowed,
      message: 'rejected',
    ),
  ];
}
