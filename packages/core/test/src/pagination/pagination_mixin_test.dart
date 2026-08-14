// blocTest act: lambdas prevent Dart from inferring const at call-sites.
// ignore_for_file: prefer_const_constructors

import 'package:bloc/bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

// ── Test fixture: a minimal feature built on PaginationMixin ───────────────

class _Item extends Equatable {
  const _Item(this.id);
  final int id;
  @override
  List<Object?> get props => [id];
}

class _TestQuery extends PageQuery {
  const _TestQuery({super.page, super.limit, super.search});

  @override
  _TestQuery copyWithPage(int page) =>
      _TestQuery(page: page, limit: limit, search: search);
}

sealed class _Event {}

class _Fetch extends _Event {}

class _LoadMore extends _Event {}

class _Refresh extends _Event {}

class _SearchChanged extends _Event {
  _SearchChanged(this.search);
  final String search;
}

class _TestState extends Equatable {
  const _TestState({
    this.page = const PaginationData<_Item>(),
    this.search = '',
  });

  final PaginationData<_Item> page;
  final String search;

  _TestState copyWith({PaginationData<_Item>? page, String? search}) =>
      _TestState(page: page ?? this.page, search: search ?? this.search);

  @override
  List<Object?> get props => [page, search];
}

class _TestBloc extends Bloc<_Event, _TestState>
    with PaginationMixin<_Event, _TestState, _Item, _TestQuery> {
  _TestBloc(this._fetcher) : super(const _TestState()) {
    on<_Fetch>((event, emit) => loadFirstPage(emit));
    on<_LoadMore>((event, emit) => loadNextPage(emit));
    on<_Refresh>((event, emit) => refresh(emit));
    on<_SearchChanged>((event, emit) async {
      emit(state.copyWith(search: event.search));
      await onQueryChanged(emit);
    });
  }

  final Future<Either<Failure, Page<_Item>>> Function(_TestQuery query)
  _fetcher;

  @override
  PaginationData<_Item> readPage(_TestState state) => state.page;

  @override
  _TestState writePage(_TestState state, PaginationData<_Item> data) =>
      state.copyWith(page: data);

  @override
  _TestQuery buildQuery({required int page}) =>
      _TestQuery(page: page, search: state.search);

  @override
  TaskEither<Failure, Page<_Item>> fetchPage(_TestQuery query) =>
      TaskEither(() => _fetcher(query));
}

// ── Fixture: an item whose structural equality is NOT a safe dedup key ──────
// (two fetches of "the same record" can differ on a non-identity field, e.g.
// a freshness timestamp or a denormalized display value).

class _TaggedItem extends Equatable {
  const _TaggedItem(this.id, this.tag);
  final int id;
  final String tag;
  @override
  List<Object?> get props => [id, tag];
}

class _TaggedState extends Equatable {
  const _TaggedState({this.page = const PaginationData<_TaggedItem>()});
  final PaginationData<_TaggedItem> page;
  _TaggedState copyWith({PaginationData<_TaggedItem>? page}) =>
      _TaggedState(page: page ?? this.page);
  @override
  List<Object?> get props => [page];
}

class _TaggedBloc extends Bloc<_Event, _TaggedState>
    with PaginationMixin<_Event, _TaggedState, _TaggedItem, _TestQuery> {
  _TaggedBloc(this._fetcher, {required this.useIdDedup})
    : super(const _TaggedState()) {
    on<_Fetch>((event, emit) => loadFirstPage(emit));
    on<_LoadMore>((event, emit) => loadNextPage(emit));
  }

  final Future<Either<Failure, Page<_TaggedItem>>> Function(_TestQuery query)
  _fetcher;
  final bool useIdDedup;

  @override
  PaginationData<_TaggedItem> readPage(_TaggedState state) => state.page;

  @override
  _TaggedState writePage(
    _TaggedState state,
    PaginationData<_TaggedItem> data,
  ) => state.copyWith(page: data);

  @override
  _TestQuery buildQuery({required int page}) => _TestQuery(page: page);

  @override
  TaskEither<Failure, Page<_TaggedItem>> fetchPage(_TestQuery query) =>
      TaskEither(() => _fetcher(query));

  @override
  Object? dedupKey(_TaggedItem item) => useIdDedup ? item.id : item;
}

