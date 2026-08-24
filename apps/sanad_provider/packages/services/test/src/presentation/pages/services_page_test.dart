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
import 'package:services/src/presentation/widgets/service_list_item.dart';
import 'package:services/src/presentation/widgets/service_metrics_section.dart';
import 'package:services/src/presentation/widgets/services_empty_state.dart';
import 'package:services/src/presentation/widgets/services_filter_bar.dart';
import 'package:storage/storage.dart';

import '../../../support/fake_hive_local_storage.dart';

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

const _carCategory = CategoryRefEntity(
  id: 'cat-1',
  name: 'Car',
  description: null,
);
const _homeCategory = CategoryRefEntity(
  id: 'cat-2',
  name: 'Home Cleaning',
  description: null,
);

// Two services in two distinct categories — the fixture the category-filter
// tests below narrow with `ServicesListCategoryChangedEvent`.
ServicesPagedResult<ProviderServiceEntity> _multiCategoryServicesPage() =>
    ServicesPagedResult(
      items: [
        ProviderServiceEntity(
          id: 'svc-1',
          serviceId: 'catalog-1',
          serviceName: 'Wash Car',
          category: _carCategory,
          description: 'desc',
          status: ProviderServiceStatus.active,
          images: const [],
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        ),
        ProviderServiceEntity(
          id: 'svc-2',
          serviceId: 'catalog-2',
          serviceName: 'Sofa Cleaning',
          category: _homeCategory,
          description: 'desc',
          status: ProviderServiceStatus.active,
          images: const [],
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        ),
      ],
      meta: const PaginationMetaEntity(
        totalItems: 2,
        itemCount: 2,
        itemsPerPage: 10,
        totalPages: 1,
        currentPage: 1,
      ),
    );

