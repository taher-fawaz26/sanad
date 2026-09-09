import 'package:equatable/equatable.dart';
import 'package:requests_core/requests_core.dart';

/// One node in **this provider's own** negotiation thread.
///
/// Rival providers' offers never reach the device, so there is no thread
/// grouping here the way there is on the client side — a provider has exactly
/// one thread per request.
class ProviderOffer extends Equatable {
  /// Creates an offer node.
  const ProviderOffer({
    required this.id,
    required this.actorType,
    required this.status,
    required this.proposedAt,
    required this.createdAt,
    this.note,
    this.parentOfferId,
  });

  /// Offer id — the address for withdraw, accept, decline and counter.
  final String id;

  /// Who proposed it. On the pending node this decides whose turn it is.
  final RequestOfferActorType actorType;

  /// Where this node stands.
  final RequestOfferStatus status;

  /// The proposed start time.
  final DateTime proposedAt;

  /// When the offer was made.
  final DateTime createdAt;

  /// Optional message from whoever proposed it.
  final String? note;

  /// The offer this one answers. Null on the thread's root offer.
  final String? parentOfferId;

  /// Whether this provider authored it.
  bool get isMine => actorType == RequestOfferActorType.provider;

  /// Pending and authored by this provider — waiting on the client.
  bool get awaitsClient => status.isPending && isMine;

  /// Pending and authored by the client — waiting on this provider.
  bool get awaitsProvider =>
      status.isPending && actorType == RequestOfferActorType.client;

  @override
  List<Object?> get props => [
    id,
    actorType,
    status,
    proposedAt,
    createdAt,
    note,
    parentOfferId,
  ];
}
