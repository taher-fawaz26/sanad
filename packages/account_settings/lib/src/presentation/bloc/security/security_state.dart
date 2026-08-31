part of 'security_bloc.dart';

class SecurityState extends Equatable {
  const SecurityState({
    this.loadStatus = RequestStatus.initial,
    this.toggleStatus = RequestStatus.initial,
    this.enabled = false,
    this.capability = AppLockCapability.unsupported,
    this.availableBiometrics = const [],
    this.lastFailure,
  });

  final RequestStatus loadStatus;

  /// Lifecycle of an in-flight enable/disable. Drives the switch's inline
  /// spinner; never a blocking full-screen progress dialog.
  final RequestStatus toggleStatus;

  /// The persisted preference — the switch's actual value. Never optimistic:
  /// it changes only after the OS has authenticated the user.
  final bool enabled;

  final AppLockCapability capability;

  /// Enrolled biometric methods. **Presentation only** — used to pick the row
  /// icon and copy ("Face ID" vs "Fingerprint"). The gate's correctness never
  /// depends on this being non-empty.
  final List<BiometricType> availableBiometrics;

  /// Why the last attempt did not succeed, or `null`.
  final BiometricAuthStatus? lastFailure;

  /// Whether the device can authenticate at all.
  bool get isSupported => capability == AppLockCapability.available;

  SecurityState copyWith({
    RequestStatus? loadStatus,
    RequestStatus? toggleStatus,
    bool? enabled,
    AppLockCapability? capability,
    List<BiometricType>? availableBiometrics,
    BiometricAuthStatus? lastFailure,
    bool clearLastFailure = false,
  }) {
    return SecurityState(
      loadStatus: loadStatus ?? this.loadStatus,
      toggleStatus: toggleStatus ?? this.toggleStatus,
      enabled: enabled ?? this.enabled,
      capability: capability ?? this.capability,
      availableBiometrics: availableBiometrics ?? this.availableBiometrics,
      lastFailure: clearLastFailure ? null : (lastFailure ?? this.lastFailure),
    );
  }

  @override
  List<Object?> get props => [
    loadStatus,
    toggleStatus,
    enabled,
    capability,
    availableBiometrics,
    lastFailure,
  ];
}
