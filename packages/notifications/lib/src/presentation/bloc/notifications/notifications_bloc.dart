import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:notifications/src/domain/entities/app_notification.dart';
import 'package:notifications/src/domain/usecases/get_notifications_usecase.dart';
import 'package:notifications/src/domain/usecases/mark_all_notifications_read_usecase.dart';
import 'package:notifications/src/domain/usecases/mark_notification_read_usecase.dart';
import 'package:notifications/src/domain/usecases/notifications_query.dart';

part 'notifications_event.dart';
part 'notifications_state.dart';

/// The notification inbox.
///
/// Read state comes only from the server. There is no local timer and no
/// stream: a refresh happens on open, on pull-to-refresh, and when a push
/// signals that something changed.
class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState>
    with
        PaginationMixin<
          NotificationsEvent,
          NotificationsState,
          AppNotification,
          NotificationsQuery
        > {
  NotificationsBloc({
    required GetNotificationsUseCase getNotifications,
    required MarkNotificationReadUseCase markRead,
    required MarkAllNotificationsReadUseCase markAllRead,
  }) : _getNotifications = getNotifications,
       _markRead = markRead,
       _markAllRead = markAllRead,
       super(const NotificationsState()) {
    on<NotificationsStarted>((_, emit) => loadFirstPage(emit));
    on<NotificationsNextPageRequested>(
      (_, emit) => loadNextPage(emit),
      transformer: droppable(),
    );
    on<NotificationsRefreshed>(
      (_, emit) => refresh(emit),
      transformer: restartable(),
    );
    on<NotificationMarkedRead>(_onMarkedRead, transformer: sequential());
    on<NotificationsAllMarkedRead>(
      _onAllMarkedRead,
      transformer: droppable(),
    );
  }

  final GetNotificationsUseCase _getNotifications;
  final MarkNotificationReadUseCase _markRead;
  final MarkAllNotificationsReadUseCase _markAllRead;

  /// Carries the unread total from the fetch into the next emit.
  ///
  /// [PaginationMixin.fetchPage] can only return the page, but the endpoint
  /// answers with `unreadCount` beside it. Folding it in from [writePage] —
  /// which the mixin calls on every emit — keeps the badge in step with the
  /// list without a second request.
  int? _pendingUnreadCount;

  @override
  PaginationData<AppNotification> readPage(NotificationsState state) =>
      state.data;

  @override
  NotificationsState writePage(
    NotificationsState state,
    PaginationData<AppNotification> data,
  ) {
    final unread = _pendingUnreadCount;
    _pendingUnreadCount = null;
    return state.copyWith(data: data, unreadCount: unread);
  }

  @override
  NotificationsQuery buildQuery({required int page}) =>
      NotificationsQuery(page: page);

  @override
  Object? dedupKey(AppNotification item) => item.id;

  @override
  TaskEither<Failure, Page<AppNotification>> fetchPage(
    NotificationsQuery query,
  ) => _getNotifications(query).map((result) {
    _pendingUnreadCount = result.unreadCount;
    return result.page;
  });

  Future<void> _onMarkedRead(
    NotificationMarkedRead event,
    Emitter<NotificationsState> emit,
  ) async {
    final target = state.data.items
        .where((item) => item.id == event.id)
        .firstOrNull;
    if (target == null || !target.isUnread) return;

    // Optimistic: the row is already open on screen, so waiting for a round
    // trip to un-bold it would be visible. A failure re-reads rather than
    // rolling back by hand.
    emit(_withRead(event.id));
    final result = await _markRead(event.id).run();
    if (result.isLeft()) add(const NotificationsRefreshed());
  }

  Future<void> _onAllMarkedRead(
    NotificationsAllMarkedRead event,
    Emitter<NotificationsState> emit,
  ) async {
    emit(
      state.copyWith(
        markAllStatus: RequestStatus.loading,
        clearMarkAllFailure: true,
      ),
    );
    final result = await _markAllRead(const NoParams()).run();
    result.match(
      (failure) => emit(
        state.copyWith(
          markAllStatus: RequestStatus.failure,
          markAllFailure: failure,
        ),
      ),
      (_) => emit(state.copyWith(markAllStatus: RequestStatus.success)),
    );
    // Re-read either way: on success to pick up the server's own unread total,
    // on failure because the local view may already be out of date.
    add(const NotificationsRefreshed());
  }

  NotificationsState _withRead(String id) {
    final now = DateTime.now();
    final items = state.data.items
        .map((item) => item.id == id ? item.copyWith(readAt: now) : item)
        .toList();
    return state.copyWith(
      data: state.data.copyWith(items: items),
      unreadCount: state.unreadCount > 0 ? state.unreadCount - 1 : 0,
    );
  }
}
