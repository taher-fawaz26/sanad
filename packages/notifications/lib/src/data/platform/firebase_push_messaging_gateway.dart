import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:notifications/src/domain/entities/push_message.dart';
import 'package:notifications/src/domain/services/push_messaging_gateway.dart';

/// The single `firebase_messaging` boundary.
///
/// Nothing else in the app may import that package: keeping it here is what
/// lets every other notification concern be unit-tested without Firebase, and
/// guarantees there is exactly one token-refresh stream to subscribe to.
class FirebasePushMessagingGateway implements PushMessagingGateway {
  FirebasePushMessagingGateway({FirebaseMessaging? messaging})
    : _messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseMessaging _messaging;

  @override
  Future<bool> requestPermission() async {
    final settings = await _messaging.requestPermission();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  @override
  Future<String?> getToken() => _messaging.getToken();

  @override
  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  @override
  Stream<PushMessage> get onMessage =>
      FirebaseMessaging.onMessage.map(_toPushMessage);

  @override
  Stream<PushMessage> get onMessageOpenedApp =>
      FirebaseMessaging.onMessageOpenedApp.map(_toPushMessage);

  @override
  Future<PushMessage?> getInitialMessage() async {
    final message = await _messaging.getInitialMessage();
    return message == null ? null : _toPushMessage(message);
  }

  static PushMessage _toPushMessage(RemoteMessage message) =>
      PushMessage.fromData(
        message.data,
        title: message.notification?.title,
        body: message.notification?.body,
      );
}
