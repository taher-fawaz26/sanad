import 'package:equatable/equatable.dart';
import 'package:requests_core/requests_core.dart';

/// One node in a negotiation thread — a proposal from either side.
class RequestOffer extends Equatable {
  /// Creates an offer node.
  const RequestOffer({
    required this.id,
    required this.actorType,
    required this.status,
    required this.proposedAt,
    required this.createdAt,
    this.note,
    this.parentOfferId,
  });

  /// Offer id — required in the URL of every offer action.
  final String id;

  /// Who proposed it. On the thread's pending node this is the whole
  /// turn-taking rule.
  final RequestOfferActorType actorType;

  /// Where this node stands. `LOST` and `REJECTED` are different
  /// outcomes and must not be shown as the same thing.
  final RequestOfferStatus status;

  /// The proposed start time.
  final DateTime proposedAt;

  /// When the offer was made.
  final DateTime createdAt;

  /// Optional message from whoever proposed it.
  final String? note;

  /// Set on a counter — the offer this one answers.
  final String? parentOfferId;

  /// Whether a provider authored this node.
  bool get isFromProvider => actorType == RequestOfferActorType.provider;

  /// Whether the client authored this node.
  bool get isFromClient => actorType == RequestOfferActorType.client;

  /// Awaiting a reply *from the client*.
  bool get awaitsClient => status.isPending && isFromProvider;

  /// Awaiting a reply *from the provider* — i.e. the client already countered.
  bool get awaitsProvider => status.isPending && isFromClient;

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
