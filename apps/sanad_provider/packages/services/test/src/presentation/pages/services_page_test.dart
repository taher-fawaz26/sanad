import 'dart:async';

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:services/src/domain/entities/category_ref_entity.dart';
import 'package:services/src/domain/entities/pagination_meta_entity.dart';
import 'package:services/src/domain/entities/provider_service_entity.dart';
import 'package:services/src/domain/entities/provider_service_overview_entity.dart';
import 'package:services/src/domain/entities/provider_service_status.dart';
import 'package:services/src/domain/entities/service_request_entity.dart';
import 'package:services/src/domain/repositories/provider_services_repository.dart';
import 'package:services/src/domain/repositories/service_requests_repository.dart';
import 'package:services/src/domain/usecases/delete_provider_service_usecase.dart';
import 'package:services/src/domain/usecases/get_my_service_requests_usecase.dart';
import 'package:services/src/domain/usecases/get_provider_services_overview_usecase.dart';
import 'package:services/src/domain/usecases/list_provider_services_usecase.dart';
import 'package:services/src/domain/usecases/set_provider_service_status_usecase.dart';
import 'package:services/src/presentation/bloc/service_action/service_action_bloc.dart';
import 'package:services/src/presentation/bloc/service_analytics/service_analytics_bloc.dart';
import 'package:services/src/presentation/bloc/service_requests_list/service_requests_list_bloc.dart';
import 'package:services/src/presentation/bloc/services_list/services_list_bloc.dart';
import 'package:services/src/presentation/pages/services_page.dart';
import 'package:services/src/presentation/widgets/services_filter_bar.dart';

// No EasyLocalization bootstrap (avoids a real SharedPreferences hang in this
// sandboxed test environment) — `.tr()` calls fall back to the raw key.

class _MockProviderServicesRepository extends Mock
    implements ProviderServicesRepository {}

class _MockServiceRequestsRepository extends Mock
    implements ServiceRequestsRepository {}

// Non-empty — an empty first page renders `ProviderServicesPage`'s own
// empty-state layout instead of `_MyServicesContent` (and its
// `ServicesFilterBar`), which isn't what this test verifies.
ServicesPagedResult<ProviderServiceEntity> _servicesPage() =>
    ServicesPagedResult(
      items: [
        ProviderServiceEntity(
          id: 'svc-1',
          serviceId: 'catalog-1',
          serviceName: 'Wash Car',
          category: const CategoryRefEntity(
            id: 'cat-1',
            name: 'Car',
            description: null,
          ),
          description: 'desc',
          status: ProviderServiceStatus.active,
          images: const [],
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        ),
      ],
      meta: const PaginationMetaEntity(
        totalItems: 1,
        itemCount: 1,
        itemsPerPage: 10,
        totalPages: 1,
        currentPage: 1,
      ),
    );

ServicesPagedResult<ServiceRequestEntity> _emptyRequestsPage() =>
    const ServicesPagedResult(
      items: [],
      meta: PaginationMetaEntity(
        totalItems: 0,
        itemCount: 0,
        itemsPerPage: 10,
        totalPages: 1,
        currentPage: 1,
      ),
    );

void main() {
  late _MockProviderServicesRepository providerServicesRepo;
  late _MockServiceRequestsRepository serviceRequestsRepo;

  setUp(() {
    providerServicesRepo = _MockProviderServicesRepository();
    serviceRequestsRepo = _MockServiceRequestsRepository();
    when(
      () => serviceRequestsRepo.getServiceRequests(page: 1, limit: 10),
    ).thenAnswer((_) => TaskEither.of(_emptyRequestsPage()));
    when(
      providerServicesRepo.getOverview,
    ).thenAnswer(
      (_) => TaskEither.of(const ProviderServiceOverviewEntity.unavailable()),
    );
  });

  // Blocs are built inside the test body (via this helper), not `setUp` —
  // a bloc constructed in `setUp` never delivers its stream to a widget
  // subscribed later in the same `testWidgets` body under
  // `flutter_test`'s FakeAsync zone. Returns the `ServicesListBloc` so the
  // test can dispatch directly to it (bypassing the status-filter sheet,
  // which isn't what this test is about) and inspect its state.
  Future<ServicesListBloc> pump(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1080, 2400));
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final servicesListBloc = ServicesListBloc(
      listProviderServicesUseCase: ListProviderServicesUseCase(
        providerServicesRepo,
      ),
    );
    final serviceActionBloc = ServiceActionBloc(
      deleteProviderServiceUseCase: DeleteProviderServiceUseCase(
        providerServicesRepo,
      ),
      setProviderServiceStatusUseCase: SetProviderServiceStatusUseCase(
        providerServicesRepo,
      ),
    );
    final serviceAnalyticsBloc = ServiceAnalyticsBloc(
      getProviderServicesOverviewUseCase: GetProviderServicesOverviewUseCase(
        providerServicesRepo,
      ),
    );
    final serviceRequestsListBloc = ServiceRequestsListBloc(
      getMyServiceRequestsUseCase: GetMyServiceRequestsUseCase(
        serviceRequestsRepo,
      ),
    );
    addTearDown(() {
      servicesListBloc.close();
      serviceActionBloc.close();
      serviceAnalyticsBloc.close();
      serviceRequestsListBloc.close();
    });

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(360, 800),
        minTextAdapt: true,
        builder: (_, _) => MaterialApp(
          theme: AppTheme.light(),
          home: MultiBlocProvider(
            providers: [
              BlocProvider<ServicesListBloc>.value(value: servicesListBloc),
              BlocProvider<ServiceActionBloc>.value(value: serviceActionBloc),
              BlocProvider<ServiceAnalyticsBloc>.value(
                value: serviceAnalyticsBloc,
              ),
              BlocProvider<ServiceRequestsListBloc>.value(
                value: serviceRequestsListBloc,
              ),
            ],
            child: const ProviderServicesPage(),
          ),
        ),
      ),
    );

    return servicesListBloc;
  }

  testWidgets(
    'a filter-changed reload keeps the search field and status filter '
    'mounted — only the list region skeletonizes',
    (tester) async {
      when(
        () => providerServicesRepo.listProviderServices(page: 1, limit: 10),
      ).thenAnswer((_) => TaskEither.of(_servicesPage()));

      final bloc = await pump(tester);
      await tester.pump();

      // Initial load has settled — the filter bar is present.
      expect(bloc.state.isLoading, isFalse);
      expect(find.byType(ServicesFilterBar), findsOneWidget);

      // A status-filter change never resolves within this test — long
      // enough to observe the loading frame without racing a real
      // response. Dispatched directly to the bloc rather than through the
      // status-filter action sheet, since the sheet interaction itself
      // isn't what this test verifies.
      final neverResolves =
          Completer<
            Either<Failure, ServicesPagedResult<ProviderServiceEntity>>
          >();
      when(
        () => providerServicesRepo.listProviderServices(
          page: 1,
          limit: 10,
          status: ProviderServiceStatus.active,
        ),
      ).thenAnswer((_) => TaskEither(() => neverResolves.future));

      bloc.add(
        const ServicesListStatusChangedEvent(ProviderServiceStatus.active),
      );
      await tester.pump();

      expect(bloc.state.isLoading, isTrue);
      // The search field and status filter stay mounted and visible while
      // the reload is in flight — the bug this fix addresses was the
      // entire chrome (including this bar) disappearing here.
      expect(find.byType(ServicesFilterBar), findsOneWidget);
    },
  );
}
