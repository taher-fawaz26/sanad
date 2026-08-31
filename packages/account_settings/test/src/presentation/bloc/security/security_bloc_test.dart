import 'package:account_settings/src/domain/enums/app_lock_capability.dart';
import 'package:account_settings/src/domain/repositories/app_lock_repository.dart';
import 'package:account_settings/src/presentation/bloc/security/security_bloc.dart';
import 'package:account_settings/src/presentation/lock/app_lock_controller.dart';
import 'package:core/core.dart';
import 'package:device/device.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:testing/testing.dart';

class _MockRepository extends Mock implements AppLockRepository {}

class _MockBiometricService extends Mock implements BiometricService {}

class _MockController extends Mock implements AppLockController {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockRepository repository;
  late _MockBiometricService biometrics;
  late _MockController controller;

  SecurityBloc build() => SecurityBloc(
    repository: repository,
    biometrics: biometrics,
    controller: controller,
  );

  void stubAuth(BiometricAuthStatus status) {
    when(
      () => biometrics.authenticate(
        reason: any(named: 'reason'),
        biometricOnly: any(named: 'biometricOnly'),
      ),
    ).thenAnswer((_) async => BiometricAuthResult(status: status));
  }

  setUp(() {
    repository = _MockRepository();
    biometrics = _MockBiometricService();
    controller = _MockController();

    when(
      repository.capability,
    ).thenAnswer((_) async => AppLockCapability.available);
    when(repository.isEnabled).thenAnswer((_) async => false);
    when(repository.markOffered).thenAnswer((_) async {});
    when(
      biometrics.availableBiometrics,
    ).thenAnswer((_) async => [BiometricType.face]);
    when(
      () => controller.setEnabled(enabled: any(named: 'enabled')),
    ).thenAnswer((_) async {});
    stubAuth(BiometricAuthStatus.success);
  });

  group('load', () {
    sandBlocTest<SecurityBloc, SecurityState>(
      'reports capability, stored preference, and enrolled methods',
      build: build,
      setUp: () => when(repository.isEnabled).thenAnswer((_) async => true),
      act: (bloc) => bloc.add(const SecurityLoaded()),
      expect: () => [
        const SecurityState(loadStatus: RequestStatus.loading),
        const SecurityState(
          loadStatus: RequestStatus.success,
          enabled: true,
          capability: AppLockCapability.available,
          availableBiometrics: [BiometricType.face],
        ),
      ],
    );

    sandBlocTest<SecurityBloc, SecurityState>(
      'skips the enrolled-methods lookup on an unsupported device',
      build: build,
      setUp: () => when(
        repository.capability,
      ).thenAnswer((_) async => AppLockCapability.unsupported),
      act: (bloc) => bloc.add(const SecurityLoaded()),
      verify: (_) => verifyNever(biometrics.availableBiometrics),
    );
  });

  group('enable', () {
    sandBlocTest<SecurityBloc, SecurityState>(
      'persists ONLY after a successful local authentication',
      build: build,
      act: (bloc) => bloc.add(const SecurityAppLockToggled(enable: true)),
      expect: () => [
        const SecurityState(toggleStatus: RequestStatus.loading),
        const SecurityState(enabled: true, toggleStatus: RequestStatus.success),
      ],
      verify: (_) {
        verify(() => controller.setEnabled(enabled: true)).called(1);
      },
    );

    sandBlocTest<SecurityBloc, SecurityState>(
      'does not persist when authentication fails',
      build: build,
      setUp: () => stubAuth(BiometricAuthStatus.failed),
      act: (bloc) => bloc.add(const SecurityAppLockToggled(enable: true)),
      expect: () => [
        const SecurityState(toggleStatus: RequestStatus.loading),
        const SecurityState(
          toggleStatus: RequestStatus.failure,
          lastFailure: BiometricAuthStatus.failed,
        ),
      ],
      verify: (_) {
        // The whole point of the class: the preference is never written for an
        // attempt the OS did not approve.
        verifyNever(
          () => controller.setEnabled(enabled: any(named: 'enabled')),
        );
      },
    );

    sandBlocTest<SecurityBloc, SecurityState>(
      'does not persist when the user is locked out',
      build: build,
      setUp: () => stubAuth(BiometricAuthStatus.lockedOut),
      act: (bloc) => bloc.add(const SecurityAppLockToggled(enable: true)),
      expect: () => [
        const SecurityState(toggleStatus: RequestStatus.loading),
        const SecurityState(
          toggleStatus: RequestStatus.failure,
          lastFailure: BiometricAuthStatus.lockedOut,
        ),
      ],
      verify: (_) {
        verifyNever(
          () => controller.setEnabled(enabled: any(named: 'enabled')),
        );
      },
    );

    sandBlocTest<SecurityBloc, SecurityState>(
      'raises no prompt at all on an unsupported device',
      build: build,
      setUp: () => when(
        repository.capability,
      ).thenAnswer((_) async => AppLockCapability.unsupported),
      act: (bloc) => bloc.add(const SecurityAppLockToggled(enable: true)),
      expect: () => [
        const SecurityState(
          // Asserted explicitly: the point is that the bloc *reports* the
          // unsupported capability, not that it happens to match the default.
          // ignore: avoid_redundant_argument_values
          capability: AppLockCapability.unsupported,
          toggleStatus: RequestStatus.failure,
          lastFailure: BiometricAuthStatus.notAvailable,
        ),
      ],
      verify: (_) {
        verifyNever(
          () => biometrics.authenticate(
            reason: any(named: 'reason'),
            biometricOnly: any(named: 'biometricOnly'),
          ),
        );
        verifyNever(
          () => controller.setEnabled(enabled: any(named: 'enabled')),
        );
      },
    );

    sandBlocTest<SecurityBloc, SecurityState>(
      'a double tap raises a single prompt (droppable)',
      build: build,
      act: (bloc) => bloc
        ..add(const SecurityAppLockToggled(enable: true))
        ..add(const SecurityAppLockToggled(enable: true)),
      verify: (_) {
        verify(
          () => biometrics.authenticate(
            reason: any(named: 'reason'),
            biometricOnly: any(named: 'biometricOnly'),
          ),
        ).called(1);
      },
    );
  });

