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
import 'package:services/src/domain/entities/category_record_entity.dart';
import 'package:services/src/domain/entities/pagination_meta_entity.dart';
import 'package:services/src/domain/usecases/create_service_request_usecase.dart';
import 'package:services/src/domain/usecases/get_categories_usecase.dart';
import 'package:services/src/presentation/bloc/request_new_service/request_new_service_bloc.dart';
import 'package:services/src/presentation/widgets/request_new_service_form_body.dart';

class _MockMediaUploadRepository extends Mock
    implements MediaUploadRepository {}

/// Never invoked by these tests — this widget only ever dispatches
/// [RequestNewServiceCategoriesRequested]; submission is
/// [RequestNewServicePage]'s job.
class _UnusedCreateServiceRequestUseCase extends Mock
    implements CreateServiceRequestUseCase {}

class _FakeGetCategoriesUseCase implements GetCategoriesUseCase {
  const _FakeGetCategoriesUseCase();

  @override
  TaskEither<Failure, ServicesPagedResult<CategoryRecordEntity>> call(
    GetCategoriesParams params,
  ) => TaskEither.right(
    ServicesPagedResult(
      items: [
        CategoryRecordEntity(
          id: 'cat-car',
          slug: 'car',
          name: 'Car',
          description: 'Car services',
          icon: null,
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        ),
      ],
      meta: const PaginationMetaEntity(
        totalItems: 1,
        itemCount: 1,
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

/// Builds and pumps the widget tree, constructing both blocs here — inside
/// the `testWidgets` body's own zone — rather than in a top-level
/// `setUp()`. A bloc built in `setUp()` and then subscribed to (via
/// `RequestNewServiceBloc.stream` in `_loadCategories`) from inside the
/// test body never delivers its emissions to that subscriber under
/// `flutter_test`'s FakeAsync zone; constructing it here avoids the
/// mismatch (see `add_service_form_body_test.dart`'s `_pump` for the same
/// pattern).
Future<void> _pump(
  WidgetTester tester, {
  required ValueChanged<bool> onCompletenessChanged,
  Key? key,
}) async {
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
  final requestNewServiceBloc = RequestNewServiceBloc(
    createServiceRequestUseCase: _UnusedCreateServiceRequestUseCase(),
    getCategoriesUseCase: const _FakeGetCategoriesUseCase(),
  );
  addTearDown(() {
    mediaBloc.close();
    requestNewServiceBloc.close();
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
              BlocProvider<RequestNewServiceBloc>.value(
                value: requestNewServiceBloc,
              ),
            ],
            child: SingleChildScrollView(
              child: RequestNewServiceFormBody(
                key: key,
                onCompletenessChanged: onCompletenessChanged,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(_asset());
  });

  testWidgets(
    'renders free-text Service Name, a real Category dropdown, Description '
    'and Images fields',
    (tester) async {
      await _pump(tester, onCompletenessChanged: (_) {});

      expect(find.byType(AppSelectField), findsOneWidget);
      expect(find.byType(AppTextField), findsNWidgets(2));
      expect(
        find.text('services.request_new_service.service_name_hint'),
        findsOneWidget,
      );
      expect(
        find.text('services.request_new_service.category_name_hint'),
        findsOneWidget,
      );
    },
  );

  testWidgets('entering a service name updates the field', (tester) async {
    final key = GlobalKey<RequestNewServiceFormBodyState>();
    await _pump(tester, onCompletenessChanged: (_) {}, key: key);

    await tester.enterText(find.byType(TextField).at(0), 'Ceramic Coating');
    await tester.pumpAndSettle();

    expect(key.currentState!.name, 'Ceramic Coating');
  });

  testWidgets('selecting a category updates the field and retains its id', (
    tester,
  ) async {
    final key = GlobalKey<RequestNewServiceFormBodyState>();
    await _pump(tester, onCompletenessChanged: (_) {}, key: key);

    await tester.tap(find.byType(AppSelectField).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Car'));
    await tester.pumpAndSettle();

    expect(find.text('Car'), findsOneWidget);
    expect(key.currentState!.categoryId, 'cat-car');
  });

  testWidgets(
    'reports complete once name, category, and description are present — '
    'images are optional',
    (tester) async {
      final completenessEvents = <bool>[];
      await _pump(tester, onCompletenessChanged: completenessEvents.add);

      await tester.enterText(find.byType(TextField).at(0), 'Ceramic Coating');
      await tester.pumpAndSettle();
      expect(completenessEvents, isNot(contains(true)));

      await tester.tap(find.byType(AppSelectField).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Car'));
      await tester.pumpAndSettle();
      expect(completenessEvents, isNot(contains(true)));

      await tester.enterText(
        find.byType(TextField).at(1),
        'A full ceramic coating protection package.',
      );
      await tester.pumpAndSettle();

      expect(completenessEvents.last, isTrue);
    },
  );

  group('name validation', () {
    testWidgets('empty name shows the required error', (tester) async {
      await _pump(tester, onCompletenessChanged: (_) {});

      await tester.enterText(find.byType(TextField).at(0), 'a');
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(0), '');
      await tester.pumpAndSettle();

      expect(
        find.text('services.request_new_service.name_required_error'),
        findsOneWidget,
      );
    });

    testWidgets('valid name shows no error', (tester) async {
      await _pump(tester, onCompletenessChanged: (_) {});

      await tester.enterText(find.byType(TextField).at(0), 'Ceramic Coating');
      await tester.pumpAndSettle();

      expect(
        find.text('services.request_new_service.name_required_error'),
        findsNothing,
      );
      expect(
        find.text('validation.length_max'),
        findsNothing,
      );
    });

    testWidgets('256 characters fails the length check', (tester) async {
      await _pump(tester, onCompletenessChanged: (_) {});

      await tester.enterText(find.byType(TextField).at(0), 'a' * 256);
      await tester.pumpAndSettle();

      expect(
        find.text('validation.length_max'),
        findsOneWidget,
      );
    });

    testWidgets('255 characters (the boundary) passes', (tester) async {
      await _pump(tester, onCompletenessChanged: (_) {});

      await tester.enterText(find.byType(TextField).at(0), 'a' * 255);
      await tester.pumpAndSettle();

      expect(
        find.text('validation.length_max'),
        findsNothing,
      );
    });
  });

  group('description validation', () {
    testWidgets('exactly 500 characters passes', (tester) async {
      await _pump(tester, onCompletenessChanged: (_) {});

      await tester.enterText(find.byType(TextField).at(1), 'a' * 500);
      await tester.pumpAndSettle();

      expect(
        find.text('validation.length_max'),
        findsNothing,
      );
    });

    testWidgets('501 characters shows the corrected length error', (
      tester,
    ) async {
      await _pump(tester, onCompletenessChanged: (_) {});

      await tester.enterText(find.byType(TextField).at(1), 'a' * 501);
      await tester.pumpAndSettle();

      expect(
        find.text('validation.length_max'),
        findsOneWidget,
      );
    });
  });

  testWidgets(
    'validateCategory reveals the required error when no category is '
    'selected, and clears it once one is picked',
    (tester) async {
      final key = GlobalKey<RequestNewServiceFormBodyState>();
      await _pump(tester, onCompletenessChanged: (_) {}, key: key);

      expect(
        find.text('services.request_new_service.category_required_error'),
        findsNothing,
      );

      final isValid = key.currentState!.validateCategory();
      await tester.pumpAndSettle();

      expect(isValid, isFalse);
      expect(
        find.text('services.request_new_service.category_required_error'),
        findsOneWidget,
      );

      await tester.tap(find.byType(AppSelectField).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Car'));
      await tester.pumpAndSettle();

      expect(
        find.text('services.request_new_service.category_required_error'),
        findsNothing,
      );
    },
  );
}
