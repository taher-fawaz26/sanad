import 'package:app_logger/app_logger.dart';
import 'package:go_router/go_router.dart';
import 'package:notifications/notifications.dart';
import 'package:sanad_client/src/features/client_requests/client_requests.dart';

/// Opens a notification subject in the client app.
///
/// Subject *parsing* is shared (`package:notifications` owns it, so a client
/// and a provider cannot drift on what a subject means); only the destination
/// is role-specific, which is what this supplies.
///
/// The router is attached after construction because a push can arrive before
/// the app has one — during bootstrap, or from a cold start. Every method
/// tolerates that and simply drops the navigation rather than throwing on a
/// background isolate.
class ClientNotificationNavigator implements NotificationNavigator {
  GoRouter? _router;

  /// Attaches the live router. Called once, from the root widget.
  // ignore: use_setters_to_change_properties
  void attach(GoRouter router) => _router = router;

  /// Detaches on dispose so a stale router is never navigated.
  void detach() => _router = null;

  @override
  void openSubject(NotificationSubject subject) {
    final router = _router;
    if (router == null) {
      appLogger.w('Notification tapped before the router existed.');
      return;
    }
    final requestId = subject.requestId;
    if (requestId == null) {
      openInbox();
      return;
    }
    // A REQUEST_OFFER opens the thread *inside* its request rather than a
    // standalone offer screen — an offer has no meaning detached from the
    // request it negotiates.
    router.push(
      ClientRequestRoutes.detail(requestId, offerId: subject.offerId),
    );
  }

  @override
  void openInbox() => _router?.push(NotificationsRoutes.notifications);
}
