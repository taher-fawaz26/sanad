import 'package:asset_picker/asset_picker.dart';
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
