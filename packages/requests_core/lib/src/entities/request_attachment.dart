import 'package:equatable/equatable.dart';

/// A file attached to a request.
///
/// Identical in the client and provider views, which is why it lives here
/// rather than being modelled twice. [mediaId] is the identifier — [url] is
/// display-only and must never be used as one (the same rule
/// `package:media_upload`'s `UploadedMedia` states for its own payload).
class RequestAttachment extends Equatable {
  const RequestAttachment({
    required this.id,
    required this.mediaId,
    required this.url,
    required this.mimeType,
  });

  /// Parses the shared `RequestAttachmentDto` shape. Every field is required by
  /// the contract; missing values degrade to empty strings rather than throwing
  /// so one malformed attachment cannot fail a whole request payload.
  factory RequestAttachment.fromJson(Map<String, dynamic> json) =>
      RequestAttachment(
        id: json['id'] as String? ?? '',
        mediaId: json['mediaId'] as String? ?? '',
        url: json['url'] as String? ?? '',
        mimeType: json['mimeType'] as String? ?? '',
      );

  final String id;
  final String mediaId;
  final String url;
  final String mimeType;

  /// Whether this attachment renders as an image (the alternative the backend
  /// accepts is PDF).
  bool get isImage => mimeType.startsWith('image/');

  Map<String, dynamic> toJson() => {
    'id': id,
    'mediaId': mediaId,
    'url': url,
    'mimeType': mimeType,
  };

  @override
  List<Object?> get props => [id, mediaId, url, mimeType];
}
