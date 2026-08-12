import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider_rbac/src/domain/entities/role_entity.dart';
import 'package:provider_rbac/src/domain/entities/role_persona_type.dart';
import 'package:provider_rbac/src/domain/repositories/roles_repository.dart';
import 'package:provider_rbac/src/domain/usecases/get_roles_usecase.dart';
import 'package:provider_rbac/src/domain/usecases/roles_query.dart';
import 'package:provider_rbac/src/presentation/bloc/roles_list/roles_list_bloc.dart';

class _MockRolesRepository extends Mock implements RolesRepository {}

RoleEntity _role(String id) => RoleEntity(
  id: id,
  name: 'role-$id',
  displayName: 'Role $id',
  userType: RolePersonaType.companyProvider,
  isSystem: false,
  permissions: const [],
);

PageMeta _meta({int currentPage = 1, int totalPages = 1, int totalItems = 2}) =>
    PageMeta(
      totalItems: totalItems,
      itemCount: totalItems,
      itemsPerPage: 20,
      totalPages: totalPages,
      currentPage: currentPage,
    );

Page<RoleEntity> _page(
  List<RoleEntity> items, {
  int currentPage = 1,
  int totalPages = 1,
}) => Page<RoleEntity>(
  items: items,
  meta: _meta(
    currentPage: currentPage,
    totalPages: totalPages,
    totalItems: items.length,
  ),
);

PaginationData<RoleEntity> _data({
  RequestStatus status = RequestStatus.success,
  List<RoleEntity> items = const [],
  PageMeta? meta,
  bool loadingMore = false,
  Failure? firstPageError,
}) => PaginationData<RoleEntity>(
  status: status,
  items: items,
  meta: meta ?? const PageMeta.empty(),
  loadingMore: loadingMore,
  firstPageError: firstPageError,
);

void main() {
  late _MockRolesRepository repository;

  setUpAll(() => registerFallbackValue(const RolesQuery()));

  setUp(() => repository = _MockRolesRepository());

  RolesListBloc build() =>
      RolesListBloc(getRolesUseCase: GetRolesUseCase(repository));

  blocTest<RolesListBloc, RolesListState>(
    'LoadRolesEvent emits [loading, success] with the fetched page',
    build: () {
      when(() => repository.getRoles(any())).thenAnswer(
        (_) => TaskEither.of(_page([_role('a'), _role('b')])),
      );
      return build();
    },
    act: (bloc) => bloc.add(const LoadRolesEvent()),
    expect: () => [
      RolesListState(pagination: _data(status: RequestStatus.loading)),
      RolesListState(
        pagination: _data(
          items: [_role('a'), _role('b')],
          meta: _meta(),
        ),
      ),
    ],
  );

  blocTest<RolesListBloc, RolesListState>(
    'LoadRolesEvent emits [loading, failure] on a repository error',
    build: () {
      when(() => repository.getRoles(any())).thenAnswer(
        (_) => TaskEither.left(const ServerFailure(message: 'boom')),
      );
      return build();
    },
    act: (bloc) => bloc.add(const LoadRolesEvent()),
    expect: () => [
      RolesListState(pagination: _data(status: RequestStatus.loading)),
      RolesListState(
        pagination: _data(
          status: RequestStatus.failure,
          firstPageError: const ServerFailure(message: 'boom'),
        ),
      ),
    ],
  );

  blocTest<RolesListBloc, RolesListState>(
    'LoadMoreRolesEvent appends the next page',
    build: () {
      when(() => repository.getRoles(any())).thenAnswer(
        (_) => TaskEither.of(
          _page([_role('c')], currentPage: 2, totalPages: 2),
        ),
      );
      return build();
    },
    seed: () => RolesListState(
      pagination: _data(
        items: [_role('a'), _role('b')],
        meta: _meta(currentPage: 1, totalPages: 2),
      ),
    ),
    act: (bloc) => bloc.add(const LoadMoreRolesEvent()),
    expect: () => [
      RolesListState(
        pagination: _data(
          items: [_role('a'), _role('b')],
          meta: _meta(currentPage: 1, totalPages: 2),
          loadingMore: true,
        ),
      ),
      RolesListState(
        pagination: _data(
          items: [_role('a'), _role('b'), _role('c')],
          meta: _meta(currentPage: 2, totalPages: 2, totalItems: 1),
        ),
      ),
    ],
    verify: (_) {
      final query =
          verify(() => repository.getRoles(captureAny())).captured.last
              as RolesQuery;
      expect(query.page, 2);
    },
  );

  blocTest<RolesListBloc, RolesListState>(
    'SearchRolesChangedEvent debounces then refetches page 1 with search',
    build: () {
      when(() => repository.getRoles(any())).thenAnswer(
        (_) => TaskEither.of(_page([_role('a')])),
      );
      return build();
    },
    act: (bloc) => bloc.add(const SearchRolesChangedEvent('mgr')),
    wait: const Duration(milliseconds: 450),
    verify: (_) {
      final query =
          verify(() => repository.getRoles(captureAny())).captured.last
              as RolesQuery;
      expect(query.search, 'mgr');
      expect(query.page, 1);
    },
  );

  blocTest<RolesListBloc, RolesListState>(
    'RoleRemovedFromListEvent removes the role locally without a refetch',
    build: build,
    seed: () => RolesListState(
      pagination: _data(items: [_role('a'), _role('b')], meta: _meta()),
    ),
    act: (bloc) => bloc.add(const RoleRemovedFromListEvent('a')),
    expect: () => [
      RolesListState(
        pagination: _data(items: [_role('b')], meta: _meta()),
      ),
    ],
    verify: (_) => verifyNever(() => repository.getRoles(any())),
  );

  blocTest<RolesListBloc, RolesListState>(
    'RoleUpsertedInListEvent appends a new role and replaces an existing one',
    build: build,
    seed: () => RolesListState(
      pagination: _data(items: [_role('a')], meta: _meta(totalItems: 1)),
    ),
    act: (bloc) => bloc
      ..add(RoleUpsertedInListEvent(_role('b')))
      ..add(
        RoleUpsertedInListEvent(
          RoleEntity(
            id: 'a',
            name: 'renamed',
            displayName: 'Renamed',
            userType: RolePersonaType.companyProvider,
            isSystem: false,
            permissions: const [],
          ),
        ),
      ),
    expect: () => [
      RolesListState(
        pagination: _data(
          items: [_role('a'), _role('b')],
          meta: _meta(totalItems: 1),
        ),
      ),
      RolesListState(
        pagination: _data(
          items: [
            RoleEntity(
              id: 'a',
              name: 'renamed',
              displayName: 'Renamed',
              userType: RolePersonaType.companyProvider,
              isSystem: false,
              permissions: const [],
            ),
            _role('b'),
          ],
          meta: _meta(totalItems: 1),
        ),
      ),
    ],
  );
}
