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
import 'package:services/src/presentation/widgets/add_service_form_body.dart';

class _MockMediaUploadRepository extends Mock
    implements MediaUploadRepository {}

/// Backs the Service Name dropdown — proves it loads from the real catalog
/// (`GET /services` via [BrowseCatalogUseCase]), and that only `name` is
/// shown.
class _FakeBrowseCatalogUseCase implements BrowseCatalogUseCase {
  const _FakeBrowseCatalogUseCase();

  static final _services = [
    const CatalogServiceEntity(
      id: 'svc-wash-car',
      name: 'Wash Car',
      category: CategoryRefEntity(id: 'cat-car', name: 'Car', description: null),
    ),
    const CatalogServiceEntity(
      id: 'svc-oil-change',
      name: 'Oil Change',
      category: CategoryRefEntity(id: 'cat-car', name: 'Car', description: null),
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

Future<void> _pump(
  WidgetTester tester,
  MediaUploadBloc bloc, {
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
    sl.registerLazySingleton<BrowseCatalogUseCase>(
      () => const _FakeBrowseCatalogUseCase(),
    );
  });

  tearDownAll(() {
    sl.unregister<BrowseCatalogUseCase>();
  });

  setUp(() {
    repository = _MockMediaUploadRepository();
    bloc = MediaUploadBloc(repository: repository);
  });

  tearDown(() => bloc.close());

  testWidgets(
    'renders Service Name dropdown, Description and Images fields — no '
    'price or free category field',
    (tester) async {
      await _pump(tester, bloc, onCompletenessChanged: (_) {});

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
      await _pump(tester, bloc, onCompletenessChanged: (_) {}, key: key);

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
      await _pump(tester, bloc, onCompletenessChanged: completenessEvents.add);

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
}
