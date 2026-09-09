import 'package:flutter_test/flutter_test.dart';
import 'package:notifications/notifications.dart';

import '../../support/notification_fakes.dart';

void main() {
  late FakeLocalStorage storage;
  late NotificationDedupStore store;

  setUp(() {
    storage = FakeLocalStorage();
    store = NotificationDedupStore(storage: storage);
  });

  test('the first sighting of an id is new; the second is not', () async {
    expect(await store.markHandled('notif-1'), isTrue);
    expect(await store.markHandled('notif-1'), isFalse);
  });

  test('different ids are independent', () async {
    expect(await store.markHandled('notif-1'), isTrue);
    expect(await store.markHandled('notif-2'), isTrue);
  });

  test('survives a process restart', () async {
    // The two deliveries of one event can straddle a process death: a push
    // handled in the background, then the cold-start tap that follows it.
    await store.markHandled('notif-1');

    final afterRestart = NotificationDedupStore(storage: storage);

    expect(await afterRestart.markHandled('notif-1'), isFalse);
  });

  test('a delivery with no stable id is always treated as new', () async {
    // Not every push carries the server notification id. Acting twice is
    // better than silently swallowing a real notification.
    expect(await store.markHandled(null), isTrue);
    expect(await store.markHandled(null), isTrue);
    expect(await store.markHandled('   '), isTrue);
  });

  test('is bounded, evicting the oldest ids first', () async {
    final small = NotificationDedupStore(storage: storage, capacity: 3);
    for (final id in ['a', 'b', 'c', 'd']) {
      await small.markHandled(id);
    }

    expect(await small.isHandled('a'), isFalse, reason: 'evicted');
    expect(await small.isHandled('b'), isTrue);
    expect(await small.isHandled('d'), isTrue);
  });

  test('isHandled does not itself record the id', () async {
    expect(await store.isHandled('notif-1'), isFalse);
    expect(await store.markHandled('notif-1'), isTrue);
  });

  test('clear() forgets everything', () async {
    // Runs at a session boundary so one account's handled ids cannot suppress
    // another's notifications on a shared device.
    await store.markHandled('notif-1');

    await store.clear();

    expect(await store.markHandled('notif-1'), isTrue);
  });
}
