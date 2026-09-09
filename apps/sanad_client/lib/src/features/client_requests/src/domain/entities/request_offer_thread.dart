import 'package:equatable/equatable.dart';
import 'package:sanad_client/src/features/client_requests/src/domain/entities/request_offer.dart';

/// One provider's negotiation, oldest offer first.
///
/// Exactly one offer in a live thread is pending; its actor says whose turn it
/// is. [completedJobs] and [distanceKm] are the only signals a client has to
/// choose between providers — no prices pass through the platform.
class RequestOfferThread extends Equatable {
  /// Creates a negotiation thread.
  const RequestOfferThread({
    required this.rootOfferId,
    required this.providerId,
    required this.providerName,
    required this.branchId,
    required this.branchName,
    required this.distanceKm,
    required this.completedJobs,
    required this.offers,
  });

  /// The offer that opened this thread.
  final String rootOfferId;

  /// The company negotiating.
  final String providerId;

  /// Provider display name.
  final String providerName;

  /// The branch that would do the work.
  final String branchId;

  /// Branch display name.
  final String branchName;

  /// Straight-line km, frozen at match time.
  final double distanceKm;

  /// Jobs this provider has completed. With no prices in the system,
  /// this and response speed are the only signals a client can choose
  /// on.
  final int completedJobs;

  /// Oldest first, as the server returns them.
  final List<RequestOffer> offers;

  /// The open node, or `null` when the thread is settled.
  RequestOffer? get pendingOffer =>
      offers.where((offer) => offer.status.isPending).firstOrNull;

  /// The client owes this thread a reply.
  bool get isAwaitingClient => pendingOffer?.awaitsClient ?? false;

  /// The client already countered and is waiting on the provider.
  bool get isAwaitingProvider => pendingOffer?.awaitsProvider ?? false;

  /// The most recent proposal, whoever made it — what the UI headlines.
  RequestOffer? get latestOffer => offers.isEmpty ? null : offers.last;

  @override
  List<Object?> get props => [
    rootOfferId,
    providerId,
    providerName,
    branchId,
    branchName,
    distanceKm,
    completedJobs,
    offers,
  ];
}
