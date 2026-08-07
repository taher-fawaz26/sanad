import 'package:document_flow/src/domain/entities/document_type.dart';
import 'package:document_flow/src/domain/entities/extracted_field.dart';
import 'package:equatable/equatable.dart';

/// Points a document slot back at the media already stored for it.
///
/// Populated by a `DocumentFlowRepository.fetch` prefill (a settings/update
/// flow resuming with existing documents) so the bloc can seed that slot as
/// already-uploaded without the user re-picking a file. A single section may
/// back more than one slot (e.g. an Emirates ID section backs both
/// `emiratesIdFront` and `emiratesIdBack`), hence [ExtractedDocument.media]
/// is a list rather than a single reference.
class DocumentMediaRef extends Equatable {
  const DocumentMediaRef({
    required this.type,
    required this.mediaId,
    this.mediaUrl,
    this.fileName,
    this.mimeType,
  });

  final DocumentType type;
  final String mediaId;
  final String? mediaUrl;
  final String? fileName;
  final String? mimeType;

  @override
  List<Object?> get props => [type, mediaId, mediaUrl, fileName, mimeType];
}

/// The OCR/verification outcome for one document, generalized for display.
///
/// [fields] drive generic review UIs (label/value grid). [raw] carries the
/// same data keyed by backend field name so a feature can read specific
/// values (e.g. a name fallback for a submit request) without the package
/// knowing what those fields mean. [media] optionally backs one or more
/// upload slots with already-stored media (see [DocumentMediaRef]).
class ExtractedDocument extends Equatable {
  const ExtractedDocument({
    required this.type,
    required this.fields,
    this.issue = DocumentIssue.none,
    this.raw = const {},
    this.media = const [],
  });

  final DocumentType type;
  final DocumentIssue issue;
  final List<ExtractedField> fields;
  final Map<String, String> raw;
  final List<DocumentMediaRef> media;

  bool get ok => issue == DocumentIssue.none;

  @override
  List<Object?> get props => [type, issue, fields, raw, media];
}

/// The combined outcome of an extraction call across every requested document.
class ExtractedDocuments extends Equatable {
  const ExtractedDocuments({this.sections = const []});

  final List<ExtractedDocument> sections;

  /// True when every section extracted without an issue.
  bool get allOk => sections.every((s) => s.ok);

  ExtractedDocument? sectionOf(DocumentType type) {
    for (final section in sections) {
      if (section.type == type) return section;
    }
    return null;
  }

  @override
  List<Object?> get props => [sections];
}
