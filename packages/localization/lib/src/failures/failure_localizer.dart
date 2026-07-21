import 'package:core/core.dart';
import 'package:easy_localization/easy_localization.dart';

/// Single source of truth for turning a domain [Failure] into a user-facing,
/// localized string.
///
/// This replaces the per-page `message.contains(' ') ? raw : message.tr()`
/// heuristic, which mis-translated single-word server prose (e.g. "Forbidden")
/// as an i18n key. Resolution here is deterministic and keyed off failure
/// *type* and a stable key namespace, never off the shape of the text.
///
/// Two kinds of message can reach this resolver:
///   * **Client i18n keys** — the network layer emits namespaced keys
///     ([_errorKeyPrefix], e.g. `errors.no_internet`) for transport/local
///     failures. These are translated client-side.
///   * **Backend prose** — the API returns human messages (already locale-
///     negotiated via the Accept-Language interceptor) for 4xx/5xx bodies.
///     These are shown as-is; the specific text is the useful part.
extension FailureLocalizer on Failure {
  /// Matches an i18n key: dotted, lower snake_case, no spaces or capitals
  /// (e.g. `errors.no_internet`, `auth.session_unauthenticated`). Backend prose
  /// ("Cannot delete the only branch", "Forbidden") never matches, so it is
  /// shown verbatim.
  static final RegExp _i18nKeyPattern = RegExp(r'^[a-z0-9_]+(\.[a-z0-9_]+)+$');

  /// The user-facing, localized message for this failure.
  ///
  /// - i18n keys (client-emitted, any namespace) are translated.
  /// - Non-empty backend prose is returned verbatim.
  /// - Empty messages fall back to the type-based [errorKey].
  String localizedMessage() {
    final raw = message.trim();
    if (raw.isEmpty) return errorKey.tr();
    if (_i18nKeyPattern.hasMatch(raw)) return raw.tr();
    return raw;
  }

  /// A generic, type-based localized message that ignores any server prose.
  ///
  /// Use where a consistent, branded message is preferred over backend text.
  String localizedGenericMessage() => errorKey.tr();

  /// The canonical i18n key for this failure's *type* (no translation applied).
  ///
  /// Deterministic and side-effect free — safe for tests, logging, and
  /// analytics categorization as well as as a fallback for [localizedMessage].
  String get errorKey {
    if (isNoInternet) return 'errors.no_internet';
    if (isTimeout) return 'errors.timeout';
    if (isSecureConnection) return 'errors.secure_connection_failed';
    if (isUnauthorized || isUnauthorizedRole) return 'errors.unauthorized';
    if (isValidation) return 'errors.bad_request';
    if (isConflict) return 'errors.conflict';
    if (isRateLimit) return 'errors.rate_limit';
    if (isBusinessRule) return 'errors.business_rule';
    if (isCache) return 'errors.cache_error';
    if (isServer) return 'errors.server_error';
    return 'errors.unknown';
  }
}

/// Validation-specific resolution: exposes every message the backend returned,
/// for use by an aggregate validation-summary component.
extension ValidationFailureLocalizer on ValidationFailure {
  /// All validation messages (already locale-negotiated by the backend).
  ///
  /// Falls back to the single resolved [localizedMessage] when the backend
  /// provided no discrete messages.
  List<String> localizedMessages() => messages.isNotEmpty
      ? List<String>.unmodifiable(messages)
      : <String>[localizedMessage()];
}
