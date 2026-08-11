import 'dart:async';

import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
    extends Bloc<InvitationsListEvent, InvitationsListState> {
  InvitationsListBloc({required GetInvitationsUseCase getInvitationsUseCase})
    : _getInvitationsUseCase = getInvitationsUseCase,
      super(const InvitationsListState()) {
    on<InvitationsListFetchEvent>(_onFetch);
    on<InvitationsListRefreshEvent>(_onRefresh);
    on<InvitationsListLoadMoreEvent>(_onLoadMore);
    on<InvitationsListSearchChangedEvent>(_onSearchChanged);
    on<InvitationRemovedFromListEvent>(_onRemoved);
    on<InvitationCancelledInListEvent>(_onCancelled);
  }

  final GetInvitationsUseCase _getInvitationsUseCase;
  Timer? _searchTimer;

  String? get _search =>
      state.searchQuery.trim().isEmpty ? null : state.searchQuery.trim();

  @override
  Future<void> close() {
    _searchTimer?.cancel();
    return super.close();
  }

  Future<void> _onFetch(
    InvitationsListFetchEvent event,
    Emitter<InvitationsListState> emit,
  ) async {
    emit(state.copyWith(status: RequestStatus.loading, clearFailure: true));
    await _fetch(emit, page: 1, append: false);
  }

  Future<void> _onRefresh(
    InvitationsListRefreshEvent event,
    Emitter<InvitationsListState> emit,
  ) async {
    emit(state.copyWith(status: RequestStatus.loading, clearFailure: true));
    await _fetch(emit, page: 1, append: false);
  }

  Future<void> _onLoadMore(
    InvitationsListLoadMoreEvent event,
    Emitter<InvitationsListState> emit,
  ) async {
    if (state.loadingMore || !state.hasMore) return;
    emit(state.copyWith(loadingMore: true));
    await _fetch(emit, page: state.page + 1, append: true);
  }

  void _onSearchChanged(
    InvitationsListSearchChangedEvent event,
    Emitter<InvitationsListState> emit,
  ) {
    emit(state.copyWith(searchQuery: event.query));
    _searchTimer?.cancel();
    _searchTimer = Timer(_searchDebounce, () {
      if (isClosed) return;
      add(const InvitationsListFetchEvent());
    });
  }

  void _onRemoved(
    InvitationRemovedFromListEvent event,
    Emitter<InvitationsListState> emit,
  ) {
    final updated = state.invitations
        .where((i) => i.id != event.invitationId)
        .toList();
    emit(state.copyWith(invitations: updated));
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
    emit(state.copyWith(invitations: updated));
  }

  Future<void> _fetch(
    Emitter<InvitationsListState> emit, {
    required int page,
    required bool append,
  }) async {
    final result = await _getInvitationsUseCase(
      GetInvitationsParams(page: page, search: _search),
    ).run();

    result.fold(
      (failure) => emit(
        append
            ? state.copyWith(loadingMore: false)
            : state.copyWith(status: RequestStatus.failure, failure: failure),
      ),
      (paged) => emit(
        state.copyWith(
          status: RequestStatus.success,
          invitations: append
              ? [...state.invitations, ...paged.items]
              : paged.items,
          page: paged.currentPage,
          totalPages: paged.totalPages,
          loadingMore: false,
        ),
      ),
    );
  }
}
