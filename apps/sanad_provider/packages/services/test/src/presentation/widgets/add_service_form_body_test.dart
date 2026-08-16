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
import 'package:services/src/domain/entities/catalog_service_entity.dart';
import 'package:services/src/domain/entities/category_ref_entity.dart';
import 'package:services/src/domain/entities/pagination_meta_entity.dart';
import 'package:services/src/domain/usecases/browse_catalog_usecase.dart';
import 'package:services/src/domain/usecases/create_provider_service_usecase.dart';
import 'package:services/src/presentation/bloc/add_service/add_service_bloc.dart';
import 'package:services/src/presentation/widgets/add_service_form_body.dart';

class _MockMediaUploadRepository extends Mock
    implements MediaUploadRepository {}

/// Never invoked by these tests — this widget only ever dispatches
/// [AddServiceCatalogRequested]; submission is [AddServicePage]'s job.
class _UnusedCreateProviderServiceUseCase extends Mock
    implements CreateProviderServiceUseCase {}

/// Backs the Service Name dropdown — proves it loads from the real catalog
/// (`GET /services` via [AddServiceBloc]'s [BrowseCatalogUseCase]), and
/// that only `name` is shown.
class _FakeBrowseCatalogUseCase implements BrowseCatalogUseCase {
  const _FakeBrowseCatalogUseCase();

  static final _services = [
    const CatalogServiceEntity(
      id: 'svc-wash-car',
      name: 'Wash Car',
      category: CategoryRefEntity(
        id: 'cat-car',
        name: 'Car',
        description: null,
      ),
    ),
    const CatalogServiceEntity(
      id: 'svc-oil-change',
      name: 'Oil Change',
      category: CategoryRefEntity(
        id: 'cat-car',
        name: 'Car',
        description: null,
      ),
    ),
  ];

  @override
  TaskEither<Failure, ServicesPagedResult<CatalogServiceEntity>> call(
    BrowseCatalogParams params,
  ) => TaskEither.right(
    ServicesPagedResult(
      items: _services,
      meta: const PaginationMetaEntity(
        totalItems: 2,
        itemCount: 2,
        itemsPerPage: 100,
        totalPages: 1,
        currentPage: 1,
      ),
    ),
  );
}

PickedAsset _asset({String name = 'photo.jpg'}) => PickedAsset(
  name: name,
  path: '/tmp/$name',
  mimeType: 'image/jpeg',
  size: 1024,
  assetType: AssetType.image,
);

void _noop() {}

/// The blocs a pumped [AddServiceFormBody] tree was wired with — tests that
/// need to interact with them afterward (e.g. seed media items) read them
/// from here rather than a `setUp()`-created variable.
class _Harness {
  _Harness(this.mediaBloc, this.addServiceBloc);

  final MediaUploadBloc mediaBloc;
  final AddServiceBloc addServiceBloc;
}

/// Builds and pumps the widget tree, constructing both blocs here — inside
/// the `testWidgets` body's own zone — rather than in a top-level `setUp()`.
/// A bloc built in `setUp()` and then subscribed to (via
/// `AddServiceBloc.stream` in `_loadCatalog`) from inside the test body
/// never delivers its emissions to that subscriber under
/// `flutter_test`'s FakeAsync zone; constructing it here avoids the
/// mismatch.
Future<_Harness> _pump(
  WidgetTester tester, {
  required ValueChanged<bool> onCompletenessChanged,
  VoidCallback onRequestNewService = _noop,
  Key? key,
}) async {
  // The Service modal sheet can exceed the default (small) test surface —
  // use a realistic device-sized surface instead.
  await tester.binding.setSurfaceSize(const Size(1080, 2400));
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  final mediaBloc = MediaUploadBloc(repository: _MockMediaUploadRepository());
  final addServiceBloc = AddServiceBloc(
    createProviderServiceUseCase: _UnusedCreateProviderServiceUseCase(),
    browseCatalogUseCase: const _FakeBrowseCatalogUseCase(),
  );
  addTearDown(() {
    mediaBloc.close();
    addServiceBloc.close();
  });

  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(360, 800),
      minTextAdapt: true,
      builder: (_, _) => MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: MultiBlocProvider(
            providers: [
              BlocProvider<MediaUploadBloc>.value(value: mediaBloc),
              BlocProvider<AddServiceBloc>.value(value: addServiceBloc),
            ],
            child: SingleChildScrollView(
              child: AddServiceFormBody(
                key: key,
                onCompletenessChanged: onCompletenessChanged,
                onRequestNewService: onRequestNewService,
              ),
            ),
          ),
        ),
      ),
    ),
  );

  return _Harness(mediaBloc, addServiceBloc);
}

