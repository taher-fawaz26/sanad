import 'dart:async';

import 'package:app_logger/app_logger.dart';
import 'package:notifications/src/domain/entities/notification_subject.dart';
import 'package:notifications/src/domain/entities/push_message.dart';
import 'package:notifications/src/domain/services/push_messaging_gateway.dart';
import 'package:notifications/src/navigation/notification_dedup_store.dart';
import 'package:notifications/src/navigation/notification_navigator.dart';

/// Turns an inbound push into a banner, a navigation, or a refresh signal —
/// once each, whichever way it arrived.
///
/// The three delivery paths (foreground, tap-while-backgrounded, tap-from-
/// terminated) all converge here so the destination rule is written once.
///
/// This is the mobile counterpart to the backend's SSE stream, which is a web
/// channel and is deliberately not implemented. Nothing here opens a
/// connection: FCM delivers while backgrounded, and [requestStateChanged] lets
/// an open screen re-read the resource — the server stays the source of truth
/// for the transitions that happen on timers rather than on a tap.
class PushNotificationRouter {
  PushNotificationRouter({
    required PushMessagingGateway gateway,
    required NotificationDedupStore dedupStore,
    required NotificationNavigator? Function() resolveNavigator,
    Future<void> Function(PushMessage message)? presentForeground,
  }) : _gateway = gateway,
       _dedupStore = dedupStore,
       _resolveNavigator = resolveNavigator,
       _presentForeground = presentForeground;

  final PushMessagingGateway _gateway;
  final NotificationDedupStore _dedupStore;
  final NotificationNavigator? Function() _resolveNavigator;
  final Future<void> Function(PushMessage message)? _presentForeground;

  final StreamController<NotificationSubject> _requestStateChanged =
      StreamController<NotificationSubject>.broadcast();

  StreamSubscription<PushMessage>? _foregroundSubscription;
  StreamSubscription<PushMessage>? _openedAppSubscription;
  bool _started = false;

  /// Emits whenever a push says the server-side state of a request moved.
  ///
  /// A screen showing that request should re-read it. The frame is a signal,
  /// not the resource: the payload is minimal and role-neutral, while the full
  /// request differs by who is asking for it.
  Stream<NotificationSubject> get requestStateChanged =>
      _requestStateChanged.stream;

  /// Attaches every delivery path. Idempotent — a second call is a no-op, so a
  /// re-entered bootstrap cannot produce duplicate handlers.
  Future<void> start() async {
    if (_started) return;
    _started = true;

    _foregroundSubscription = _gateway.onMessage.listen(
      (message) => _handleForeground(message).ignore(),
      onError: (Object error) => appLogger.w('Push stream failed: $error'),
    );
    _openedAppSubscription = _gateway.onMessageOpenedApp.listen(
      (message) => handleTap(message).ignore(),
      onError: (Object error) => appLogger.w('Push tap stream failed: $error'),
    );

    // A push that launched the app from terminated. Deduplicated like any
    // other, because the same notification may already have been acted on in
    // an earlier run.
    final initial = await _gateway.getInitialMessage();
    if (initial != null) await handleTap(initial);
  }

  /// Navigates for [message], at most once per notification id.
  Future<void> handleTap(PushMessage message) async {
    final isNew = await _dedupStore.markHandled(
      _key('nav', message.notificationId),
    );
    if (!isNew) {
      appLogger.i('Ignoring an already-handled notification tap.');
      return;
    }
    _signalRequestState(message);

    final navigator = _resolveNavigator();
    if (navigator == null) {
      appLogger.w('No notification navigator yet; dropping the tap.');
      return;
    }
    final subject = message.subject;
    if (subject.isNavigable) {
      navigator.openSubject(subject);
    } else {
      // No subject, an unknown subject, or an offer with no request to open it
      // inside. The inbox is always a valid destination.
      navigator.openInbox();
    }
  }

  Future<void> _handleForeground(PushMessage message) async {
    _signalRequestState(message);
    final present = _presentForeground;
    if (present == null) return;
    final isNew = await _dedupStore.markHandled(
      _key('show', message.notificationId),
    );
    if (!isNew) return;
    await present(message);
  }

  void _signalRequestState(PushMessage message) {
    if (!message.type.invalidatesRequestState) return;
    if (_requestStateChanged.isClosed) return;
    _requestStateChanged.add(message.subject);
  }

  /// Namespaced so showing a foreground banner does not consume the dedup slot
  /// for the tap that follows it — those are two actions on one event.
  static String? _key(String action, String? id) =>
      id == null || id.isEmpty ? null : '$action:$id';

  Future<void> dispose() async {
    await _foregroundSubscription?.cancel();
    await _openedAppSubscription?.cancel();
    _foregroundSubscription = null;
    _openedAppSubscription = null;
    _started = false;
    await _requestStateChanged.close();
  }
}
