part of 'account_deletion_bloc.dart';

sealed class AccountDeletionEvent extends Equatable {
  const AccountDeletionEvent();

  @override
  List<Object?> get props => const [];
}

/// Loads eligibility — the server-driven blockers/warnings/cascade that
/// entirely determine the confirmation UI.
class AccountDeletionEligibilityRequested extends AccountDeletionEvent {
  const AccountDeletionEligibilityRequested();
}

/// Detects/resumes an already-active deletion request.
class AccountDeletionStatusRequested extends AccountDeletionEvent {
  const AccountDeletionStatusRequested();
}

/// `POST account/deletion` — idempotent; sends the verification OTP.
class AccountDeletionStarted extends AccountDeletionEvent {
  const AccountDeletionStarted();
}

class AccountDeletionOtpVerified extends AccountDeletionEvent {
  const AccountDeletionOtpVerified(this.otp);

  final String otp;

  @override
  List<Object?> get props => [otp];

  // The OTP must never reach the logs. `AppBlocObserver` logs `$event`, which
  // would otherwise stringify [otp] via Equatable — mask it here.
  @override
  String toString() => 'AccountDeletionOtpVerified(***)';
}

class AccountDeletionOtpResendRequested extends AccountDeletionEvent {
  const AccountDeletionOtpResendRequested();
}

class AccountDeletionResendInfoRequested extends AccountDeletionEvent {
  const AccountDeletionResendInfoRequested();
}

/// `DELETE account/deletion` — the in-app cancel.
class AccountDeletionCancelled extends AccountDeletionEvent {
  const AccountDeletionCancelled();
}
