import 'dart:convert';

import 'package:app_logger/app_logger.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:notifications/src/domain/entities/push_message.dart';

/// Displays a push that arrived while the app was in the foreground.
///
/// The OS suppresses its own banner for a foreground delivery, so without this
/// a notification received while the user is looking at the app is invisible.
/// Taps on what this shows re-enter the same routing path as an OS tap, so
/// there is one destination rule regardless of where the app was.
class LocalNotificationPresenter {
  LocalNotificationPresenter({
    required void Function(PushMessage message) onTap,
    FlutterLocalNotificationsPlugin? plugin,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
       _onTap = onTap;

  static const AndroidNotificationDetails _androidDetails =
      AndroidNotificationDetails(
        'sanad_default',
        'General',
        channelDescription: 'Request updates, offers and account notices.',
        importance: Importance.high,
        priority: Priority.high,
      );

  final FlutterLocalNotificationsPlugin _plugin;
  final void Function(PushMessage message) _onTap;

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          // The OS banner is requested through `package:permissions`, so this
          // must not prompt a second time.
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: _handleResponse,
    );
  }

  /// Shows [message]. A push with no title and no body is a silent data
  /// message and is not displayed.
  Future<void> show(PushMessage message) async {
    final title = message.title;
    final body = message.body;
    if ((title == null || title.isEmpty) && (body == null || body.isEmpty)) {
      return;
    }
    await initialize();
    await _plugin.show(
      // A stable, non-negative id derived from the server notification id, so
      // the same notification cannot stack twice in the tray.
      (message.notificationId ?? '').hashCode & 0x7fffffff,
      title,
      body,
      const NotificationDetails(
        android: _androidDetails,
        iOS: DarwinNotificationDetails(),
      ),
      payload: jsonEncode(message.data),
    );
  }

  void _handleResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;
    try {
      final decoded = jsonDecode(payload);
      if (decoded is! Map) return;
      _onTap(PushMessage.fromData(Map<String, dynamic>.from(decoded)));
    } on FormatException catch (error) {
      appLogger.w('Unreadable local-notification payload: $error');
    }
  }
}
