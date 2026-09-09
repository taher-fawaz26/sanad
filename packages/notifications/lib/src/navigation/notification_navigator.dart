import 'package:notifications/src/domain/entities/notification_subject.dart';

/// How this app opens a notification subject.
///
/// Subject *parsing* is shared (see [NotificationSubject]); only the
/// destination differs by role, so each app supplies one of these. A client
/// opens its own request; a provider opens the same request through its own
/// role-specific view.
abstract interface class NotificationNavigator {
  /// Opens the screen for [subject].
  ///
  /// Called only for a navigable subject. Implementations must tolerate being
  /// invoked before the router is ready and degrade to the notification list
  /// rather than throwing — a push can arrive at any moment in the app's life.
  void openSubject(NotificationSubject subject);

  /// Opens the notification inbox. The fallback whenever a subject is absent,
  /// unrecognised, or missing the request it belongs to.
  void openInbox();
}
