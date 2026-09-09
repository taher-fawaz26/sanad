/// Notification endpoint paths.
///
/// Relative, no leading slash and no `/api/v1` prefix — the configured base URL
/// already ends in `/api/v1/` (see `NetworkConfig`).
///
/// The backend also exposes `notifications/stream-ticket` and
/// `notifications/stream`. Those are **deliberately absent**: the SSE stream is
/// a web delivery channel and is out of scope for the mobile apps, which use
/// FCM while backgrounded and re-read these endpoints when a screen activates.
abstract final class NotificationsApiPaths {
  NotificationsApiPaths._();

  /// `GET` — the caller's own notifications, newest first, paginated.
  static const String notifications = 'notifications';

  /// `PATCH` — mark one notification read.
  static String read(String id) => 'notifications/$id/read';

  /// `PATCH` — mark every unread notification read.
  static const String readAll = 'notifications/read-all';

  /// `POST` — register or refresh this installation's push token. `204`.
  ///
  /// An upsert: safe (and required) on every launch, not a one-time setup.
  static const String devices = 'notifications/devices';

  /// `DELETE` — unregister a token on logout. `204`, and idempotent, so a
  /// retried logout is safe.
  static String device(String token) =>
      'notifications/devices/${Uri.encodeComponent(token)}';
}