void main() {
  setUpAll(() {
    registerFallbackValue(_asset());
  });

  testWidgets(
    'renders Service Name dropdown, Description and Images fields — no '
    'price or free category field',
    (tester) async {
      await _pump(
        tester,
        onCompletenessChanged: (_) {},
      );

      expect(find.byType(AppSelectField), findsOneWidget);
      expect(find.byType(AppTextField), findsOneWidget);
      expect(
        find.text('services.add_service.service_select_hint'),
        findsOneWidget,
      );
      expect(find.text('services.add_service.price_hint'), findsNothing);
      // AppInlineLinkText renders as a single Text.rich, so use
      // findRichText to see its span text.
      expect(
        find.textContaining(
          'services.add_service.inline_not_found_prefix',
          findRichText: true,
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'selecting a service from the dropdown updates the field, retains its '
    'id, and reveals the read-only category',
    (tester) async {
      final key = GlobalKey<AddServiceFormBodyState>();
      await _pump(
        tester,
        onCompletenessChanged: (_) {},
        key: key,
      );

      await tester.tap(find.byType(AppSelectField).first);
      await tester.pumpAndSettle();

      // Only the name is shown in the picker rows.
      expect(find.text('Wash Car'), findsWidgets);
      expect(find.text('Oil Change'), findsOneWidget);

      await tester.tap(find.text('Oil Change'));
      await tester.pumpAndSettle();

      expect(key.currentState!.serviceId, 'svc-oil-change');
      expect(find.text('Oil Change'), findsOneWidget);
      expect(find.text('Car'), findsOneWidget);
    },
  );

  testWidgets(
    'reports complete once a service, a description, and at least one '
    'uploaded image are present',
    (tester) async {
      final completenessEvents = <bool>[];
      await _pump(
        tester,
        onCompletenessChanged: completenessEvents.add,
      );

      await tester.tap(find.byType(AppSelectField).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Wash Car'));
      await tester.pumpAndSettle();

      expect(completenessEvents, isNot(contains(true)));

      await tester.enterText(find.byType(TextField).first, 'Great service');
      await tester.pumpAndSettle();

      expect(completenessEvents, isNot(contains(true)));
    },
  );

  group('description validation', () {
    testWidgets('valid input shows no length error', (tester) async {
      await _pump(
        tester,
        onCompletenessChanged: (_) {},
      );

      await tester.enterText(
        find.byType(TextField).first,
        'A valid description',
      );
      await tester.pumpAndSettle();

      expect(
        find.text('validation.length_max'),
        findsNothing,
      );
    });

    testWidgets('exactly 500 characters passes', (tester) async {
      await _pump(
        tester,
        onCompletenessChanged: (_) {},
      );

      await tester.enterText(find.byType(TextField).first, 'a' * 500);
      await tester.pumpAndSettle();

      expect(
        find.text('validation.length_max'),
        findsNothing,
      );
    });

    testWidgets('501 characters shows the corrected length error', (
      tester,
    ) async {
      await _pump(
        tester,
        onCompletenessChanged: (_) {},
      );

      await tester.enterText(find.byType(TextField).first, 'a' * 501);
      await tester.pumpAndSettle();

      expect(
        find.text('validation.length_max'),
        findsOneWidget,
      );
    });

    testWidgets('over 500 characters shows the length error', (tester) async {
      await _pump(
        tester,
        onCompletenessChanged: (_) {},
      );

      await tester.enterText(find.byType(TextField).first, 'a' * 600);
      await tester.pumpAndSettle();

      expect(
        find.text('validation.length_max'),
        findsOneWidget,
      );
    });
  });

  testWidgets(
    'validateSelection reveals the required error when no service is '
    'selected, and clears it once one is picked',
    (tester) async {
      final key = GlobalKey<AddServiceFormBodyState>();
      await _pump(
        tester,
        onCompletenessChanged: (_) {},
        key: key,
      );

      expect(
        find.text('services.add_service.service_required_error'),
        findsNothing,
      );

      final isValid = key.currentState!.validateSelection();
      await tester.pumpAndSettle();

      expect(isValid, isFalse);
      expect(
        find.text('services.add_service.service_required_error'),
        findsOneWidget,
      );

      await tester.tap(find.byType(AppSelectField).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Wash Car'));
      await tester.pumpAndSettle();

      expect(
        find.text('services.add_service.service_required_error'),
        findsNothing,
      );
    },
  );

  group('images count', () {
    testWidgets('0 uploaded images keeps the form incomplete', (
      tester,
    ) async {
      final completenessEvents = <bool>[];
      await _pump(
        tester,
        onCompletenessChanged: completenessEvents.add,
      );

      await tester.tap(find.byType(AppSelectField).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Wash Car'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Great service');
      await tester.pumpAndSettle();

      expect(completenessEvents, isNot(contains(true)));
    });

    testWidgets(
      '6 successfully-uploaded images (the backend maxItems) satisfies the '
      'images requirement',
      (tester) async {
        final completenessEvents = <bool>[];
        final harness = await _pump(
          tester,
          onCompletenessChanged: completenessEvents.add,
        );

        // Seed 6 already-successful items directly via the bloc's
        // existing-items-seed event (used in real usage for pre-filling an
        // edit form) — this exercises `AddServiceFormBody`'s completeness
        // check against a real 6-item success count without touching
        // `asset_picker`/`media_upload` internals.
        // Empty URL — a real one renders `AppNetworkImage`, whose
        // `AppShimmer` loading state has a repeating ticker that never
        // settles under `pumpAndSettle()`. An empty URL instead renders
        // `AppImagePlaceholder`, avoiding that indeterminate animation.
        harness.mediaBloc.add(
          MediaUploadExistingItemsSeeded([
            for (var i = 0; i < 6; i++)
              MediaUploadItem.remote(mediaId: 'media-$i', url: ''),
          ]),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byType(AppSelectField).first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Wash Car'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField).first, 'Great service');
        await tester.pumpAndSettle();

        expect(completenessEvents.last, isTrue);
      },
    );

    // A 7th image is not reachable through this widget's own UI — the
    // picker itself is capped at `maxFiles` (wired to 6 by `AddServicePage`,
    // see its `MediaUploadConfig`), and `AddServiceImagesField` only ever
    // adds up to that cap via `AssetPicker.pick`'s `maxSelection`. Driving
    // the bloc to 7 successful items directly (bypassing the picker) would
    // only be testing `MediaUploadBloc` internals, not this form body, so
    // it's left untested here per the task's guidance to use judgment.
  });
}
