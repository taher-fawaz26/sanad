import 'package:asset_picker/src/domain/enums/asset_source.dart';
import 'package:asset_picker/src/domain/validation/asset_validation_error.dart';

/// Base type for every hard failure the asset picker can raise.
///
/// User cancellation is **not** an exception — it is returned as
/// `AssetPickerResult.cancelled()`. Exceptions are reserved for conditions the
/// caller must handle explicitly: denied permissions, unavailable sources,
/// validation failures, and unexpected platform errors.
sealed class AssetPickerException implements Exception {
  const AssetPickerException(this.message);

  /// A descriptive, developer-facing message.
  final String message;

  @override
  String toString() => 'AssetPickerException: $message';
}

/// The OS denied (or permanently denied) access required by a source, e.g.
/// camera or photo-library permission.
class AssetPermissionDeniedException extends AssetPickerException {
  const AssetPermissionDeniedException(
    this.source, {
    this.permanentlyDenied = false,
    String? message,
  }) : super(message ?? 'Permission denied for source: $source');

  /// The source whose permission was denied.
  final AssetSource source;

  /// Whether the user permanently denied the permission (must be fixed in
  /// system settings).
  final bool permanentlyDenied;
}

/// A requested source has no provider registered, or is unavailable on the
/// current platform.
class AssetSourceUnavailableException extends AssetPickerException {
  const AssetSourceUnavailableException(this.source, {String? message})
    : super(message ?? 'Source unavailable: $source');

  /// The unavailable source.
  final AssetSource source;
}

/// One or more selected assets failed validation against `AssetPickerOptions`.
class AssetValidationException extends AssetPickerException {
  AssetValidationException(this.errors) : super(_composeMessage(errors));

  /// The full, descriptive list of validation errors.
  final List<AssetValidationError> errors;

  static String _composeMessage(List<AssetValidationError> errors) {
    if (errors.isEmpty) return 'Asset validation failed';
    return errors.map((e) => e.message).join('\n');
  }
}

/// An unexpected error bubbled up from an underlying picker plugin.
class AssetPickerPlatformException extends AssetPickerException {
  const AssetPickerPlatformException(
    super.message, {
    this.source,
    this.cause,
  });

  /// The source being used when the error occurred, when known.
  final AssetSource? source;

  /// The original error object, preserved for logging.
  final Object? cause;
}
