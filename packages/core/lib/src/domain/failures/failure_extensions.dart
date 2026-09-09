import 'package:core/src/domain/failures/failure.dart';

/// Maps each [Failure] variant to a stable i18n key under the `errors.*`
/// namespace. Call `.tr()` at the presentation layer — e.g.
/// `AppSnackbar.error(failure.messageKey.tr())`.
///
/// For [ValidationFailure] prefer showing [ValidationFailure.messages] when
/// non-empty (already user-facing, locale-agnostic server text). Fall back to
/// `errors.validation` otherwise.
extension FailureMessageX on Failure {
  String get messageKey => switch (this) {
    NoInternetFailure() => 'errors.no_internet',
    TimeoutFailure() => 'errors.timeout',
    NetworkFailure() => 'errors.request_cancelled',
    ServerFailure() => 'errors.server_error',
    UnauthorizedFailure() => 'errors.unauthorized',
    SecureConnectionFailure() => 'errors.secure_connection_failed',
    LocationFailure() => 'errors.location',
    CacheFailure() => 'errors.cache_error',
    UnknownFailure() => 'errors.unknown',
    ValidationFailure() => 'errors.validation',
    UnverifiedUserFailure() => 'errors.unverified_user',
    UnauthorizedRoleFailure() => 'errors.unauthorized_role',
    BusinessRuleFailure() => 'errors.business_rule',
    ConflictFailure() => 'errors.conflict',
    RateLimitFailure() => 'errors.rate_limit',
    EmailNotValidFailure() => 'errors.email_not_valid',
  };
}

/// Presentation helpers — use in BlocListener / UI.
extension FailureKindX on Failure {
  bool get isTimeout => this is TimeoutFailure;
  bool get isServer => this is ServerFailure;
  bool get isUnknown => this is UnknownFailure;
  bool get isSecureConnection => this is SecureConnectionFailure;
  bool get isUnauthorized => this is UnauthorizedFailure;
  bool get isNoInternet => this is NoInternetFailure;
  bool get isCache => this is CacheFailure;
  bool get isValidation => this is ValidationFailure;
  bool get isUnverifiedUser => this is UnverifiedUserFailure;
  bool get isUnauthorizedRole => this is UnauthorizedRoleFailure;
  bool get isLocation => this is LocationFailure;
  bool get isBusinessRule => this is BusinessRuleFailure;
  bool get isConflict => this is ConflictFailure;
  bool get isRateLimit => this is RateLimitFailure;
  bool get isEmailNotValid => this is EmailNotValidFailure;

  /// Whether retrying the same operation could plausibly succeed.
  ///
  /// Transient transport failures and 5xx server errors are retryable;
  /// validation, auth, permission, not-found/4xx, secure-connection, and
  /// cancellation are not. Drives retry affordances in the UI and any
  /// automatic retry policy. See `docs/ARCHITECTURE_BLUEPRINT.md` §10.
  bool get isRetryable {
    if (isNoInternet || isTimeout || isRateLimit) return true;
    if (isValidation ||
        isUnauthorized ||
        isUnverifiedUser ||
        isUnauthorizedRole ||
        isSecureConnection ||
        isConflict ||
        isBusinessRule) {
      return false;
    }
    if (isServer) {
      // `code` carries the HTTP status for server failures. 5xx (and an
      // unparseable status) are transient; 4xx (404/409/business) are not.
      final status = int.tryParse(code ?? '');
      return status == null || status >= 500;
    }
    if (isCache || isLocation || isUnknown) return true;
    // NetworkFailure (request cancelled) and anything else: not retryable.
    return false;
  }
}

/// Reads a *business* error code out of a failure.
///
/// [Failure.code] deliberately carries the HTTP status (`'409'`, `'403'`, …)
/// and callers depend on that — notably [FailureKindX.isRetryable], which
/// parses it as an int. The backend's own machine-readable code (e.g.
/// `OUTSIDE_HOURS`, `ACCOUNT_UNVERIFIED`) instead survives inside
/// [Failure.metadata], because `ErrorMapper` preserves the whole 4xx/5xx
/// response body there.
///
/// This is the one supported way to read it, so features stop reaching into
/// `metadata` with their own key guesses. Key aliases are tried in the order
/// the backend has used them across versions.
extension FailureBackendCodeX on Failure {
  /// The backend's business error code, upper-cased, or `null` when the
  /// response carried none.
  String? get backendCode {
    final meta = metadata;
    if (meta == null) return null;
    for (final key in const ['code', 'errorCode', 'error_code']) {
      final raw = meta[key];
      if (raw is String && raw.trim().isNotEmpty) {
        return raw.trim().toUpperCase();
      }
    }
    return null;
  }
}
