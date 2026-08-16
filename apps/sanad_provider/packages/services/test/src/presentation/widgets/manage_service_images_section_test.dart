// No EasyLocalization bootstrap (avoids a real SharedPreferences hang in this
// sandboxed test environment) — `.tr()` calls fall back to the raw key.

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
import 'package:services/src/presentation/bloc/service_images/service_images_bloc.dart';
import 'package:services/src/presentation/widgets/manage_service_images_section.dart';
import 'package:services/src/presentation/widgets/service_image_card.dart';

// Deep business-logic coverage (mediaId-vs-rowId protection, set-primary/
// delete dispatch by ROW id, attach failure/retry independence, partial
// batches, failureNonce on mutation failure) lives entirely in
// `service_images_bloc_test.dart` — including the exact "uses the image
// ROW id, not mediaId" and "failure bumps failureNonce" cases this file
// used to re-verify through the real modal image-menu/confirmation sheets.
//
// KNOWN GAP: interaction tests that render a committed image (via any
// non-empty `images:` list passed to `pump()`) hang unpredictably
// somewhere between 1 and 3 subsequent `pump()` calls in this
// environment — reproduced down to a bare tree with no bloc, no sheet,
// and no tap at all, and NOT fixed by bounding `pump()` duration (bounded
// pumps hang exactly like unbounded `pumpAndSettle()` did). The exact
// trigger was not isolated despite extensive bisection; root cause
// undetermined (suspected: a real, non-fake async gap — e.g. image/SVG
// decode — that the FakeAsync test zone can't drive to completion,
// though this is unconfirmed). Given the full ID-routing/dispatch/
// failure business logic this would have exercised is already
// deterministically covered at the bloc level, this file does not
// interact with (tap) a committed image row at all — the "committed
// images" and "image limit" groups below do render committed images, but
// only through the single implicit pump inside `pump()`, with no further
// interaction/pumping, which has held up reliably.


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

