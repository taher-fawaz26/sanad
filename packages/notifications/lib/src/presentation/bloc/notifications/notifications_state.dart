part of 'notifications_bloc.dart';

class NotificationsState extends Equatable {
  const NotificationsState({
    this.data = const PaginationData<AppNotification>(),
    this.unreadCount = 0,
    this.markAllStatus = RequestStatus.initial,
    this.markAllFailure,
  });

  final PaginationData<AppNotification> data;

  /// Server-reported unread total, returned alongside the page so the bell
  /// badge needs no second call.
  final int unreadCount;

  final RequestStatus markAllStatus;
  final Failure? markAllFailure;

  NotificationsState copyWith({
    PaginationData<AppNotification>? data,
    int? unreadCount,
    RequestStatus? markAllStatus,
    Failure? markAllFailure,
    bool clearMarkAllFailure = false,
  }) => NotificationsState(
    data: data ?? this.data,
    unreadCount: unreadCount ?? this.unreadCount,
    markAllStatus: markAllStatus ?? this.markAllStatus,
    markAllFailure: clearMarkAllFailure
        ? null
        : (markAllFailure ?? this.markAllFailure),
  );

  @override
  List<Object?> get props => [data, unreadCount, markAllStatus, markAllFailure];
}
