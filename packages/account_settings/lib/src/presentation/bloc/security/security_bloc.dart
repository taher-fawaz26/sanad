import 'package:account_settings/src/domain/enums/app_lock_capability.dart';
import 'package:account_settings/src/domain/repositories/app_lock_repository.dart';
import 'package:account_settings/src/presentation/lock/app_lock_controller.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:core/core.dart';
import 'package:device/device.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'security_event.dart';
part 'security_state.dart';

/// Enable/disable orchestration for the local authentication (app lock)
/// preference.
///
/// The rule the whole class exists to enforce: **the preference is written
/// only after the OS has authenticated the user.** That holds in both
/// directions —
///
/// * turning the lock **on** proves the user can actually pass the gate they
///   are about to put in front of themselves, so they cannot lock themselves
///   out with a credential they do not have; and
/// * turning it **off** proves the person holding an already-unlocked phone is
///   the owner, and not someone quietly removing the lock (fails closed, per
///   `.claude/rules/security.md`).
///
/// The one relaxation is a device that can no longer authenticate anyone at
/// all (screen lock removed after the fact). Demanding an impossible
/// authentication to switch the lock off would trap the user, so that case is
/// allowed through — and the gate treats the same condition as
/// `AppLockState.unavailable`, so the two can never disagree and no
/// lock-out is reachable.
class SecurityBloc extends Bloc<SecurityEvent, SecurityState> {
  SecurityBloc({
    required AppLockRepository repository,
    required BiometricService biometrics,
    required AppLockController controller,
  }) : _repository = repository,
       _biometrics = biometrics,
       _controller = controller,
       super(const SecurityState()) {
    on<SecurityLoaded>(_onLoaded);
    // droppable(): a double-tap on the switch must not raise two OS prompts.
    on<SecurityAppLockToggled>(_onToggled, transformer: droppable());
    on<SecurityAppLockOfferAccepted>(
      _onOfferAccepted,
      transformer: droppable(),
    );
  }

  final AppLockRepository _repository;
  final BiometricService _biometrics;
  final AppLockController _controller;

  Future<void> _onLoaded(
    SecurityLoaded event,
    Emitter<SecurityState> emit,
  ) async {
    emit(state.copyWith(loadStatus: RequestStatus.loading));

    final capability = await _repository.capability();
    final enabled = await _repository.isEnabled();
    // Presentation only — drives the row's icon and label wording.
    final biometrics = capability == AppLockCapability.available
        ? await _biometrics.availableBiometrics()
        : const <BiometricType>[];

    emit(
      state.copyWith(
        loadStatus: RequestStatus.success,
        enabled: enabled,
        capability: capability,
        availableBiometrics: biometrics,
      ),
    );
  }

  Future<void> _onToggled(
    SecurityAppLockToggled event,
    Emitter<SecurityState> emit,
  ) => _applyPreference(emit, enable: event.enable);

  Future<void> _onOfferAccepted(
    SecurityAppLockOfferAccepted event,
    Emitter<SecurityState> emit,
  ) async {
    // Written whichever way the offer is answered, so a user who declines is
    // never asked again — and a user who accepts but fails the prompt is not
    // re-offered either, since they can still turn it on from Settings.
    await _repository.markOffered();
    await _applyPreference(emit, enable: true);
  }

  Future<void> _applyPreference(
    Emitter<SecurityState> emit, {
    required bool enable,
  }) async {
    final capability = await _repository.capability();
    if (capability != AppLockCapability.available) {
      if (enable) {
        // Nothing to authenticate against; surface the unsupported state
        // rather than raising a prompt that cannot succeed.
        emit(
          state.copyWith(
            capability: capability,
            toggleStatus: RequestStatus.failure,
            lastFailure: BiometricAuthStatus.notAvailable,
          ),
        );
        return;
      }
      // Escape hatch — see the class doc. Let the user switch it off.
      await _controller.setEnabled(enabled: false);
      emit(
        state.copyWith(
          capability: capability,
          enabled: false,
          toggleStatus: RequestStatus.success,
          clearLastFailure: true,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        toggleStatus: RequestStatus.loading,
        clearLastFailure: true,
      ),
    );

    final result = await _biometrics.authenticate(
      reason: enable
          ? 'settings.biometric_enable_reason'.tr()
          : 'settings.biometric_disable_reason'.tr(),
      // Stated explicitly even though it matches the default: whether the
      // device credential is an acceptable fallback is a security decision,
      // not an incidental argument.
      // ignore: avoid_redundant_argument_values
      biometricOnly: false,
    );

    if (!result.isSuccess) {
      // Preference untouched. The switch keeps its previous value, so the UI
      // never shows a state the user did not earn.
      emit(
        state.copyWith(
          toggleStatus: RequestStatus.failure,
          lastFailure: result.status,
        ),
      );
      return;
    }

    // Only now does anything get persisted. Routed through the controller so
    // the live gate picks up the same change in the same step.
    await _controller.setEnabled(enabled: enable);

    emit(
      state.copyWith(
        enabled: enable,
        toggleStatus: RequestStatus.success,
        clearLastFailure: true,
      ),
    );
  }
}
