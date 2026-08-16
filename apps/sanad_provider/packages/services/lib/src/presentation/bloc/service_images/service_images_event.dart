part of 'service_images_bloc.dart';

sealed class ServiceImagesEvent extends Equatable {
  const ServiceImagesEvent();

  @override
  List<Object?> get props => [];
}

/// Forwarded verbatim from `MediaUploadBloc` by `ManageServiceImagesSection`
/// (`BlocListener` → `add`) on every state change. This bloc alone decides
/// which items are newly-succeeded and kicks off their attach — the widget
/// makes no such decision, it only relays.
final class ServiceImagesUploadStateChanged extends ServiceImagesEvent {
  const ServiceImagesUploadStateChanged(this.items);

  final List<MediaUploadItem> items;

  @override
  List<Object?> get props => [items];
}

/// Re-attempts the attach for an already upload-succeeded item. Never
/// re-uploads — the asset is already on the media service; only
/// [AddProviderServiceImageUseCase] is re-called.
final class ServiceImagesAttachRetryRequested extends ServiceImagesEvent {
  const ServiceImagesAttachRetryRequested({
    required this.localId,
    required this.mediaId,
  });

  final String localId;
  final String mediaId;

  @override
  List<Object?> get props => [localId, mediaId];
}

/// The user gave up on an in-progress (not-yet-attached) item — dispatched
/// alongside `MediaUploadRemoveRequested` on the sibling `MediaUploadBloc`,
/// which owns the actual removal/best-effort media cleanup. This event only
/// drops this bloc's own `attachStatus` tracking for it.
final class ServiceImagesInProgressRemoved extends ServiceImagesEvent {
  const ServiceImagesInProgressRemoved(this.localId);

  final String localId;

  @override
  List<Object?> get props => [localId];
}

/// `imageId` is the image row id ([ProviderServiceImageEntity.id]), never
/// the underlying `mediaId`.
final class ServiceImagesSetPrimaryRequested extends ServiceImagesEvent {
  const ServiceImagesSetPrimaryRequested(this.imageId);

  final String imageId;

  @override
  List<Object?> get props => [imageId];
}

/// `imageId` is the image row id ([ProviderServiceImageEntity.id]), never
/// the underlying `mediaId`.
final class ServiceImagesDeleteRequested extends ServiceImagesEvent {
  const ServiceImagesDeleteRequested(this.imageId);

  final String imageId;

  @override
  List<Object?> get props => [imageId];
}
