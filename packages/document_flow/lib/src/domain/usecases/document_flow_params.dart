import 'package:document_flow/document_flow.dart' show DocumentFlowRepository, ExtractDocumentsUseCase, FetchDocumentsUseCase, SubmitDocumentsUseCase, UploadMediaUseCase;
import 'package:document_flow/src/domain/entities/document_flow_context.dart';
import 'package:document_flow/src/domain/entities/document_type.dart';
import 'package:document_flow/src/domain/entities/extracted_document.dart';

/// Params for [DocumentFlowRepository.uploadMedia] / [UploadMediaUseCase].
class UploadMediaParams {
  const UploadMediaParams({
    required this.type,
    required this.filePath,
    required this.fileName,
    required this.mimeType,
    required this.uploadKey,
    required this.context,
    this.onProgress,
  });

  final DocumentType type;
  final String filePath;
  final String fileName;
  final String mimeType;

  /// Identifies this in-flight upload so it can be cancelled independently.
  final String uploadKey;
  final DocumentFlowContext context;
  final void Function(double progress)? onProgress;
}

/// Params for [DocumentFlowRepository.extract] / [ExtractDocumentsUseCase].
class ExtractParams {
  const ExtractParams({required this.uploadedIds, required this.context});

  /// Backend media ids keyed by the document slot they belong to.
  final Map<DocumentType, String> uploadedIds;
  final DocumentFlowContext context;
}

/// Params for [DocumentFlowRepository.submit] / [SubmitDocumentsUseCase].
class SubmitParams {
  const SubmitParams({
    required this.uploadedIds,
    required this.context,
    this.extracted,
  });

  final Map<DocumentType, String> uploadedIds;
  final ExtractedDocuments? extracted;
  final DocumentFlowContext context;
}

/// Params for [DocumentFlowRepository.fetch] / [FetchDocumentsUseCase].
class FetchParams {
  const FetchParams({required this.context});

  final DocumentFlowContext context;
}