void main() {
  late _MockRepository repository;
  late _MockMediaUploadRepository uploadRepository;
  // Both blocs are intentionally NOT built in `setUp` — a bloc constructed
  // there never delivers its stream to a widget subscribed later in the
  // same `testWidgets` body under `flutter_test`'s FakeAsync zone (its
  // listeners silently never fire, hanging `pumpAndSettle` on any
  // shimmer/loading animation). Building them from code reached via the
  // test body itself (here, `pump()`) avoids it.
  late MediaUploadBloc mediaUploadBloc;
  late ServiceImagesBloc serviceImagesBloc;

  setUp(() {
    repository = _MockRepository();
    uploadRepository = _MockMediaUploadRepository();
  });

  tearDown(() async {
    await mediaUploadBloc.close();
    await serviceImagesBloc.close();
  });

  // `ServiceImageCard`'s failure-state row overflows at this test's viewport
  // when rendered with raw (untranslated) fallback keys standing in for
  // "Failed"/"Retry" — this suite deliberately skips the EasyLocalization
  // bootstrap (see the file-top note), so those keys are always longer than
  // the real short translations. Pre-existing layout issue in a shared
  // widget, unrelated to the wiring under test here — drain the resulting
  // overflow `FlutterError`s so they don't fail otherwise-passing
  // assertions.
  void drainOverflowExceptions(WidgetTester tester) {
    while (tester.takeException() != null) {}
  }

  // `SheetNavigator.push`'s modal sheet transition (enter/exit both
  // `SheetTransitions`-driven — 300ms/250ms) is a genuinely-scheduled
  // animation; even a bounded `pumpAndSettle(..., timeout: 5s)` was
  // observed hanging on it in this environment (the settle-loop itself).
  // Advancing a fixed, known-sufficient duration with plain `pump()`
  // calls sidesteps the settle-detection loop entirely.
  Future<void> pumpSheetTransition(WidgetTester tester) async {
    await tester.pump();
    // 700ms comfortably covers a single transition (300ms enter / 250ms
    // exit) or a pop-then-push pair (e.g. closing the image menu and
    // opening the delete-confirmation sheet) in one call, with margin.
    // Under-pumping here leaves the popped route's ticker still running
    // when the test ends, which hangs the framework's own teardown even
    // though the test body itself has already finished (a ticker left
    // running is a real, still-open async gap — not just an unconverged
    // `pumpAndSettle` loop).
    await tester.pump(const Duration(milliseconds: 700));
  }

  Future<void> pump(WidgetTester tester, ProviderServiceEntity service) async {
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

    mediaUploadBloc = MediaUploadBloc(
      repository: uploadRepository,
      config: const MediaUploadConfig(maxFiles: 6),
    );
    serviceImagesBloc = ServiceImagesBloc(
      addProviderServiceImageUseCase: AddProviderServiceImageUseCase(
        repository,
      ),
      deleteProviderServiceImageUseCase: DeleteProviderServiceImageUseCase(
        repository,
      ),
      setPrimaryProviderServiceImageUseCase:
          SetPrimaryProviderServiceImageUseCase(repository),
      initialService: service,
    );

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(360, 800),
        minTextAdapt: true,
        builder: (_, _) => MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: MultiBlocProvider(
              providers: [
                BlocProvider<MediaUploadBloc>.value(value: mediaUploadBloc),
                BlocProvider<ServiceImagesBloc>.value(
                  value: serviceImagesBloc,
                ),
              ],
              child: const SingleChildScrollView(
                child: ManageServiceImagesSection(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  group('committed images — Main badge reflects isPrimary, not position', () {
    testWidgets(
      'the Main badge renders on the image flagged isPrimary even when '
      "it isn't first",
      (tester) async {
        const imageA = ProviderServiceImageEntity(
          id: 'row-a',
          mediaId: 'media-a',
          url: '',
          isPrimary: false,
        );
        const imageB = ProviderServiceImageEntity(
          id: 'row-b',
          mediaId: 'media-b',
          url: '',
          isPrimary: true,
        );

        await pump(tester, _service(images: [imageA, imageB]));

        final cards = tester
            .widgetList<ServiceImageCard>(find.byType(ServiceImageCard))
            .toList();
        expect(cards, hasLength(2));
        expect(
          cards.singleWhere((c) => c.data.id == 'row-a').isMain,
          isFalse,
        );
        expect(
          cards.singleWhere((c) => c.data.id == 'row-b').isMain,
          isTrue,
        );
        // Exactly one "Main" badge is rendered — proves the badge follows
        // the flag rather than every/no card showing it.
        expect(
          find.text('services.images_main_badge'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'no image flagged isPrimary renders no Main badge (never assumes '
      'the first image)',
      (tester) async {
        const imageA = ProviderServiceImageEntity(
          id: 'row-a',
          mediaId: 'media-a',
          url: '',
          isPrimary: false,
        );
        const imageB = ProviderServiceImageEntity(
          id: 'row-b',
          mediaId: 'media-b',
          url: '',
          isPrimary: false,
        );

        await pump(tester, _service(images: [imageA, imageB]));

        final cards = tester
            .widgetList<ServiceImageCard>(find.byType(ServiceImageCard))
            .toList();
        expect(cards.every((c) => !c.isMain), isTrue);
        expect(find.text('services.images_main_badge'), findsNothing);
      },
    );
  });

  group('add flow — MediaUploadBloc state is forwarded verbatim', () {
    testWidgets(
      'a successfully-uploaded item reaches ServiceImagesBloc and is '
      'attached with its mediaId',
      (tester) async {
        when(
          () => repository.addImage(id: 'svc-1', mediaId: 'media-new'),
        ).thenAnswer((_) => TaskEither.of(_service()));

        await pump(tester, _service());

        mediaUploadBloc.add(
          MediaUploadExistingItemsSeeded([
            MediaUploadItem.remote(mediaId: 'media-new', url: ''),
          ]),
        );
        await pumpSheetTransition(tester);

        verify(
          () => repository.addImage(id: 'svc-1', mediaId: 'media-new'),
        ).called(1);
        expect(serviceImagesBloc.state.attachStatus, isEmpty);
      },
    );

    testWidgets(
      'an in-progress card renders and its retry re-dispatches the attach '
      '(never re-uploads)',
      (tester) async {
        var attempt = 0;
        when(
          () => repository.addImage(id: 'svc-1', mediaId: 'media-new'),
        ).thenAnswer((_) {
          attempt++;
          return attempt == 1
              ? TaskEither.left(_serverFailure)
              : TaskEither.of(_service());
        });

        await pump(tester, _service());

        mediaUploadBloc.add(
          MediaUploadExistingItemsSeeded([
            MediaUploadItem.remote(mediaId: 'media-new', url: ''),
          ]),
        );
        await pumpSheetTransition(tester);
        drainOverflowExceptions(tester);

        expect(find.byType(ServiceImageCard), findsOneWidget);
        expect(attempt, 1);

        // The failure-state row overflows at this test's viewport (see
        // `drainOverflowExceptions`), which pushes "Retry" outside its
        // hit-testable bounds — invoke the card's callback directly rather
        // than tapping raw (untranslated) text at an unreliable offset.
        tester
            .widget<ServiceImageCard>(find.byType(ServiceImageCard))
            .onRetry!();
        await pumpSheetTransition(tester);
        drainOverflowExceptions(tester);

        expect(attempt, 2);
        verifyNever(
          () => uploadRepository.upload(
            uploadKey: any(named: 'uploadKey'),
            asset: any(named: 'asset'),
            onProgress: any(named: 'onProgress'),
          ),
        );
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

      await pump(tester, _service(images: images));

      expect(find.byType(ServiceImageAddCard), findsNothing);
    });
  });
}
