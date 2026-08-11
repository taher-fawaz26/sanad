import 'package:document_flow/src/domain/entities/document_flow_config.dart';
import 'package:document_flow/src/domain/entities/document_type.dart';

/// Pure validation helpers driven entirely by [DocumentFlowConfig] — no
/// feature ever branches on document type here, only on what its config
/// declares as required/allowed.
abstract final class DocumentValidation {
  DocumentValidation._();

  /// Whether [mimeType] is accepted for [type] under [config].
  static bool isAllowedType(
    DocumentFlowConfig config,
    DocumentType type,
    String mimeType,
  ) {
    final allowed =
        config.allowedMimeTypes[type] ?? config.defaultAllowedMimeTypes;
    return allowed.isEmpty || allowed.contains(mimeType);
  }

  /// Whether [sizeBytes] is within the configured limit for [type].
  static bool isAllowedSize(
    DocumentFlowConfig config,
    DocumentType type,
    int sizeBytes,
  ) {
    final max = config.maxSizeBytes[type] ?? config.defaultMaxSizeBytes;
    return max == null || sizeBytes <= max;
  }

  /// Whether every document `config.requiredDocuments` declares has a
  /// remote id in [uploadedIds].
  static bool isComplete(
    DocumentFlowConfig config,
    Map<DocumentType, String> uploadedIds,
  ) {
    return config.requiredDocuments.every(
      (type) => (uploadedIds[type] ?? '').isNotEmpty,
    );
  }
}
