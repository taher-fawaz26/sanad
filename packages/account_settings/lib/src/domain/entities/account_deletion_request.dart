import 'package:account_settings/src/domain/enums/account_deletion_status.dart';
import 'package:equatable/equatable.dart';

/// `AccountDeletionResponseDto` — the active deletion request, returned by
/// initiate/verify/resend-otp/status.
class AccountDeletionRequest extends Equatable {
  const AccountDeletionRequest({
    required this.id,
    required this.status,
    required this.initiator,
    required this.verificationRequired,
    required this.scheduledExecutionDate,
    required this.gracePeriodDays,
    required this.message,
    required this.createdAt,
    required this.updatedAt,
    this.cascadeSummary = const {},
  });

  final String id;
  final AccountDeletionStatus status;
  final DeletionInitiator initiator;
  final bool verificationRequired;
  final DateTime? scheduledExecutionDate;
  final int gracePeriodDays;

  /// Localized description of the current state, from the server.
  final String message;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic> cascadeSummary;

  /// `pending_verification` and `scheduled` support in-app cancel;
  /// `executing` is a non-cancellable execution state.
  bool get isCancellable =>
      status == AccountDeletionStatus.pendingVerification ||
      status == AccountDeletionStatus.scheduled;

  @override
  List<Object?> get props => [
    id,
    status,
    initiator,
    verificationRequired,
    scheduledExecutionDate,
    gracePeriodDays,
    message,
    createdAt,
    updatedAt,
    cascadeSummary,
  ];
}
