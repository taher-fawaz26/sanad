import 'package:equatable/equatable.dart';
import 'package:requests_core/requests_core.dart';
import 'package:sanad_provider/src/features/requests/src/domain/entities/gated_contact.dart';
import 'package:sanad_provider/src/features/requests/src/domain/entities/provider_offer.dart';
import 'package:sanad_provider/src/features/requests/src/domain/enums/provider_request_tab.dart';

/// A client request, as a **matched provider** sees it.
///
/// Deliberately a different model from the client app's `ClientRequest`, not a
/// shared one with fields blanked out. The server returns genuinely different
/// shapes, and for privacy reasons:
///
/// * rival offers are never present — only [myOffers], this provider's own
///   thread;
/// * the street address and exact coordinates are withheld until this provider
///   wins the work. Only [areaName] is exposed before that, and only one area,
///   because listing every overlapping area would pinpoint the client more
///   precisely than naming one.
///
/// Sharing one model across both roles is exactly the mistake that would leak
/// either.
class ProviderRequest extends Equatable {
  /// Creates a provider-view request.
  const ProviderRequest({
    required this.id,
    required this.status,
    required this.tab,
    required this.serviceName,
    required this.distanceKm,
    required this.remainingRebids,
    required this.contact,
    required this.createdAt,
    this.categoryName,
    this.areaName,
    this.preferredAt,
    this.note,
    this.attachments = const [],
    this.branchId,
    this.branchName,
    this.myOfferStatus,
    this.myOffers = const [],
    this.disputeReason,
  });

  /// Request id.
  final String id;

  /// The request's own lifecycle state, shared with the client view.
  final ClientRequestStatus status;

  /// Which workspace tab this sits in — **server-derived**, never recomputed.
  final ProviderRequestTab tab;

  /// What the client asked for, localized server-side.
  final String serviceName;

  /// Owning category, localized server-side.
  final String? categoryName;

  /// A single coarse area. The only location detail available before the
  /// booking is won.
  final String? areaName;

  /// When the client would like the work done.
  final DateTime? preferredAt;

  /// The client's description of the job.
  final String? note;

  /// Photos and documents the client attached.
  final List<RequestAttachment> attachments;

  /// From the branch on this provider's offer, or their nearest match.
  final double distanceKm;

  /// The branch this provider offered from, once they have.
  final String? branchId;

  /// That branch's name.
  final String? branchName;

  /// This provider's own thread status. Null before they bid.
  final RequestOfferStatus? myOfferStatus;

  /// Only this provider's thread. Rivals are never visible.
  final List<ProviderOffer> myOffers;

  /// How many further offers this provider may make on this request.
  ///
  /// Withdrawing consumes one — send-and-withdraw is not a free retry. At zero,
  /// creating another live root offer answers `409`.
  final int remainingRebids;

  /// The gated client contact block. [GatedContact.isUnlocked] is the single
  /// field the UI may consult to decide whether details are available.
  final GatedContact contact;

  /// Why the client says the work was not done. Read-only here.
  final String? disputeReason;

  /// When the request was created.
  final DateTime createdAt;

  /// The open node in this provider's thread, if any.
  ProviderOffer? get pendingOffer =>
      myOffers.where((offer) => offer.status.isPending).firstOrNull;

  /// Whether the next move is this provider's — i.e. the client countered.
  bool get isAwaitingProvider => pendingOffer?.awaitsProvider ?? false;

  /// Whether this provider is waiting on the client.
  bool get isAwaitingClient => pendingOffer?.awaitsClient ?? false;

  /// Whether an offer can be sent right now.
  ///
  /// Only a gate on the button: the server re-checks, and a `409` for an
  /// exhausted budget or a still-live thread must still be surfaced.
  bool get canSendOffer =>
      myOffers.isEmpty ||
      (pendingOffer == null && remainingRebids > 0 && !status.isClosed);

  /// Whether a pending offer of this provider's own can be pulled back.
  bool get canWithdraw => pendingOffer?.awaitsClient ?? false;

  /// Whether the job can be marked finished.
  bool get canComplete =>
      status == ClientRequestStatus.scheduled ||
      status == ClientRequestStatus.inProgress;

  /// Whether a won booking can still be cancelled.
  bool get canCancelBooking =>
      contact.isUnlocked &&
      !status.isClosed &&
      status != ClientRequestStatus.draft;

  @override
  List<Object?> get props => [
    id,
    status,
    tab,
    serviceName,
    categoryName,
    areaName,
    preferredAt,
    note,
    attachments,
    distanceKm,
    branchId,
    branchName,
    myOfferStatus,
    myOffers,
    remainingRebids,
    contact,
    disputeReason,
    createdAt,
  ];
}
