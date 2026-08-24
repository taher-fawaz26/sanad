import 'package:equatable/equatable.dart';

/// A single labelled field extracted from a document (label → value).
///
/// Kept as an explicit key/value pair so review UIs can render rows
/// generically without hard-coding every field name in the widget tree.
class ExtractedField extends Equatable {
  const ExtractedField(
    this.label,
    this.value, {
    this.highlight = false,
    this.fullWidth = false,
    this.rtl = false,
  });

  final String label;

  /// The extracted value. Empty renders as an em-dash placeholder on screen.
  final String value;

  /// When true the value is emphasised (e.g. an expiry date on an error card).
  final bool highlight;

  /// When true the field spans the full card width; otherwise it shares a row
  /// with the next half-width field (two-column grid).
  final bool fullWidth;

  /// When true the value is rendered right-to-left (Arabic name / trade name).
  final bool rtl;

  @override
  List<Object?> get props => [label, value, highlight, fullWidth, rtl];
}

/// Why a document could not be verified. [none] means it extracted cleanly.
enum DocumentIssue {
  none,

  /// The photo was too blurry / cropped to read reliably.
  imageUnclear,

  /// The document is already linked to another account (HTTP 409).
  alreadyRegistered,

  /// The document is past its expiry date.
  expired,

  /// The front and back of a multi-part document (e.g. Emirates ID) do not
  /// belong to the same physical card (`EXTRACTION_ID_MISMATCH`).
  idMismatch,
}
