import 'package:account_settings/src/domain/enums/app_lock_capability.dart';
import 'package:account_settings/src/domain/enums/app_lock_state.dart';
import 'package:account_settings/src/domain/repositories/app_lock_repository.dart';
import 'package:account_settings/src/presentation/lock/app_lock_controller.dart';
import 'package:auth/auth.dart';
import 'package:device/device.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements AppLockRepository {}

class _MockBiometricService extends Mock implements BiometricService {}

class _MockSessionManager extends Mock implements SessionManager {}

class _MockSession extends Mock implements AuthSessionEntity {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockRepository repository;
  late _MockBiometricService biometrics;
  late _MockSessionManager sessionManager;
  late ValueNotifier<AuthSessionEntity?> sessionNotifier;
  late AuthSessionEntity? session;

  AppLockController build({bool featureEnabled = true}) => AppLockController(
    repository: repository,
    biometrics: biometrics,
    sessionManager: sessionManager,
    featureEnabled: featureEnabled,
  );

  void stubAuth(BiometricAuthStatus status) {
    when(
      () => biometrics.authenticate(
        reason: any(named: 'reason'),
        biometricOnly: any(named: 'biometricOnly'),
      ),
    ).thenAnswer((_) async => BiometricAuthResult(status: status));
  }

  /// Verifies how many OS prompts were raised.
  void verifyPrompts(int count) {
    if (count == 0) {
      verifyNever(
        () => biometrics.authenticate(
          reason: any(named: 'reason'),
          biometricOnly: any(named: 'biometricOnly'),
        ),
      );
      return;
    }
    verify(
      () => biometrics.authenticate(
        reason: any(named: 'reason'),
        biometricOnly: any(named: 'biometricOnly'),
      ),
    ).called(count);
  }

  setUp(() {
    repository = _MockRepository();
    biometrics = _MockBiometricService();
    sessionManager = _MockSessionManager();
    session = _MockSession();
    sessionNotifier = ValueNotifier<AuthSessionEntity?>(session);

    when(() => sessionManager.watch()).thenReturn(sessionNotifier);
    when(() => sessionManager.current()).thenAnswer((_) => session);
    when(repository.isEnabled).thenAnswer((_) async => true);
    when(
      repository.capability,
    ).thenAnswer((_) async => AppLockCapability.available);
    when(
      () => repository.setEnabled(enabled: any(named: 'enabled')),
    ).thenAnswer((_) async {});
    stubAuth(BiometricAuthStatus.success);
  });

  tearDown(() => sessionNotifier.dispose());

  group('initialize', () {
    test('feature flag off means unlocked and no prompt', () async {
      final controller = build(featureEnabled: false);
      await controller.initialize();

      expect(controller.state, AppLockState.unlocked);
      expect(controller.isOpen, isTrue);
      verifyNever(repository.isEnabled);
      verifyPrompts(0);
    });

    test('preference off means unlocked and no prompt', () async {
      when(repository.isEnabled).thenAnswer((_) async => false);
      final controller = build();
      await controller.initialize();

      expect(controller.state, AppLockState.unlocked);
      verifyPrompts(0);
    });

    test('no session means unlocked and no prompt', () async {
      session = null;
      when(() => sessionManager.current()).thenAnswer((_) => null);
      final controller = build();
      await controller.initialize();

      expect(controller.state, AppLockState.unlocked);
      verifyPrompts(0);
    });

    test(
      'capability lost while enabled is unavailable, and fails OPEN',
      () async {
        when(
          repository.capability,
        ).thenAnswer((_) async => AppLockCapability.unsupported);
        final controller = build();
        await controller.initialize();

        expect(controller.state, AppLockState.unavailable);
        // Fail open: a device that can authenticate nobody must not be able to
        // lock the user out of an app no credential can open.
        expect(controller.isOpen, isTrue);
        verifyPrompts(0);
      },
    );

    test(
      'session + enabled + available locks and prompts exactly once',
      () async {
        final controller = build();
        await controller.initialize();

        expect(controller.state, AppLockState.unlocked);
        verifyPrompts(1);
      },
    );

    test('a failed prompt leaves the gate shut with no auto-retry', () async {
      stubAuth(BiometricAuthStatus.failed);
      final controller = build();
      await controller.initialize();

      expect(controller.state, AppLockState.locked);
      expect(controller.isOpen, isFalse);
      expect(controller.lastFailure, BiometricAuthStatus.failed);
      // Exactly one prompt: no retry loop.
      verifyPrompts(1);
    });

    test('lockout is recorded for the lock screen but stays locked', () async {
      stubAuth(BiometricAuthStatus.lockedOut);
      final controller = build();
      await controller.initialize();

      expect(controller.state, AppLockState.locked);
      expect(controller.lastFailure, BiometricAuthStatus.lockedOut);
    });

    test(
      'unknown is not open, so nothing protected renders before we know',
      () {
        final controller = build();

        expect(controller.state, AppLockState.unknown);
        expect(controller.isOpen, isFalse);
      },
    );

    test(
      'passes biometricOnly false so the device passcode is accepted',
      () async {
        final controller = build();
        await controller.initialize();

        final captured = verify(
          () => biometrics.authenticate(
            reason: any(named: 'reason'),
            biometricOnly: captureAny(named: 'biometricOnly'),
          ),
        ).captured;
        expect(captured.single, isFalse);
      },
    );
  });

