import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:media_upload/media_upload.dart';
import 'package:mocktail/mocktail.dart';
import 'package:services/src/domain/entities/category_record_entity.dart';
import 'package:services/src/domain/entities/catalog_service_entity.dart';
import 'package:services/src/domain/entities/pagination_meta_entity.dart';
import 'package:services/src/domain/usecases/browse_catalog_usecase.dart';
import 'package:services/src/domain/usecases/create_provider_service_usecase.dart';
import 'package:services/src/domain/usecases/create_service_request_usecase.dart';
import 'package:services/src/domain/usecases/get_categories_usecase.dart';
import 'package:services/src/presentation/bloc/add_service/add_service_bloc.dart';
import 'package:services/src/presentation/bloc/request_new_service/request_new_service_bloc.dart';
import 'package:services/src/presentation/pages/add_service_page.dart';
import 'package:services/src/presentation/pages/request_new_service_page.dart';
import 'package:shared_ui/shared_ui.dart';

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

class _FakeBrowseCatalogUseCase implements BrowseCatalogUseCase {
  const _FakeBrowseCatalogUseCase();

  @override
  TaskEither<Failure, ServicesPagedResult<CatalogServiceEntity>> call(
    BrowseCatalogParams params,
  ) => TaskEither.right(
    const ServicesPagedResult(
      items: [],
      meta: PaginationMetaEntity(
        totalItems: 0,
        itemCount: 0,
        itemsPerPage: 100,
        totalPages: 1,
        currentPage: 1,
      ),
    ),
  );
}

class _MockCreateProviderServiceUseCase extends Mock
    implements CreateProviderServiceUseCase {}

class _MockCreateServiceRequestUseCase extends Mock
    implements CreateServiceRequestUseCase {}

Future<void> _pumpRouter(WidgetTester tester) async {
  // The Category modal sheet can exceed the default (small) test surface —
  // use a realistic device-sized surface instead.
  await tester.binding.setSurfaceSize(const Size(1080, 2400));
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  // AddServicePage calls context.push(ServiceRoutes.requestNew) =
  // '/services/request-new', an absolute path, so the test router must
  // register that same real path (flat, since nesting under a bare
  // '/services' parent would need its own builder/redirect that isn't
  // relevant to this test).
  final router = GoRouter(
    initialLocation: '/services/add',
    routes: [
      GoRoute(
        path: '/services/add',
        builder: (context, state) => BlocProvider(
          create: (_) => sl<AddServiceBloc>(),
          child: const AddServicePage(),
        ),
      ),
      GoRoute(
        path: '/services/request-new',
        builder: (context, state) => BlocProvider(
          create: (_) => sl<RequestNewServiceBloc>(),
          child: const RequestNewServicePage(),
        ),
      ),
    ],
  );

  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(360, 800),
      minTextAdapt: true,
      builder: (_, _) => MaterialApp.router(
        theme: AppTheme.light(),
        routerConfig: router,
      ),
    ),
  );
}

void main() {
  setUpAll(() {
    final repository = _MockMediaUploadRepository();
    sl
      ..registerFactoryParam<MediaUploadBloc, MediaUploadConfig, void>(
        (config, _) => MediaUploadBloc(repository: repository, config: config),
      )
      ..registerLazySingleton<GetCategoriesUseCase>(
        () => const _FakeGetCategoriesUseCase(),
      )
      ..registerFactory<AddServiceBloc>(
        () => AddServiceBloc(
          createProviderServiceUseCase: _MockCreateProviderServiceUseCase(),
          browseCatalogUseCase: const _FakeBrowseCatalogUseCase(),
        ),
      )
      ..registerFactory<RequestNewServiceBloc>(
        () => RequestNewServiceBloc(
          createServiceRequestUseCase: _MockCreateServiceRequestUseCase(),
          getCategoriesUseCase: const _FakeGetCategoriesUseCase(),
        ),
      );
  });

  tearDownAll(() {
    sl
      ..unregister<MediaUploadBloc>()
      ..unregister<GetCategoriesUseCase>()
      ..unregister<AddServiceBloc>()
      ..unregister<RequestNewServiceBloc>();
  });

  testWidgets(
    'tapping the header "Request a New Service" button navigates to '
    'RequestNewServicePage',
    (tester) async {
      await _pumpRouter(tester);

      await tester.tap(find.text('services.add_service.request_new_service'));
      await tester.pumpAndSettle();

      expect(find.byType(RequestNewServicePage), findsOneWidget);
      expect(find.byType(AddServicePage), findsNothing);
    },
  );

  testWidgets(
    'tapping the inline "Request New service" link navigates to '
    'RequestNewServicePage',
    (tester) async {
      await _pumpRouter(tester);

      final linkWidget = tester.widget<AppInlineLinkText>(
        find.byType(AppInlineLinkText),
      );
      linkWidget.onLinkTap();
      await tester.pumpAndSettle();

      expect(find.byType(RequestNewServicePage), findsOneWidget);
      expect(find.byType(AddServicePage), findsNothing);
    },
  );
}
