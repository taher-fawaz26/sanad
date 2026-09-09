import 'package:app_logger/app_logger.dart';
import 'package:go_router/go_router.dart';
import 'package:notifications/notifications.dart';
import 'package:sanad_provider/src/features/requests/requests.dart';

/// Opens a notification subject in the provider app.
///
/// Subject parsing is shared with the client (`package:notifications` owns it);
/// only the destination differs. A provider has exactly one negotiation thread
/// per request, so a `REQUEST_OFFER` and a `CLIENT_REQUEST` both land on the
/// same screen — the request detail — with nothing further to disambiguate.
///
/// The router is attached after construction because a push can arrive before
/// the app has one.
class ProviderNotificationNavigator implements NotificationNavigator {
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
    router.push(ProviderRequestRoutes.detail(requestId));
  }

  @override
  void openInbox() => _router?.push(NotificationsRoutes.notifications);
}
