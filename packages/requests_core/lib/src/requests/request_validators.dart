import 'package:requests_core/src/requests/request_field_limits.dart';

/// Client-side validation for the request bodies both roles send.
///
/// Each validator returns an **i18n key** to display, or `null` when the value
/// is acceptable. Keys, not prose: the caller resolves them with `.tr()` like
/// every other user-facing string in the app.
abstract final class RequestValidators {
  RequestValidators._();

  /// Validates a cancel/dispute reason against the server's 3–1000 bound.
  static String? reason(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.length < RequestFieldLimits.reasonMinLength) {
      return 'requests.validation.reason_too_short';
    }
    if (trimmed.length > RequestFieldLimits.reasonMaxLength) {
      return 'requests.validation.reason_too_long';
    }
    return null;
  }

  /// Validates an optional offer note.
  static String? offerNote(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.length > RequestFieldLimits.offerNoteMaxLength) {
      return 'requests.validation.note_too_long';
    }
    return null;
  }

  /// Validates a proposed/preferred start time.
  ///
  /// The backend answers `400` for a time in the past on both submit and every
  /// counter, so it is checked here first. [now] is injectable so tests do not
  /// depend on the wall clock.
  static String? futureInstant(DateTime? value, {DateTime? now}) {
    if (value == null) return 'requests.validation.time_required';
    if (!value.isAfter(now ?? DateTime.now())) {
      return 'requests.validation.time_must_be_future';
    }
    return null;
  }

  /// Validates the media-id set attached to a draft.
  static String? mediaIds(List<String> value) =>
      value.length > RequestFieldLimits.maxMediaIds
      ? 'requests.validation.too_many_attachments'
      : null;
}
