part of 'identity_header_bloc.dart';

/// State of a single identity image slot (cover or logo).
class IdentityMediaSlotState extends Equatable {
  const IdentityMediaSlotState({
    this.status = RequestStatus.initial,
    this.imageUrl,
    this.progress = 0.0,
    this.failure,
    this.lastMedia,
  });

  /// `loading` == an upload or removal is in flight.
  final RequestStatus status;

  /// The current image URL, updated optimistically on success.
  final String? imageUrl;

  final double progress;

  final Failure? failure;

  /// The most recent edited media for this slot, retained so a failed upload
  /// can be retried without re-picking. `null` for a removal.
  final EditedMedia? lastMedia;

  bool get isBusy => status == RequestStatus.loading;

  bool get hasError => status == RequestStatus.failure;

  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;

  bool get canRetry => hasError && lastMedia != null;

  IdentityMediaSlotState copyWith({
    RequestStatus? status,
    Object? imageUrl = _sentinel,
    double? progress,
    Failure? failure,
    Object? lastMedia = _sentinel,
    bool clearFailure = false,
  }) {
    return IdentityMediaSlotState(
      status: status ?? this.status,
      imageUrl: identical(imageUrl, _sentinel)
          ? this.imageUrl
          : imageUrl as String?,
      progress: progress ?? this.progress,
      failure: clearFailure ? null : (failure ?? this.failure),
      lastMedia: identical(lastMedia, _sentinel)
          ? this.lastMedia
          : lastMedia as EditedMedia?,
    );
  }

  static const Object _sentinel = Object();

  @override
  List<Object?> get props => [status, imageUrl, progress, failure, lastMedia];
}
