import 'package:equatable/equatable.dart';

/// A single uploaded media file returned by the backend — used for both the
/// organization's cover/profile images and legal-document media (front/back
/// Emirates ID, trade license document). Backend has two distinct DTOs for
/// these (`ServiceProviderMediaResponseDto` / `LegalDataMediaResponseDto`)
/// but they are structurally identical, so they map to this one entity.
class MediaEntity extends Equatable {
  const MediaEntity({
    required this.id,
    required this.url,
    required this.originalName,
    required this.mimeType,
  });

  final String id;
  final String url;
  final String originalName;
  final String mimeType;

  @override
  List<Object?> get props => [id, url, originalName, mimeType];
}
