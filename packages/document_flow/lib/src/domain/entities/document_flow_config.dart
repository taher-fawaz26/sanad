import 'package:document_flow/document_flow.dart' show DocumentValidation;
import 'package:document_flow/src/domain/entities/document_type.dart';
import 'package:document_flow/src/domain/entities/document_validation.dart'
    show DocumentValidation;

/// Branch-free configuration for one document flow instance.
///
/// A feature builds one of these (e.g. `registrationDocumentFlowConfig`,
/// `organizationDocumentFlowConfig`) instead of the package branching on
/// "am I registration or organization settings".
class DocumentFlowConfig {
  const DocumentFlowConfig({
    required this.requiredDocuments,
    this.allowedMimeTypes = const {},
    this.defaultAllowedMimeTypes = const {
      'image/jpeg',
      'image/png',
      'application/pdf',
    },
    this.maxSizeBytes = const {},
    this.defaultMaxSizeBytes,
    this.enableExtraction = true,
    this.enablePreview = true,
    this.enableValidation = true,
    this.enablePrefetch = false,
    this.showWarnings = true,
    this.labelKeys = const {},
    this.titleKey,
    this.subtitleKey,
  });

  /// Documents that must have an uploaded remote id before submit is allowed.
  final List<DocumentType> requiredDocuments;

  /// Allowed mime types per document type; falls back to
  /// [defaultAllowedMimeTypes] when a type has no explicit entry.
  final Map<DocumentType, Set<String>> allowedMimeTypes;
  final Set<String> defaultAllowedMimeTypes;

  /// Max file size per document type; falls back to [defaultMaxSizeBytes]
  /// (`null` meaning unlimited) when a type has no explicit entry.
  final Map<DocumentType, int> maxSizeBytes;
  final int? defaultMaxSizeBytes;

  /// Whether this flow calls OCR extraction after upload, or goes straight
  /// from uploaded to editable/submittable.
  final bool enableExtraction;

  /// Whether uploaded documents render an inline preview.
  final bool enablePreview;

  /// Whether [DocumentValidation] rules are enforced before submit.
  final bool enableValidation;

  /// Whether the flow fetches previously submitted documents on start
  /// (settings/update flows) as opposed to starting empty (onboarding).
  final bool enablePrefetch;

  /// Whether extraction-issue banners/warnings are shown in review UIs.
  final bool showWarnings;

  /// l10n keys for labels, keyed by document type (e.g. upload card titles).
  final Map<DocumentType, String> labelKeys;

  final String? titleKey;
  final String? subtitleKey;
}
