part of 'provider_request_detail_bloc.dart';

/// Base type for everything the provider detail bloc reacts to.
sealed class ProviderRequestDetailEvent extends Equatable {
  /// Const so subclasses can be const.
  const ProviderRequestDetailEvent();

  @override
  List<Object?> get props => const [];
}

/// First load of the request.
final class ProviderRequestDetailStarted extends ProviderRequestDetailEvent {
  /// Creates the load event.
  const ProviderRequestDetailStarted();
}

/// Re-reads the request from the server.
final class ProviderRequestDetailRefreshed extends ProviderRequestDetailEvent {
  /// Creates the re-read event.
  const ProviderRequestDetailRefreshed();
}

/// Offers to do the job.
final class ProviderOfferCreated extends ProviderRequestDetailEvent {
  /// Creates the offer event.
  const ProviderOfferCreated({
    required this.branchId,
    required this.proposedAt,
    this.note,
  });

  /// The matched branch that will do the work.
  final String branchId;

  /// Proposed start. Must be in the future.
  final DateTime proposedAt;

  /// Optional message to the client.
  final String? note;

  @override
  List<Object?> get props => [branchId, proposedAt, note];
}

/// Pulls back a pending offer. Consumes a re-bid.
final class ProviderOfferWithdrawn extends ProviderRequestDetailEvent {
  /// Creates the withdraw event.
  const ProviderOfferWithdrawn(this.offerId);

  /// The offer to withdraw.
  final String offerId;

  @override
  List<Object?> get props => [offerId];
}

/// Accepts the client's counter and books the job.
final class ProviderCounterAccepted extends ProviderRequestDetailEvent {
  /// Creates the accept event.
  const ProviderCounterAccepted(this.offerId);

  /// The client counter being accepted.
  final String offerId;

  @override
  List<Object?> get props => [offerId];
}

/// Declines the client's counter.
final class ProviderCounterDeclined extends ProviderRequestDetailEvent {
  /// Creates the decline event.
  const ProviderCounterDeclined(this.offerId);

  /// The client counter being declined.
  final String offerId;

  @override
  List<Object?> get props => [offerId];
}

/// Counters the client's counter with another time.
final class ProviderCounterSent extends ProviderRequestDetailEvent {
  /// Creates the counter event.
  const ProviderCounterSent({
    required this.offerId,
    required this.proposedAt,
    this.note,
  });

  /// The client counter being answered.
  final String offerId;

  /// The time this provider proposes instead. Must be in the future.
  final DateTime proposedAt;

  /// Optional message to the client.
  final String? note;

  @override
  List<Object?> get props => [offerId, proposedAt, note];
}

/// Marks the job finished, moving it to AWAITING_CONFIRMATION.
final class ProviderJobCompleted extends ProviderRequestDetailEvent {
  /// Creates the complete event.
  const ProviderJobCompleted();
}

/// Cancels a won booking, with a reason the client will read.
final class ProviderJobCancelled extends ProviderRequestDetailEvent {
  /// Creates the cancel event.
  const ProviderJobCancelled(this.reason);

  /// Why the booking is being called off. 3-1000 characters.
  final String reason;

  @override
  List<Object?> get props => [reason];
}

/// Clears a consumed action result so a snackbar cannot fire twice.
final class ProviderRequestMutationAcknowledged
    extends ProviderRequestDetailEvent {
  /// Creates the acknowledgement event.
  const ProviderRequestMutationAcknowledged();
}
