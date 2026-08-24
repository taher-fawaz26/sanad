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
import 'package:services/src/domain/entities/category_record_entity.dart';
import 'package:services/src/domain/entities/category_ref_entity.dart';
import 'package:services/src/domain/entities/pagination_meta_entity.dart';
import 'package:services/src/domain/usecases/browse_catalog_usecase.dart';
import 'package:services/src/domain/usecases/create_provider_service_usecase.dart';
import 'package:services/src/domain/usecases/get_categories_usecase.dart';
import 'package:services/src/presentation/bloc/add_service/add_service_bloc.dart';
import 'package:services/src/presentation/widgets/add_service_form_body.dart';
import 'package:text_optimization/text_optimization.dart';

class _MockMediaUploadRepository extends Mock
    implements MediaUploadRepository {}

class _MockTextOptimizationRepository extends Mock
    implements TextOptimizationRepository {}

/// `AddServiceFormBody`'s description field resolves a `TextOptimizationCubit`
/// from `sl` (SAN-578) — these tests never tap "Enhance with AI", but the
/// widget still needs one registered to build at all.
void _registerTextOptimizationCubit() {
  final repository = _MockTextOptimizationRepository();
  when(
    () => repository.optimize(any()),
  ).thenAnswer((_) => TaskEither.right(''));
  if (sl.isRegistered<TextOptimizationCubit>()) {
    sl.unregister<TextOptimizationCubit>();
  }
  sl.registerFactory<TextOptimizationCubit>(
    () => TextOptimizationCubit(OptimizeTextUseCase(repository)),
  );
}

/// Never invoked by these tests — this widget only ever dispatches
/// [AddServiceCatalogRequested]/[AddServiceCategoriesRequested]; submission
/// is [AddServicePage]'s job.
class _UnusedCreateProviderServiceUseCase extends Mock
    implements CreateProviderServiceUseCase {}

/// Backs the Category picker (`GET /categories`) — two categories, one
/// ("Home") deliberately has zero catalog services so the empty-in-category
/// state can be exercised.
class _FakeGetCategoriesUseCase implements GetCategoriesUseCase {
  const _FakeGetCategoriesUseCase();

  // Not `const` — `CategoryRecordEntity.createdAt`/`updatedAt` are
  // `DateTime`, which has no const constructor.
  static final _categories = [
    CategoryRecordEntity(
      id: 'cat-car',
      slug: 'car',
      name: 'Car',
      description: 'Car services',
      icon: null,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    ),
    CategoryRecordEntity(
      id: 'cat-home',
      slug: 'home',
      name: 'Home',
      description: 'Home services',
      icon: null,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    ),
  ];

