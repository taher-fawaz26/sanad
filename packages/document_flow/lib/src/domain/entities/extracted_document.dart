import 'package:document_flow/src/domain/entities/document_repair_target.dart';
import 'package:document_flow/src/domain/entities/document_status.dart';
import 'package:document_flow/src/domain/entities/document_type.dart';
import 'package:document_flow/src/domain/entities/extracted_field.dart';
import 'package:document_flow/src/domain/entities/id_verification.dart';
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
    this.issueDetail,
    this.repair,
    this.raw = const {},
    this.media = const [],
    this.missingFields = const [],
    this.status,
    this.idVerification,
  });

  final DocumentType type;
  final DocumentIssue issue;

  /// The server-derived lifecycle status for this document, when the
  /// extraction/preview response carries one. `null` for a flow that predates
  /// or doesn't surface this signal (e.g. a synthetic already-registered
  /// section). Distinct from [issue]: [DocumentStatus.expiringSoon] is a
  /// non-blocking warning, while [issue] reflects only what blocks submit.
  final DocumentStatus? status;

  /// The Emirates ID front/back comparison result, when this document is an
  /// Emirates ID and the backend returned one. Always `null` for a trade
  /// licence, which has no such concept.
  final IdVerification? idVerification;

  /// A dynamic, already-localized detail message for [issue] (e.g. a backend
  /// rejection message such as "couldn't read license_number…"). When present
  /// the review UI shows this in the error banner in place of the static,
  /// issue-generic copy; when null the static message is used. Always null for
  /// a cleanly extracted document ([DocumentIssue.none]).
  final String? issueDetail;

  /// What must be replaced to fix [issue], when it's more than the default
  /// single-file replace — e.g. a front/back mismatch requiring both sides.
  /// Null (the common case) means the existing single-file replace action
  /// applies as-is.
  final DocumentRepairTarget? repair;

  final List<ExtractedField> fields;
  final Map<String, String> raw;
  final List<DocumentMediaRef> media;

  /// Raw backend field identifiers (e.g. `license_number`) this document's
  /// [issue] concerns — OCR-unreadable or missing required fields. English,
  /// machine-cased, and not user-facing as-is: the presentation layer resolves
  /// each to a localized label before display. Empty unless [issue] is set
  /// with specific fields attributable to it.
  final List<String> missingFields;

  bool get ok => issue == DocumentIssue.none;

  @override
  List<Object?> get props => [
    type,
    issue,
    issueDetail,
    repair,
    fields,
    raw,
    media,
    missingFields,
    status,
    idVerification,
  ];
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
