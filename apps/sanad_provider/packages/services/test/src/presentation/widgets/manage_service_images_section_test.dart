// No EasyLocalization bootstrap (avoids a real SharedPreferences hang in this
// sandboxed test environment) — `.tr()` calls fall back to the raw key.

import 'package:asset_picker/asset_picker.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:media_upload/media_upload.dart';
import 'package:mocktail/mocktail.dart';
import 'package:services/src/domain/entities/category_ref_entity.dart';
import 'package:services/src/domain/entities/provider_service_entity.dart';
import 'package:services/src/domain/entities/provider_service_image_entity.dart';
import 'package:services/src/domain/entities/provider_service_status.dart';
import 'package:services/src/domain/repositories/provider_services_repository.dart';
import 'package:services/src/domain/usecases/add_provider_service_image_usecase.dart';
import 'package:services/src/domain/usecases/delete_provider_service_image_usecase.dart';
import 'package:services/src/domain/usecases/set_primary_provider_service_image_usecase.dart';
import 'package:services/src/presentation/widgets/manage_service_images_section.dart';
import 'package:services/src/presentation/widgets/service_image_card.dart';

class _MockRepository extends Mock implements ProviderServicesRepository {}

class _MockMediaUploadRepository extends Mock
    implements MediaUploadRepository {}

const _serverFailure = ServerFailure(message: 'boom');

