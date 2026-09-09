abstract final class NotificationsRoutes {
  NotificationsRoutes._();

  static const notifications = '/notifications';

  /// Requires an authenticated session — the inbox is per-account.
  static const Set<String> protectedRoutes = {notifications};
}
