part of 'client_request_detail_bloc.dart';

/// Base type for everything the request-detail bloc reacts to.
sealed class ClientRequestDetailEvent extends Equatable {
  /// Const so subclasses can be const.
  const ClientRequestDetailEvent();

  @override
  List<Object?> get props => const [];
}

/// First load of the request.
final class ClientRequestDetailStarted extends ClientRequestDetailEvent {
  /// Creates the load event.
  const ClientRequestDetailStarted();
}

/// Re-reads the request from the server.
///
/// Dispatched on pull-to-refresh, when the screen becomes active again, on app
/// resume, and when a push signals that this request moved — including the
/// transitions the server makes on a timer rather than in response to a tap.
final class ClientRequestDetailRefreshed extends ClientRequestDetailEvent {
  /// Creates the re-read event.
  const ClientRequestDetailRefreshed();
}

/// Calls the request off, with a recorded reason.
final class ClientRequestCancelled extends ClientRequestDetailEvent {
  /// Creates a cancellation carrying [reason].
  const ClientRequestCancelled(this.reason);

  /// Why the request is being called off. 3-1000 characters.
  /// Why the work was not done as claimed. Shown to the provider verbatim.
  final String reason;

  @override
  List<Object?> get props => [reason];
}

/// Confirms the provider's completion claim.
final class ClientRequestConfirmed extends ClientRequestDetailEvent {
  /// Creates the confirmation event.
  const ClientRequestConfirmed();
}

/// Disputes the provider's completion claim.
final class ClientRequestDisputed extends ClientRequestDetailEvent {
  /// Creates a dispute carrying [reason].
  const ClientRequestDisputed(this.reason);

  /// Why the work was not done as claimed. Shown to the provider verbatim.
  final String reason;

  @override
  List<Object?> get props => [reason];
}

/// Accepts a provider's offer — books the job and closes rival offers as LOST.
/// Accepts a provider offer, booking the job.
final class ClientRequestOfferAccepted extends ClientRequestDetailEvent {
  /// Creates an acceptance of [offerId].
  const ClientRequestOfferAccepted(this.offerId);

  /// The offer to accept.
  /// The offer to decline.
  /// The offer being countered.
  /// The offer to accept.
  final String offerId;

  @override
  List<Object?> get props => [offerId];
}

/// Declines one provider's offer. Ends that thread only.
/// Declines one provider offer. Ends that thread only.
final class ClientRequestOfferRejected extends ClientRequestDetailEvent {
  /// Creates a rejection of [offerId].
  const ClientRequestOfferRejected(this.offerId);

  /// The offer to decline.
  final String offerId;

  @override
  List<Object?> get props => [offerId];
}

/// Counters with a different time. Supersedes the provider's offer rather than
/// rejecting it, and hands the turn back to them.
final class ClientRequestOfferCountered extends ClientRequestDetailEvent {
  /// Creates a counter-proposal against [offerId].
  const ClientRequestOfferCountered({
    required this.offerId,
    required this.proposedAt,
    this.note,
  });

  /// The offer being countered. Must belong to this request.
  final String offerId;

  /// The time the client would prefer instead. Must be future.
  final DateTime proposedAt;

  /// Optional message, at most 1000 chars.
  final String? note;

  @override
  List<Object?> get props => [offerId, proposedAt, note];
}

/// Clears a consumed mutation result so a snackbar cannot fire twice.
/// Clears a consumed action result so a snackbar cannot fire twice.
final class ClientRequestMutationAcknowledged extends ClientRequestDetailEvent {
  /// Creates the acknowledgement event.
  const ClientRequestMutationAcknowledged();
}
