import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:workers/src/domain/entities/invitation_entity.dart';
import 'package:workers/src/domain/entities/invitation_status.dart';
import 'package:workers/src/domain/usecases/get_invitations_usecase.dart';

part 'invitations_list_event.dart';
part 'invitations_list_state.dart';

const _searchDebounce = Duration(milliseconds: 350);

/// Owns the invitations list: fetch, refresh, load-more, search, and single
/// invitation replacement/removal.
///
/// Invitation mutations (resend / cancel / delete) live in
/// `InvitationActionCubit`. The page applies successful outcomes to this
/// bloc via [InvitationRemovedFromListEvent] /
/// [InvitationCancelledInListEvent].
class InvitationsListBloc
    extends Bloc<InvitationsListEvent, InvitationsListState>
    with
        PaginationMixin<
          InvitationsListEvent,
          InvitationsListState,
          InvitationEntity,
          InvitationsQuery
        > {
  InvitationsListBloc({required GetInvitationsUseCase getInvitationsUseCase})
    : _getInvitationsUseCase = getInvitationsUseCase,
      super(const InvitationsListState()) {
    on<InvitationsListFetchEvent>((event, emit) => loadFirstPage(emit));
    on<InvitationsListRefreshEvent>(
      (event, emit) => refresh(emit),
      transformer: droppable(),
    );
    on<InvitationsListLoadMoreEvent>(
      (event, emit) => loadNextPage(emit),
      transformer: droppable(),
    );
    on<InvitationsListSearchChangedEvent>(
      _onSearchChanged,
      transformer: restartable(),
    );
    on<InvitationRemovedFromListEvent>(_onRemoved);
    on<InvitationCancelledInListEvent>(_onCancelled);
  }

  final GetInvitationsUseCase _getInvitationsUseCase;

  Future<void> _onSearchChanged(
    InvitationsListSearchChangedEvent event,
    Emitter<InvitationsListState> emit,
  ) async {
    emit(state.copyWith(searchQuery: event.query));
    await Future<void>.delayed(_searchDebounce);
    await onQueryChanged(emit);
  }

  void _onRemoved(
    InvitationRemovedFromListEvent event,
    Emitter<InvitationsListState> emit,
  ) {
    final updated = state.invitations
        .where((i) => i.id != event.invitationId)
        .toList();
    emit(state.copyWith(pagination: state.pagination.copyWith(items: updated)));
  }

  void _onCancelled(
    InvitationCancelledInListEvent event,
    Emitter<InvitationsListState> emit,
  ) {
    final updated = state.invitations
        .map(
          (i) => i.id == event.invitationId
              ? i.copyWith(status: InvitationStatus.cancelled)
              : i,
        )
        .toList();
    emit(state.copyWith(pagination: state.pagination.copyWith(items: updated)));
  }

  @override
  PaginationData<InvitationEntity> readPage(InvitationsListState state) =>
      state.pagination;

  @override
  InvitationsListState writePage(
    InvitationsListState state,
    PaginationData<InvitationEntity> data,
  ) => state.copyWith(pagination: data);

  @override
  InvitationsQuery buildQuery({required int page}) => InvitationsQuery(
    page: page,
    search: state.searchQuery.trim().isEmpty ? null : state.searchQuery.trim(),
  );

  @override
  TaskEither<Failure, Page<InvitationEntity>> fetchPage(
    InvitationsQuery query,
  ) => _getInvitationsUseCase(query);

  @override
  Object dedupKey(InvitationEntity item) => item.id;
}
