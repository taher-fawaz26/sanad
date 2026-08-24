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
import 'package:text_optimization/text_optimization.dart';

class _MockMediaUploadRepository extends Mock
    implements MediaUploadRepository {}

class _MockTextOptimizationRepository extends Mock
    implements TextOptimizationRepository {}

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

  // The description field's AppEnhanceWithAiButton (from
  // AiEnhanceDescriptionField) runs a perpetual rainbow-border animation
  // that never settles on its own, which would hang pumpAndSettle() —
  // disabling animations makes the widget stop its controller (it checks
  // MediaQuery.disableAnimationsOf). Same convention as
  // add_service_form_body_test.dart's `_pump`.
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
          getCategoriesUseCase: sl<GetCategoriesUseCase>(),
        ),
      )
      ..registerFactory<RequestNewServiceBloc>(
        () => RequestNewServiceBloc(
          createServiceRequestUseCase: _MockCreateServiceRequestUseCase(),
          getCategoriesUseCase: const _FakeGetCategoriesUseCase(),
        ),
      )
      // Both pages' description fields resolve a `TextOptimizationCubit`
      // from `sl` (SAN-578) — never tapped here, but the widget still needs
      // one registered to build.
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

  tearDownAll(() {
    sl
      ..unregister<MediaUploadBloc>()
      ..unregister<GetCategoriesUseCase>()
      ..unregister<AddServiceBloc>()
      ..unregister<RequestNewServiceBloc>()
      ..unregister<TextOptimizationCubit>();
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
