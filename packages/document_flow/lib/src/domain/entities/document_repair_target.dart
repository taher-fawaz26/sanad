import 'package:document_flow/src/domain/entities/document_type.dart';
import 'package:equatable/equatable.dart';

/// How much of a document must be replaced to fix its `DocumentIssue`.
///
/// Distinct from `DocumentIssue`: the issue describes *what* is wrong; this
/// describes *what the user must replace* to fix it. Most issues (a blurry
/// single-file scan, an expired trade licence) only ever need [singlePart].
enum DocumentRepairScope {
  /// Only the one flagged [DocumentType] needs replacing.
  singlePart,

  /// Every part in [DocumentRepairTarget.parts] must be replaced together —
  /// e.g. a front/back mismatch, where replacing only one side can still
  /// leave two sides that don't belong to the same physical card.
  wholeDocument,
}

/// What a document's `DocumentIssue` requires the user to replace.
///
/// A `null` `ExtractedDocument.repair` means the default, existing
/// single-file replace action applies. This type only needs to be populated
/// when an issue requires more than that (currently: a whole multi-part
/// document such as a front/back Emirates ID mismatch).
class DocumentRepairTarget extends Equatable {
  const DocumentRepairTarget({required this.parts, required this.scope});

  /// The document slots that must all be satisfied before the issue can be
  /// considered fixed. For [DocumentRepairScope.wholeDocument] this is every
  /// part of the logical document (e.g. Emirates ID front + back).
  final List<DocumentType> parts;

  final DocumentRepairScope scope;

  @override
  List<Object?> get props => [parts, scope];
}
