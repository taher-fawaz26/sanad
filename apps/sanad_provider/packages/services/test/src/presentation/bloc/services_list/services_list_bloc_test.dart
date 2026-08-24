// blocTest act: lambdas prevent Dart from inferring const at call-sites.
// ignore_for_file: prefer_const_constructors

import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:services/src/domain/entities/category_ref_entity.dart';
import 'package:services/src/domain/entities/pagination_meta_entity.dart';
import 'package:services/src/domain/entities/provider_service_entity.dart';
import 'package:services/src/domain/entities/provider_service_status.dart';
import 'package:services/src/domain/repositories/provider_services_repository.dart';
import 'package:services/src/domain/usecases/list_provider_services_usecase.dart';
import 'package:services/src/presentation/bloc/services_list/services_list_bloc.dart';

class _MockRepo extends Mock implements ProviderServicesRepository {}

ProviderServiceEntity _service(
  String id, {
  CategoryRefEntity category = const CategoryRefEntity(
    id: 'cat-1',
    name: 'Category',
    description: null,
  ),
}) => ProviderServiceEntity(
  id: id,
  serviceId: 'catalog-$id',
  serviceName: 'Service $id',
  category: category,
  description: 'desc',
  status: ProviderServiceStatus.active,
  images: const [],
  createdAt: DateTime(2024),
  updatedAt: DateTime(2024),
);

ServicesPagedResult<ProviderServiceEntity> _page(
  List<String> ids, {
  required int currentPage,
  required int totalPages,
}) => ServicesPagedResult(
  items: ids.map(_service).toList(),
  meta: PaginationMetaEntity(
    totalItems: ids.length,
    itemCount: ids.length,
    itemsPerPage: 10,
    totalPages: totalPages,
    currentPage: currentPage,
  ),
);

const _serverFailure = ServerFailure(message: 'boom');

