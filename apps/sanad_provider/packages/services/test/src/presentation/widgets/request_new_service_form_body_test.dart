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
import 'package:services/src/presentation/widgets/request_new_service_form_body.dart';

class _MockMediaUploadRepository extends Mock
    implements MediaUploadRepository {}

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

Future<void> _pump(
  WidgetTester tester,
  MediaUploadBloc bloc, {
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
  late _MockMediaUploadRepository repository;
  late MediaUploadBloc bloc;

  setUpAll(() {
    registerFallbackValue(_asset());
    sl.registerLazySingleton<GetCategoriesUseCase>(
      () => const _FakeGetCategoriesUseCase(),
    );
  });

  tearDownAll(() {
    sl.unregister<GetCategoriesUseCase>();
  });

  setUp(() {
    repository = _MockMediaUploadRepository();
    bloc = MediaUploadBloc(repository: repository);
  });

  tearDown(() => bloc.close());

  testWidgets(
    'renders free-text Service Name, a real Category dropdown, Description '
    'and Images fields',
    (tester) async {
      await _pump(tester, bloc, onCompletenessChanged: (_) {});

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
    await _pump(tester, bloc, onCompletenessChanged: (_) {}, key: key);

    await tester.enterText(find.byType(TextField).at(0), 'Ceramic Coating');
    await tester.pumpAndSettle();

    expect(key.currentState!.name, 'Ceramic Coating');
  });

  testWidgets('selecting a category updates the field and retains its id', (
    tester,
  ) async {
    final key = GlobalKey<RequestNewServiceFormBodyState>();
    await _pump(tester, bloc, onCompletenessChanged: (_) {}, key: key);

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
      await _pump(tester, bloc, onCompletenessChanged: completenessEvents.add);

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
}
