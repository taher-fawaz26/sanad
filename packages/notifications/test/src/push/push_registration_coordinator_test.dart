import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:notifications/notifications.dart';

import '../../support/notification_fakes.dart';

class _MockRepository extends Mock implements NotificationsRepository {}

void main() {
  // `any(named: 'platform')` needs a fallback for a non-nullable custom type.
  setUpAll(() => registerFallbackValue(DevicePlatform.android));

  late FakePushMessagingGateway gateway;
  late FakeLocalStorage storage;
  late _MockRepository repository;
  late PushRegistrationCoordinator coordinator;

  setUp(() {
    gateway = FakePushMessagingGateway();
    storage = FakeLocalStorage();
    repository = _MockRepository();
    when(
      () => repository.registerDevice(
        token: any(named: 'token'),
        platform: any(named: 'platform'),
      ),
    ).thenReturn(TaskEither.right(null));
    when(
      () => repository.unregisterDevice(any()),
    ).thenReturn(TaskEither.right(null));

    coordinator = PushRegistrationCoordinator(
      gateway: gateway,
      registerDevice: RegisterDeviceUseCase(repository),
      unregisterDevice: UnregisterDeviceUseCase(repository),
      storage: storage,
      resolvePlatform: () => DevicePlatform.android,
    );
  });

  tearDown(() async {
    await coordinator.dispose();
    await gateway.close();
  });

  group('syncRegistration', () {
    test('upserts the current token', () async {
      await coordinator.syncRegistration();

      verify(
        () => repository.registerDevice(
          token: 'token-1',
          platform: DevicePlatform.android,
        ),
      ).called(1);
    });

    test('is an upsert — calling it again re-registers', () async {
      // Registration is not a one-time setup step: the server also refreshes a
      // last-seen timestamp that keeps the token from being pruned.
      await coordinator.syncRegistration();
      await coordinator.syncRegistration();

      verify(
        () => repository.registerDevice(
          token: any(named: 'token'),
          platform: any(named: 'platform'),
        ),
      ).called(2);
    });

    test('defers quietly when the SDK has no token yet', () async {
      // Normal on iOS before the APNs token arrives.
      gateway.token = null;

      await coordinator.syncRegistration();

      verifyNever(
        () => repository.registerDevice(
          token: any(named: 'token'),
          platform: any(named: 'platform'),
        ),
      );
    });

    test('never throws when the request fails', () async {
      when(
        () => repository.registerDevice(
          token: any(named: 'token'),
          platform: any(named: 'platform'),
        ),
      ).thenReturn(TaskEither.left(const ServerFailure(message: 'boom')));

      await expectLater(coordinator.syncRegistration(), completes);
    });
  });

  group('token refresh', () {
    test('a rotated token re-registers', () async {
      coordinator.start();

      gateway.tokenRefreshes.add('token-2');
      await Future<void>.delayed(Duration.zero);

      verify(
        () => repository.registerDevice(
          token: 'token-2',
          platform: DevicePlatform.android,
        ),
      ).called(1);
    });

    test(
      'start() is idempotent — no duplicate listeners on relaunch',
      () async {
        // A re-entered bootstrap, or a second module initialize(), must not
        // produce two registration callbacks for one rotation.
        coordinator
          ..start()
          ..start()
          ..start();

        expect(gateway.tokenRefreshListenerCount, 1);

        gateway.tokenRefreshes.add('token-2');
        await Future<void>.delayed(Duration.zero);

        verify(
          () => repository.registerDevice(
            token: 'token-2',
            platform: any(named: 'platform'),
          ),
        ).called(1);
      },
    );
  });

  group('unregister', () {
    test('deletes the token the server actually holds', () async {
      // Not whatever the SDK reports now: if the token rotated after
      // registration, asking the SDK would delete the wrong one and leave the
      // real registration forwarding the next user's notifications.
      await coordinator.syncRegistration();
      gateway.token = 'token-rotated-since';

      await coordinator.unregister();

      verify(() => repository.unregisterDevice('token-1')).called(1);
    });

    test(
      'does nothing when this coordinator never registered a token',
      () async {
        // `SessionManager.clear()` also runs on a 401-refresh failure and on a
        // signed-out cold start. Falling back to the SDK token there fires an
        // unauthenticated DELETE every time, which the backend answers 401 and
        // then 429 once they pile up — observed on device before this guard.
        await coordinator.unregister();

        verifyNever(() => repository.unregisterDevice(any()));
      },
    );

    test('forgets the token even when the delete fails', () async {
      // A token we could not delete must not be re-sent under the next user's
      // credentials.
      when(
        () => repository.unregisterDevice(any()),
      ).thenReturn(TaskEither.left(const ServerFailure(message: 'offline')));
      await coordinator.syncRegistration();

      await coordinator.unregister();

      expect(storage.values, isEmpty);
    });

    test('never throws when the request fails', () async {
      when(
        () => repository.unregisterDevice(any()),
      ).thenReturn(TaskEither.left(const NoInternetFailure(message: 'x')));

      await expectLater(coordinator.unregister(), completes);
    });

    test('is a no-op when there is no token at all', () async {
      gateway.token = null;

      await coordinator.unregister();

      verifyNever(() => repository.unregisterDevice(any()));
    });

    test('a second unregister does not re-send the deleted token', () async {
      await coordinator.syncRegistration();
      await coordinator.unregister();
      clearInteractions(repository);

      await coordinator.unregister();

      verifyNever(() => repository.unregisterDevice(any()));
    });
  });

  test('DevicePlatform sends only IOS or ANDROID', () {
    expect(DevicePlatform.ios.apiValue, 'IOS');
    expect(DevicePlatform.android.apiValue, 'ANDROID');
    expect(DevicePlatform.values, hasLength(2));
  });
}