ProviderServiceEntity _service({
  String id = 'svc-1',
  List<ProviderServiceImageEntity> images = const [],
}) => ProviderServiceEntity(
  id: id,
  serviceId: 'catalog-1',
  serviceName: 'Wash Car',
  category: const CategoryRefEntity(
    id: 'cat-1',
    name: 'Car',
    description: null,
  ),
  description: 'desc',
  status: ProviderServiceStatus.active,
  images: images,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

PickedAsset _asset({String name = 'photo.jpg'}) => PickedAsset(
  name: name,
  path: '/tmp/$name',
  mimeType: 'image/jpeg',
  size: 1024,
  assetType: AssetType.image,
);

void main() {
  late _MockRepository repository;
  late _MockMediaUploadRepository uploadRepository;
  late MediaUploadBloc mediaUploadBloc;

  setUpAll(() {
    registerFallbackValue(_asset());
  });

  setUp(() {
    repository = _MockRepository();
    uploadRepository = _MockMediaUploadRepository();

    sl
      ..registerLazySingleton<AddProviderServiceImageUseCase>(
        () => AddProviderServiceImageUseCase(repository),
      )
      ..registerLazySingleton<DeleteProviderServiceImageUseCase>(
        () => DeleteProviderServiceImageUseCase(repository),
      )
      ..registerLazySingleton<SetPrimaryProviderServiceImageUseCase>(
        () => SetPrimaryProviderServiceImageUseCase(repository),
      );
  });

  tearDown(() async {
    await mediaUploadBloc.close();
    sl
      ..unregister<AddProviderServiceImageUseCase>()
      ..unregister<DeleteProviderServiceImageUseCase>()
      ..unregister<SetPrimaryProviderServiceImageUseCase>();
  });

  // `ServiceImageCard`'s failure-state row overflows at this test's viewport
  // when rendered with raw (untranslated) fallback keys standing in for
  // "Failed"/"Retry" — this suite deliberately skips the EasyLocalization
  // bootstrap (see the file-top note), so those keys are always longer than
  // the real short translations. Pre-existing layout issue in a shared
  // widget, unrelated to the attach logic under test here — drain the
  // resulting overflow `FlutterError`s so they don't fail otherwise-passing
  // assertions.
  void drainOverflowExceptions(WidgetTester tester) {
    while (tester.takeException() != null) {}
  }

  Future<void> pump(
    WidgetTester tester,
    ProviderServiceEntity service, {
    required ValueChanged<ProviderServiceEntity> onServiceUpdated,
  }) async {
    // The image-menu/confirmation sheets can exceed the default (small)
    // test surface — use a realistic device-sized surface instead, same
    // fix as `add_service_form_body_test.dart`.
    await tester.binding.setSurfaceSize(const Size(1080, 2400));
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    // Constructed here (inside the test body's own call stack) rather than
    // in `setUp` — a `MediaUploadBloc` built from `setUp`'s callback never
    // delivers its stream to widgets subscribed later in the same test,
    // under `flutter_test`'s FakeAsync test zone. Symptom: `BlocConsumer`'s
    // `listener` silently never fires for any state emitted after the
    // widget subscribes, even though `bloc.state`/a freshly-attached
    // listener both see it immediately. Constructing the bloc from code
    // reached via the test body (as here) avoids it entirely.
    mediaUploadBloc = MediaUploadBloc(
      repository: uploadRepository,
      config: const MediaUploadConfig(maxFiles: 6),
    );

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(360, 800),
        minTextAdapt: true,
        builder: (_, _) => MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: BlocProvider<MediaUploadBloc>.value(
              value: mediaUploadBloc,
              child: SingleChildScrollView(
                child: ManageServiceImagesSection(
                  service: service,
                  onServiceUpdated: onServiceUpdated,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  group('committed images — delete/set-primary use the image row id', () {
    testWidgets(
      'Set Main calls setPrimaryImage with the image ROW id, never mediaId',
      (tester) async {
        const image = ProviderServiceImageEntity(
          id: 'row-1',
          mediaId: 'media-xyz',
          url: '',
          isPrimary: false,
        );
        final updated = _service(images: [image]);
        when(
          () => repository.setPrimaryImage(id: 'svc-1', imageId: 'row-1'),
        ).thenAnswer((_) => TaskEither.of(updated));

        var received = updated;
        await pump(
          tester,
          _service(images: [image]),
          onServiceUpdated: (s) => received = s,
        );

        await tester.tap(find.byType(InkWell).first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('services.image_menu_set_main'));
        await tester.pumpAndSettle();

        verify(
          () => repository.setPrimaryImage(id: 'svc-1', imageId: 'row-1'),
        ).called(1);
        verifyNever(
          () => repository.setPrimaryImage(
            id: any(named: 'id'),
            imageId: 'media-xyz',
          ),
        );
        expect(received, updated);
      },
    );

    testWidgets(
      'Delete confirms then calls deleteImage with the image ROW id',
      (tester) async {
        const image = ProviderServiceImageEntity(
          id: 'row-1',
          mediaId: 'media-xyz',
          url: '',
          isPrimary: true,
        );
        final updated = _service();
        when(
          () => repository.deleteImage(id: 'svc-1', imageId: 'row-1'),
        ).thenAnswer((_) => TaskEither.of(updated));

        var received = _service(images: [image]);
        await pump(
          tester,
          _service(images: [image]),
          onServiceUpdated: (s) => received = s,
        );

        await tester.tap(find.byType(InkWell).first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('common.delete'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('services.delete_image_confirm_action'));
        await tester.pumpAndSettle();

        verify(
          () => repository.deleteImage(id: 'svc-1', imageId: 'row-1'),
        ).called(1);
        expect(received, updated);
      },
    );

    testWidgets('a failed delete preserves the image (snackbar shown)', (
      tester,
    ) async {
      const image = ProviderServiceImageEntity(
        id: 'row-1',
        mediaId: 'media-xyz',
        url: '',
        isPrimary: true,
      );
      when(
        () => repository.deleteImage(id: 'svc-1', imageId: 'row-1'),
      ).thenAnswer((_) => TaskEither.left(_serverFailure));

      var updateCount = 0;
      await pump(
        tester,
        _service(images: [image]),
        onServiceUpdated: (_) => updateCount++,
      );

      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('common.delete'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('services.delete_image_confirm_action'));
      await tester.pumpAndSettle();

      expect(updateCount, 0);
    });
  });

  // These tests seed already-resolved `MediaUploadItem`s via
  // `MediaUploadExistingItemsSeeded` instead of driving a real upload
  // through the mocked `MediaUploadRepository` — same rationale as
  // `add_service_form_body_test.dart`: it exercises this widget's own
  // attach wiring (which mediaId/ID it uses, how it reacts to success vs
  // failure) without re-testing `MediaUploadBloc`'s own upload/retry
  // machinery, which already has its own coverage in
  // `media_upload_bloc_test.dart`.
  group('add flow — upload then attach, using the mediaId (not row id)', () {
    testWidgets(
      'a successfully-uploaded item is attached with its mediaId, and the '
      'returned service is folded in',
      (tester) async {
        when(
          () => repository.addImage(id: 'svc-1', mediaId: 'media-new'),
        ).thenAnswer((_) => TaskEither.of(_service()));

        ProviderServiceEntity? received;
        await pump(
          tester,
          _service(),
          onServiceUpdated: (s) => received = s,
        );

        mediaUploadBloc.add(
          MediaUploadExistingItemsSeeded([
            MediaUploadItem.remote(mediaId: 'media-new', url: ''),
          ]),
        );
        await tester.pumpAndSettle();

        verify(
          () => repository.addImage(id: 'svc-1', mediaId: 'media-new'),
        ).called(1);
        expect(received, _service());
      },
    );

    testWidgets(
      'an item still uploading/failed is never attached',
      (tester) async {
        await pump(tester, _service(), onServiceUpdated: (_) {});

        mediaUploadBloc.add(
          const MediaUploadExistingItemsSeeded([
            MediaUploadItem(
              localId: 'local-1',
              asset: PickedAsset(
                name: 'photo.jpg',
                path: '/tmp/photo.jpg',
                mimeType: 'image/jpeg',
                size: 1024,
                assetType: AssetType.image,
              ),
              status: MediaUploadStatus.failure,
              failure: UploadRequestFailure('boom'),
            ),
          ]),
        );
        await tester.pumpAndSettle();
        drainOverflowExceptions(tester);

        verifyNever(
          () => repository.addImage(
            id: any(named: 'id'),
            mediaId: any(named: 'mediaId'),
          ),
        );
        expect(find.byType(ServiceImageCard), findsOneWidget);
      },
    );

    testWidgets(
      'attach failure never re-uploads; retry only re-calls addImage',
      (tester) async {
        var attachAttempt = 0;
        when(
          () => repository.addImage(id: 'svc-1', mediaId: 'media-new'),
        ).thenAnswer((_) {
          attachAttempt++;
          return attachAttempt == 1
              ? TaskEither.left(_serverFailure)
              : TaskEither.of(_service());
        });

        await pump(tester, _service(), onServiceUpdated: (_) {});

        mediaUploadBloc.add(
          MediaUploadExistingItemsSeeded([
            MediaUploadItem.remote(mediaId: 'media-new', url: ''),
          ]),
        );
        await tester.pumpAndSettle();
        drainOverflowExceptions(tester);

        expect(attachAttempt, 1);
        verifyNever(
          () => uploadRepository.upload(
            uploadKey: any(named: 'uploadKey'),
            asset: any(named: 'asset'),
            onProgress: any(named: 'onProgress'),
          ),
        );

        // The failure-state row overflows at this test's viewport (see
        // `drainOverflowExceptions`), which pushes "Retry" outside its
        // hit-testable bounds — invoke the card's callback directly rather
        // than tapping raw (untranslated) text at an unreliable offset.
        tester
            .widget<ServiceImageCard>(find.byType(ServiceImageCard))
            .onRetry!();
        await tester.pumpAndSettle();
        drainOverflowExceptions(tester);

        expect(attachAttempt, 2);
        verifyNever(
          () => uploadRepository.upload(
            uploadKey: any(named: 'uploadKey'),
            asset: any(named: 'asset'),
            onProgress: any(named: 'onProgress'),
          ),
        );
      },
    );

    testWidgets(
      'partial batch: one image fully attaches while another fails at '
      'attach — the successful one is unaffected',
      (tester) async {
        when(
          () => repository.addImage(id: 'svc-1', mediaId: 'media-a'),
        ).thenAnswer((_) => TaskEither.of(_service()));
        when(
          () => repository.addImage(id: 'svc-1', mediaId: 'media-b'),
        ).thenAnswer((_) => TaskEither.left(_serverFailure));

        final updates = <ProviderServiceEntity>[];
        await pump(tester, _service(), onServiceUpdated: updates.add);

        mediaUploadBloc.add(
          MediaUploadExistingItemsSeeded([
            MediaUploadItem.remote(mediaId: 'media-a', url: ''),
            MediaUploadItem.remote(mediaId: 'media-b', url: ''),
          ]),
        );
        await tester.pumpAndSettle();
        drainOverflowExceptions(tester);

        verify(
          () => repository.addImage(id: 'svc-1', mediaId: 'media-a'),
        ).called(1);
        verify(
          () => repository.addImage(id: 'svc-1', mediaId: 'media-b'),
        ).called(1);
        expect(updates, [_service()]);
        // Only the still-failed item ("b") remains as a retryable tile.
        expect(find.byType(ServiceImageCard), findsOneWidget);
      },
    );
  });

  group('image limit', () {
    testWidgets('the add card is hidden once 6 images are committed', (
      tester,
    ) async {
      final images = [
        for (var i = 0; i < 6; i++)
          ProviderServiceImageEntity(
            id: 'row-$i',
            mediaId: 'media-$i',
            url: '',
            isPrimary: i == 0,
          ),
      ];

      await pump(
        tester,
        _service(images: images),
        onServiceUpdated: (_) {},
      );

      expect(find.byType(ServiceImageAddCard), findsNothing);
    });
  });
}
