import 'package:core/core.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:localization/src/failures/failure_localizer.dart';

/// Resolved copy for a full-area error state, derived from a [Failure].
///
/// Returned by [failureErrorDisplay] so features no longer hand-roll the
/// failure-type → (title, description, style) mapping in private `_ErrorState`
/// widgets. [isConnectivity] lets the presentation layer pick the network vs.
/// generic illustration without importing the design system here.
class FailureErrorDisplay {
  const FailureErrorDisplay({
    required this.title,
    required this.description,
    required this.isConnectivity,
    required this.isRetryable,
  });

  final String title;
  final String description;
  final bool isConnectivity;

  /// Whether a retry affordance should be offered for this failure.
  /// Callers should hide the retry action when this is false.
  final bool isRetryable;
}

/// Localized retry label for error/retry states.
String failureRetryLabel() => 'empty_states.retry'.tr();

/// Maps a [failure] to localized error-state copy.
///
/// - No-internet → connectivity copy + network illustration.
/// - Timeout → timeout copy + network illustration.
/// - Everything else → generic copy; the description prefers the backend
///   message (via the resolver) and falls back to a generic line.
///
/// [genericTitleKey] / [genericDescriptionKey] let a feature override the
/// non-connectivity copy (e.g. `branches.load_error_title`) while still reusing
/// the shared connectivity/timeout handling and message resolution.
FailureErrorDisplay failureErrorDisplay(
  Failure? failure, {
  String genericTitleKey = 'empty_states.server_error_title',
  String genericDescriptionKey = 'empty_states.server_error_description',
}) {
  if (failure != null && failure.isNoInternet) {
    return FailureErrorDisplay(
      title: 'empty_states.network_title'.tr(),
      description: 'empty_states.network_description'.tr(),
      isConnectivity: true,
      isRetryable: true,
    );
  }

  if (failure != null && failure.isTimeout) {
    return FailureErrorDisplay(
      title: 'empty_states.timeout_title'.tr(),
      description: 'empty_states.timeout_description'.tr(),
      isConnectivity: true,
      isRetryable: true,
    );
  }

  final hasMessage = failure != null && failure.message.trim().isNotEmpty;
  return FailureErrorDisplay(
    title: genericTitleKey.tr(),
    description: hasMessage
        ? failure.localizedMessage()
        : genericDescriptionKey.tr(),
    isConnectivity: false,
    isRetryable: failure?.isRetryable ?? true,
  );
}
