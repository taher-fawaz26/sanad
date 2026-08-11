import 'package:equatable/equatable.dart';

/// Item-level validation failure. Distinct from `core`'s network-oriented
/// `Failure` hierarchy — these are raised synchronously by
/// `MediaUploadValidator` before any network call is made.
sealed class MediaUploadFailure extends Equatable {
  const MediaUploadFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];

  @override
  String toString() => message;
}

/// The file exceeds `MediaUploadConfig.maxFileSize`.
final class FileTooLargeFailure extends MediaUploadFailure {
  const FileTooLargeFailure({required this.maxFileSize})
    : super('errors.media_upload.file_too_large');

  final int maxFileSize;

  @override
  List<Object?> get props => [message, maxFileSize];
}

/// The file's MIME type or extension is not in the allowed list.
final class UnsupportedTypeFailure extends MediaUploadFailure {
  const UnsupportedTypeFailure()
    : super('errors.media_upload.unsupported_type');
}

/// Adding this item would exceed `MediaUploadConfig.maxFiles`.
final class MaxFilesExceededFailure extends MediaUploadFailure {
  const MaxFilesExceededFailure({required this.maxFiles})
    : super('errors.media_upload.max_files_exceeded');

  final int maxFiles;

  @override
  List<Object?> get props => [message, maxFiles];
}

/// The upload request itself failed (network/server) — wraps `core`'s
/// `Failure.message` without introducing a dependency on `core` here.
final class UploadRequestFailure extends MediaUploadFailure {
  const UploadRequestFailure(super.message);
}