  group('disable', () {
    SecurityBloc buildEnabled() =>
        build()..emit(const SecurityState(enabled: true));

    sandBlocTest<SecurityBloc, SecurityState>(
      'requires authentication and then persists',
      build: buildEnabled,
      act: (bloc) => bloc.add(const SecurityAppLockToggled(enable: false)),
      expect: () => [
        const SecurityState(enabled: true, toggleStatus: RequestStatus.loading),
        const SecurityState(toggleStatus: RequestStatus.success),
      ],
      verify: (_) {
        verify(() => controller.setEnabled(enabled: false)).called(1);
      },
    );

    sandBlocTest<SecurityBloc, SecurityState>(
      'stays ENABLED when the disable authentication fails',
      build: buildEnabled,
      setUp: () => stubAuth(BiometricAuthStatus.failed),
      act: (bloc) => bloc.add(const SecurityAppLockToggled(enable: false)),
      expect: () => [
        const SecurityState(enabled: true, toggleStatus: RequestStatus.loading),
        const SecurityState(
          enabled: true,
          toggleStatus: RequestStatus.failure,
          lastFailure: BiometricAuthStatus.failed,
        ),
      ],
      verify: (_) {
        // Fail closed: someone holding an unlocked phone cannot quietly
        // remove the lock.
        verifyNever(
          () => controller.setEnabled(enabled: any(named: 'enabled')),
        );
      },
    );

    sandBlocTest<SecurityBloc, SecurityState>(
      'is allowed without a prompt once the device can authenticate nobody',
      build: buildEnabled,
      setUp: () => when(
        repository.capability,
      ).thenAnswer((_) async => AppLockCapability.unsupported),
      act: (bloc) => bloc.add(const SecurityAppLockToggled(enable: false)),
      expect: () => [
        const SecurityState(
          // Asserted explicitly: the point is that the bloc *reports* the
          // unsupported capability, not that it happens to match the default.
          // ignore: avoid_redundant_argument_values
          capability: AppLockCapability.unsupported,
          toggleStatus: RequestStatus.success,
        ),
      ],
      verify: (_) {
        // Escape hatch — demanding an impossible authentication here would
        // trap the user with a lock they can never switch off.
        verifyNever(
          () => biometrics.authenticate(
            reason: any(named: 'reason'),
            biometricOnly: any(named: 'biometricOnly'),
          ),
        );
        verify(() => controller.setEnabled(enabled: false)).called(1);
      },
    );
  });

  group('post-login offer', () {
    sandBlocTest<SecurityBloc, SecurityState>(
      'accepting records the offer and enables after authenticating',
      build: build,
      act: (bloc) => bloc.add(const SecurityAppLockOfferAccepted()),
      expect: () => [
        const SecurityState(toggleStatus: RequestStatus.loading),
        const SecurityState(enabled: true, toggleStatus: RequestStatus.success),
      ],
      verify: (_) {
        verify(repository.markOffered).called(1);
        verify(() => controller.setEnabled(enabled: true)).called(1);
      },
    );

    sandBlocTest<SecurityBloc, SecurityState>(
      'a failed accept still records the offer, so the user is not re-nagged',
      build: build,
      setUp: () => stubAuth(BiometricAuthStatus.failed),
      act: (bloc) => bloc.add(const SecurityAppLockOfferAccepted()),
      verify: (_) {
        verify(repository.markOffered).called(1);
        verifyNever(
          () => controller.setEnabled(enabled: any(named: 'enabled')),
        );
      },
    );
  });
}
