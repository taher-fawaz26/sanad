import 'package:equatable/equatable.dart';

/// A file successfully stored by `POST media/onboarding`.
///
/// Backend response is the source of truth — [id] and [url] are persisted on
/// the corresponding uploadable asset as `remoteId` / `remoteUrl`.
class MediaFileEntity extends Equatable {
  const MediaFileEntity({
    required this.id,
    required this.originalName,
    required this.fileName,
    required this.mimeType,
    required this.size,
    required this.type,
    required this.url,
    required this.createdAt,
  });

  final String id;
  final String originalName;
  final String fileName;
  final String mimeType;
  final int size;
  final String type;
  final String url;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
        id,
        originalName,
        fileName,
        mimeType,
        size,
        type,
        url,
        createdAt,
      ];
}
