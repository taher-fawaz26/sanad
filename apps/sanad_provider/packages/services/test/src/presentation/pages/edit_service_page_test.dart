import 'dart:async';

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
import 'package:services/src/domain/usecases/get_provider_service_usecase.dart';
import 'package:services/src/domain/usecases/set_primary_provider_service_image_usecase.dart';
import 'package:services/src/domain/usecases/update_provider_service_description_usecase.dart';
import 'package:services/src/presentation/bloc/edit_service/edit_service_bloc.dart';
import 'package:services/src/presentation/bloc/service_details/service_details_bloc.dart';
import 'package:services/src/presentation/bloc/service_images/service_images_bloc.dart';
import 'package:services/src/presentation/pages/edit_service_page.dart';
import 'package:services/src/presentation/widgets/edit_service_form_body.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:text_optimization/text_optimization.dart';

// No EasyLocalization bootstrap (avoids a real SharedPreferences hang in this
// sandboxed test environment) — `.tr()` calls fall back to the raw key.

class _MockRepository extends Mock implements ProviderServicesRepository {}

class _MockMediaUploadRepository extends Mock
    implements MediaUploadRepository {}

class _MockTextOptimizationRepository extends Mock
    implements TextOptimizationRepository {}

// No committed images by default — keeps `ManageServiceImagesSection` on
// its empty-state (drop zone) path, matching the pattern established in
// `manage_service_images_section_test.dart`'s top comment: rendering
// committed images is subject to a documented, unresolved environment
// flake, so tests unrelated to image rendering avoid it deliberately.
ProviderServiceEntity _fetchedService({
  String id = 'svc-1',
  String description = 'Fetched description',
  List<ProviderServiceImageEntity> images = const [],
}) => ProviderServiceEntity(
  id: id,
  serviceId: 'catalog-1',
  serviceName: 'Wash Car (fetched)',
  category: const CategoryRefEntity(
    id: 'cat-1',
    name: 'Car',
    description: null,
  ),
  description: description,
  status: ProviderServiceStatus.active,
  images: images,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

void main() {
  late _MockRepository repository;
  late _MockMediaUploadRepository uploadRepository;
  ProviderServiceEntity? capturedServiceImagesBlocInitialService;

  setUp(() {
    repository = _MockRepository();
    uploadRepository = _MockMediaUploadRepository();
    capturedServiceImagesBlocInitialService = null;

    // `EditServicePage`'s success branch resolves these three blocs itself
    // via `sl<...>()` (they need the FETCHED entity, which only exists
    // after the async gap, so they can no longer be provided at the route
    // level — see the page's doc comment) — register fakes the same way
    // `add_service_navigation_test.dart` does for its own page-composed
    // blocs.
    sl
      ..registerFactory<EditServiceBloc>(
        () => EditServiceBloc(
          updateProviderServiceDescriptionUseCase:
              UpdateProviderServiceDescriptionUseCase(repository),
        ),
      )
      ..registerFactoryParam<MediaUploadBloc, MediaUploadConfig, void>(
        (config, _) =>
            MediaUploadBloc(repository: uploadRepository, config: config),
      )
      ..registerFactoryParam<ServiceImagesBloc, ProviderServiceEntity, void>(
        (initialService, _) {
          capturedServiceImagesBlocInitialService = initialService;
          return ServiceImagesBloc(
            addProviderServiceImageUseCase: AddProviderServiceImageUseCase(
              repository,
            ),
            deleteProviderServiceImageUseCase:
                DeleteProviderServiceImageUseCase(repository),
            setPrimaryProviderServiceImageUseCase:
                SetPrimaryProviderServiceImageUseCase(repository),
            initialService: initialService,
          );
        },
      )
      // `EditServiceFormBody`'s description field resolves a
      // `TextOptimizationCubit` from `sl` (SAN-578) — never tapped here,
      // but the widget still needs one registered to build.
      ..registerFactory<TextOptimizationCubit>(() {
        final textOptimizationRepository = _MockTextOptimizationRepository();
        when(
          () => textOptimizationRepository.optimize(any()),
        ).thenAnswer((_) => TaskEither.right(''));
        return TextOptimizationCubit(
          OptimizeTextUseCase(textOptimizationRepository),
        );
      });
  });

  tearDown(() {
    sl
      ..unregister<EditServiceBloc>()
      ..unregister<MediaUploadBloc>()
      ..unregister<ServiceImagesBloc>()
      ..unregister<TextOptimizationCubit>();
  });

  // `detailsBloc` is intentionally NOT built in `setUp` — a bloc
  // constructed there never delivers its stream to a widget subscribed
  // later in the same `testWidgets` body under `flutter_test`'s FakeAsync
  // zone. Building it from code reached via the test body itself (here,
  // `pump()`) avoids it — same precedent as `service_details_page_test.dart`.
  Future<ServiceDetailsBloc> pump(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1080, 2400));
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    // Same fix as `edit_service_form_body_test.dart`: the description
    // field's AppEnhanceWithAiButton runs a perpetual rainbow-border
    // animation that never settles on its own, which hangs
    // `pumpAndSettle()`; disabling animations stops its controller (it
    // checks `MediaQuery.disableAnimationsOf`).
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

    // EasyLocalization isn't bootstrapped in this harness, so `.tr()` falls
    // back to the raw key — longer than any real translation, which
    // overflows AppEnhanceWithAiButton's fixed-width pill. A byproduct of
    // the untranslated test key, not a real layout bug.
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exception.toString().contains('A RenderFlex overflowed')) {
        return;
      }
      originalOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = originalOnError);

    final detailsBloc = ServiceDetailsBloc(
      getProviderServiceUseCase: GetProviderServiceUseCase(repository),
    );
    addTearDown(() => detailsBloc.close());

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(360, 800),
        minTextAdapt: true,
        builder: (_, _) => MaterialApp(
          theme: AppTheme.light(),
          home: BlocProvider<ServiceDetailsBloc>.value(
            value: detailsBloc,
            child: const EditServicePage(serviceId: 'svc-1'),
          ),
        ),
      ),
    );

    return detailsBloc;
  }

  testWidgets(
    'fetches the service by id (GET /provider-services/:id) instead of '
    'trusting a passed-in entity — no `service` constructor param exists',
    (tester) async {
      when(
        () => repository.getProviderService('svc-1'),
      ).thenReturn(TaskEither.right(_fetchedService()));

      final detailsBloc = await pump(tester);
      detailsBloc.add(const ServiceDetailsFetchRequested('svc-1'));
      await tester.pump();
      await tester.pumpAndSettle();

      verify(() => repository.getProviderService('svc-1')).called(1);
      expect(find.text('Wash Car (fetched)'), findsWidgets);
      expect(find.text('Fetched description'), findsWidgets);
    },
  );

  testWidgets(
    'shows a loading skeleton — not the form — before the fetch resolves',
    (tester) async {
      // No repository stub, no fetch dispatched — `ServiceDetailsBloc`'s
      // own initial state (`status: initial`) already satisfies
      // `isLoading`, so the skeleton renders on mount, before any fetch is
      // even requested. Checked immediately with no further `pump()`.
      await pump(tester);

      expect(find.byType(EditServiceFormBody), findsNothing);
      expect(find.text('services.edit_service.save_button'), findsNothing);

      // The skeleton's shimmer (`AppSkeletonizer`) is a genuinely-repeating
      // animation — by design, since the fetch never resolves in this
      // test. Leaving it mounted with a live ticker when the test function
      // returns hangs the framework's own teardown (a still-running
      // ticker is a real, open async gap — not just an unconverged
      // `pumpAndSettle` loop). Unmount the tree first so its ticker is
      // disposed cleanly before teardown runs.
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'a failed fetch shows a retryable error state; retry re-fetches',
    (tester) async {
      var callCount = 0;
      when(() => repository.getProviderService('svc-1')).thenAnswer((_) {
        callCount++;
        return callCount == 1
            ? TaskEither.left(const ServerFailure(message: 'boom'))
            : TaskEither.right(_fetchedService());
      });

      final detailsBloc = await pump(tester);
      detailsBloc.add(const ServiceDetailsFetchRequested('svc-1'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byType(AppErrorState), findsOneWidget);
      expect(find.byType(EditServiceFormBody), findsNothing);

      final errorState = tester.widget<AppErrorState>(
        find.byType(AppErrorState),
      );
      errorState.onRetry?.call();
      await tester.pump();
      await tester.pumpAndSettle();

      expect(callCount, 2);
      expect(find.byType(EditServiceFormBody), findsOneWidget);
    },
  );

  testWidgets(
    'the full fetched image collection reaches ServiceImagesBloc — not a '
    'reconstructed subset',
    (tester) async {
      const images = [
        ProviderServiceImageEntity(
          id: 'row-1',
          mediaId: 'media-1',
          url: '',
          isPrimary: false,
        ),
        ProviderServiceImageEntity(
          id: 'row-2',
          mediaId: 'media-2',
          url: '',
          isPrimary: true,
        ),
        ProviderServiceImageEntity(
          id: 'row-3',
          mediaId: 'media-3',
          url: '',
          isPrimary: false,
        ),
      ];
      when(() => repository.getProviderService('svc-1')).thenReturn(
        TaskEither.right(_fetchedService(images: images)),
      );

      final detailsBloc = await pump(tester);
      detailsBloc.add(const ServiceDetailsFetchRequested('svc-1'));
      // Bounded — two pumps only (loading emission, then success emission)
      // to keep this within the pump budget that's held up reliably for
      // trees rendering committed images (see
      // `manage_service_images_section_test.dart`'s top comment); no
      // `pumpAndSettle()` here.
      await tester.pump();
      await tester.pump();

      expect(capturedServiceImagesBlocInitialService?.images, images);
      expect(
        capturedServiceImagesBlocInitialService?.images
            .where((i) => i.isPrimary)
            .single
            .id,
        'row-2',
      );
    },
  );

  testWidgets(
    'tapping Save dispatches EditServiceSubmittedEvent directly — no '
    'confirmation modal on normal save',
    (tester) async {
      when(
        () => repository.getProviderService('svc-1'),
      ).thenReturn(TaskEither.right(_fetchedService()));
      // Deliberately never resolves within this test — the assertion only
      // needs the bloc to have left its initial status by the very next
      // pump; letting the update actually complete would trigger
      // `EditServicePage`'s success handler, which calls `context.pop()`
      // via GoRouter (not wired up in this test's plain `MaterialApp`)
      // and is unrelated to what this test checks.
      final neverResolves = Completer<Either<Failure, ProviderServiceEntity>>();
      when(
        () => repository.updateProviderService(
          id: 'svc-1',
          description: 'Fetched description',
        ),
      ).thenAnswer((_) => TaskEither(() => neverResolves.future));

      final detailsBloc = await pump(tester);
      detailsBloc.add(const ServiceDetailsFetchRequested('svc-1'));
      await tester.pump();
      await tester.pumpAndSettle();

      await tester.tap(find.text('services.edit_service.save_button'));
      await tester.pump();

      // No confirmation copy anywhere on screen — the only confirmation
      // sheet this page ever shows is the back-navigation discard guard
      // (`services.discard_confirm_title`), and that must never appear
      // from tapping Save.
      expect(find.text('services.discard_confirm_title'), findsNothing);
      verify(
        () => repository.updateProviderService(
          id: 'svc-1',
          description: 'Fetched description',
        ),
      ).called(1);
    },
  );

  testWidgets(
    'PopScope.canPop is true with no unsaved changes (system swipe-back '
    'pops straight to Service Detail — SAN-581) and false once the '
    'description is edited (so the discard guard can intercept)',
    (tester) async {
      when(
        () => repository.getProviderService('svc-1'),
      ).thenReturn(TaskEither.right(_fetchedService()));

      final detailsBloc = await pump(tester);
      detailsBloc.add(const ServiceDetailsFetchRequested('svc-1'));
      await tester.pump();
      await tester.pumpAndSettle();

      final popScope = find.byWidgetPredicate((w) => w is PopScope<Object?>);
      expect(tester.widget<PopScope<Object?>>(popScope).canPop, isTrue);

      await tester.enterText(
        find.byType(TextField).first,
        'Unsaved edit',
      );
      await tester.pumpAndSettle();

      expect(tester.widget<PopScope<Object?>>(popScope).canPop, isFalse);

      await tester.enterText(
        find.byType(TextField).first,
        'Fetched description',
      );
      await tester.pumpAndSettle();

      expect(tester.widget<PopScope<Object?>>(popScope).canPop, isTrue);
    },
  );
}
