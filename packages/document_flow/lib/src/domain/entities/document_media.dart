import 'package:document_flow/src/domain/entities/document_type.dart';
import 'package:equatable/equatable.dart';

/// The result of a single successful media upload.
class DocumentMedia extends Equatable {
  const DocumentMedia({
    required this.id,
    required this.url,
    required this.fileName,
    required this.mimeType,
    required this.size,
    required this.type,
  });

  final String id;
  final String url;
  final String fileName;
  final String mimeType;
  final int size;
  final DocumentType type;

  @override
  List<Object?> get props => [id, url, fileName, mimeType, size, type];
}
