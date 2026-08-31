part of 'security_bloc.dart';

sealed class SecurityEvent extends Equatable {
  const SecurityEvent();

  @override
  List<Object?> get props => [];
}

/// Reads the stored preference and probes device capability.
final class SecurityLoaded extends SecurityEvent {
  const SecurityLoaded();
}

/// The user moved the app-lock switch.
///
/// Carries the *requested* value, not the new state — the preference only
/// changes if the local authentication that follows succeeds.
final class SecurityAppLockToggled extends SecurityEvent {
  const SecurityAppLockToggled({required this.enable});

  final bool enable;

  @override
  List<Object?> get props => [enable];
}

/// Enables the lock straight from the post-login offer.
final class SecurityAppLockOfferAccepted extends SecurityEvent {
  const SecurityAppLockOfferAccepted();
}
