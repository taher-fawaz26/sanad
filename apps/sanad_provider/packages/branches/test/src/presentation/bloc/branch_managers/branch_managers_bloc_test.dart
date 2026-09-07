import 'package:bloc_test/bloc_test.dart';
import 'package:branches/src/domain/entities/branch_manager_entity.dart';
import 'package:branches/src/domain/usecases/branch_managers_query.dart';
import 'package:branches/src/domain/usecases/get_branch_managers_usecase.dart';
import 'package:branches/src/presentation/bloc/branch_managers/branch_managers_bloc.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockGetBranchManagers extends Mock implements GetBranchManagersUseCase {}

BranchManagerEntity _mgr(String id) =>
    BranchManagerEntity(id: id, fullName: 'Manager $id', initials: 'M$id');

Page<BranchManagerEntity> _page(
  List<BranchManagerEntity> items, {
  int currentPage = 1,
  int totalPages = 1,
}) => Page<BranchManagerEntity>(
  items: items,
  meta: PageMeta(
    totalItems: items.length,
    itemCount: items.length,
    itemsPerPage: 20,
    totalPages: totalPages,
    currentPage: currentPage,
  ),
);

void main() {
  late _MockGetBranchManagers useCase;

  setUpAll(() => registerFallbackValue(const BranchManagersQuery()));

  setUp(() => useCase = _MockGetBranchManagers());

  BranchManagersBloc build() =>
      BranchManagersBloc(getBranchManagersUseCase: useCase);

  group('initial state', () {
    test('is RequestStatus.initial with no items — never "empty"', () {
      final bloc = build();
      addTearDown(bloc.close);
      // The genuine-empty flag must be false at initial, so the picker shows
      // a loading state (not "No managers") before the first fetch resolves.
      expect(bloc.state.status, RequestStatus.initial);
      expect(bloc.state.pagination.isEmpty, isFalse);
      expect(bloc.state.managers, isEmpty);
    });
  });

  group('first page', () {
    blocTest<BranchManagersBloc, BranchManagersState>(
      'Fetch emits loading (not empty) then success with managers',
      build: build,
      setUp: () => when(() => useCase(any())).thenAnswer(
        (_) => TaskEither.of(_page([_mgr('1'), _mgr('2')])),
      ),
      act: (bloc) => bloc.add(const BranchManagersFetchEvent()),
      expect: () => [
        // loading — isEmpty is false, so no premature "No Results".
        predicate<BranchManagersState>(
          (s) => s.isLoadingFirstPage && !s.pagination.isEmpty,
        ),
        predicate<BranchManagersState>(
          (s) =>
              s.status == RequestStatus.success &&
              s.managers.length == 2 &&
              !s.pagination.isEmpty,
        ),
      ],
      verify: (_) => verify(
        () => useCase(
          any(
            that: isA<BranchManagersQuery>().having((q) => q.page, 'page', 1),
          ),
        ),
      ).called(1),
    );

    blocTest<BranchManagersBloc, BranchManagersState>(
      'Fetch with zero managers ends in a genuine empty state',
      build: build,
      setUp: () => when(
        () => useCase(any()),
      ).thenAnswer((_) => TaskEither.of(_page([]))),
      act: (bloc) => bloc.add(const BranchManagersFetchEvent()),
      expect: () => [
        predicate<BranchManagersState>((s) => s.isLoadingFirstPage),
        predicate<BranchManagersState>(
          (s) => s.status == RequestStatus.success && s.pagination.isEmpty,
        ),
      ],
    );

    blocTest<BranchManagersBloc, BranchManagersState>(
      'Fetch failure ends in a failure state, never empty',
      build: build,
      setUp: () => when(
        () => useCase(any()),
      ).thenAnswer((_) => TaskEither.left(const UnknownFailure(message: 'x'))),
      act: (bloc) => bloc.add(const BranchManagersFetchEvent()),
      expect: () => [
        predicate<BranchManagersState>((s) => s.isLoadingFirstPage),
        predicate<BranchManagersState>(
          (s) =>
              s.status == RequestStatus.failure &&
              s.firstPageError != null &&
              !s.pagination.isEmpty,
        ),
      ],
    );
  });

  group('search', () {
    blocTest<BranchManagersBloc, BranchManagersState>(
      'debounced search reloads with the query as type=manager',
      build: build,
      setUp: () => when(
        () => useCase(any()),
      ).thenAnswer((_) => TaskEither.of(_page([_mgr('9')]))),
      act: (bloc) => bloc.add(const BranchManagersSearchChangedEvent('ali')),
      wait: const Duration(milliseconds: 400),
      verify: (_) {
        final captured = verify(
          () => useCase(captureAny()),
        ).captured.cast<BranchManagersQuery>();
        // The final query carries the search term and the manager type.
        final last = captured.last;
        expect(last.search, 'ali');
        expect(last.toQueryMap()['type'], 'manager');
      },
    );

    blocTest<BranchManagersBloc, BranchManagersState>(
      'rapid keystrokes settle on the trailing query only (restartable)',
      build: build,
      setUp: () => when(
        () => useCase(any()),
      ).thenAnswer((_) => TaskEither.of(_page([_mgr('1')]))),
      act: (bloc) async {
        bloc
          ..add(const BranchManagersSearchChangedEvent('a'))
          ..add(const BranchManagersSearchChangedEvent('ab'))
          ..add(const BranchManagersSearchChangedEvent('abc'));
      },
      wait: const Duration(milliseconds: 500),
      verify: (bloc) {
        // The settled state reflects only the last query — restartable +
        // PaginationMixin's epoch guard ensure a stale response can't
        // overwrite the newest one.
        expect(bloc.state.searchQuery, 'abc');
        final captured = verify(
          () => useCase(captureAny()),
        ).captured.cast<BranchManagersQuery>();
        // The final fetch that actually resolved carried the trailing query.
        expect(captured.last.search, 'abc');
      },
    );
  });

  group('pagination', () {
    blocTest<BranchManagersBloc, BranchManagersState>(
      'LoadMore appends the next page and keeps existing items',
      build: build,
      setUp: () {
        when(
          () => useCase(
            any(that: isA<BranchManagersQuery>().having((q) => q.page, 'p', 1)),
          ),
        ).thenAnswer(
          (_) =>
              TaskEither.of(_page([_mgr('1')], currentPage: 1, totalPages: 2)),
        );
        when(
          () => useCase(
            any(that: isA<BranchManagersQuery>().having((q) => q.page, 'p', 2)),
          ),
        ).thenAnswer(
          (_) =>
              TaskEither.of(_page([_mgr('2')], currentPage: 2, totalPages: 2)),
        );
      },
      act: (bloc) async {
        bloc.add(const BranchManagersFetchEvent());
        await bloc.stream.firstWhere((s) => s.status == RequestStatus.success);
        bloc.add(const BranchManagersLoadMoreEvent());
        await bloc.stream.firstWhere(
          (s) => !s.loadingMore && s.hasMore == false,
        );
      },
      verify: (bloc) {
        expect(bloc.state.loadingMore, isFalse);
        expect(bloc.state.managers.map((m) => m.id).toList(), ['1', '2']);
      },
    );
  });
}
