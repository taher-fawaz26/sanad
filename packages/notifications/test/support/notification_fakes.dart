import 'dart:async';

import 'package:notifications/notifications.dart';
import 'package:storage/storage.dart';

/// In-memory [LocalStorage] — mirrors Hive's read/write/delete semantics
/// without touching disk.
class FakeLocalStorage implements LocalStorage {
  final Map<String, Object?> values = {};

  @override
  Future<Object?> load({required String key, String? boxName}) async =>
      values[key];

  @override
  Future<void> save({
    required String key,
    required Object? value,
    String? boxName,
  }) async => values[key] = value;

  @override
  Future<void> delete({required String key, String? boxName}) async =>
      values.remove(key);
}

/// A scriptable [PushMessagingGateway]. The whole reason the real gateway is a
/// one-file boundary: every push concern is testable without Firebase.
class FakePushMessagingGateway implements PushMessagingGateway {
  FakePushMessagingGateway({this.token = 'token-1', this.initialMessage});

  String? token;
  PushMessage? initialMessage;

  final StreamController<String> tokenRefreshes =
      StreamController<String>.broadcast();
  final StreamController<PushMessage> foreground =
      StreamController<PushMessage>.broadcast();
  final StreamController<PushMessage> opened =
      StreamController<PushMessage>.broadcast();

  int tokenRefreshListenerCount = 0;
  int getTokenCalls = 0;

  @override
  Future<String?> getToken() async {
    getTokenCalls++;
    return token;
  }

  @override
  Stream<String> get onTokenRefresh {
    tokenRefreshListenerCount++;
    return tokenRefreshes.stream;
  }

  @override
  Stream<PushMessage> get onMessage => foreground.stream;

  @override
  Stream<PushMessage> get onMessageOpenedApp => opened.stream;

  @override
  Future<PushMessage?> getInitialMessage() async => initialMessage;

  @override
  Future<bool> requestPermission() async => true;

  Future<void> close() async {
    await tokenRefreshes.close();
    await foreground.close();
    await opened.close();
  }
}

/// Records what a tap resolved to.
class RecordingNotificationNavigator implements NotificationNavigator {
  final List<NotificationSubject> opened = [];
  int inboxOpens = 0;

  @override
  void openSubject(NotificationSubject subject) => opened.add(subject);

  @override
  void openInbox() => inboxOpens++;
}