Page<_TaggedItem> _taggedPageOf(
  List<_TaggedItem> items, {
  required int currentPage,
  required int totalPages,
}) => Page(
  items: items,
  meta: PageMeta(
    totalItems: items.length,
    itemCount: items.length,
    itemsPerPage: 2,
    totalPages: totalPages,
    currentPage: currentPage,
  ),
);

Page<_Item> _pageOf(
  List<int> ids, {
  required int currentPage,
  required int totalPages,
}) => Page(
  items: ids.map(_Item.new).toList(),
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
  group('PaginationMixin', () {
    blocTest<_TestBloc, _TestState>(
      'loads the first page on Fetch',
      build: () => _TestBloc(
        (q) async => right(_pageOf([1, 2], currentPage: 1, totalPages: 2)),
      ),
      act: (bloc) => bloc.add(_Fetch()),
      expect: () => [
        isA<_TestState>().having(
          (s) => s.page.status,
          'status',
          RequestStatus.loading,
        ),
        isA<_TestState>()
            .having((s) => s.page.status, 'status', RequestStatus.success)
            .having((s) => s.page.items, 'items', [_Item(1), _Item(2)])
            .having((s) => s.page.hasMore, 'hasMore', isTrue),
      ],
    );

    blocTest<_TestBloc, _TestState>(
      'loads and appends the next page, deduping overlapping items',
      build: () => _TestBloc((q) async {
        if (q.page == 1) {
          return right(_pageOf([1, 2], currentPage: 1, totalPages: 2));
        }
        // Overlaps item 2 from page 1 — must be deduped, not duplicated.
        return right(_pageOf([2, 3], currentPage: 2, totalPages: 2));
      }),
      act: (bloc) async {
        bloc.add(_Fetch());
        await Future<void>.delayed(Duration.zero);
        bloc.add(_LoadMore());
      },
      wait: const Duration(milliseconds: 10),
      verify: (bloc) {
        expect(bloc.state.page.items, [_Item(1), _Item(2), _Item(3)]);
        expect(bloc.state.page.hasMore, isFalse); // last page reached
        expect(bloc.state.page.loadingMore, isFalse);
      },
    );

    blocTest<_TestBloc, _TestState>(
      'LoadMore is a no-op when there is no next page',
      build: () => _TestBloc(
        (q) async => right(_pageOf([1], currentPage: 1, totalPages: 1)),
      ),
      act: (bloc) async {
        bloc.add(_Fetch());
        await Future<void>.delayed(Duration.zero);
        bloc.add(_LoadMore());
      },
      wait: const Duration(milliseconds: 10),
      verify: (bloc) {
        expect(bloc.state.page.items, [_Item(1)]);
        expect(bloc.state.page.hasMore, isFalse);
      },
    );

    blocTest<_TestBloc, _TestState>(
      'empty result set surfaces isEmpty',
      build: () => _TestBloc(
        (q) async => right(
          const Page<_Item>(items: [], meta: PageMeta.empty()),
        ),
      ),
      act: (bloc) => bloc.add(_Fetch()),
      verify: (bloc) {
        expect(bloc.state.page.isEmpty, isTrue);
      },
    );

    blocTest<_TestBloc, _TestState>(
      'first-page error surfaces firstPageError and keeps items empty',
      build: () => _TestBloc((q) async => left(_serverFailure)),
      act: (bloc) => bloc.add(_Fetch()),
      verify: (bloc) {
        expect(bloc.state.page.status, RequestStatus.failure);
        expect(bloc.state.page.firstPageError, _serverFailure);
        expect(bloc.state.page.items, isEmpty);
      },
    );

    blocTest<_TestBloc, _TestState>(
      'next-page error surfaces nextPageError but keeps existing items',
      build: () => _TestBloc((q) async {
        if (q.page == 1) {
          return right(_pageOf([1], currentPage: 1, totalPages: 2));
        }
        return left(_serverFailure);
      }),
      act: (bloc) async {
        bloc.add(_Fetch());
        await Future<void>.delayed(Duration.zero);
        bloc.add(_LoadMore());
      },
      wait: const Duration(milliseconds: 10),
      verify: (bloc) {
        expect(bloc.state.page.items, [_Item(1)]);
        expect(bloc.state.page.nextPageError, _serverFailure);
        expect(bloc.state.page.loadingMore, isFalse);
      },
    );

    blocTest<_TestBloc, _TestState>(
      'retrying the first page after an error clears firstPageError',
      build: () {
        var calls = 0;
        return _TestBloc((q) async {
          calls++;
          if (calls == 1) return left(_serverFailure);
          return right(_pageOf([1], currentPage: 1, totalPages: 1));
        });
      },
      act: (bloc) async {
        bloc.add(_Fetch());
        await Future<void>.delayed(Duration.zero);
        bloc.add(_Fetch());
      },
      wait: const Duration(milliseconds: 10),
      verify: (bloc) {
        expect(bloc.state.page.firstPageError, isNull);
        expect(bloc.state.page.items, [_Item(1)]);
      },
    );

    blocTest<_TestBloc, _TestState>(
      'retrying the next page after an error clears nextPageError',
      build: () {
        var nextCalls = 0;
        return _TestBloc((q) async {
          if (q.page == 1) {
            return right(_pageOf([1], currentPage: 1, totalPages: 2));
          }
          nextCalls++;
          if (nextCalls == 1) return left(_serverFailure);
          return right(_pageOf([2], currentPage: 2, totalPages: 2));
        });
      },
      act: (bloc) async {
        bloc.add(_Fetch());
        await Future<void>.delayed(Duration.zero);
        bloc.add(_LoadMore());
        await Future<void>.delayed(Duration.zero);
        bloc.add(_LoadMore());
      },
      wait: const Duration(milliseconds: 10),
      verify: (bloc) {
        expect(bloc.state.page.nextPageError, isNull);
        expect(bloc.state.page.items, [_Item(1), _Item(2)]);
      },
    );

    blocTest<_TestBloc, _TestState>(
      'refresh reloads page 1 and replaces items, keeping the query',
      build: () {
        var calls = 0;
        return _TestBloc((q) async {
          calls++;
          return right(_pageOf([calls], currentPage: 1, totalPages: 1));
        });
      },
      act: (bloc) async {
        bloc.add(_Fetch());
        await Future<void>.delayed(Duration.zero);
        bloc.add(_Refresh());
      },
      wait: const Duration(milliseconds: 10),
      verify: (bloc) {
        expect(bloc.state.page.items, [_Item(2)]);
      },
    );

    blocTest<_TestBloc, _TestState>(
      'search change resets to page 1 and clears previously loaded items',
      build: () => _TestBloc((q) async {
        if (q.search == null) {
          return right(_pageOf([1, 2], currentPage: 4, totalPages: 4));
        }
        return right(_pageOf([9], currentPage: 1, totalPages: 1));
      }),
      seed: () => const _TestState(
        page: PaginationData<_Item>(
          status: RequestStatus.success,
          items: [_Item(1), _Item(2)],
          meta: PageMeta(
            totalItems: 40,
            itemCount: 10,
            itemsPerPage: 10,
            totalPages: 4,
            currentPage: 4,
          ),
        ),
      ),
      act: (bloc) => bloc.add(_SearchChanged('Mohamed')),
      verify: (bloc) {
        expect(bloc.state.page.items, [_Item(9)]);
        expect(bloc.state.page.meta.currentPage, 1);
      },
    );

    // `loadNextPage` and a query-change reducer (`onQueryChanged`/`refresh`)
    // are different reducers a feature typically wires to *different* event
    // types under *different* bloc_concurrency transformers (e.g.
    // `droppable()` for load-more, `restartable()` for search) — so
    // bloc_concurrency alone won't cancel one for the other. The mixin's
    // fetch-epoch guard is what actually prevents a slow load-more from
    // landing after a newer query reset.
    blocTest<_TestBloc, _TestState>(
      'a slow in-flight load-more resolving after a query change does not '
      'graft stale rows onto the new query',
      build: () => _TestBloc((q) async {
        if (q.search != null) {
          return right(_pageOf([9], currentPage: 1, totalPages: 1));
        }
        if (q.page == 2) {
          await Future<void>.delayed(const Duration(milliseconds: 500));
          return right(_pageOf([3], currentPage: 2, totalPages: 2));
        }
        return right(_pageOf([1, 2], currentPage: 1, totalPages: 2));
      }),
      act: (bloc) async {
        bloc.add(_Fetch());
        await Future<void>.delayed(Duration.zero);
        bloc.add(_LoadMore());
        await Future<void>.delayed(const Duration(milliseconds: 50));
        bloc.add(_SearchChanged('x'));
      },
      wait: const Duration(milliseconds: 900),
      verify: (bloc) {
        expect(bloc.state.page.items, [_Item(9)]);
        expect(bloc.state.page.loadingMore, isFalse);
      },
    );

    blocTest<_TestBloc, _TestState>(
      'a slow in-flight load-more resolving after a refresh does not graft '
      'stale rows onto the refreshed page 1',
      build: () => _TestBloc((q) async {
        if (q.page == 2) {
          await Future<void>.delayed(const Duration(milliseconds: 500));
          return right(_pageOf([3], currentPage: 2, totalPages: 2));
        }
        return right(_pageOf([1, 2], currentPage: 1, totalPages: 2));
      }),
      act: (bloc) async {
        bloc.add(_Fetch());
        await Future<void>.delayed(Duration.zero);
        bloc.add(_LoadMore());
        await Future<void>.delayed(const Duration(milliseconds: 50));
        bloc.add(_Refresh());
      },
      wait: const Duration(milliseconds: 900),
      verify: (bloc) {
        expect(bloc.state.page.items, [_Item(1), _Item(2)]);
        expect(bloc.state.page.loadingMore, isFalse);
      },
    );
  });

  group('PaginationMixin.dedupKey', () {
    blocTest<_TaggedBloc, _TaggedState>(
      'default dedupKey (structural equality) does NOT dedupe items that '
      'share an id but differ on another field',
      build: () => _TaggedBloc((q) async {
        if (q.page == 1) {
          return right(
            _taggedPageOf(
              [
                const _TaggedItem(1, 'v1'),
              ],
              currentPage: 1,
              totalPages: 2,
            ),
          );
        }
        // Same id (1) as page 1, but a different `tag` — e.g. the backing
        // record shifted between requests. Structural equality treats this
        // as a distinct item.
        return right(
          _taggedPageOf(
            [
              const _TaggedItem(1, 'v2'),
            ],
            currentPage: 2,
            totalPages: 2,
          ),
        );
      }, useIdDedup: false),
      act: (bloc) async {
        bloc.add(_Fetch());
        await Future<void>.delayed(Duration.zero);
        bloc.add(_LoadMore());
      },
      wait: const Duration(milliseconds: 10),
      verify: (bloc) {
        expect(bloc.state.page.items, hasLength(2));
        expect(bloc.state.page.items.map((i) => i.id), [1, 1]);
      },
    );

    blocTest<_TaggedBloc, _TaggedState>(
      'overriding dedupKey with a stable id correctly dedupes across pages',
      build: () => _TaggedBloc((q) async {
        if (q.page == 1) {
          return right(
            _taggedPageOf(
              [
                const _TaggedItem(1, 'v1'),
              ],
              currentPage: 1,
              totalPages: 2,
            ),
          );
        }
        return right(
          _taggedPageOf(
            [
              const _TaggedItem(1, 'v2'),
            ],
            currentPage: 2,
            totalPages: 2,
          ),
        );
      }, useIdDedup: true),
      act: (bloc) async {
        bloc.add(_Fetch());
        await Future<void>.delayed(Duration.zero);
        bloc.add(_LoadMore());
      },
      wait: const Duration(milliseconds: 10),
      verify: (bloc) {
        expect(bloc.state.page.items, hasLength(1));
        // First-seen occurrence wins — matches typical pagination semantics.
        expect(bloc.state.page.items.single.tag, 'v1');
      },
    );
  });
}
