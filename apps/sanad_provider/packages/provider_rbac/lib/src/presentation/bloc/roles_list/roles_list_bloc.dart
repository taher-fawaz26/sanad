import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:provider_rbac/src/domain/entities/role_entity.dart';
import 'package:provider_rbac/src/domain/usecases/get_roles_usecase.dart';
import 'package:provider_rbac/src/domain/usecases/roles_query.dart';

part 'roles_list_event.dart';
part 'roles_list_state.dart';

/// Debounce applied to search keystrokes before hitting the server.
const _searchDebounce = Duration(milliseconds: 350);

/// Owns the roles list: fetch, refresh, load-more, and server-side search,
/// using the shared [PaginationMixin] over `GET /provider/roles`.
///
/// Role mutations (delete) live in [RoleActionBloc]; create/edit live in
/// `RoleFormBloc`. Their results are folded back into this list via
/// [RoleRemovedFromListEvent] / [RoleUpsertedInListEvent] to avoid a refetch.
class RolesListBloc extends Bloc<RolesListEvent, RolesListState>
    with
        PaginationMixin<
          RolesListEvent,
          RolesListState,
          RoleEntity,
          RolesQuery
        > {
  RolesListBloc({required GetRolesUseCase getRolesUseCase})
    : _getRolesUseCase = getRolesUseCase,
      super(const RolesListState()) {
    on<LoadRolesEvent>((event, emit) => loadFirstPage(emit));
    on<RefreshRolesEvent>(
      (event, emit) => refresh(emit),
      transformer: droppable(),
    );
    on<LoadMoreRolesEvent>(
      (event, emit) => loadNextPage(emit),
      transformer: droppable(),
    );
    on<SearchRolesChangedEvent>(_onSearchChanged, transformer: restartable());
    on<RoleRemovedFromListEvent>(_onRemoved);
    on<RoleUpsertedInListEvent>(_onUpserted);
  }

  final GetRolesUseCase _getRolesUseCase;

  Future<void> _onSearchChanged(
    SearchRolesChangedEvent event,
    Emitter<RolesListState> emit,
  ) async {
    emit(state.copyWith(searchQuery: event.query));
    await Future<void>.delayed(_searchDebounce);
    await onQueryChanged(emit);
  }

  void _onRemoved(
    RoleRemovedFromListEvent event,
    Emitter<RolesListState> emit,
  ) {
    final updated = state.roles.where((r) => r.id != event.roleId).toList();
    emit(state.copyWith(pagination: state.pagination.copyWith(items: updated)));
  }

  void _onUpserted(
    RoleUpsertedInListEvent event,
    Emitter<RolesListState> emit,
  ) {
    final exists = state.roles.any((r) => r.id == event.role.id);
    final updated = exists
        ? state.roles
              .map((r) => r.id == event.role.id ? event.role : r)
              .toList()
        : [...state.roles, event.role];
    emit(state.copyWith(pagination: state.pagination.copyWith(items: updated)));
  }

  @override
  PaginationData<RoleEntity> readPage(RolesListState state) => state.pagination;

  @override
  RolesListState writePage(
    RolesListState state,
    PaginationData<RoleEntity> data,
  ) => state.copyWith(pagination: data);

  @override
  RolesQuery buildQuery({required int page}) => RolesQuery(
    page: page,
    search: state.searchQuery.trim().isEmpty ? null : state.searchQuery.trim(),
  );

  @override
  TaskEither<Failure, Page<RoleEntity>> fetchPage(RolesQuery query) =>
      _getRolesUseCase(query);
}
