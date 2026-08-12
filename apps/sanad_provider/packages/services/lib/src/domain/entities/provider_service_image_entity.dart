import 'package:equatable/equatable.dart';

/// One image attached to a provider service.
///
/// [id] is the image **row id** — required by the delete and set-primary
/// endpoints (`.../images/:imageId`, `.../images/:imageId/primary`). It is
/// distinct from [mediaId], the id returned by the media-upload service.
class ProviderServiceImageEntity extends Equatable {
  const ProviderServiceImageEntity({
    required this.id,
    required this.mediaId,
    required this.url,
    required this.isPrimary,
  });

  final String id;
  final String mediaId;
  final String url;
  final bool isPrimary;

  @override
  List<Object?> get props => [id, mediaId, url, isPrimary];
}
