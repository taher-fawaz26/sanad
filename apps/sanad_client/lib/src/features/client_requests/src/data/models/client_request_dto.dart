import 'package:requests_core/requests_core.dart';
import 'package:sanad_client/src/features/client_requests/src/domain/entities/client_request.dart';
import 'package:sanad_client/src/features/client_requests/src/domain/entities/matched_branch.dart';
import 'package:sanad_client/src/features/client_requests/src/domain/entities/request_offer.dart';
import 'package:sanad_client/src/features/client_requests/src/domain/entities/request_offer_thread.dart';

/// `ClientRequestResponseDto` — the wire shape every client request endpoint
/// answers with, including the mutations.
///
/// Timestamps and enums are kept as raw strings here and converted by
/// `toEntity`, so a single malformed value degrades one field instead of
/// failing the whole response.
///
/// **Nullability is the point of this class.** Every field the contract marks
/// nullable is nullable here, because a draft is meant to be saveable
/// half-finished: `serviceId`, `serviceName`, `categoryId`, `categoryName`, the
/// location fields and every timestamp but `createdAt` are absent until the
/// client fills them in. Treating any of them as required would make the app
/// unable to read back a draft it had just created.
class ClientRequestDto {
  /// Creates a DTO. Used by `fromJson` and by tests.
  const ClientRequestDto({
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

  /// Reads the server payload. Absent or wrongly-typed collections become
  /// empty lists rather than throwing.
  factory ClientRequestDto.fromJson(Map<String, dynamic> json) =>
      ClientRequestDto(
        id: json['id'] as String? ?? '',
        status: json['status'] as String?,
        createdAt: json['createdAt'] as String?,
        serviceId: json['serviceId'] as String?,
        serviceName: json['serviceName'] as String?,
        categoryId: json['categoryId'] as String?,
        categoryName: json['categoryName'] as String?,
        lat: (json['lat'] as num?)?.toDouble(),
        lng: (json['lng'] as num?)?.toDouble(),
        addressLine: json['addressLine'] as String?,
        areaName: json['areaName'] as String?,
        preferredAt: json['preferredAt'] as String?,
        note: json['note'] as String?,
        attachments: parseList(json['attachments'], RequestAttachment.fromJson),
        submittedAt: json['submittedAt'] as String?,
        expiresAt: json['expiresAt'] as String?,
        scheduledAt: json['scheduledAt'] as String?,
        disputeReason: json['disputeReason'] as String?,
        cancelReason: json['cancelReason'] as String?,
        offerCount: (json['offerCount'] as num?)?.toInt() ?? 0,
        matchedBranches: parseList(
          json['matchedBranches'],
          MatchedProviderDto.fromJson,
        ),
        threads: parseList(json['threads'], RequestOfferThreadDto.fromJson),
      );

  /// Server-assigned request id.
  final String id;

  /// Raw lifecycle status. Resolved to [ClientRequestStatus] in [toEntity].
  final String? status;

  /// ISO-8601 creation instant.
  final String? createdAt;

  /// Catalogue service id. Null on a draft that has not picked one yet.
  final String? serviceId;

  /// Service display name, localized server-side from `x-lang`.
  final String? serviceName;

  /// Category id of [serviceId], when the server resolves one.
  final String? categoryId;

  /// Category display name, localized server-side.
  final String? categoryName;

  /// Latitude of the job location. Null until the client picks a place.
  final double? lat;

  /// Longitude of the job location. Null until the client picks a place.
  final double? lng;

  /// Free-text street address the client entered.
  final String? addressLine;

  /// Coarse area label (e.g. "Al Barsha 1"). This — not [addressLine] — is
  /// what a matched provider sees before it wins the booking.
  final String? areaName;

  /// Requested start instant, ISO-8601.
  final String? preferredAt;

  /// The client's description of the job.
  final String? note;

  /// Images and PDFs attached to the request.
  final List<RequestAttachment> attachments;

  /// When the draft went live. Null while it is still a draft.
  final String? submittedAt;

  /// When an unanswered submitted request expires. Set by the server at submit
  /// time — never computed on the device.
  final String? expiresAt;

  /// The booked start, set when an offer is accepted.
  final String? scheduledAt;

  /// Why the client said the work was not done. Set only on a dispute.
  final String? disputeReason;

  /// Why the request was called off, from whichever side cancelled.
  final String? cancelReason;

  /// How many live offers the request has. Derived server-side.
  final int offerCount;

  /// Branches matched at submit time. Frozen — matching runs once.
  final List<MatchedProviderDto> matchedBranches;

  /// One negotiation thread per provider.
  final List<RequestOfferThreadDto> threads;

  /// Serializes back to the wire shape. Exists for round-trip tests; the app
  /// never POSTs this shape (see `SaveClientRequestRequest`).
  Map<String, dynamic> toJson() => {
    'id': id,
    'status': status,
    'serviceId': serviceId,
    'serviceName': serviceName,
    'categoryId': categoryId,
    'categoryName': categoryName,
    'lat': lat,
    'lng': lng,
    'addressLine': addressLine,
    'areaName': areaName,
    'preferredAt': preferredAt,
    'note': note,
    'attachments': attachments.map((e) => e.toJson()).toList(),
    'submittedAt': submittedAt,
    'expiresAt': expiresAt,
    'scheduledAt': scheduledAt,
    'disputeReason': disputeReason,
    'cancelReason': cancelReason,
    'offerCount': offerCount,
    'matchedBranches': matchedBranches.map((e) => e.toJson()).toList(),
    'threads': threads.map((e) => e.toJson()).toList(),
    'createdAt': createdAt,
  };

  /// Converts to the domain entity, resolving enums and timestamps.
  ClientRequest toEntity() => ClientRequest(
    id: id,
    status: ClientRequestStatus.fromApi(status),
    // A request always has a creation time; the epoch keeps a malformed one
    // sortable rather than dropping the whole row.
    createdAt:
        ApiDateTime.decode(createdAt) ?? DateTime.fromMillisecondsSinceEpoch(0),
    serviceId: serviceId,
    serviceName: serviceName,
    categoryId: categoryId,
    categoryName: categoryName,
    lat: lat,
    lng: lng,
    addressLine: addressLine,
    areaName: areaName,
    preferredAt: ApiDateTime.decode(preferredAt),
    note: note,
    attachments: attachments,
    submittedAt: ApiDateTime.decode(submittedAt),
    expiresAt: ApiDateTime.decode(expiresAt),
    scheduledAt: ApiDateTime.decode(scheduledAt),
    disputeReason: disputeReason,
    cancelReason: cancelReason,
    offerCount: offerCount,
    matchedBranches: matchedBranches.map((e) => e.toEntity()).toList(),
    threads: threads.map((e) => e.toEntity()).toList(),
  );
}

/// Parses a JSON array of objects, tolerating an absent or wrongly-typed value.
///
/// Shared by the request DTOs so one malformed collection cannot fail an
/// otherwise-usable response.
List<T> parseList<T>(
  Object? raw,
  T Function(Map<String, dynamic> json) parse,
) => raw is List
    ? raw.whereType<Map<String, dynamic>>().map(parse).toList()
    : const [];

/// `MatchedProviderDto` — one branch the request was matched to.
class MatchedProviderDto {
  /// Creates a DTO.
  const MatchedProviderDto({
    required this.branchId,
    required this.branchName,
    required this.providerId,
    required this.providerName,
    required this.distanceKm,
  });

  /// Reads the server payload.
  factory MatchedProviderDto.fromJson(Map<String, dynamic> json) =>
      MatchedProviderDto(
        branchId: json['branchId'] as String? ?? '',
        branchName: json['branchName'] as String? ?? '',
        providerId: json['providerId'] as String? ?? '',
        providerName: json['providerName'] as String? ?? '',
        distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0,
      );

  /// The matched branch.
  final String branchId;

  /// Branch display name.
  final String branchName;

  /// The company that owns the branch.
  final String providerId;

  /// Provider display name.
  final String providerName;

  /// Straight-line distance captured at match time, not measured live.
  final double distanceKm;

  /// Serializes back to the wire shape.
  Map<String, dynamic> toJson() => {
    'branchId': branchId,
    'branchName': branchName,
    'providerId': providerId,
    'providerName': providerName,
    'distanceKm': distanceKm,
  };

  /// Converts to the domain entity.
  MatchedBranch toEntity() => MatchedBranch(
    branchId: branchId,
    branchName: branchName,
    providerId: providerId,
    providerName: providerName,
    distanceKm: distanceKm,
  );
}

/// `RequestOfferDto` — one node in a negotiation thread.
class RequestOfferDto {
  /// Creates a DTO.
  const RequestOfferDto({
    required this.id,
    required this.actorType,
    required this.status,
    required this.proposedAt,
    required this.createdAt,
    this.note,
    this.parentOfferId,
  });

  /// Reads the server payload.
  factory RequestOfferDto.fromJson(Map<String, dynamic> json) =>
      RequestOfferDto(
        id: json['id'] as String? ?? '',
        actorType: json['actorType'] as String?,
        status: json['status'] as String?,
        proposedAt: json['proposedAt'] as String?,
        createdAt: json['createdAt'] as String?,
        note: json['note'] as String?,
        parentOfferId: json['parentOfferId'] as String?,
      );

  /// Offer id. Required in the URL of every offer action.
  final String id;

  /// Raw `PROVIDER` / `CLIENT`. On the pending node this decides whose turn
  /// it is.
  final String? actorType;

  /// Raw offer state. Note that `LOST` and `REJECTED` are different things.
  final String? status;

  /// Proposed start instant, ISO-8601.
  final String? proposedAt;

  /// When the offer was made.
  final String? createdAt;

  /// Optional message from whoever proposed it.
  final String? note;

  /// The offer this one counters. Null on a thread's root offer.
  final String? parentOfferId;

  /// Serializes back to the wire shape.
  Map<String, dynamic> toJson() => {
    'id': id,
    'actorType': actorType,
    'status': status,
    'proposedAt': proposedAt,
    'note': note,
    'parentOfferId': parentOfferId,
    'createdAt': createdAt,
  };

  /// Converts to the domain entity.
  RequestOffer toEntity() {
    final epoch = DateTime.fromMillisecondsSinceEpoch(0);
    return RequestOffer(
      id: id,
      actorType: RequestOfferActorType.fromApi(actorType),
      status: RequestOfferStatus.fromApi(status),
      proposedAt: ApiDateTime.decode(proposedAt) ?? epoch,
      createdAt: ApiDateTime.decode(createdAt) ?? epoch,
      note: note,
      parentOfferId: parentOfferId,
    );
  }
}

/// `RequestOfferThreadDto` — one provider's whole negotiation.
class RequestOfferThreadDto {
  /// Creates a DTO.
  const RequestOfferThreadDto({
    required this.rootOfferId,
    required this.providerId,
    required this.providerName,
    required this.branchId,
    required this.branchName,
    required this.distanceKm,
    required this.completedJobs,
    required this.offers,
  });

  /// Reads the server payload.
  factory RequestOfferThreadDto.fromJson(Map<String, dynamic> json) =>
      RequestOfferThreadDto(
        rootOfferId: json['rootOfferId'] as String? ?? '',
        providerId: json['providerId'] as String? ?? '',
        providerName: json['providerName'] as String? ?? '',
        branchId: json['branchId'] as String? ?? '',
        branchName: json['branchName'] as String? ?? '',
        distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0,
        completedJobs: (json['completedJobs'] as num?)?.toInt() ?? 0,
        offers: parseList(json['offers'], RequestOfferDto.fromJson),
      );

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

  /// Straight-line distance, frozen at match time.
  final double distanceKm;

  /// Jobs this provider has completed. With no prices in the system, this and
  /// response speed are the only signals a client can choose on.
  final int completedJobs;

  /// Offers oldest-first, as the contract orders them.
  final List<RequestOfferDto> offers;

  /// Serializes back to the wire shape.
  Map<String, dynamic> toJson() => {
    'rootOfferId': rootOfferId,
    'providerId': providerId,
    'providerName': providerName,
    'branchId': branchId,
    'branchName': branchName,
    'distanceKm': distanceKm,
    'completedJobs': completedJobs,
    'offers': offers.map((e) => e.toJson()).toList(),
  };

  /// Converts to the domain entity, preserving the contractual offer order.
  RequestOfferThread toEntity() => RequestOfferThread(
    rootOfferId: rootOfferId,
    providerId: providerId,
    providerName: providerName,
    branchId: branchId,
    branchName: branchName,
    distanceKm: distanceKm,
    completedJobs: completedJobs,
    offers: offers.map((e) => e.toEntity()).toList(),
  );
}