void main() {
  late _MockRepo repo;

  setUp(() {
    repo = _MockRepo();
    registerFallbackValue(ProviderServiceStatus.active);
  });

  ServicesListBloc buildBloc() => ServicesListBloc(
    listProviderServicesUseCase: ListProviderServicesUseCase(repo),
  );

  group('ServicesListBloc', () {
    blocTest<ServicesListBloc, ServicesListState>(
      'loads the first page on Fetch',
      setUp: () =>
          when(
            () => repo.listProviderServices(
              page: 1,
              limit: 10,
              search: null,
              status: null,
            ),
          ).thenAnswer(
            (_) =>
                TaskEither.of(_page(['1', '2'], currentPage: 1, totalPages: 2)),
          ),
      build: buildBloc,
      act: (bloc) => bloc.add(const ServicesListFetchEvent()),
      expect: () => [
        isA<ServicesListState>().having(
          (s) => s.isLoading,
          'isLoading',
          isTrue,
        ),
        isA<ServicesListState>()
            .having((s) => s.isLoading, 'isLoading', isFalse)
            .having((s) => s.services.length, 'services.length', 2)
            .having((s) => s.hasMore, 'hasMore', isTrue),
      ],
    );

    blocTest<ServicesListBloc, ServicesListState>(
      'loads and appends the next page, deduping by id',
      setUp: () {
        when(
          () => repo.listProviderServices(
            page: 1,
            limit: 10,
            search: null,
            status: null,
          ),
        ).thenAnswer(
          (_) =>
              TaskEither.of(_page(['1', '2'], currentPage: 1, totalPages: 2)),
        );
        when(
          () => repo.listProviderServices(
            page: 2,
            limit: 10,
            search: null,
            status: null,
          ),
        ).thenAnswer(
          (_) => TaskEither.of(_page(['3'], currentPage: 2, totalPages: 2)),
        );
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const ServicesListFetchEvent());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const ServicesListLoadMoreEvent());
      },
      wait: const Duration(milliseconds: 10),
      verify: (bloc) {
        expect(bloc.state.services.map((s) => s.id), ['1', '2', '3']);
        expect(bloc.state.hasMore, isFalse);
      },
    );

    blocTest<ServicesListBloc, ServicesListState>(
      'empty result surfaces an empty list, not an error',
      setUp: () =>
          when(
            () => repo.listProviderServices(
              page: 1,
              limit: 10,
              search: null,
              status: null,
            ),
          ).thenAnswer(
            (_) => TaskEither.of(
              ServicesPagedResult<ProviderServiceEntity>.empty(),
            ),
          ),
      build: buildBloc,
      act: (bloc) => bloc.add(const ServicesListFetchEvent()),
      verify: (bloc) {
        expect(bloc.state.services, isEmpty);
        expect(bloc.state.hasError, isFalse);
      },
    );

    blocTest<ServicesListBloc, ServicesListState>(
      'first-page error surfaces hasError with no services',
      setUp: () => when(
        () => repo.listProviderServices(
          page: 1,
          limit: 10,
          search: null,
          status: null,
        ),
      ).thenAnswer((_) => TaskEither.left(_serverFailure)),
      build: buildBloc,
      act: (bloc) => bloc.add(const ServicesListFetchEvent()),
      verify: (bloc) {
        expect(bloc.state.hasError, isTrue);
        expect(bloc.state.failure, _serverFailure);
        expect(bloc.state.services, isEmpty);
      },
    );

    blocTest<ServicesListBloc, ServicesListState>(
      'next-page error keeps existing services visible',
      setUp: () {
        when(
          () => repo.listProviderServices(
            page: 1,
            limit: 10,
            search: null,
            status: null,
          ),
        ).thenAnswer(
          (_) => TaskEither.of(_page(['1'], currentPage: 1, totalPages: 2)),
        );
        when(
          () => repo.listProviderServices(
            page: 2,
            limit: 10,
            search: null,
            status: null,
          ),
        ).thenAnswer((_) => TaskEither.left(_serverFailure));
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const ServicesListFetchEvent());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const ServicesListLoadMoreEvent());
      },
      wait: const Duration(milliseconds: 10),
      verify: (bloc) {
        expect(bloc.state.services.map((s) => s.id), ['1']);
        expect(bloc.state.loadingMore, isFalse);
      },
    );

    blocTest<ServicesListBloc, ServicesListState>(
      'refresh reloads page 1 and replaces services',
      setUp: () {
        var calls = 0;
        when(
          () => repo.listProviderServices(
            page: 1,
            limit: 10,
            search: null,
            status: null,
          ),
        ).thenAnswer((_) {
          calls++;
          return TaskEither.of(
            _page(['$calls'], currentPage: 1, totalPages: 1),
          );
        });
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const ServicesListFetchEvent());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const ServicesListRefreshEvent());
      },
      wait: const Duration(milliseconds: 10),
      verify: (bloc) {
        expect(bloc.state.services.map((s) => s.id), ['2']);
      },
    );

    blocTest<ServicesListBloc, ServicesListState>(
      'refresh preserves the currently active search query',
      setUp: () =>
          when(
            () => repo.listProviderServices(
              page: 1,
              limit: 10,
              search: 'foo',
              status: null,
            ),
          ).thenAnswer(
            (_) => TaskEither.of(_page(['1'], currentPage: 1, totalPages: 1)),
          ),
      build: buildBloc,
      seed: () => ServicesListState(
        searchQuery: 'foo',
        pagination: PaginationData(
          status: RequestStatus.success,
          items: [_service('stale')],
          meta: const PageMeta(
            totalItems: 1,
            itemCount: 1,
            itemsPerPage: 10,
            totalPages: 1,
            currentPage: 1,
          ),
        ),
      ),
      act: (bloc) => bloc.add(const ServicesListRefreshEvent()),
      verify: (bloc) {
        verify(
          () => repo.listProviderServices(
            page: 1,
            limit: 10,
            search: 'foo',
            status: null,
          ),
        ).called(1);
        expect(bloc.state.services.map((s) => s.id), ['1']);
        expect(bloc.state.searchQuery, 'foo');
      },
    );

    blocTest<ServicesListBloc, ServicesListState>(
      'search resets to page 1 and replaces previously loaded services',
      setUp: () =>
          when(
            () => repo.listProviderServices(
              page: 1,
              limit: 10,
              search: 'Car',
              status: null,
            ),
          ).thenAnswer(
            (_) => TaskEither.of(_page(['9'], currentPage: 1, totalPages: 1)),
          ),
      build: buildBloc,
      act: (bloc) => bloc.add(const ServicesListSearchChangedEvent('Car')),
      wait: const Duration(milliseconds: 400),
      verify: (bloc) {
        expect(bloc.state.services.map((s) => s.id), ['9']);
        expect(bloc.state.page, 1);
      },
    );

    blocTest<ServicesListBloc, ServicesListState>(
      'status change resets to page 1 and sends the status filter',
      setUp: () =>
          when(
            () => repo.listProviderServices(
              page: 1,
              limit: 10,
              search: null,
              status: ProviderServiceStatus.active,
            ),
          ).thenAnswer(
            (_) => TaskEither.of(_page(['1'], currentPage: 1, totalPages: 1)),
          ),
      build: buildBloc,
      act: (bloc) => bloc.add(
        const ServicesListStatusChangedEvent(ProviderServiceStatus.active),
      ),
      verify: (bloc) {
        verify(
          () => repo.listProviderServices(
            page: 1,
            limit: 10,
            search: null,
            status: ProviderServiceStatus.active,
          ),
        ).called(1);
        expect(bloc.state.services.map((s) => s.id), ['1']);
        expect(bloc.state.statusFilter, ProviderServiceStatus.active);
      },
    );

    blocTest<ServicesListBloc, ServicesListState>(
      'status filter of "all" is omitted from the query',
      setUp: () =>
          when(
            () => repo.listProviderServices(
              page: 1,
              limit: 10,
              search: null,
              status: null,
            ),
          ).thenAnswer(
            (_) => TaskEither.of(_page(['1'], currentPage: 1, totalPages: 1)),
          ),
      build: buildBloc,
      seed: () =>
          const ServicesListState(statusFilter: ProviderServiceStatus.active),
      act: (bloc) => bloc.add(
        const ServicesListStatusChangedEvent(ProviderServiceStatus.all),
      ),
      verify: (bloc) {
        verify(
          () => repo.listProviderServices(
            page: 1,
            limit: 10,
            search: null,
            status: null,
          ),
        ).called(1);
      },
    );

    blocTest<ServicesListBloc, ServicesListState>(
      'search and status compose into a single query',
      setUp: () =>
          when(
            () => repo.listProviderServices(
              page: 1,
              limit: 10,
              search: 'Car',
              status: ProviderServiceStatus.active,
            ),
          ).thenAnswer(
            (_) => TaskEither.of(_page(['1'], currentPage: 1, totalPages: 1)),
          ),
      build: buildBloc,
      seed: () =>
          const ServicesListState(statusFilter: ProviderServiceStatus.active),
      act: (bloc) => bloc.add(const ServicesListSearchChangedEvent('Car')),
      wait: const Duration(milliseconds: 400),
      verify: (bloc) {
        verify(
          () => repo.listProviderServices(
            page: 1,
            limit: 10,
            search: 'Car',
            status: ProviderServiceStatus.active,
          ),
        ).called(1);
      },
    );

    blocTest<ServicesListBloc, ServicesListState>(
      'replacing a service in the list updates it in place',
      build: buildBloc,
      seed: () => ServicesListState(
        pagination: PaginationData(
          status: RequestStatus.success,
          items: [_service('1'), _service('2')],
        ),
      ),
      act: (bloc) => bloc.add(
        ServiceReplacedInListEvent(
          _service('1').copyWith(status: ProviderServiceStatus.inactive),
        ),
      ),
      verify: (bloc) {
        expect(
          bloc.state.services.firstWhere((s) => s.id == '1').status,
          ProviderServiceStatus.inactive,
        );
      },
    );

    blocTest<ServicesListBloc, ServicesListState>(
      'removing a service drops it from the list',
      build: buildBloc,
      seed: () => ServicesListState(
        pagination: PaginationData(
          status: RequestStatus.success,
          items: [_service('1'), _service('2')],
        ),
      ),
      act: (bloc) => bloc.add(const ServiceRemovedFromListEvent('1')),
      verify: (bloc) {
        expect(bloc.state.services.map((s) => s.id), ['2']);
      },
    );

    blocTest<ServicesListBloc, ServicesListState>(
      'stale search protection: the latest keystroke wins even if an '
      'earlier search resolves later',
      setUp: () {
        when(
          () => repo.listProviderServices(
            page: 1,
            limit: 10,
            search: 'a',
            status: null,
          ),
        ).thenAnswer(
          (_) => TaskEither(() async {
            await Future<void>.delayed(const Duration(milliseconds: 500));
            return right(_page(['stale'], currentPage: 1, totalPages: 1));
          }),
        );
        when(
          () => repo.listProviderServices(
            page: 1,
            limit: 10,
            search: 'ab',
            status: null,
          ),
        ).thenAnswer(
          (_) => TaskEither.of(_page(['fresh'], currentPage: 1, totalPages: 1)),
        );
      },
      build: buildBloc,
      act: (bloc) {
        bloc
          ..add(const ServicesListSearchChangedEvent('a'))
          ..add(const ServicesListSearchChangedEvent('ab'));
      },
      wait: const Duration(milliseconds: 900),
      verify: (bloc) {
        expect(bloc.state.services.map((s) => s.id), ['fresh']);
      },
    );

    // Regression for the B1 defect from the Services audit: load-more runs
    // under `droppable()` while search runs under `restartable()` —
    // different event types, so a search reset does NOT cancel an in-flight
    // load-more via `bloc_concurrency` alone. A slow page-2 response for the
    // old query resolving after the search has already reset to a fresh
    // page-1 result must NOT graft stale rows onto the new query — enforced
    // by the fetch-epoch guard in `PaginationMixin`.
    blocTest<ServicesListBloc, ServicesListState>(
      'a slow in-flight load-more resolving after a search reset does not '
      "corrupt the newer query's results (B1 fix)",
      setUp: () {
        when(
          () => repo.listProviderServices(
            page: 1,
            limit: 10,
            search: null,
            status: null,
          ),
        ).thenAnswer(
          (_) =>
              TaskEither.of(_page(['1', '2'], currentPage: 1, totalPages: 2)),
        );
        when(
          () => repo.listProviderServices(
            page: 2,
            limit: 10,
            search: null,
            status: null,
          ),
        ).thenAnswer(
          (_) => TaskEither(() async {
            await Future<void>.delayed(const Duration(milliseconds: 500));
            return right(_page(['3'], currentPage: 2, totalPages: 2));
          }),
        );
        when(
          () => repo.listProviderServices(
            page: 1,
            limit: 10,
            search: 'foo',
            status: null,
          ),
        ).thenAnswer(
          (_) => TaskEither.of(_page(['9'], currentPage: 1, totalPages: 1)),
        );
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const ServicesListFetchEvent());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const ServicesListLoadMoreEvent());
        await Future<void>.delayed(const Duration(milliseconds: 50));
        bloc.add(const ServicesListSearchChangedEvent('foo'));
      },
      wait: const Duration(milliseconds: 900),
      verify: (bloc) {
        expect(bloc.state.services.map((s) => s.id), ['9']);
        expect(bloc.state.page, 1);
        expect(bloc.state.loadingMore, isFalse);
      },
    );

    // Same root cause as the B1 case above, via `refresh` instead of
    // `search`: both `refresh` and `loadNextPage` run under `droppable()`
    // but as *different* event types, so bloc_concurrency doesn't cancel
    // one for the other. A slow load-more resolving after a refresh must
    // not graft stale rows onto the freshly-refreshed page 1.
    blocTest<ServicesListBloc, ServicesListState>(
      'a slow in-flight load-more resolving after a refresh does not '
      'corrupt the refreshed page 1',
      setUp: () {
        when(
          () => repo.listProviderServices(
            page: 1,
            limit: 10,
            search: null,
            status: null,
          ),
        ).thenAnswer(
          (_) =>
              TaskEither.of(_page(['1', '2'], currentPage: 1, totalPages: 2)),
        );
        when(
          () => repo.listProviderServices(
            page: 2,
            limit: 10,
            search: null,
            status: null,
          ),
        ).thenAnswer(
          (_) => TaskEither(() async {
            await Future<void>.delayed(const Duration(milliseconds: 500));
            return right(_page(['3'], currentPage: 2, totalPages: 2));
          }),
        );
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const ServicesListFetchEvent());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const ServicesListLoadMoreEvent());
        await Future<void>.delayed(const Duration(milliseconds: 50));
        bloc.add(const ServicesListRefreshEvent());
      },
      wait: const Duration(milliseconds: 900),
      verify: (bloc) {
        // The second `listProviderServices(page: 1, ...)` stub call (the
        // refresh) returns the same fixed page — asserting on ids alone
        // would pass even if the stale page-2 landed on top of it, so
        // assert the length instead: exactly the refreshed page 1, no
        // grafted page-2 row.
        expect(bloc.state.services.map((s) => s.id), ['1', '2']);
        expect(bloc.state.loadingMore, isFalse);
      },
    );
  });

  // Regression coverage for the Type → Category filter rework: category
  // options and filtering are derived entirely from the categories already
  // present on the loaded `provider-services` response — never a hardcoded
  // list, never a separate categories endpoint.
  group('Category filter (client-side)', () {
    const homeCleaning = CategoryRefEntity(
      id: 'cat-home-cleaning',
      name: 'Home Cleaning',
      description: null,
    );
    const carWash = CategoryRefEntity(
      id: 'cat-car-wash',
      name: 'Car Wash & Detailing',
      description: null,
    );
    const plumbing = CategoryRefEntity(
      id: 'cat-plumbing',
      name: 'Plumbing',
      description: null,
    );

    ServicesListState seededState() => ServicesListState(
      pagination: PaginationData(
        status: RequestStatus.success,
        items: [
          _service('sofa', category: homeCleaning),
          _service('new1', category: carWash),
          _service('water-heater', category: plumbing),
          _service('polish', category: carWash),
          _service('leak', category: plumbing),
        ],
      ),
    );

    blocTest<ServicesListBloc, ServicesListState>(
      'category options are derived from the loaded services, deduplicated '
      'by category.id, preserving first-seen order — never hardcoded',
      build: buildBloc,
      seed: seededState,
      verify: (bloc) {
        expect(
          bloc.state.categoryOptions.map((c) => c.id),
          ['cat-home-cleaning', 'cat-car-wash', 'cat-plumbing'],
        );
      },
    );

    blocTest<ServicesListBloc, ServicesListState>(
      'selecting Home Cleaning returns only the Home Cleaning service',
      build: buildBloc,
      seed: seededState,
      act: (bloc) => bloc.add(
        const ServicesListCategoryChangedEvent('cat-home-cleaning'),
      ),
      verify: (bloc) {
        expect(bloc.state.filteredServices.map((s) => s.id), ['sofa']);
      },
    );

    blocTest<ServicesListBloc, ServicesListState>(
      'selecting Car Wash & Detailing returns both matching services',
      build: buildBloc,
      seed: seededState,
      act: (bloc) =>
          bloc.add(const ServicesListCategoryChangedEvent('cat-car-wash')),
      verify: (bloc) {
        expect(
          bloc.state.filteredServices.map((s) => s.id),
          ['new1', 'polish'],
        );
      },
    );

    blocTest<ServicesListBloc, ServicesListState>(
      'selecting Plumbing returns both matching services',
      build: buildBloc,
      seed: seededState,
      act: (bloc) =>
          bloc.add(const ServicesListCategoryChangedEvent('cat-plumbing')),
      verify: (bloc) {
        expect(
          bloc.state.filteredServices.map((s) => s.id),
          ['water-heater', 'leak'],
        );
      },
    );

    blocTest<ServicesListBloc, ServicesListState>(
      'clearing the category restores the full loaded list',
      build: buildBloc,
      seed: () => seededState().copyWith(
        selectedCategoryId: 'cat-plumbing',
      ),
      act: (bloc) => bloc.add(const ServicesListCategoryChangedEvent(null)),
      verify: (bloc) {
        expect(bloc.state.selectedCategoryId, isNull);
        expect(bloc.state.filteredServices, bloc.state.services);
      },
    );

    blocTest<ServicesListBloc, ServicesListState>(
      'a category with no matching loaded services filters to empty '
      "without touching the server (status/search remain the bloc's own "
      'server-side query)',
      build: buildBloc,
      seed: seededState,
      act: (bloc) =>
          bloc.add(const ServicesListCategoryChangedEvent('cat-unknown')),
      verify: (bloc) {
        expect(bloc.state.filteredServices, isEmpty);
        // The full loaded list and its derived options are untouched — an
        // empty category result must not look like "no services at all".
        expect(bloc.state.services, hasLength(5));
        expect(bloc.state.categoryOptions, hasLength(3));
      },
    );

    blocTest<ServicesListBloc, ServicesListState>(
      'category selection composes with an already-active status filter '
      '(both narrow the same loaded list independently)',
      build: buildBloc,
      seed: () => ServicesListState(
        statusFilter: ProviderServiceStatus.active,
        pagination: PaginationData(
          status: RequestStatus.success,
          items: [
            _service('sofa', category: homeCleaning),
            _service('leak', category: plumbing)
                .copyWith(status: ProviderServiceStatus.inactive),
            _service('water-heater', category: plumbing),
          ],
        ),
      ),
      act: (bloc) =>
          bloc.add(const ServicesListCategoryChangedEvent('cat-plumbing')),
      verify: (bloc) {
        // Category filtering narrows whatever the server already returned
        // for the active status filter — it does not re-fetch or bypass it.
        expect(
          bloc.state.filteredServices.map((s) => s.id),
          ['leak', 'water-heater'],
        );
        expect(bloc.state.statusFilter, ProviderServiceStatus.active);
      },
    );

    blocTest<ServicesListBloc, ServicesListState>(
      'category selection composes with the currently loaded search results',
      build: buildBloc,
      seed: () => ServicesListState(
        searchQuery: 'Car',
        pagination: PaginationData(
          status: RequestStatus.success,
          items: [
            _service('new1', category: carWash),
            _service('polish', category: carWash),
          ],
        ),
      ),
      act: (bloc) =>
          bloc.add(const ServicesListCategoryChangedEvent('cat-car-wash')),
      verify: (bloc) {
        expect(
          bloc.state.filteredServices.map((s) => s.id),
          ['new1', 'polish'],
        );
        expect(bloc.state.searchQuery, 'Car');
      },
    );
  });
}
