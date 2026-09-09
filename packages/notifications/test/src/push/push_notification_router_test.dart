import 'package:flutter_test/flutter_test.dart';
import 'package:notifications/notifications.dart';

import '../../support/notification_fakes.dart';

PushMessage _push({
  String? id = 'notif-1',
  String subjectType = 'CLIENT_REQUEST',
  String subjectId = 'req-1',
  String type = 'REQUEST_MATCHED',
  Map<String, dynamic> extra = const {},
}) => PushMessage.fromData(
  {
    if (id != null) 'notificationId': id,
    'type': type,
    'subjectType': subjectType,
    'subjectId': subjectId,
    ...extra,
  },
  title: 'Matched',
  body: 'Three providers can help.',
);

void main() {
  late FakePushMessagingGateway gateway;
  late FakeLocalStorage storage;
  late NotificationDedupStore dedup;
  late RecordingNotificationNavigator navigator;
  late List<PushMessage> presented;
  late PushNotificationRouter router;

  PushNotificationRouter build({
    NotificationNavigator? Function()? resolveNavigator,
    bool present = true,
  }) => PushNotificationRouter(
    gateway: gateway,
    dedupStore: dedup,
    resolveNavigator: resolveNavigator ?? () => navigator,
    presentForeground: present
        ? (message) async => presented.add(message)
        : null,
  );

  setUp(() {
    gateway = FakePushMessagingGateway();
    storage = FakeLocalStorage();
    dedup = NotificationDedupStore(storage: storage);
    navigator = RecordingNotificationNavigator();
    presented = [];
    router = build();
  });

  tearDown(() async {
    await router.dispose();
    await gateway.close();
  });

  group('tap routing', () {
    test('a CLIENT_REQUEST tap opens the request', () async {
      await router.handleTap(_push());

      expect(navigator.opened, hasLength(1));
      expect(navigator.opened.single.requestId, 'req-1');
      expect(navigator.inboxOpens, 0);
    });

    test('a REQUEST_OFFER tap opens the thread inside its request', () async {
      await router.handleTap(
        _push(
          subjectType: 'REQUEST_OFFER',
          subjectId: 'offer-7',
          type: 'REQUEST_OFFER_RECEIVED',
          extra: const {'requestId': 'req-1'},
        ),
      );

      final subject = navigator.opened.single;
      expect(subject.type, NotificationSubjectType.requestOffer);
      expect(subject.requestId, 'req-1');
      expect(subject.offerId, 'offer-7');
    });

    test('an offer with no requestId falls back to the inbox', () async {
      await router.handleTap(
        _push(subjectType: 'REQUEST_OFFER', subjectId: 'offer-7'),
      );

      expect(navigator.opened, isEmpty);
      expect(navigator.inboxOpens, 1);
    });

    test('an unknown subject falls back to the inbox', () async {
      await router.handleTap(_push(subjectType: 'INVOICE'));

      expect(navigator.inboxOpens, 1);
    });

    test('a tap before the navigator exists is dropped, not thrown', () async {
      final early = build(resolveNavigator: () => null);
      addTearDown(early.dispose);

      await expectLater(early.handleTap(_push()), completes);
    });
  });

  group('deduplication', () {
    test('the same notification navigates only once', () async {
      await router.handleTap(_push());
      await router.handleTap(_push());

      expect(navigator.opened, hasLength(1));
    });

    test('different notifications each navigate', () async {
      await router.handleTap(_push());
      await router.handleTap(_push(id: 'notif-2', subjectId: 'req-2'));

      expect(navigator.opened, hasLength(2));
    });

    test('a push with no id still navigates every time', () async {
      await router.handleTap(_push(id: null));
      await router.handleTap(_push(id: null));

      expect(navigator.opened, hasLength(2));
    });

    test(
      'showing a foreground banner does not consume the tap that follows it',
      () async {
        // Display and navigation are two actions on one event; sharing a dedup
        // slot would silently swallow the tap.
        await router.start();
        gateway.foreground.add(_push());
        await Future<void>.delayed(Duration.zero);
        expect(presented, hasLength(1));

        await router.handleTap(_push());

        expect(navigator.opened, hasLength(1));
      },
    );

    test('the same foreground push is shown only once', () async {
      await router.start();
      gateway.foreground
        ..add(_push())
        ..add(_push());
      await Future<void>.delayed(Duration.zero);

      expect(presented, hasLength(1));
    });
  });

  group('delivery paths', () {
    test('a cold start from a tapped push navigates once', () async {
      gateway.initialMessage = _push();

      await router.start();

      expect(navigator.opened, hasLength(1));
    });

    test('a cold-start push handled earlier does not re-navigate', () async {
      await router.handleTap(_push());
      gateway.initialMessage = _push();

      await router.start();

      expect(navigator.opened, hasLength(1));
    });

    test('a tap while backgrounded navigates', () async {
      await router.start();

      gateway.opened.add(_push());
      await Future<void>.delayed(Duration.zero);

      expect(navigator.opened, hasLength(1));
    });

    test('start() is idempotent', () async {
      await router.start();
      await router.start();

      gateway.opened.add(_push());
      await Future<void>.delayed(Duration.zero);

      expect(navigator.opened, hasLength(1));
    });
  });

  group('requestStateChanged', () {
    test('signals a timer-driven transition so open screens re-read', () async {
      // SUBMITTED to EXPIRED happens with no user action. The app models no
      // local timer for it; the push is the prompt to refetch.
      final signals = <NotificationSubject>[];
      final subscription = router.requestStateChanged.listen(signals.add);
      addTearDown(subscription.cancel);
      await router.start();

      gateway.foreground.add(_push(type: 'REQUEST_EXPIRED'));
      await Future<void>.delayed(Duration.zero);

      expect(signals, hasLength(1));
      expect(signals.single.requestId, 'req-1');
    });

    test('does not signal for an unrelated notification type', () async {
      final signals = <NotificationSubject>[];
      final subscription = router.requestStateChanged.listen(signals.add);
      addTearDown(subscription.cancel);
      await router.start();

      gateway.foreground.add(
        _push(type: 'ADMIN_MESSAGE_RECEIVED', subjectType: 'INVOICE'),
      );
      await Future<void>.delayed(Duration.zero);

      expect(signals, isEmpty);
    });

    test('signals on a tap as well as in the foreground', () async {
      final signals = <NotificationSubject>[];
      final subscription = router.requestStateChanged.listen(signals.add);
      addTearDown(subscription.cancel);

      await router.handleTap(_push(type: 'REQUEST_JOB_STARTED'));
      // The signal is added synchronously; a broadcast stream delivers it on
      // the next microtask.
      await Future<void>.delayed(Duration.zero);

      expect(signals, hasLength(1));
    });
  });

  group('PushMessage parsing', () {
    test('lifts FCM flat data keys into subject metadata', () {
      // FCM data payloads are Map<String, String>: nested JSON does not
      // survive, so metadata arrives as sibling keys.
      final message = _push(
        subjectType: 'REQUEST_OFFER',
        subjectId: 'offer-7',
        extra: const {'requestId': 'req-1', 'serviceName': 'Deep cleaning'},
      );

      expect(message.subject.requestId, 'req-1');
      expect(message.subject.serviceName, 'Deep cleaning');
    });

    test('reads a bare id key when notificationId is absent', () {
      final message = PushMessage.fromData(const {
        'id': 'notif-9',
        'subjectType': 'CLIENT_REQUEST',
        'subjectId': 'req-1',
      });

      expect(message.notificationId, 'notif-9');
    });

    test('a payload with no subject yields NotificationSubject.none', () {
      final message = PushMessage.fromData(const {'id': 'notif-9'});

      expect(message.subject, NotificationSubject.none);
      expect(message.subject.isNavigable, isFalse);
    });
  });
}
