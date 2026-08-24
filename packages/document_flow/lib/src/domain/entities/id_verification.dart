import 'package:equatable/equatable.dart';

/// The extractor's Emirates ID front/back comparison result. Present only for
/// Emirates ID documents; a trade licence has no such concept. Not persisted
/// server-side — this is preview-only, produced fresh on every extraction.
class IdVerification extends Equatable {
  const IdVerification({required this.matched, this.reason, this.backIdNumber});

  /// `false` means the front and back images belong to different physical
  /// cards (backend code `EXTRACTION_ID_MISMATCH`).
  final bool matched;

  /// Machine-readable reason for a mismatch, e.g. `front_back_id_mismatch`.
  final String? reason;

  final String? backIdNumber;

  @override
  List<Object?> get props => [matched, reason, backIdNumber];
}