ServicesPagedResult<ProviderServiceEntity> _emptyServicesPage() =>
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
    // Default: hint already seen — these tests aren't about the swipe hint,
    // so this keeps it from ever arming here. The dedicated "first-time
    // swipe hint" group below overrides this per scenario.
    registerFakeHiveLocalStorage(hintSeen: true);
  });

  tearDown(unregisterFakeHiveLocalStorage);

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
            child: const ProviderServicesPage(isOwner: true),
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

  group('My Services search (SAN-580)', () {
    testWidgets(
      'a genuinely empty provider (no search, no filter) shows the full '
      'onboarding empty state, with the search bar/segmented control '
      'hidden and no FAB (its own CTA replaces it)',
      (tester) async {
        when(
          () => providerServicesRepo.listProviderServices(page: 1, limit: 10),
        ).thenAnswer((_) => TaskEither.of(_emptyServicesPage()));

        await pump(tester);
        await tester.pump();
        // Scaffold animates a FAB's appear/disappear transition — a single
        // zero-duration pump can still catch the outgoing FAB mid-animation.
        // No repeating animation on this (non-skeletonized) branch, so
        // settling is safe/bounded here.
        await tester.pumpAndSettle();

        expect(find.byType(ServicesEmptyState), findsOneWidget);
        expect(find.byType(ServicesSearchEmptyState), findsNothing);
        expect(find.byType(ServicesFilterBar), findsNothing);
        expect(find.byType(AppSegmentedControl<int>), findsNothing);
        expect(find.byType(AppFloatingActionButton), findsNothing);
      },
    );

    testWidgets(
      'a search with matches keeps the list, filter bar, and FAB visible '
      '— no empty state of any kind',
      (tester) async {
        when(
          () => providerServicesRepo.listProviderServices(page: 1, limit: 10),
        ).thenAnswer((_) => TaskEither.of(_servicesPage()));
        when(
          () => providerServicesRepo.listProviderServices(
            page: 1,
            limit: 10,
            search: 'Wash',
          ),
        ).thenAnswer((_) => TaskEither.of(_servicesPage()));

        await pump(tester);
        await tester.pump();

        await tester.enterText(find.byType(TextField).first, 'Wash');
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump();

        expect(find.byType(ServiceListItem), findsOneWidget);
        expect(find.byType(ServicesEmptyState), findsNothing);
        expect(find.byType(ServicesSearchEmptyState), findsNothing);
        expect(find.byType(ServicesFilterBar), findsOneWidget);
        expect(find.byType(AppFloatingActionButton), findsOneWidget);
      },
    );

    testWidgets(
      'a search with no matches shows the distinct "no results" empty '
      'state, not the full "no services added yet" onboarding state — '
      'the search bar, segmented control, and FAB all stay visible '
      '(previously the entire chrome collapsed away, trapping the user)',
      (tester) async {
        when(
          () => providerServicesRepo.listProviderServices(page: 1, limit: 10),
        ).thenAnswer((_) => TaskEither.of(_servicesPage()));
        when(
          () => providerServicesRepo.listProviderServices(
            page: 1,
            limit: 10,
            search: 'zzz',
          ),
        ).thenAnswer((_) => TaskEither.of(_emptyServicesPage()));

        await pump(tester);
        await tester.pump();

        await tester.enterText(find.byType(TextField).first, 'zzz');
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump();

        expect(find.byType(ServicesSearchEmptyState), findsOneWidget);
        expect(find.byType(ServicesEmptyState), findsNothing);
        expect(find.byType(ServiceListItem), findsNothing);
        expect(find.byType(ServicesFilterBar), findsOneWidget);
        expect(find.byType(AppSegmentedControl<int>), findsOneWidget);
        expect(find.byType(AppFloatingActionButton), findsOneWidget);
      },
    );

    testWidgets(
      'clearing a no-match search restores the real list', (tester) async {
        when(
          () => providerServicesRepo.listProviderServices(page: 1, limit: 10),
        ).thenAnswer((_) => TaskEither.of(_servicesPage()));
        when(
          () => providerServicesRepo.listProviderServices(
            page: 1,
            limit: 10,
            search: 'zzz',
          ),
        ).thenAnswer((_) => TaskEither.of(_emptyServicesPage()));

        await pump(tester);
        await tester.pump();

        await tester.enterText(find.byType(TextField).first, 'zzz');
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump();
        expect(find.byType(ServicesSearchEmptyState), findsOneWidget);

        await tester.enterText(find.byType(TextField).first, '');
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump();

        expect(find.byType(ServiceListItem), findsOneWidget);
        expect(find.byType(ServicesSearchEmptyState), findsNothing);
        expect(find.byType(ServicesEmptyState), findsNothing);
      },
    );

    testWidgets(
      'the Scaffold does not resize for the keyboard — the FAB stays '
      'anchored at a fixed position instead of Scaffold\'s default '
      'follow-the-keyboard behavior lifting it into the middle of the '
      'list on search focus',
      (tester) async {
        when(
          () => providerServicesRepo.listProviderServices(page: 1, limit: 10),
        ).thenAnswer((_) => TaskEither.of(_servicesPage()));

        await pump(tester);
        await tester.pump();

        final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
        expect(scaffold.resizeToAvoidBottomInset, isFalse);
      },
    );
  });

  group('My Services Category filter (Type → Category rework)', () {
    testWidgets(
      'the filter bar shows a Category dropdown, never a Type one',
      (tester) async {
        when(
          () => providerServicesRepo.listProviderServices(page: 1, limit: 10),
        ).thenAnswer((_) => TaskEither.of(_multiCategoryServicesPage()));

        await pump(tester);
        await tester.pump();

        expect(find.text('services.filter_category'), findsOneWidget);
        expect(find.text('services.filter_type'), findsNothing);
      },
    );

    testWidgets(
      'selecting a category narrows the list to only that category — no '
      'server round trip, purely client-side over the loaded page',
      (tester) async {
        when(
          () => providerServicesRepo.listProviderServices(page: 1, limit: 10),
        ).thenAnswer((_) => TaskEither.of(_multiCategoryServicesPage()));

        final bloc = await pump(tester);
        await tester.pump();

        expect(find.byType(ServiceListItem), findsNWidgets(2));

        // Dispatched directly to the bloc rather than through the Category
        // picker sheet, since the sheet interaction itself isn't what this
        // test verifies (mirrors the existing status-filter test above).
        bloc.add(const ServicesListCategoryChangedEvent('cat-2'));
        await tester.pump();
        await tester.pump();

        expect(find.byType(ServiceListItem), findsOneWidget);
        expect(find.text('Sofa Cleaning'), findsOneWidget);
        expect(find.text('Wash Car'), findsNothing);
        // No new repo call for the category change — status/search are the
        // only server-side filters.
        verify(
          () => providerServicesRepo.listProviderServices(page: 1, limit: 10),
        ).called(1);
      },
    );

    testWidgets(
      'a category with no matching loaded services shows the distinct '
      '"no results" empty state, not the full "no services added yet" '
      'onboarding state — the search bar, segmented control, and FAB all '
      'stay visible',
      (tester) async {
        when(
          () => providerServicesRepo.listProviderServices(page: 1, limit: 10),
        ).thenAnswer((_) => TaskEither.of(_multiCategoryServicesPage()));

        final bloc = await pump(tester);
        await tester.pump();

        bloc.add(const ServicesListCategoryChangedEvent('cat-unknown'));
        await tester.pump();
        await tester.pump();

        expect(find.byType(ServicesCategoryEmptyState), findsOneWidget);
        expect(find.byType(ServicesEmptyState), findsNothing);
        expect(find.byType(ServiceListItem), findsNothing);
        expect(find.byType(ServicesFilterBar), findsOneWidget);
        expect(find.byType(AppSegmentedControl<int>), findsOneWidget);
        expect(find.byType(AppFloatingActionButton), findsOneWidget);
      },
    );

    testWidgets(
      'clearing the category restores the full list',
      (tester) async {
        when(
          () => providerServicesRepo.listProviderServices(page: 1, limit: 10),
        ).thenAnswer((_) => TaskEither.of(_multiCategoryServicesPage()));

        final bloc = await pump(tester);
        await tester.pump();

        bloc.add(const ServicesListCategoryChangedEvent('cat-2'));
        await tester.pump();
        await tester.pump();
        expect(find.byType(ServiceListItem), findsOneWidget);

        bloc.add(const ServicesListCategoryChangedEvent(null));
        await tester.pump();
        await tester.pump();

        expect(find.byType(ServiceListItem), findsNWidgets(2));
      },
    );

    testWidgets(
      'category and an active status filter narrow the list together',
      (tester) async {
        when(
          () => providerServicesRepo.listProviderServices(page: 1, limit: 10),
        ).thenAnswer((_) => TaskEither.of(_multiCategoryServicesPage()));
        when(
          () => providerServicesRepo.listProviderServices(
            page: 1,
            limit: 10,
            status: ProviderServiceStatus.active,
          ),
        ).thenAnswer((_) => TaskEither.of(_multiCategoryServicesPage()));

        final bloc = await pump(tester);
        await tester.pump();

        bloc.add(
          const ServicesListStatusChangedEvent(ProviderServiceStatus.active),
        );
        await tester.pump();
        await tester.pump();
        bloc.add(const ServicesListCategoryChangedEvent('cat-1'));
        await tester.pump();
        await tester.pump();

        expect(find.byType(ServiceListItem), findsOneWidget);
        expect(find.text('Wash Car'), findsOneWidget);
      },
    );
  });

  group('isOwner: false (RBAC Phase 7C — the reported worker 403 bug)', () {
    // Deliberately does NOT construct ServiceAnalyticsBloc or
    // ServiceRequestsListBloc at all — proves the page never reads them
    // when isOwner is false, matching ServicesModule.shellRoute() not
    // providing them for a non-owner. If the page tried to read either
    // one, this test would fail with a "provider not found" error rather
    // than an assertion mismatch.
    Future<void> pumpNonOwner(WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1080, 2400));
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      when(
        () => providerServicesRepo.listProviderServices(page: 1, limit: 10),
      ).thenAnswer((_) => TaskEither.of(_servicesPage()));

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
      addTearDown(() {
        servicesListBloc.close();
        serviceActionBloc.close();
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
                BlocProvider<ServiceActionBloc>.value(
                  value: serviceActionBloc,
                ),
              ],
              child: const ProviderServicesPage(isOwner: false),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets(
      'renders the services list without ServiceAnalyticsBloc or '
      'ServiceRequestsListBloc provided anywhere in the tree',
      (tester) async {
        await pumpNonOwner(tester);

        expect(find.byType(ServicesFilterBar), findsOneWidget);
      },
    );

    testWidgets(
      'shows no segmented control — there is nothing to switch to',
      (tester) async {
        await pumpNonOwner(tester);

        expect(find.byType(AppSegmentedControl<int>), findsNothing);
      },
    );

    testWidgets(
      'shows no ServiceMetricsSection (the owner-only analytics summary)',
      (tester) async {
        await pumpNonOwner(tester);

        expect(find.byType(ServiceMetricsSection), findsNothing);
      },
    );

    testWidgets(
      'shows no Add Service FAB (RBAC Phase 7L — create is owner-only, '
      'finding G3; the AppFloatingActionButton was previously rendered '
      'unconditionally, and tapping it bounced non-owners home via the '
      'route guard — the reveal-then-bounce pattern the plan forbids)',
      (tester) async {
        await pumpNonOwner(tester);

        expect(find.byType(AppFloatingActionButton), findsNothing);
      },
    );

    testWidgets(
      'renders row items with isOwner: false — the row still shows the '
      'service (a manager holding provider-service:view legitimately sees '
      'it) but its swipe-action list is empty',
      (tester) async {
        await pumpNonOwner(tester);

        final rows = find.byType(ServiceListItem);
        expect(rows, findsOneWidget);
        expect(
          (tester.widget<ServiceListItem>(rows)).isOwner,
          isFalse,
          reason:
              'ServiceListItem.isOwner must be false for a non-owner '
              'page so the Edit / Pause-Resume / Delete swipes are hidden',
        );
      },
    );
  });

  group('swipe discoverability hint (My Services) — wiring & persistence', () {
    // The animation/timing/cancellation mechanics themselves are covered by
    // the shared driver's own suite
    // (design_system/test/src/components/app_swipe_action_hint_test.dart) —
    // these tests only verify this page wires it correctly.

    testWidgets(
      'unseen: the first row is wrapped in the shared AppSwipeActionHint '
      'driver',
      (tester) async {
        registerFakeHiveLocalStorage(hintSeen: false);
        when(
          () => providerServicesRepo.listProviderServices(page: 1, limit: 10),
        ).thenAnswer((_) => TaskEither.of(_servicesPage()));

        await pump(tester);
        await tester.pump();

        expect(find.byType(AppSwipeActionHint), findsOneWidget);
      },
    );

    testWidgets(
      'already seen: no AppSwipeActionHint is mounted — the row renders as '
      'a plain ServiceListItem',
      (tester) async {
        registerFakeHiveLocalStorage(hintSeen: true);
        when(
          () => providerServicesRepo.listProviderServices(page: 1, limit: 10),
        ).thenAnswer((_) => TaskEither.of(_servicesPage()));

        await pump(tester);
        await tester.pump();

        expect(find.byType(AppSwipeActionHint), findsNothing);
        expect(find.byType(ServiceListItem), findsOneWidget);
      },
    );

    testWidgets(
      'a real swipe on the row cancels the hint and persists it as seen',
      (tester) async {
        final storage = registerFakeHiveLocalStorage(hintSeen: false);
        when(
          () => providerServicesRepo.listProviderServices(page: 1, limit: 10),
        ).thenAnswer((_) => TaskEither.of(_servicesPage()));

        await pump(tester);
        await tester.pump();
        expect(find.byType(AppSwipeActionHint), findsOneWidget);

        await tester.drag(find.text('Wash Car'), const Offset(-300, 0));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        verify(
          () => storage.save(
            key: StorageKeys.servicesSwipeHintSeen,
            value: true,
            boxName: HiveBoxes.defaultBox,
          ),
        ).called(1);
      },
    );

    testWidgets(
      'a non-owner row (no swipe actions attached) makes the hint '
      'self-abort without throwing, and still marks itself seen',
      (tester) async {
        final storage = registerFakeHiveLocalStorage(hintSeen: false);
        when(
          () => providerServicesRepo.listProviderServices(page: 1, limit: 10),
        ).thenAnswer((_) => TaskEither.of(_servicesPage()));

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
        addTearDown(() {
          servicesListBloc.close();
          serviceActionBloc.close();
        });

        await tester.pumpWidget(
          ScreenUtilInit(
            designSize: const Size(360, 800),
            minTextAdapt: true,
            builder: (_, _) => MaterialApp(
              theme: AppTheme.light(),
              home: MultiBlocProvider(
                providers: [
                  BlocProvider<ServicesListBloc>.value(
                    value: servicesListBloc,
                  ),
                  BlocProvider<ServiceActionBloc>.value(
                    value: serviceActionBloc,
                  ),
                ],
                child: const ProviderServicesPage(isOwner: false),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(tester.takeException(), isNull);
        verify(
          () => storage.save(
            key: StorageKeys.servicesSwipeHintSeen,
            value: true,
            boxName: HiveBoxes.defaultBox,
          ),
        ).called(1);
      },
    );
  });
}