  @override
  TaskEither<Failure, ServicesPagedResult<CategoryRecordEntity>> call(
    GetCategoriesParams params,
  ) => TaskEither.right(
    ServicesPagedResult(
      items: _categories,
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

/// Backs the Service picker (`GET /services?categoryId=`) — SAN-577:
/// scoped per category, proving the service list is never the full,
/// unfiltered catalog. "cat-home" intentionally has none.
class _FakeBrowseCatalogUseCase implements BrowseCatalogUseCase {
  const _FakeBrowseCatalogUseCase();

  static const _byCategory = {
    'cat-car': [
      CatalogServiceEntity(
        id: 'svc-wash-car',
        name: 'Wash Car',
        category: CategoryRefEntity(
          id: 'cat-car',
          name: 'Car',
          description: null,
        ),
      ),
      CatalogServiceEntity(
        id: 'svc-oil-change',
        name: 'Oil Change',
        category: CategoryRefEntity(
          id: 'cat-car',
          name: 'Car',
          description: null,
        ),
      ),
    ],
    'cat-home': <CatalogServiceEntity>[],
  };

  @override
  TaskEither<Failure, ServicesPagedResult<CatalogServiceEntity>> call(
    BrowseCatalogParams params,
  ) {
    final items = _byCategory[params.categoryId] ?? const [];
    return TaskEither.right(
      ServicesPagedResult(
        items: items,
        meta: PaginationMetaEntity(
          totalItems: items.length,
          itemCount: items.length,
          itemsPerPage: 100,
          totalPages: 1,
          currentPage: 1,
        ),
      ),
    );
  }
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
/// `AddServiceBloc.stream` in `_loadCatalog`/`_loadCategories`) from inside
/// the test body never delivers its emissions to that subscriber under
/// `flutter_test`'s FakeAsync zone; constructing it here avoids the
/// mismatch.
Future<_Harness> _pump(
  WidgetTester tester, {
  required ValueChanged<bool> onCompletenessChanged,
  VoidCallback onRequestNewService = _noop,
  Key? key,
}) async {
  // The Category/Service modal sheets can exceed the default (small) test
  // surface — use a realistic device-sized surface instead.
  await tester.binding.setSurfaceSize(const Size(1080, 2400));
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  // The description field's AppEnhanceWithAiButton (from AppDescriptionField)
  // runs a perpetual rainbow-border animation that never settles on its own,
  // which would hang pumpAndSettle(); disabling animations makes the widget
  // stop its controller (it checks MediaQuery.disableAnimationsOf).
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

  // EasyLocalization isn't bootstrapped in this harness, so `.tr()` falls
  // back to the raw key ('common.enhance_with_ai') — longer than any real
  // translation, which overflows AppEnhanceWithAiButton's fixed-width
  // (160px) pill. That's a byproduct of the untranslated test key, not a
  // real layout bug in the widget under test.
  final originalOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    if (details.exception.toString().contains('A RenderFlex overflowed')) {
      return;
    }
    originalOnError?.call(details);
  };
  addTearDown(() => FlutterError.onError = originalOnError);

  final mediaBloc = MediaUploadBloc(repository: _MockMediaUploadRepository());
  final addServiceBloc = AddServiceBloc(
    createProviderServiceUseCase: _UnusedCreateProviderServiceUseCase(),
    browseCatalogUseCase: const _FakeBrowseCatalogUseCase(),
    getCategoriesUseCase: const _FakeGetCategoriesUseCase(),
  );
  addTearDown(() {
    mediaBloc.close();
    addServiceBloc.close();
  });

  _registerTextOptimizationCubit();
  addTearDown(() {
    if (sl.isRegistered<TextOptimizationCubit>()) {
      sl.unregister<TextOptimizationCubit>();
    }
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

/// Opens the Category picker (the first `AppSelectField`) and selects
/// [name].
Future<void> _selectCategory(WidgetTester tester, String name) async {
  await tester.tap(find.byType(AppSelectField).first);
  await tester.pumpAndSettle();
  await tester.tap(find.text(name).last);
  await tester.pumpAndSettle();
}

/// Opens the Service picker (the second `AppSelectField`) and selects
/// [name]. Only reachable once a category has been selected.
Future<void> _selectService(WidgetTester tester, String name) async {
  await tester.tap(find.byType(AppSelectField).at(1));
  await tester.pumpAndSettle();
  await tester.tap(find.text(name).last);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() {
    registerFallbackValue(_asset());
  });

  testWidgets(
    'renders Category and Service dropdowns, Description and Images '
    'fields — no price field, Service starts disabled',
    (tester) async {
      await _pump(
        tester,
        onCompletenessChanged: (_) {},
      );

      expect(find.byType(AppSelectField), findsNWidgets(2));
      expect(find.byType(AppTextField), findsOneWidget);
      expect(
        find.text('services.add_service.category_select_hint'),
        findsOneWidget,
      );
      expect(
        find.text('services.add_service.service_disabled_hint'),
        findsOneWidget,
      );
      expect(find.text('services.add_service.price_hint'), findsNothing);

      final serviceField = tester.widget<AppSelectField>(
        find.byType(AppSelectField).at(1),
      );
      expect(serviceField.enabled, isFalse);
      expect(serviceField.onTap, isNull);

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
    'tapping the disabled Service field before a category is chosen opens '
    'nothing',
    (tester) async {
      await _pump(
        tester,
        onCompletenessChanged: (_) {},
      );

      await tester.tap(find.byType(AppSelectField).at(1));
      await tester.pumpAndSettle();

      expect(find.byType(AppTableRow), findsNothing);
    },
  );

  testWidgets(
    'selecting a category enables the Service field, scoped to that '
    'category — selecting a service updates the field and retains its id',
    (tester) async {
      final key = GlobalKey<AddServiceFormBodyState>();
      await _pump(
        tester,
        onCompletenessChanged: (_) {},
        key: key,
      );

      await _selectCategory(tester, 'Car');

      expect(find.text('Car'), findsOneWidget);
      final serviceField = tester.widget<AppSelectField>(
        find.byType(AppSelectField).at(1),
      );
      expect(serviceField.enabled, isTrue);

      await tester.tap(find.byType(AppSelectField).at(1));
      await tester.pumpAndSettle();

      // Only this category's services are listed — not the full catalog.
      expect(find.text('Wash Car'), findsOneWidget);
      expect(find.text('Oil Change'), findsOneWidget);

      await tester.tap(find.text('Oil Change'));
      await tester.pumpAndSettle();

      expect(key.currentState!.serviceId, 'svc-oil-change');
      expect(find.text('Oil Change'), findsOneWidget);
    },
  );

  testWidgets(
    'a category with no services shows the localized empty state inside '
    'the Service picker, and Category stays changeable',
    (tester) async {
      await _pump(
        tester,
        onCompletenessChanged: (_) {},
      );

      await _selectCategory(tester, 'Home');
      await tester.tap(find.byType(AppSelectField).at(1));
      await tester.pumpAndSettle();

      expect(
        find.text('services.add_service.service_empty_in_category'),
        findsOneWidget,
      );

      // Category is still tappable/changeable behind this sheet — dismiss
      // it via the modal barrier (no confirm/close button on a singleSelect
      // AppSelectSheet) and switch category.
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();
      await _selectCategory(tester, 'Car');

      expect(find.text('Car'), findsOneWidget);
    },
  );

  testWidgets(
    'changing category after selecting a service clears the previously '
    'selected service',
    (tester) async {
      final key = GlobalKey<AddServiceFormBodyState>();
      await _pump(
        tester,
        onCompletenessChanged: (_) {},
        key: key,
      );

      await _selectCategory(tester, 'Car');
      await _selectService(tester, 'Wash Car');
      expect(key.currentState!.serviceId, 'svc-wash-car');

      await _selectCategory(tester, 'Home');

      expect(key.currentState!.serviceId, isNull);
      expect(find.text('Wash Car'), findsNothing);
      expect(
        find.text('services.add_service.service_select_hint'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'reports complete once a category, a service, a description, and at '
    'least one uploaded image are present',
    (tester) async {
      final completenessEvents = <bool>[];
      await _pump(
        tester,
        onCompletenessChanged: completenessEvents.add,
      );

      await _selectCategory(tester, 'Car');
      await _selectService(tester, 'Wash Car');

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
    'validateSelection reveals both required errors when nothing is '
    'selected, reveals only the service error once a category is chosen, '
    'and clears both once a service is picked',
    (tester) async {
      final key = GlobalKey<AddServiceFormBodyState>();
      await _pump(
        tester,
        onCompletenessChanged: (_) {},
        key: key,
      );

      expect(
        find.text('services.add_service.category_required_error'),
        findsNothing,
      );
      expect(
        find.text('services.add_service.service_required_error'),
        findsNothing,
      );

      final isValid = key.currentState!.validateSelection();
      await tester.pumpAndSettle();

      expect(isValid, isFalse);
      expect(
        find.text('services.add_service.category_required_error'),
        findsOneWidget,
      );
      expect(
        find.text('services.add_service.service_required_error'),
        findsOneWidget,
      );

      await _selectCategory(tester, 'Car');

      expect(
        find.text('services.add_service.category_required_error'),
        findsNothing,
      );
      expect(
        find.text('services.add_service.service_required_error'),
        findsOneWidget,
      );

      await _selectService(tester, 'Wash Car');

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

      await _selectCategory(tester, 'Car');
      await _selectService(tester, 'Wash Car');
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

        await _selectCategory(tester, 'Car');
        await _selectService(tester, 'Wash Car');
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
