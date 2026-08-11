import 'package:core/core.dart';

/// Outcome of an `OtpFlow.start` call. Match on this instead of inspecting
/// bloc/route internals.
sealed class OtpResult<T> {
  const OtpResult();
}

/// The code was verified; [data] is whatever `OtpVerifier.verifyCode`
/// resolved to (e.g. a session entity, or `void`-ish marker type).
class OtpVerified<T> extends OtpResult<T> {
  const OtpVerified(this.data);

  final T data;
}

/// The user dismissed the flow (back/drag/barrier tap) before verifying.
class OtpCancelled<T> extends OtpResult<T> {
  const OtpCancelled();
}

/// The code expired and the user did not (or could not) request a new one.
class OtpExpired<T> extends OtpResult<T> {
  const OtpExpired();
}

/// Verification failed for a reason other than expiry (invalid code,
/// network error, server rejection).
class OtpFailed<T> extends OtpResult<T> {
  const OtpFailed(this.failure);

  final Failure failure;
}

/// Ergonomic check for the common case: `if (result.isVerified) { ... }`.
extension OtpResultX<T> on OtpResult<T> {
  bool get isVerified => this is OtpVerified<T>;
}
