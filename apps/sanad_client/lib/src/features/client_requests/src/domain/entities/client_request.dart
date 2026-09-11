import 'package:equatable/equatable.dart';
import 'package:requests_core/requests_core.dart';
import 'package:sanad_client/src/features/client_requests/src/domain/entities/matched_branch.dart';
import 'package:sanad_client/src/features/client_requests/src/domain/entities/request_offer_thread.dart';

/// A service request, as its **owning client** sees it.
///
/// This is deliberately not shared with the provider app. The two APIs return
/// different shapes on purpose: a matched provider never sees rival offers, and
/// never sees the client's contact details until it wins the booking. Reusing
/// one model across both roles is exactly the mistake that would leak either.
///
/// Almost every descriptive field is nullable, because a draft is meant to be
/// saved half-finished — `serviceId`, `serviceName`, `categoryId`,
/// `categoryName`, the location fields and the timestamps are all absent until
/// the client fills them in. Only [id], [status], [attachments], [offerCount],
/// [matchedBranches], [threads] and [createdAt] are guaranteed.
class ClientRequest extends Equatable {
  /// Creates a client-view request.
  const ClientRequest({
    required this.id,
    required this.status,
    required this.createdAt,
    this.serviceId,
    this.serviceName,
    this.categoryId,
    this.categoryName,
    this.lat,
    this.lng,
    this.addressLine,
    this.areaName,
    this.preferredAt,
    this.note,
    this.attachments = const [],
    this.submittedAt,
    this.expiresAt,
    this.scheduledAt,
    this.disputeReason,
    this.cancelReason,
    this.offerCount = 0,
    this.matchedBranches = const [],
    this.threads = const [],
  });

  /// Server-assigned request id.
  final String id;

  /// The server-owned lifecycle state. Never predicted locally: some
  /// transitions happen on a timer with no user action at all.
  final ClientRequestStatus status;

  /// When the request was created.
  final DateTime createdAt;

  /// Catalogue service id. Null on a draft that has not picked one.
  final String? serviceId;

  /// Service display name, localized server-side.
  final String? serviceName;

  /// Owning category id, when resolved.
  final String? categoryId;

  /// Owning category display name.
  final String? categoryName;

  /// Job latitude. Null until a location is chosen.
  final double? lat;

  /// Job longitude. Null until a location is chosen.
  final double? lng;

  /// The street address the client entered.
  final String? addressLine;

  /// A coarse area label. The provider view exposes only this, never the
  /// street address, before a booking.
  final String? areaName;

  /// The requested start time.
  final DateTime? preferredAt;

  /// The client's description of the job.
  final String? note;

  /// Images and PDFs attached to the request.
  final List<RequestAttachment> attachments;

  /// When the draft went live. Null while it is still a draft.
  final DateTime? submittedAt;

  /// When an un-answered SUBMITTED request expires. Set by the server at
  /// submit time; the app never computes it.
  final DateTime? expiresAt;

  /// The booked start, set when an offer is accepted.
  final DateTime? scheduledAt;

  /// Why the client said the work was not done.
  final String? disputeReason;

  /// Why the request was called off, from whichever side cancelled.
  final String? cancelReason;

  /// Derived server-side from the live offers.
  final int offerCount;

  /// Frozen at submit time — the branches the request was matched to.
  final List<MatchedBranch> matchedBranches;

  /// One negotiation per provider, offers oldest-first within each.
  final List<RequestOfferThread> threads;

  /// Everything `POST /requests/:id/submit` requires.
  ///
  /// Checked here so the composer can enable its own submit button, but the
  /// server re-validates and a `400` still has to be surfaced.
  bool get isSubmittable =>
      status.isDraft &&
      serviceId != null &&
      lat != null &&
      lng != null &&
      preferredAt != null;

  /// Which of the required fields are still missing, for the composer to
  /// point at.
  List<String> get missingForSubmit => [
    if (serviceId == null) 'serviceId',
    if (lat == null || lng == null) 'location',
    if (preferredAt == null) 'preferredAt',
  ];

  /// Whether the client may still cancel.
  bool get canCancel => !status.isClosed && status != ClientRequestStatus.draft;

  /// Whether the confirm/dispute pair applies right now.
  bool get canConfirmOrDispute =>
      status == ClientRequestStatus.awaitingConfirmation;

  /// Whether this request is waiting on the **client** for something.
  ///
  /// Drives Figma's `Needs your attention` section and its count badge
  /// (`8385:4387`). Three things can put a request there, and all three are
  /// already answered by fields the server sends: an unfinished draft, a
  /// finished job the client has not confirmed, and an offer whose turn is
  /// the client's. Nothing here is a new rule — it is the existing
  /// action-availability getters, read as one question.
  bool get needsAttention =>
      (status.isDraft && missingForSubmit.isNotEmpty) ||
      canConfirmOrDispute ||
      threadsAwaitingClient.isNotEmpty;

  /// The thread whose pending offer is waiting on the **client**, if any.
  ///
  /// Whose turn it is comes from the pending offer's actor, never from the
  /// request status.
  Iterable<RequestOfferThread> get threadsAwaitingClient =>
      threads.where((thread) => thread.isAwaitingClient);

  /// Returns a copy with the given fields replaced.
  ClientRequest copyWith({
    ClientRequestStatus? status,
    String? serviceId,
    String? serviceName,
    double? lat,
    double? lng,
    String? addressLine,
    DateTime? preferredAt,
    String? note,
    List<RequestAttachment>? attachments,
  }) => ClientRequest(
    id: id,
    status: status ?? this.status,
    createdAt: createdAt,
    serviceId: serviceId ?? this.serviceId,
    serviceName: serviceName ?? this.serviceName,
    categoryId: categoryId,
    categoryName: categoryName,
    lat: lat ?? this.lat,
    lng: lng ?? this.lng,
    addressLine: addressLine ?? this.addressLine,
    areaName: areaName,
    preferredAt: preferredAt ?? this.preferredAt,
    note: note ?? this.note,
    attachments: attachments ?? this.attachments,
    submittedAt: submittedAt,
    expiresAt: expiresAt,
    scheduledAt: scheduledAt,
    disputeReason: disputeReason,
    cancelReason: cancelReason,
    offerCount: offerCount,
    matchedBranches: matchedBranches,
    threads: threads,
  );

  @override
  List<Object?> get props => [
    id,
    status,
    createdAt,
    serviceId,
    serviceName,
    categoryId,
    categoryName,
    lat,
    lng,
    addressLine,
    areaName,
    preferredAt,
    note,
    attachments,
    submittedAt,
    expiresAt,
    scheduledAt,
    disputeReason,
    cancelReason,
    offerCount,
    matchedBranches,
    threads,
  ];
}
