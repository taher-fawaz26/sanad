part of 'account_deletion_bloc.dart';

class AccountDeletionState extends Equatable {
  const AccountDeletionState({
    this.eligibilityStatus = RequestStatus.initial,
    this.eligibility,
    this.eligibilityFailure,
    this.activeRequestStatus = RequestStatus.initial,
    this.activeRequest,
    this.mutationStatus = RequestStatus.initial,
    this.mutationFailure,
    this.resendStatus = RequestStatus.initial,
    this.resendInfoStatus = RequestStatus.initial,
    this.resendInfo,
  });

  final RequestStatus eligibilityStatus;
  final AccountDeletionEligibility? eligibility;
  final Failure? eligibilityFailure;

  /// The active deletion request, from either `GET account/deletion` (resume)
  /// or the latest start/verify/resend-otp response.
  final RequestStatus activeRequestStatus;
  final AccountDeletionRequest? activeRequest;

  /// Shared by start / verify-otp / cancel — each is read from exactly one
  /// screen (confirmation, OTP, scheduled), so they never overlap.
  final RequestStatus mutationStatus;
  final Failure? mutationFailure;

  /// Resend-otp has its own status so the OTP screen can distinguish "resend
  /// in flight" from "verify in flight" (both live on the same page).
  final RequestStatus resendStatus;

  final RequestStatus resendInfoStatus;
  final DeletionResendInfo? resendInfo;

  bool get hasBlockers => eligibility?.hasBlockers ?? false;

  AccountDeletionState copyWith({
    RequestStatus? eligibilityStatus,
    AccountDeletionEligibility? eligibility,
    Failure? eligibilityFailure,
    bool clearEligibilityFailure = false,
    RequestStatus? activeRequestStatus,
    AccountDeletionRequest? activeRequest,
    bool clearActiveRequest = false,
    RequestStatus? mutationStatus,
    Failure? mutationFailure,
    bool clearMutationFailure = false,
    RequestStatus? resendStatus,
    RequestStatus? resendInfoStatus,
    DeletionResendInfo? resendInfo,
  }) {
    return AccountDeletionState(
      eligibilityStatus: eligibilityStatus ?? this.eligibilityStatus,
      eligibility: eligibility ?? this.eligibility,
      eligibilityFailure: clearEligibilityFailure
          ? null
          : (eligibilityFailure ?? this.eligibilityFailure),
      activeRequestStatus: activeRequestStatus ?? this.activeRequestStatus,
      activeRequest: clearActiveRequest
          ? null
          : (activeRequest ?? this.activeRequest),
      mutationStatus: mutationStatus ?? this.mutationStatus,
      mutationFailure: clearMutationFailure
          ? null
          : (mutationFailure ?? this.mutationFailure),
      resendStatus: resendStatus ?? this.resendStatus,
      resendInfoStatus: resendInfoStatus ?? this.resendInfoStatus,
      resendInfo: resendInfo ?? this.resendInfo,
    );
  }

  @override
  List<Object?> get props => [
    eligibilityStatus,
    eligibility,
    eligibilityFailure,
    activeRequestStatus,
    activeRequest,
    mutationStatus,
    mutationFailure,
    resendStatus,
    resendInfoStatus,
    resendInfo,
  ];
}
