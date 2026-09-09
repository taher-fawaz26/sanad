import 'package:notifications/src/domain/entities/push_message.dart';

/// The app's only view of a push-messaging SDK.
///
/// `firebase_messaging` types stop here, exactly as `permission_handler` stops
/// at a single file in `package:permissions`. That is what makes the rest of
/// this package — the registration lifecycle, the routing, the dedup — testable
/// with a plain fake and free of a Firebase binary dependency.
abstract interface class PushMessagingGateway {
  /// Asks the OS for notification permission. `false` if declined.
  Future<bool> requestPermission();

  /// This installation's current registration token, or `null` when the
  /// platform has not issued one yet (notably iOS before the APNs token
  /// arrives).
  Future<String?> getToken();

  /// Fires whenever the SDK rotates the token.
  ///
  /// Exactly one subscription to this exists per app run — see
  /// `PushRegistrationCoordinator`.
  Stream<String> get onTokenRefresh;

  /// Pushes arriving while the app is in the foreground. The OS does not
  /// display these; the app decides whether to.
  Stream<PushMessage> get onMessage;

  /// A push the user tapped while the app was backgrounded but alive.
  Stream<PushMessage> get onMessageOpenedApp;

  /// The push that launched the app from a terminated state, if any.
  /// Returns `null` on an ordinary cold start.
  Future<PushMessage?> getInitialMessage();
}
