part of 'notifications_bloc.dart';

sealed class NotificationsEvent extends Equatable {
  const NotificationsEvent();

  @override
  List<Object?> get props => const [];
}

/// First load of the inbox.
final class NotificationsStarted extends NotificationsEvent {
  const NotificationsStarted();
}

/// Infinite-scroll page append.
final class NotificationsNextPageRequested extends NotificationsEvent {
  const NotificationsNextPageRequested();
}

/// Pull-to-refresh, and the re-read performed when the screen becomes active
/// again or a push signals that something changed.
final class NotificationsRefreshed extends NotificationsEvent {
  const NotificationsRefreshed();
}

/// Marks one row read — dispatched when the user opens it.
final class NotificationMarkedRead extends NotificationsEvent {
  const NotificationMarkedRead(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}

/// Marks every unread row read.
final class NotificationsAllMarkedRead extends NotificationsEvent {
  const NotificationsAllMarkedRead();
}
