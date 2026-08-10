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
import 'package:services/src/domain/usecases/get_categories_usecase.dart';
import 'package:services/src/presentation/widgets/add_service_form_body.dart';
import 'package:shared_ui/shared_ui.dart';

class _MockMediaUploadRepository extends Mock
    implements MediaUploadRepository {}

class _FakeGetCategoriesUseCase implements GetCategoriesUseCase {
  const _FakeGetCategoriesUseCase();

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
      slug: 'home-maintenance',
      name: 'Home Maintenance',
      description: 'Home maintenance services',
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

PickedAsset _asset({String name = 'photo.jpg'}) => PickedAsset(
  name: name,
  path: '/tmp/$name',
  mimeType: 'image/jpeg',
  size: 1024,
  assetType: AssetType.image,
);

void _noop() {}

Future<void> _pump(
  WidgetTester tester,
  MediaUploadBloc bloc, {
  required ValueChanged<bool> onCompletenessChanged,
  VoidCallback onRequestNewService = _noop,
}) async {
  // The Category modal sheet can exceed the default (small) test surface —
  // use a realistic device-sized surface instead.
  await tester.binding.setSurfaceSize(const Size(1080, 2400));
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(360, 800),
      minTextAdapt: true,
      builder: (_, _) => MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: BlocProvider<MediaUploadBloc>.value(
            value: bloc,
            child: SingleChildScrollView(
              child: AddServiceFormBody(
                onCompletenessChanged: onCompletenessChanged,
                onRequestNewService: onRequestNewService,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  late _MockMediaUploadRepository repository;
  late MediaUploadBloc bloc;

  setUpAll(() {
    registerFallbackValue(_asset());
    sl.registerLazySingleton<GetCategoriesUseCase>(
      () => const _FakeGetCategoriesUseCase(),
    );
  });

  tearDownAll(() => sl.unregister<GetCategoriesUseCase>());

  setUp(() {
    repository = _MockMediaUploadRepository();
    bloc = MediaUploadBloc(repository: repository);
  });

  tearDown(() => bloc.close());

  testWidgets(
    'renders Category, free-text Service Name, Price, Description and '
    'Images fields',
    (tester) async {
      await _pump(tester, bloc, onCompletenessChanged: (_) {});

      expect(find.byType(AppSelectField), findsOneWidget);
      expect(find.byType(AppTextField), findsNWidgets(3));
      expect(find.text('services.add_service.category_hint'), findsOneWidget);
      expect(
        find.text('services.add_service.service_name_hint'),
        findsOneWidget,
      );
      expect(find.text('services.add_service.price_hint'), findsOneWidget);
      // The inline "didn't find your category?" hint is always available,
      // not gated on a selection (there is no catalog to fall back from).
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

  testWidgets('selecting a category updates the field', (tester) async {
    await _pump(tester, bloc, onCompletenessChanged: (_) {});

    await tester.tap(find.byType(AppSelectField));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Car'));
    await tester.pumpAndSettle();

    expect(find.text('Car'), findsOneWidget);
  });

  testWidgets(
    'tapping the inline "Request New service" link invokes '
    'onRequestNewService',
    (tester) async {
      var requestedNewService = false;
      await _pump(
        tester,
        bloc,
        onCompletenessChanged: (_) {},
        onRequestNewService: () => requestedNewService = true,
      );

      final linkWidget = tester.widget<AppInlineLinkText>(
        find.byType(AppInlineLinkText),
      );
      linkWidget.onLinkTap();

      expect(requestedNewService, isTrue);
    },
  );

  testWidgets('entering a free-text service name updates the field value', (
    tester,
  ) async {
    final key = GlobalKey<AddServiceFormBodyState>();
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(360, 800),
        minTextAdapt: true,
        builder: (_, _) => MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: BlocProvider<MediaUploadBloc>.value(
              value: bloc,
              child: SingleChildScrollView(
                child: AddServiceFormBody(
                  key: key,
                  onCompletenessChanged: (_) {},
                  onRequestNewService: _noop,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField).first, 'AC Repair');
    await tester.pumpAndSettle();

    expect(key.currentState!.name, 'AC Repair');
  });

  testWidgets(
    'reports complete once category, name and a positive price are set '
    '(description/images are optional per CreateServiceDto)',
    (tester) async {
      final completenessEvents = <bool>[];
      await _pump(tester, bloc, onCompletenessChanged: completenessEvents.add);

      await tester.tap(find.byType(AppSelectField));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Car'));
      await tester.pumpAndSettle();

      expect(completenessEvents, isNot(contains(true)));

      await tester.enterText(find.byType(TextField).at(0), 'AC Repair');
      await tester.pumpAndSettle();
      expect(completenessEvents, isNot(contains(true)));

      await tester.enterText(find.byType(TextField).at(1), '150');
      await tester.pumpAndSettle();

      expect(completenessEvents.last, isTrue);
    },
  );
}
