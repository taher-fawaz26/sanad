// blocTest act: lambdas prevent Dart from inferring const at call-sites.
// ignore_for_file: prefer_const_constructors

import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:workers/src/domain/entities/worker_entity.dart';
import 'package:workers/src/domain/entities/worker_status.dart';
import 'package:workers/src/domain/entities/worker_type.dart';
import 'package:workers/src/domain/repositories/worker_repository.dart';
import 'package:workers/src/domain/usecases/get_workers_usecase.dart';
import 'package:workers/src/presentation/bloc/workers_list/workers_list_bloc.dart';

class _MockRepo extends Mock implements WorkerRepository {}

WorkerEntity _worker(String id) => WorkerEntity(
  id: id,
  fullName: 'Worker $id',
  role: 'worker',
  initials: 'W$id',
  status: WorkerStatus.active,
);

Page<WorkerEntity> _page(
  List<String> ids, {
  required int currentPage,
  required int totalPages,
}) => Page(
  items: ids.map(_worker).toList(),
  meta: PageMeta(
    totalItems: ids.length,
    itemCount: ids.length,
    itemsPerPage: 2,
    totalPages: totalPages,
    currentPage: currentPage,
  ),
);

const _serverFailure = ServerFailure(message: 'boom');

void main() {
  late _MockRepo repo;

  setUp(() {
    repo = _MockRepo();
    registerFallbackValue(const WorkersQuery());
  });

  WorkersListBloc buildBloc() =>
      WorkersListBloc(getWorkersUseCase: GetWorkersUseCase(repo));

  group('WorkersListBloc', () {
    blocTest<WorkersListBloc, WorkersListState>(
      'loads the first page on Fetch',
      setUp: () =>
          when(
            () => repo.getWorkers(any()),
          ).thenAnswer(
            (_) =>
                TaskEither.of(_page(['1', '2'], currentPage: 1, totalPages: 2)),
          ),
      build: buildBloc,
      act: (bloc) => bloc.add(WorkersListFetchEvent()),
      expect: () => [
        isA<WorkersListState>().having(
          (s) => s.isLoading,
          'isLoading',
          isTrue,
        ),
        isA<WorkersListState>()
            .having((s) => s.isLoading, 'isLoading', isFalse)
            .having((s) => s.workers.length, 'workers.length', 2)
            .having((s) => s.hasMore, 'hasMore', isTrue),
      ],
    );

    blocTest<WorkersListBloc, WorkersListState>(
      'loads and appends the next page',
      setUp: () {
        when(() => repo.getWorkers(const WorkersQuery())).thenAnswer(
          (_) =>
              TaskEither.of(_page(['1', '2'], currentPage: 1, totalPages: 2)),
        );
        when(
          () => repo.getWorkers(const WorkersQuery(page: 2)),
        ).thenAnswer(
          (_) => TaskEither.of(_page(['3'], currentPage: 2, totalPages: 2)),
        );
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(WorkersListFetchEvent());
        await Future<void>.delayed(Duration.zero);
        bloc.add(WorkersListLoadMoreEvent());
      },
      wait: const Duration(milliseconds: 10),
      verify: (bloc) {
        expect(bloc.state.workers.map((w) => w.id), ['1', '2', '3']);
        expect(bloc.state.hasMore, isFalse);
      },
    );

    blocTest<WorkersListBloc, WorkersListState>(
      'empty result surfaces an empty list',
      setUp: () => when(() => repo.getWorkers(any())).thenAnswer(
        (_) => TaskEither.of(const Page<WorkerEntity>.empty()),
      ),
      build: buildBloc,
      act: (bloc) => bloc.add(WorkersListFetchEvent()),
      verify: (bloc) {
        expect(bloc.state.workers, isEmpty);
        expect(bloc.state.hasError, isFalse);
      },
    );

    blocTest<WorkersListBloc, WorkersListState>(
      'first-page error surfaces hasError with no workers',
      setUp: () => when(
        () => repo.getWorkers(any()),
      ).thenAnswer((_) => TaskEither.left(_serverFailure)),
      build: buildBloc,
      act: (bloc) => bloc.add(WorkersListFetchEvent()),
      verify: (bloc) {
        expect(bloc.state.hasError, isTrue);
        expect(bloc.state.failure, _serverFailure);
        expect(bloc.state.workers, isEmpty);
      },
    );

    blocTest<WorkersListBloc, WorkersListState>(
      'next-page error keeps existing workers visible',
      setUp: () {
        when(() => repo.getWorkers(const WorkersQuery())).thenAnswer(
          (_) => TaskEither.of(_page(['1'], currentPage: 1, totalPages: 2)),
        );
        when(
          () => repo.getWorkers(const WorkersQuery(page: 2)),
        ).thenAnswer((_) => TaskEither.left(_serverFailure));
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(WorkersListFetchEvent());
        await Future<void>.delayed(Duration.zero);
        bloc.add(WorkersListLoadMoreEvent());
      },
      wait: const Duration(milliseconds: 10),
      verify: (bloc) {
        expect(bloc.state.workers.map((w) => w.id), ['1']);
        expect(bloc.state.loadingMore, isFalse);
      },
    );

    blocTest<WorkersListBloc, WorkersListState>(
      'retry after a first-page error clears the error',
      setUp: () {
        var calls = 0;
        when(() => repo.getWorkers(any())).thenAnswer((_) {
          calls++;
          if (calls == 1) return TaskEither.left(_serverFailure);
          return TaskEither.of(_page(['1'], currentPage: 1, totalPages: 1));
        });
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(WorkersListFetchEvent());
        await Future<void>.delayed(Duration.zero);
        bloc.add(WorkersListFetchEvent());
      },
      wait: const Duration(milliseconds: 10),
      verify: (bloc) {
        expect(bloc.state.hasError, isFalse);
        expect(bloc.state.workers.map((w) => w.id), ['1']);
      },
    );

    blocTest<WorkersListBloc, WorkersListState>(
      'refresh reloads page 1 and replaces workers',
      setUp: () {
        var calls = 0;
        when(() => repo.getWorkers(any())).thenAnswer((_) {
          calls++;
          return TaskEither.of(
            _page(['$calls'], currentPage: 1, totalPages: 1),
          );
        });
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(WorkersListFetchEvent());
        await Future<void>.delayed(Duration.zero);
        bloc.add(WorkersListRefreshEvent());
      },
      wait: const Duration(milliseconds: 10),
      verify: (bloc) {
        expect(bloc.state.workers.map((w) => w.id), ['2']);
      },
    );

    blocTest<WorkersListBloc, WorkersListState>(
      'refresh preserves the currently active search query',
      setUp: () {
        when(
          () => repo.getWorkers(const WorkersQuery(search: 'foo')),
        ).thenAnswer(
          (_) => TaskEither.of(_page(['1'], currentPage: 1, totalPages: 1)),
        );
      },
      build: buildBloc,
      seed: () => WorkersListState(
        searchQuery: 'foo',
        pagination: PaginationData(
          status: RequestStatus.success,
          items: [_worker('stale')],
          meta: const PageMeta(
            totalItems: 1,
            itemCount: 1,
            itemsPerPage: 20,
            totalPages: 1,
            currentPage: 1,
          ),
        ),
      ),
      act: (bloc) => bloc.add(const WorkersListRefreshEvent()),
      verify: (bloc) {
        verify(
          () => repo.getWorkers(const WorkersQuery(search: 'foo')),
        ).called(1);
        expect(bloc.state.workers.map((w) => w.id), ['1']);
        expect(bloc.state.searchQuery, 'foo');
      },
    );

    blocTest<WorkersListBloc, WorkersListState>(
      'search resets to page 1 and replaces previously loaded workers',
      setUp: () {
        when(() => repo.getWorkers(const WorkersQuery())).thenAnswer(
          (_) =>
              TaskEither.of(_page(['1', '2'], currentPage: 4, totalPages: 4)),
        );
        when(
          () => repo.getWorkers(const WorkersQuery(search: 'Mohamed')),
        ).thenAnswer(
          (_) => TaskEither.of(_page(['9'], currentPage: 1, totalPages: 1)),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const WorkersListSearchChangedEvent('Mohamed')),
      wait: const Duration(milliseconds: 400),
      verify: (bloc) {
        expect(bloc.state.workers.map((w) => w.id), ['9']);
        expect(bloc.state.page, 1);
      },
    );

    group('status/type filters (server-side, SAN)', () {
      blocTest<WorkersListBloc, WorkersListState>(
        'status All -> Active sends status=active and resets to page 1',
        setUp: () {
          when(() => repo.getWorkers(const WorkersQuery())).thenAnswer(
            (_) => TaskEither.of(
              _page(['1', '2'], currentPage: 3, totalPages: 3),
            ),
          );
          when(
            () => repo.getWorkers(
              const WorkersQuery(status: WorkerStatus.active),
            ),
          ).thenAnswer(
            (_) => TaskEither.of(_page(['9'], currentPage: 1, totalPages: 1)),
          );
        },
        build: buildBloc,
        act: (bloc) async {
          bloc.add(WorkersListFetchEvent());
          await Future<void>.delayed(Duration.zero);
          bloc.add(
            const WorkersListStatusChangedEvent(WorkerStatus.active),
          );
        },
        wait: const Duration(milliseconds: 10),
        verify: (bloc) {
          verify(
            () => repo.getWorkers(
              const WorkersQuery(status: WorkerStatus.active),
            ),
          ).called(1);
          expect(bloc.state.workers.map((w) => w.id), ['9']);
          expect(bloc.state.page, 1);
          expect(bloc.state.statusFilter, WorkerStatus.active);
        },
      );

      blocTest<WorkersListBloc, WorkersListState>(
        'status Inactive sends status=inactive',
        setUp: () =>
            when(
              () => repo.getWorkers(
                const WorkersQuery(status: WorkerStatus.inactive),
              ),
            ).thenAnswer(
              (_) => TaskEither.of(_page(['1'], currentPage: 1, totalPages: 1)),
            ),
        build: buildBloc,
        act: (bloc) => bloc.add(
          const WorkersListStatusChangedEvent(WorkerStatus.inactive),
        ),
        verify: (bloc) {
          verify(
            () => repo.getWorkers(
              const WorkersQuery(status: WorkerStatus.inactive),
            ),
          ).called(1);
        },
      );

      blocTest<WorkersListBloc, WorkersListState>(
        'setting status back to null (All) omits the status param',
        setUp: () {
          when(
            () => repo.getWorkers(
              const WorkersQuery(status: WorkerStatus.active),
            ),
          ).thenAnswer(
            (_) => TaskEither.of(_page(['1'], currentPage: 1, totalPages: 1)),
          );
          when(() => repo.getWorkers(const WorkersQuery())).thenAnswer(
            (_) =>
                TaskEither.of(_page(['1', '2'], currentPage: 1, totalPages: 1)),
          );
        },
        build: buildBloc,
        act: (bloc) {
          bloc
            ..add(const WorkersListStatusChangedEvent(WorkerStatus.active))
            ..add(const WorkersListStatusChangedEvent(null));
        },
        verify: (bloc) {
          verify(() => repo.getWorkers(const WorkersQuery())).called(1);
          expect(bloc.state.statusFilter, isNull);
        },
      );

      blocTest<WorkersListBloc, WorkersListState>(
        'type Manager sends type=manager',
        setUp: () =>
            when(
              () =>
                  repo.getWorkers(const WorkersQuery(type: WorkerType.manager)),
            ).thenAnswer(
              (_) => TaskEither.of(_page(['1'], currentPage: 1, totalPages: 1)),
            ),
        build: buildBloc,
        act: (bloc) =>
            bloc.add(const WorkersListTypeChangedEvent(WorkerType.manager)),
        verify: (bloc) {
          verify(
            () => repo.getWorkers(const WorkersQuery(type: WorkerType.manager)),
          ).called(1);
          expect(bloc.state.typeFilter, WorkerType.manager);
        },
      );

      blocTest<WorkersListBloc, WorkersListState>(
        'type Worker sends type=worker',
        setUp: () =>
            when(
              () =>
                  repo.getWorkers(const WorkersQuery(type: WorkerType.worker)),
            ).thenAnswer(
              (_) => TaskEither.of(_page(['1'], currentPage: 1, totalPages: 1)),
            ),
        build: buildBloc,
        act: (bloc) =>
            bloc.add(const WorkersListTypeChangedEvent(WorkerType.worker)),
        verify: (bloc) {
          verify(
            () => repo.getWorkers(const WorkersQuery(type: WorkerType.worker)),
          ).called(1);
        },
      );

      // Status and Type are dispatched on separate `on<T>()` registrations,
      // so — unlike two keystrokes of the same search event, which
      // `restartable()` collapses — tapping Status then Type fires two
      // independent, concurrently-processed fetches. These tests await
      // between dispatches to match how a real user actually filters
      // (one tap, see it apply, then a second tap) and stub every
      // intermediate query the bloc genuinely sends along the way.
      blocTest<WorkersListBloc, WorkersListState>(
        'Active + Manager combine into a single request with both params',
        setUp: () {
          when(
            () => repo.getWorkers(
              const WorkersQuery(status: WorkerStatus.active),
            ),
          ).thenAnswer(
            (_) => TaskEither.of(_page(['1'], currentPage: 1, totalPages: 1)),
          );
          when(
            () => repo.getWorkers(
              const WorkersQuery(
                status: WorkerStatus.active,
                type: WorkerType.manager,
              ),
            ),
          ).thenAnswer(
            (_) => TaskEither.of(_page(['2'], currentPage: 1, totalPages: 1)),
          );
        },
        build: buildBloc,
        act: (bloc) async {
          bloc.add(const WorkersListStatusChangedEvent(WorkerStatus.active));
          await Future<void>.delayed(Duration.zero);
          bloc.add(const WorkersListTypeChangedEvent(WorkerType.manager));
        },
        verify: (bloc) {
          verify(
            () => repo.getWorkers(
              const WorkersQuery(
                status: WorkerStatus.active,
                type: WorkerType.manager,
              ),
            ),
          ).called(1);
          expect(bloc.state.workers.map((w) => w.id), ['2']);
        },
      );

      blocTest<WorkersListBloc, WorkersListState>(
        'Inactive + Worker combine into a single request with both params',
        setUp: () {
          when(
            () => repo.getWorkers(
              const WorkersQuery(status: WorkerStatus.inactive),
            ),
          ).thenAnswer(
            (_) => TaskEither.of(_page(['1'], currentPage: 1, totalPages: 1)),
          );
          when(
            () => repo.getWorkers(
              const WorkersQuery(
                status: WorkerStatus.inactive,
                type: WorkerType.worker,
              ),
            ),
          ).thenAnswer(
            (_) => TaskEither.of(_page(['2'], currentPage: 1, totalPages: 1)),
          );
        },
        build: buildBloc,
        act: (bloc) async {
          bloc.add(const WorkersListStatusChangedEvent(WorkerStatus.inactive));
          await Future<void>.delayed(Duration.zero);
          bloc.add(const WorkersListTypeChangedEvent(WorkerType.worker));
        },
        verify: (bloc) {
          verify(
            () => repo.getWorkers(
              const WorkersQuery(
                status: WorkerStatus.inactive,
                type: WorkerType.worker,
              ),
            ),
          ).called(1);
          expect(bloc.state.workers.map((w) => w.id), ['2']);
        },
      );

      blocTest<WorkersListBloc, WorkersListState>(
        'search + status + type all combine into one request',
        setUp: () {
          when(
            () => repo.getWorkers(
              const WorkersQuery(status: WorkerStatus.active),
            ),
          ).thenAnswer(
            (_) => TaskEither.of(_page(['1'], currentPage: 1, totalPages: 1)),
          );
          when(
            () => repo.getWorkers(
              const WorkersQuery(
                status: WorkerStatus.active,
                type: WorkerType.manager,
              ),
            ),
          ).thenAnswer(
            (_) => TaskEither.of(_page(['2'], currentPage: 1, totalPages: 1)),
          );
          when(
            () => repo.getWorkers(
              const WorkersQuery(
                search: 'Mohamed',
                status: WorkerStatus.active,
                type: WorkerType.manager,
              ),
            ),
          ).thenAnswer(
            (_) => TaskEither.of(_page(['3'], currentPage: 1, totalPages: 1)),
          );
        },
        build: buildBloc,
        act: (bloc) async {
          bloc.add(const WorkersListStatusChangedEvent(WorkerStatus.active));
          await Future<void>.delayed(Duration.zero);
          bloc.add(const WorkersListTypeChangedEvent(WorkerType.manager));
          await Future<void>.delayed(Duration.zero);
          bloc.add(const WorkersListSearchChangedEvent('Mohamed'));
        },
        wait: const Duration(milliseconds: 400),
        verify: (bloc) {
          verify(
            () => repo.getWorkers(
              const WorkersQuery(
                search: 'Mohamed',
                status: WorkerStatus.active,
                type: WorkerType.manager,
              ),
            ),
          ).called(1);
          expect(bloc.state.workers.map((w) => w.id), ['3']);
        },
      );

      blocTest<WorkersListBloc, WorkersListState>(
        'clearing both filters restores an unfiltered request',
        setUp: () {
          when(
            () => repo.getWorkers(
              const WorkersQuery(status: WorkerStatus.active),
            ),
          ).thenAnswer(
            (_) => TaskEither.of(_page(['1'], currentPage: 1, totalPages: 1)),
          );
          when(
            () => repo.getWorkers(
              const WorkersQuery(
                status: WorkerStatus.active,
                type: WorkerType.manager,
              ),
            ),
          ).thenAnswer(
            (_) => TaskEither.of(_page(['2'], currentPage: 1, totalPages: 1)),
          );
          when(
            () => repo.getWorkers(const WorkersQuery(type: WorkerType.manager)),
          ).thenAnswer(
            (_) => TaskEither.of(_page(['3'], currentPage: 1, totalPages: 1)),
          );
          when(() => repo.getWorkers(const WorkersQuery())).thenAnswer(
            (_) => TaskEither.of(
              _page(['1', '2', '3'], currentPage: 1, totalPages: 1),
            ),
          );
        },
        build: buildBloc,
        act: (bloc) async {
          bloc.add(const WorkersListStatusChangedEvent(WorkerStatus.active));
          await Future<void>.delayed(Duration.zero);
          bloc.add(const WorkersListTypeChangedEvent(WorkerType.manager));
          await Future<void>.delayed(Duration.zero);
          bloc.add(const WorkersListStatusChangedEvent(null));
          await Future<void>.delayed(Duration.zero);
          bloc.add(const WorkersListTypeChangedEvent(null));
        },
        verify: (bloc) {
          verify(() => repo.getWorkers(const WorkersQuery())).called(1);
          expect(bloc.state.workers.map((w) => w.id), ['1', '2', '3']);
          expect(bloc.state.statusFilter, isNull);
          expect(bloc.state.typeFilter, isNull);
        },
      );
    });

    blocTest<WorkersListBloc, WorkersListState>(
      'replacing a worker in the list updates it in place',
      build: buildBloc,
      seed: () => WorkersListState(
        pagination: PaginationData(
          status: RequestStatus.success,
          items: [_worker('1'), _worker('2')],
        ),
      ),
      act: (bloc) => bloc.add(
        WorkerReplacedInListEvent(
          _worker('1').copyWithStatus(WorkerStatus.inactive),
        ),
      ),
      verify: (bloc) {
        expect(
          bloc.state.workers.firstWhere((w) => w.id == '1').status,
          WorkerStatus.inactive,
        );
      },
    );

    blocTest<WorkersListBloc, WorkersListState>(
      'removing a worker drops it from the list',
      build: buildBloc,
      seed: () => WorkersListState(
        pagination: PaginationData(
          status: RequestStatus.success,
          items: [_worker('1'), _worker('2')],
        ),
      ),
      act: (bloc) => bloc.add(const WorkerRemovedFromListEvent('1')),
      verify: (bloc) {
        expect(bloc.state.workers.map((w) => w.id), ['2']);
      },
    );

    blocTest<WorkersListBloc, WorkersListState>(
      'stale search protection: the latest keystroke wins even if an '
      'earlier search resolves later',
      setUp: () {
        when(() => repo.getWorkers(const WorkersQuery(search: 'a'))).thenAnswer(
          (_) => TaskEither(() async {
            // Simulates a slow response for the first (superseded) search.
            await Future<void>.delayed(const Duration(milliseconds: 500));
            return right(_page(['stale'], currentPage: 1, totalPages: 1));
          }),
        );
        when(
          () => repo.getWorkers(const WorkersQuery(search: 'ab')),
        ).thenAnswer(
          (_) => TaskEither.of(_page(['fresh'], currentPage: 1, totalPages: 1)),
        );
      },
      build: buildBloc,
      act: (bloc) {
        bloc
          ..add(const WorkersListSearchChangedEvent('a'))
          ..add(const WorkersListSearchChangedEvent('ab'));
      },
      wait: const Duration(milliseconds: 900),
      verify: (bloc) {
        expect(bloc.state.workers.map((w) => w.id), ['fresh']);
      },
    );
  });
}

extension on WorkerEntity {
  WorkerEntity copyWithStatus(WorkerStatus status) => WorkerEntity(
    id: id,
    fullName: fullName,
    role: role,
    initials: initials,
    status: status,
  );
}
