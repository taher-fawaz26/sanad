import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:otp/src/domain/entities/otp_cooldown.dart';
import 'package:otp/src/domain/entities/otp_delivery.dart';

/// The seam between the generic OTP UI and a caller's own backend.
///
/// Implement this per use case (email login, change-phone, MFA, ...) and pass
/// it into `OtpFlowConfig`. This package never imports a network client, and
/// sits below every feature package in the dependency graph — so *every*
/// backend fact reaches the engine through this port.
abstract interface class OtpVerifier<T> {
  /// Creates a new OTP session and sends the first code.
  ///
  /// The engine calls this only when [cooldown] reports no live session, so an
  /// implementation does not need to guard against re-issuing one.
  TaskEither<Failure, OtpDelivery> requestCode();

  /// Sends another code on the session [requestCode] opened.
  ///
  /// Split from [requestCode] deliberately: the two hit different endpoints
  /// with different preconditions, and inferring which to call from mutable
  /// verifier state is how a failed first send ends up permanently wedged
  /// against a session that was never created.
  TaskEither<Failure, OtpDelivery> resendCode();

  /// Server-reported cooldown/resend state, or `null` when this flow's backend
  /// exposes no `resend-info` endpoint.
  ///
  /// The engine probes this **before** dispatching, so reopening a flow inside
  /// a live cooldown shows a countdown instead of provoking a 429.
  TaskEither<Failure, OtpCooldown>? cooldown();

  /// Verifies [code]. Resolves to whatever the caller wants returned to
  /// `OtpFlow.start`'s caller on success (e.g. a session entity).
  TaskEither<Failure, T> verifyCode(String code);
}

/// Supplies the conservative defaults so a flow with no resend/cooldown
/// endpoints only has to implement [requestCode] and [verifyCode].
abstract class OtpVerifierBase<T> implements OtpVerifier<T> {
  const OtpVerifierBase();

  /// Falls back to re-issuing a code through [requestCode].
  @override
  TaskEither<Failure, OtpDelivery> resendCode() => requestCode();

  /// No server-side cooldown to read; the engine falls back to
  /// `OtpFlowConfig.fallbackCooldown`.
  @override
  TaskEither<Failure, OtpCooldown>? cooldown() => null;
}
