import 'package:account_settings/src/domain/entities/account_deletion_eligibility.dart';
import 'package:account_settings/src/domain/entities/account_deletion_request.dart';
import 'package:account_settings/src/domain/entities/deletion_resend_info.dart';
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';

/// Reads/writes the signed-in account's deletion request — the single
/// source of truth for the Account Deletion & Recovery feature.
abstract interface class AccountDeletionRepository {
  /// `GET account/deletion/eligibility`.
  TaskEither<Failure, AccountDeletionEligibility> getEligibility();

  /// `POST account/deletion`. Idempotent — an already-active request is
  /// returned rather than duplicated.
  TaskEither<Failure, AccountDeletionRequest> startDeletion();

  /// `POST account/deletion/verify`.
  TaskEither<Failure, AccountDeletionRequest> verifyOtp(String otp);

  /// `POST account/deletion/resend-otp`.
  TaskEither<Failure, AccountDeletionRequest> resendOtp();

  /// `GET account/deletion/resend-info`.
  TaskEither<Failure, DeletionResendInfo> getResendInfo();

  /// `GET account/deletion`. `null` on 404 — no active request, a normal
  /// quiet state rather than an error.
  TaskEither<Failure, AccountDeletionRequest?> getStatus();

  /// `DELETE account/deletion` — the in-app cancel. 404 (nothing to cancel)
  /// resolves as a no-op success rather than a [Failure].
  TaskEither<Failure, Unit> cancelDeletion();
}
