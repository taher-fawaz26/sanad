import 'package:requests_core/requests_core.dart';
import 'package:sanad_provider/src/features/requests/src/domain/entities/gated_contact.dart';
import 'package:sanad_provider/src/features/requests/src/domain/entities/provider_offer.dart';
import 'package:sanad_provider/src/features/requests/src/domain/entities/provider_request.dart';
import 'package:sanad_provider/src/features/requests/src/domain/entities/provider_request_summary.dart';
import 'package:sanad_provider/src/features/requests/src/domain/enums/provider_request_tab.dart';

/// `ProviderRequestResponseDto` — the provider's view of a client request.
///
/// Distinct from the client app's DTO on purpose: there is no `threads` array
/// (rivals are never visible), no `matchedBranches`, and the location is a
/// single `areaName` until [contact] unlocks.
class ProviderRequestDto {
  /// Creates a DTO.
  const ProviderRequestDto({
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

  /// Reads the server payload.
  factory ProviderRequestDto.fromJson(Map<String, dynamic> json) =>
      ProviderRequestDto(
        id: json['id'] as String? ?? '',
        status: json['status'] as String?,
        tab: json['tab'] as String?,
        serviceName: json['serviceName'] as String? ?? '',
        categoryName: json['categoryName'] as String?,
        areaName: json['areaName'] as String?,
        preferredAt: json['preferredAt'] as String?,
        note: json['note'] as String?,
        attachments: _list(json['attachments'], RequestAttachment.fromJson),
        distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0,
        branchId: json['branchId'] as String?,
        branchName: json['branchName'] as String?,
        myOfferStatus: json['myOfferStatus'] as String?,
        myOffers: _list(json['myOffers'], ProviderOfferDto.fromJson),
        remainingRebids: (json['remainingRebids'] as num?)?.toInt() ?? 0,
        contact: GatedContactDto.fromJson(
          json['contact'] is Map
              ? Map<String, dynamic>.from(json['contact'] as Map)
              : const {},
        ),
        disputeReason: json['disputeReason'] as String?,
        createdAt: json['createdAt'] as String?,
      );

  /// Request id.
  final String id;

  /// Raw lifecycle status.
  final String? status;

  /// Raw workspace tab, computed server-side.
  final String? tab;

  /// Service name, localized server-side.
  final String serviceName;

  /// Category name, localized server-side.
  final String? categoryName;

  /// One coarse area — the only location detail before unlock.
  final String? areaName;

  /// Requested start, ISO-8601.
  final String? preferredAt;

  /// The client's description of the job.
  final String? note;

  /// Photos and documents the client attached.
  final List<RequestAttachment> attachments;

  /// Distance from the offering (or nearest matched) branch.
  final double distanceKm;

  /// The branch on this provider's offer.
  final String? branchId;

  /// That branch's name.
  final String? branchName;

  /// Raw status of this provider's own thread. Null before they bid.
  final String? myOfferStatus;

  /// This provider's own offers only.
  final List<ProviderOfferDto> myOffers;

  /// Offers this provider may still make on this request.
  final int remainingRebids;

  /// The gated contact block.
  final GatedContactDto contact;

  /// Why the client says the work was not done.
  final String? disputeReason;

  /// Creation instant, ISO-8601.
  final String? createdAt;

  /// Serializes back to the wire shape.
  Map<String, dynamic> toJson() => {
    'id': id,
    'status': status,
    'tab': tab,
    'serviceName': serviceName,
    'categoryName': categoryName,
    'areaName': areaName,
    'preferredAt': preferredAt,
    'note': note,
    'attachments': attachments.map((e) => e.toJson()).toList(),
    'distanceKm': distanceKm,
    'branchId': branchId,
    'branchName': branchName,
    'myOfferStatus': myOfferStatus,
    'myOffers': myOffers.map((e) => e.toJson()).toList(),
    'remainingRebids': remainingRebids,
    'contact': contact.toJson(),
    'disputeReason': disputeReason,
    'createdAt': createdAt,
  };

  /// Converts to the domain entity.
  ProviderRequest toEntity() => ProviderRequest(
    id: id,
    status: ClientRequestStatus.fromApi(status),
    tab: ProviderRequestTab.fromApi(tab),
    serviceName: serviceName,
    categoryName: categoryName,
    areaName: areaName,
    preferredAt: ApiDateTime.decode(preferredAt),
    note: note,
    attachments: attachments,
    distanceKm: distanceKm,
    branchId: branchId,
    branchName: branchName,
    // Null, not `unknown`: "has not bid yet" is a real state and must stay
    // distinguishable from "sent a value this build cannot parse".
    myOfferStatus: myOfferStatus == null
        ? null
        : RequestOfferStatus.fromApi(myOfferStatus),
    myOffers: myOffers.map((e) => e.toEntity()).toList(),
    remainingRebids: remainingRebids,
    contact: contact.toEntity(),
    disputeReason: disputeReason,
    createdAt:
        ApiDateTime.decode(createdAt) ?? DateTime.fromMillisecondsSinceEpoch(0),
  );

  static List<T> _list<T>(
    Object? raw,
    T Function(Map<String, dynamic> json) parse,
  ) => raw is List
      ? raw.whereType<Map<String, dynamic>>().map(parse).toList()
      : const [];
}

/// `GatedContactDto`.
///
/// Only `unlocked` is required by the contract; every other field is `null`
/// while it is `false`. [toEntity] does **not** blank them defensively — the
/// server already withholds them, and pretending otherwise would hide a
/// contract regression rather than surface it.
class GatedContactDto {
  /// Creates a DTO.
  const GatedContactDto({
    required this.unlocked,
    this.clientName,
    this.clientPhone,
    this.addressLine,
    this.lat,
    this.lng,
  });

  /// Reads the server payload. A missing block reads as locked, which is the
  /// safe default: fail closed on an ambiguity.
  factory GatedContactDto.fromJson(Map<String, dynamic> json) =>
      GatedContactDto(
        unlocked: json['unlocked'] as bool? ?? false,
        clientName: json['clientName'] as String?,
        clientPhone: json['clientPhone'] as String?,
        addressLine: json['addressLine'] as String?,
        lat: (json['lat'] as num?)?.toDouble(),
        lng: (json['lng'] as num?)?.toDouble(),
      );

  /// True once this provider's offer was accepted.
  final bool unlocked;

  /// The client's name.
  final String? clientName;

  /// The client's phone.
  final String? clientPhone;

  /// The street address.
  final String? addressLine;

  /// Exact latitude.
  final double? lat;

  /// Exact longitude.
  final double? lng;

  /// Serializes back to the wire shape.
  Map<String, dynamic> toJson() => {
    'unlocked': unlocked,
    'clientName': clientName,
    'clientPhone': clientPhone,
    'addressLine': addressLine,
    'lat': lat,
    'lng': lng,
  };

  /// Converts to the domain entity.
  GatedContact toEntity() => GatedContact(
    isUnlocked: unlocked,
    clientName: clientName,
    clientPhone: clientPhone,
    addressLine: addressLine,
    lat: lat,
    lng: lng,
  );
}

/// `RequestOfferDto`, as it appears inside `myOffers`.
class ProviderOfferDto {
  /// Creates a DTO.
  const ProviderOfferDto({
    required this.id,
    required this.actorType,
    required this.status,
    required this.proposedAt,
    required this.createdAt,
    this.note,
    this.parentOfferId,
  });

  /// Reads the server payload.
  factory ProviderOfferDto.fromJson(Map<String, dynamic> json) =>
      ProviderOfferDto(
        id: json['id'] as String? ?? '',
        actorType: json['actorType'] as String?,
        status: json['status'] as String?,
        proposedAt: json['proposedAt'] as String?,
        createdAt: json['createdAt'] as String?,
        note: json['note'] as String?,
        parentOfferId: json['parentOfferId'] as String?,
      );

  /// Offer id.
  final String id;

  /// Raw `PROVIDER` / `CLIENT`.
  final String? actorType;

  /// Raw offer state.
  final String? status;

  /// Proposed start, ISO-8601.
  final String? proposedAt;

  /// Creation instant, ISO-8601.
  final String? createdAt;

  /// Optional message.
  final String? note;

  /// The offer this one counters.
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
  ProviderOffer toEntity() {
    final epoch = DateTime.fromMillisecondsSinceEpoch(0);
    return ProviderOffer(
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

/// `ProviderRequestCountsDto` — one number per workspace tab.
class ProviderRequestCountsDto {
  /// Creates a DTO.
  const ProviderRequestCountsDto(this.byTab);

  /// Reads the server payload, keyed by the tab's wire value.
  factory ProviderRequestCountsDto.fromJson(Map<String, dynamic> json) =>
      ProviderRequestCountsDto({
        for (final entry in json.entries)
          if (entry.value is num) entry.key: (entry.value as num).toInt(),
      });

  /// Raw counts, keyed by wire tab name.
  final Map<String, int> byTab;

  /// Serializes back to the wire shape.
  Map<String, dynamic> toJson() => {...byTab};

  /// Converts to the domain entity, dropping any tab this build cannot map.
  ProviderRequestCounts toEntity() => ProviderRequestCounts(
    byTab: {
      for (final entry in byTab.entries)
        if (ProviderRequestTab.fromApi(entry.key) case final tab
            when tab != ProviderRequestTab.unknown)
          tab: entry.value,
    },
  );
}

/// `ProviderRequestStatsDto`.
class ProviderRequestStatsDto {
  /// Creates a DTO.
  const ProviderRequestStatsDto({
    required this.needsYourOffer,
    required this.awaitingClient,
    required this.scheduledToday,
    required this.completedThisMonth,
  });

  /// Reads the server payload.
  factory ProviderRequestStatsDto.fromJson(Map<String, dynamic> json) =>
      ProviderRequestStatsDto(
        needsYourOffer: (json['needsYourOffer'] as num?)?.toInt() ?? 0,
        awaitingClient: (json['awaitingClient'] as num?)?.toInt() ?? 0,
        scheduledToday: (json['scheduledToday'] as num?)?.toInt() ?? 0,
        completedThisMonth: (json['completedThisMonth'] as num?)?.toInt() ?? 0,
      );

  /// Matched requests with no offer yet.
  final int needsYourOffer;

  /// Offers awaiting a client reply.
  final int awaitingClient;

  /// Bookings starting today.
  final int scheduledToday;

  /// Jobs completed this month.
  final int completedThisMonth;

  /// Serializes back to the wire shape.
  Map<String, dynamic> toJson() => {
    'needsYourOffer': needsYourOffer,
    'awaitingClient': awaitingClient,
    'scheduledToday': scheduledToday,
    'completedThisMonth': completedThisMonth,
  };

  /// Converts to the domain entity.
  ProviderRequestStats toEntity() => ProviderRequestStats(
    needsYourOffer: needsYourOffer,
    awaitingClient: awaitingClient,
    scheduledToday: scheduledToday,
    completedThisMonth: completedThisMonth,
  );
}
