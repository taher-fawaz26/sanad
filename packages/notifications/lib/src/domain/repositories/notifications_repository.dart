import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:notifications/src/domain/entities/app_notification.dart';
import 'package:notifications/src/domain/enums/device_platform.dart';
import 'package:notifications/src/domain/usecases/notifications_query.dart';

/// A page of notifications plus the caller's unread count, which the endpoint
/// returns alongside the envelope so the bell badge needs no second call.
///
/// Named `Feed` rather than `Page` so it cannot be confused with the inbox
/// screen or with `core`'s `Page<T>` envelope, both of which it contains.
class NotificationsFeed {
  const NotificationsFeed({required this.page, required this.unreadCount});

  final Page<AppNotification> page;
  final int unreadCount;
}

abstract interface class NotificationsRepository {
  TaskEither<Failure, NotificationsFeed> getNotifications(
    NotificationsQuery query,
  );

  TaskEither<Failure, void> markRead(String id);

  TaskEither<Failure, void> markAllRead();

  /// Upserts this installation's push token. Safe to call repeatedly.
  TaskEither<Failure, void> registerDevice({
    required String token,
    required DevicePlatform platform,
  });

  /// Removes a token so a signed-out device stops receiving the next user's
  /// notifications. Idempotent server-side.
  TaskEither<Failure, void> unregisterDevice(String token);
}
