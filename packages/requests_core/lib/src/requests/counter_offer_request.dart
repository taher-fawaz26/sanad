import 'package:equatable/equatable.dart';
import 'package:requests_core/src/time/api_date_time.dart';

/// `CounterOfferDto` — the body for every counter-offer, from either side.
///
/// The client's `POST /requests/:id/offers/:offerId/counter` and the provider's
/// `POST /provider/offers/:offerId/counter` take the same shape, which is why
/// this is shared. Countering supersedes the other side's offer rather than
/// rejecting it, and makes this proposal the thread's pending node.
class CounterOfferRequest extends Equatable {
  const CounterOfferRequest({required this.proposedAt, this.note});

  /// The proposed start. Must be in the future — the server answers `400`
  /// otherwise. Serialized with an explicit offset by [ApiDateTime].
  final DateTime proposedAt;

  /// Optional free text, at most 1000 characters.
  final String? note;

  Map<String, dynamic> toJson() {
    final trimmed = note?.trim();
    return {
      'proposedAt': ApiDateTime.encode(proposedAt),
      if (trimmed != null && trimmed.isNotEmpty) 'note': trimmed,
    };
  }

  @override
  List<Object?> get props => [proposedAt, note];
}