  group('authenticate', () {
    test('concurrent calls raise a single OS prompt', () async {
      stubAuth(BiometricAuthStatus.failed);
      final controller = build();
      await controller.initialize();
      clearInteractions(biometrics);
      stubAuth(BiometricAuthStatus.success);

      await Future.wait([controller.authenticate(), controller.authenticate()]);

      verifyPrompts(1);
    });

    test('is a no-op when the gate is already open', () async {
      final controller = build();
      await controller.initialize();
      clearInteractions(biometrics);

      await controller.authenticate();

      verifyPrompts(0);
    });

    test(
      'a session ending mid-prompt does not unlock into a dead session',
      () async {
        stubAuth(BiometricAuthStatus.failed);
        final controller = build();
        await controller.initialize();

        when(
          () => biometrics.authenticate(
            reason: any(named: 'reason'),
            biometricOnly: any(named: 'biometricOnly'),
          ),
        ).thenAnswer((_) async {
          when(() => sessionManager.current()).thenAnswer((_) => null);
          return const BiometricAuthResult.success();
        });

        await controller.authenticate();

        expect(controller.state, AppLockState.unlocked);
        expect(controller.lastFailure, isNull);
      },
    );
  });

  group('lifecycle', () {
    test('pause locks, resume re-prompts once', () async {
      final controller = build();
      await controller.initialize();
      clearInteractions(biometrics);
      stubAuth(BiometricAuthStatus.failed);

      controller.onAppPaused();
      expect(controller.state, AppLockState.locked);

      controller.onAppResumed();
      await Future<void>.delayed(Duration.zero);

      verifyPrompts(1);
    });

    test('repeated resume events do not stack prompts', () async {
      final controller = build();
      await controller.initialize();
      clearInteractions(biometrics);
      stubAuth(BiometricAuthStatus.failed);

      controller
        ..onAppPaused()
        ..onAppResumed()
        ..onAppResumed()
        ..onAppResumed();
      await Future<void>.delayed(Duration.zero);

      verifyPrompts(1);
    });

    test('repeated pause events are idempotent', () async {
      final controller = build();
      await controller.initialize();
      stubAuth(BiometricAuthStatus.failed);

      controller
        ..onAppPaused()
        ..onAppPaused();

      expect(controller.state, AppLockState.locked);
    });

    test('pause does nothing when the preference is off', () async {
      when(repository.isEnabled).thenAnswer((_) async => false);
      final controller = build();
      await controller.initialize();

      controller.onAppPaused();

      expect(controller.state, AppLockState.unlocked);
    });

    test('pause does nothing without a session', () async {
      final controller = build();
      await controller.initialize();
      when(() => sessionManager.current()).thenAnswer((_) => null);

      controller.onAppPaused();

      expect(controller.state, AppLockState.unlocked);
    });
  });

  group('session boundary', () {
    test(
      'a cleared session opens the gate, never locks a logged-out app',
      () async {
        stubAuth(BiometricAuthStatus.failed);
        final controller = build();
        await controller.initialize();
        expect(controller.state, AppLockState.locked);

        when(() => sessionManager.current()).thenAnswer((_) => null);
        sessionNotifier.value = null;

        expect(controller.state, AppLockState.unlocked);
        expect(controller.lastFailure, isNull);
      },
    );
  });

  group('setEnabled', () {
    test('turning the lock off opens the gate immediately', () async {
      stubAuth(BiometricAuthStatus.failed);
      final controller = build();
      await controller.initialize();
      expect(controller.state, AppLockState.locked);

      await controller.setEnabled(enabled: false);

      expect(controller.state, AppLockState.unlocked);
      expect(controller.isEnabled, isFalse);
      verify(() => repository.setEnabled(enabled: false)).called(1);
    });

    test('turning it on persists and arms subsequent pauses', () async {
      when(repository.isEnabled).thenAnswer((_) async => false);
      final controller = build();
      await controller.initialize();

      await controller.setEnabled(enabled: true);
      stubAuth(BiometricAuthStatus.failed);
      controller.onAppPaused();

      expect(controller.isEnabled, isTrue);
      expect(controller.state, AppLockState.locked);
    });
  });
}
