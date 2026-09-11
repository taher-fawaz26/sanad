part of 'package:ai_ui_protocol/src/domain/ai_ui_node.dart';

/// The twenty-three business components — one per component the Figma library
/// publishes for the client AI surface.
///
/// Each names a concept the assistant is communicating and carries the data
/// that concept needs; none describes a layout. See `primitive_nodes.dart`
/// for why these are a `part`.
// ─── Semantic, client domain ────────────────────────────────────────────────

final class AiUiServiceCardNode extends AiUiNode {
  const AiUiServiceCardNode({
    required super.id,
    required this.serviceId,
    required this.title,
    this.subtitle,
    this.price,
    this.ratingValue,
    this.image,
    this.badge,
    this.action,
    this.selected = false,
    this.actions = const [],
    super.a11yLabel,
    super.fallbackText,
  });

  final String serviceId;
  final String title;
  final String? subtitle;
  final AiUiMoney? price;
  final double? ratingValue;
  final AiUiImageSource? image;
  final AiUiBadge? badge;
  final AiUiAction? action;

  /// Marks this card as the one the conversation is currently about, drawn
  /// with an accent border. Presentation only — selecting is the user's job,
  /// through an action, not something the agent toggles mid-list.
  final bool selected;

  /// Buttons drawn inside this card. See [AiUiCardAction].
  final List<AiUiCardAction> actions;

  @override
  AiUiNodeType get type => AiUiNodeType.serviceCard;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    ...baseJson(AiUiNodeType.serviceCard.wire),
    'serviceId': serviceId,
    'title': title,
    if (subtitle != null) 'subtitle': subtitle,
    if (price != null) 'price': price!.toJson(),
    if (ratingValue != null) 'ratingValue': ratingValue,
    if (image != null) 'image': image!.toJson(),
    if (badge != null) 'badge': badge!.toJson(),
    if (action != null) 'action': action!.toJson(),
    if (selected) 'selected': true,
    if (actions.isNotEmpty)
      'actions': [for (final entry in actions) entry.toJson()],
  };

  @override
  List<Object?> get props => [
    ...baseProps,
    serviceId,
    title,
    subtitle,
    price,
    ratingValue,
    image,
    badge,
    action,
    selected,
    actions,
  ];
}

final class AiUiAppointmentCardNode extends AiUiNode {
  const AiUiAppointmentCardNode({
    required super.id,
    required this.appointmentId,
    required this.title,
    required this.startsAt,
    this.whereText,
    this.status,
    this.statusTone = AiUiTone.neutral,
    this.action,
    this.actions = const [],
    super.a11yLabel,
    super.fallbackText,
  });

  final String appointmentId;
  final String title;

  /// Always UTC. The renderer converts to device time and formats with the
  /// repo's 12-hour `DateFormat('h:mm a')` convention — the agent never
  /// formats a date.
  final DateTime startsAt;
  final String? whereText;
  final String? status;
  final AiUiTone statusTone;
  final AiUiAction? action;

  /// Buttons drawn inside this card. See [AiUiCardAction].
  final List<AiUiCardAction> actions;

  @override
  AiUiNodeType get type => AiUiNodeType.appointmentCard;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    ...baseJson(AiUiNodeType.appointmentCard.wire),
    'appointmentId': appointmentId,
    'title': title,
    'startsAt': startsAt.toUtc().toIso8601String(),
    if (whereText != null) 'whereText': whereText,
    if (status != null) 'status': status,
    'statusTone': statusTone.wire,
    if (action != null) 'action': action!.toJson(),
    if (actions.isNotEmpty)
      'actions': [for (final entry in actions) entry.toJson()],
  };

  @override
  List<Object?> get props => [
    ...baseProps,
    appointmentId,
    title,
    startsAt,
    whereText,
    status,
    statusTone,
    action,
    actions,
  ];
}

final class AiUiBranchCardNode extends AiUiNode {
  const AiUiBranchCardNode({
    required super.id,
    required this.branchId,
    required this.name,
    this.addressText,
    this.distanceMeters,
    this.status,
    this.statusTone = AiUiTone.neutral,
    this.hoursText,
    this.action,
    this.actions = const [],
    super.a11yLabel,
    super.fallbackText,
  });

  final String branchId;
  final String name;
  final String? addressText;

  /// Structured, in metres. The renderer formats it locale-aware.
  final num? distanceMeters;
  final String? status;
  final AiUiTone statusTone;
  final AiUiAction? action;

  /// Opening-hours prose the agent has already localized — "Closes 9:00 PM",
  /// "Opens tomorrow 8:00 AM". Sits opposite the distance on its own row.
  ///
  /// Prose rather than a structured instant on purpose: what the reader needs
  /// is a *relative* phrase ("opens tomorrow"), and which day that resolves to
  /// depends on the branch's own calendar, which the agent has and the client
  /// does not.
  final String? hoursText;

  /// Buttons drawn inside this card. See [AiUiCardAction].
  final List<AiUiCardAction> actions;

  @override
  AiUiNodeType get type => AiUiNodeType.branchCard;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    ...baseJson(AiUiNodeType.branchCard.wire),
    'branchId': branchId,
    'name': name,
    if (addressText != null) 'addressText': addressText,
    if (distanceMeters != null) 'distanceMeters': distanceMeters,
    if (status != null) 'status': status,
    'statusTone': statusTone.wire,
    if (hoursText != null) 'hoursText': hoursText,
    if (action != null) 'action': action!.toJson(),
    if (actions.isNotEmpty)
      'actions': [for (final entry in actions) entry.toJson()],
  };

  @override
  List<Object?> get props => [
    ...baseProps,
    branchId,
    name,
    addressText,
    distanceMeters,
    status,
    statusTone,
    hoursText,
    action,
    actions,
  ];
}

final class AiUiDocumentCardNode extends AiUiNode {
  const AiUiDocumentCardNode({
    required super.id,
    required this.documentId,
    required this.title,
    required this.status,
    this.statusTone = AiUiTone.neutral,
    this.action,
    this.actions = const [],
    super.a11yLabel,
    super.fallbackText,
  });

  final String documentId;
  final String title;
  final String status;
  final AiUiTone statusTone;
  final AiUiAction? action;

  /// Buttons drawn inside this card. See [AiUiCardAction].
  final List<AiUiCardAction> actions;

  @override
  AiUiNodeType get type => AiUiNodeType.documentCard;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    ...baseJson(AiUiNodeType.documentCard.wire),
    'documentId': documentId,
    'title': title,
    'status': status,
    'statusTone': statusTone.wire,
    if (action != null) 'action': action!.toJson(),
    if (actions.isNotEmpty)
      'actions': [for (final entry in actions) entry.toJson()],
  };

  @override
  List<Object?> get props => [
    ...baseProps,
    documentId,
    title,
    status,
    statusTone,
    action,
    actions,
  ];
}

final class AiUiQuickReplyNode extends AiUiNode {
  const AiUiQuickReplyNode({
    required super.id,
    required this.options,
    super.a11yLabel,
    super.fallbackText,
  });

  final List<AiUiQuickReplyOption> options;

  @override
  AiUiNodeType get type => AiUiNodeType.quickReply;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    ...baseJson(AiUiNodeType.quickReply.wire),
    'options': options.map((o) => o.toJson()).toList(),
  };

  @override
  List<Object?> get props => [...baseProps, options];
}

// ─── Entity cards ───────────────────────────────────────────────────────────

/// One order in the user's tracking list — Figma `order-card`.
///
/// Distinct from [AiUiAppointmentCardNode] because an order is money that has
/// already moved and has no instant attached, where an appointment is a time
/// and a place. Several stacked `order_card` blocks are what Figma calls the
/// "order tracking dashboard" — there is no separate list type, because a list
/// of one still has to look right.
final class AiUiOrderCardNode extends AiUiNode {
  const AiUiOrderCardNode({
    required super.id,
    required this.orderId,
    required this.title,
    this.statusText,
    this.status,
    this.statusTone = AiUiTone.neutral,
    this.amount,
    this.action,
    this.actions = const [],
    super.a11yLabel,
    super.fallbackText,
  });

  final String orderId;

  /// The order's own reference as the user recognises it — "Order #1042".
  final String title;

  /// Fulfilment prose on the amount row — "Delivered", "In progress".
  final String? statusText;

  /// The badge beside the title. Independent of [statusText]: Figma shows a
  /// badge only on the *active* order, while both rows carry status prose.
  final String? status;
  final AiUiTone statusTone;
  final AiUiMoney? amount;
  final AiUiAction? action;

  /// Buttons drawn inside this card. See [AiUiCardAction].
  final List<AiUiCardAction> actions;

  @override
  AiUiNodeType get type => AiUiNodeType.orderCard;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    ...baseJson(AiUiNodeType.orderCard.wire),
    'orderId': orderId,
    'title': title,
    if (statusText != null) 'statusText': statusText,
    if (status != null) 'status': status,
    'statusTone': statusTone.wire,
    if (amount != null) 'amount': amount!.toJson(),
    if (action != null) 'action': action!.toJson(),
    if (actions.isNotEmpty)
      'actions': [for (final entry in actions) entry.toJson()],
  };

  @override
  List<Object?> get props => [
    ...baseProps,
    orderId,
    title,
    statusText,
    status,
    statusTone,
    amount,
    action,
    actions,
  ];
}

/// The person or company assigned to a request, or offering to take one —
/// Figma `provider-card` and `provider-offer-card`.
///
/// **One type, two presentations.** The compact form is identity plus the one
/// fact the decision turns on (the proposed time) plus the controls; the
/// expanded form adds distance, the provider's own description, the services
/// they offer and their work photos. They are the same provider answering the
/// same question, so splitting them would mean the agent choosing a *component*
/// when what it actually knows is how much detail the conversation needs.
///
/// [presentation] is the agent's opening position, not a lock: the renderer
/// offers a disclosure control whenever there is extra detail to show, because
/// which one the user wants is theirs to decide.
final class AiUiProviderCardNode extends AiUiNode {
  const AiUiProviderCardNode({
    required super.id,
    required this.providerId,
    required this.name,
    this.roleText,
    this.ratingValue,
    this.image,
    this.stats = const [],
    this.action,
    this.actions = const [],
    this.verified = false,
    this.presentation = AiUiPresentation.compact,
    this.distanceMeters,
    this.description,
    this.services = const [],
    this.servicesLabel,
    this.photos = const [],
    this.proposedTimeLabel,
    this.proposedTime,
    this.offer,
    super.a11yLabel,
    super.fallbackText,
  });

  final String providerId;
  final String name;

  /// What they do — "AC and plumbing specialist".
  final String? roleText;

  /// 0–5, clamped. Rendered as a star plus a locale-formatted number.
  final double? ratingValue;
  final AiUiImageSource? image;

  /// The stats strip under the hairline. Figma shows two; more than four stops
  /// fitting on one row.
  final List<AiUiStat> stats;
  final AiUiAction? action;

  /// Buttons drawn inside this card. See [AiUiCardAction].
  final List<AiUiCardAction> actions;

  /// Whether SANAD has verified the account. The tick beside the name.
  final bool verified;

  /// How much of the card the agent wants shown to begin with.
  final AiUiPresentation presentation;

  /// Structured, in metres — how far the provider is from the job. The
  /// renderer formats it locale-aware, exactly as `branch_card` does.
  final num? distanceMeters;

  /// The provider's own description of what they do. Prose, already localized.
  final String? description;

  /// The services they offer, as short labels — "Interior clean", "Polishing".
  /// Drawn as chips; the protocol has no way to make one tappable, because
  /// choosing a service belongs to the conversation.
  final List<String> services;

  /// Heading above [services] — "Services".
  final String? servicesLabel;

  /// Examples of their work. Backend-owned media, so normally `url`s, through
  /// the same `{url?, assetId?}` contract as every other image.
  final List<AiUiImageSource> photos;

  /// Label for the [proposedTime] row — "Proposed Time".
  final String? proposedTimeLabel;

  /// When the provider is offering to come. Always UTC; the renderer converts
  /// and formats, so the agent never writes "Thursday · 5:00 PM" itself.
  final DateTime? proposedTime;

  /// Present when this card *is an offer* — the accept/decline pair, answered
  /// through an `offer_resolved` interaction. See [AiUiProviderOffer].
  final AiUiProviderOffer? offer;

  @override
  AiUiNodeType get type => AiUiNodeType.providerCard;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    ...baseJson(AiUiNodeType.providerCard.wire),
    'providerId': providerId,
    'name': name,
    if (roleText != null) 'roleText': roleText,
    if (ratingValue != null) 'ratingValue': ratingValue,
    if (image != null) 'image': image!.toJson(),
    if (stats.isNotEmpty) 'stats': [for (final stat in stats) stat.toJson()],
    if (action != null) 'action': action!.toJson(),
    if (actions.isNotEmpty)
      'actions': [for (final entry in actions) entry.toJson()],
    if (verified) 'verified': true,
    'presentation': presentation.wire,
    if (distanceMeters != null) 'distanceMeters': distanceMeters,
    if (description != null) 'description': description,
    if (services.isNotEmpty) 'services': services,
    if (servicesLabel != null) 'servicesLabel': servicesLabel,
    if (photos.isNotEmpty)
      'photos': [for (final photo in photos) photo.toJson()],
    if (proposedTimeLabel != null) 'proposedTimeLabel': proposedTimeLabel,
    if (proposedTime != null)
      'proposedTime': proposedTime!.toUtc().toIso8601String(),
    if (offer != null) 'offer': offer!.toJson(),
  };

  @override
  List<Object?> get props => [
    ...baseProps,
    providerId,
    name,
    roleText,
    ratingValue,
    image,
    stats,
    action,
    actions,
    verified,
    presentation,
    distanceMeters,
    description,
    services,
    servicesLabel,
    photos,
    proposedTimeLabel,
    proposedTime,
    offer,
  ];
}

// ─── Summaries ──────────────────────────────────────────────────────────────

/// A compact set of values the user is asked to confirm — Figma `action-card`.
///
/// Not a `card` full of `text` primitives: the label-and-value grid, the header
/// rule and the attached button pair are one design the app owns, and
/// hand-assembling it from primitives is how a payload ends up looking wrong
/// the next time that design changes.
final class AiUiBookingSummaryNode extends AiUiNode {
  const AiUiBookingSummaryNode({
    required super.id,
    required this.items,
    this.title,
    this.actions = const [],
    this.statusText,
    this.statusTone = AiUiTone.success,
    this.provider,
    super.a11yLabel,
    super.fallbackText,
  });

  final String? title;
  final List<AiUiDetailItem> items;

  /// Buttons drawn inside this card. See [AiUiCardAction].
  final List<AiUiCardAction> actions;

  /// The outcome as a headline — "Booking Confirmed!".
  ///
  /// Its presence is what turns this card from *a set of values to check*
  /// into *a booking that happened*, which is the difference between Figma's
  /// `action-card` and its `booking-confirmed` frame. Deliberately **not** a
  /// separate node type: the fields are the same booking either way, and two
  /// types would mean the agent picking a component rather than stating
  /// whether the thing is done.
  final String? statusText;

  /// Tints the status disc. `success` for a confirmed booking, `warning` for
  /// one still pending, `error` for one that failed.
  final AiUiTone statusTone;

  /// Who is coming. See [AiUiProviderRef].
  final AiUiProviderRef? provider;

  @override
  AiUiNodeType get type => AiUiNodeType.bookingSummary;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    ...baseJson(AiUiNodeType.bookingSummary.wire),
    if (title != null) 'title': title,
    'items': [for (final item in items) item.toJson()],
    if (actions.isNotEmpty)
      'actions': [for (final entry in actions) entry.toJson()],
    if (statusText != null) 'statusText': statusText,
    'statusTone': statusTone.wire,
    if (provider != null) 'provider': provider!.toJson(),
  };

  @override
  List<Object?> get props => [
    ...baseProps,
    title,
    items,
    actions,
    statusText,
    statusTone,
    provider,
  ];
}

/// The full service request read back before it is submitted — Figma
/// `details-card`.
///
/// A superset of [AiUiBookingSummaryNode] in content but a genuinely different
/// component: separately-bordered value tiles, a free-prose recap the agent
/// composed from the conversation, and a maps row. Merging the two would mean
/// one renderer branching on which fields happen to be present.
final class AiUiRequestSummaryNode extends AiUiNode {
  const AiUiRequestSummaryNode({
    required super.id,
    required this.items,
    this.summaryTitle,
    this.summaryText,
    this.location,
    this.actions = const [],
    this.photos = const [],
    this.photosLabel,
    this.confirm,
    super.a11yLabel,
    super.fallbackText,
  });

  final List<AiUiDetailItem> items;

  /// Heading above [summaryText] — "Summary".
  final String? summaryTitle;

  /// The agent's own prose recap of what the user asked for.
  final String? summaryText;
  final AiUiLocationRef? location;

  /// Buttons drawn inside this card. See [AiUiCardAction].
  ///
  /// For the submit/cancel pair prefer [confirm], which answers structurally.
  /// This row stays for the *other* things a summary might offer — "Edit", a
  /// maps link — which are navigation, not an answer.
  final List<AiUiCardAction> actions;

  /// Photos the user attached while describing the request, read back so they
  /// can see what is about to be sent. The usual `{url?, assetId?}` contract.
  final List<AiUiImageSource> photos;

  /// Heading above [photos] — "photos".
  final String? photosLabel;

  /// The submit-or-cancel pair. See [AiUiConfirmChoice].
  ///
  /// When present the card's decision travels as a `confirmation_resolved`
  /// interaction — correlated with this node, recorded in the ledger, and
  /// un-repeatable — rather than as a sentence the agent has to re-read.
  final AiUiConfirmChoice? confirm;

  @override
  AiUiNodeType get type => AiUiNodeType.requestSummary;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    ...baseJson(AiUiNodeType.requestSummary.wire),
    'items': [for (final item in items) item.toJson()],
    if (summaryTitle != null) 'summaryTitle': summaryTitle,
    if (summaryText != null) 'summaryText': summaryText,
    if (location != null) 'location': location!.toJson(),
    if (actions.isNotEmpty)
      'actions': [for (final entry in actions) entry.toJson()],
    if (photos.isNotEmpty)
      'photos': [for (final photo in photos) photo.toJson()],
    if (photosLabel != null) 'photosLabel': photosLabel,
    if (confirm != null) 'confirm': confirm!.toJson(),
  };

  @override
  List<Object?> get props => [
    ...baseProps,
    items,
    summaryTitle,
    summaryText,
    location,
    actions,
    photos,
    photosLabel,
    confirm,
  ];
}

/// A completed payment — Figma `receipt-card`.
final class AiUiPaymentReceiptNode extends AiUiNode {
  const AiUiPaymentReceiptNode({
    required super.id,
    required this.title,
    required this.items,
    this.subtitle,
    this.statusTone = AiUiTone.success,
    this.total,
    this.actions = const [],
    super.a11yLabel,
    super.fallbackText,
  });

  /// The outcome as a headline — "Payment Successful".
  final String title;
  final String? subtitle;

  /// Tints the leading disc. `success` for a completed payment, `warning` for
  /// one still settling, `error` for a failure — the same card either way.
  final AiUiTone statusTone;
  final List<AiUiDetailItem> items;

  /// The emphasised bottom line, below a hairline.
  final AiUiReceiptTotal? total;

  /// Buttons drawn inside this card. See [AiUiCardAction].
  final List<AiUiCardAction> actions;

  @override
  AiUiNodeType get type => AiUiNodeType.paymentReceipt;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    ...baseJson(AiUiNodeType.paymentReceipt.wire),
    'title': title,
    if (subtitle != null) 'subtitle': subtitle,
    'statusTone': statusTone.wire,
    'items': [for (final item in items) item.toJson()],
    if (total != null) 'total': total!.toJson(),
    if (actions.isNotEmpty)
      'actions': [for (final entry in actions) entry.toJson()],
  };

  @override
  List<Object?> get props => [
    ...baseProps,
    title,
    subtitle,
    statusTone,
    items,
    total,
    actions,
  ];
}

// ─── Interactive ────────────────────────────────────────────────────────────

/// A grid of appointment slots the user picks one of — Figma `slots-card`.
///
/// The **selection lives in the widget**, not in the payload: the agent offers
/// slots, the user chooses, and confirming posts [confirmTemplate] with
/// `{slot}` replaced by the chosen slot's label. That keeps the same trust
/// model as `quick_reply` — the result reaches the agent as an ordinary user
/// turn, and nothing the user does can send text the agent did not author.
final class AiUiTimeSlotsNode extends AiUiNode {
  const AiUiTimeSlotsNode({
    required super.id,
    required this.slots,
    required this.confirmLabel,
    required this.confirmTemplate,
    this.dateLabel,
    this.selectedSlotId,
    super.a11yLabel,
    super.fallbackText,
  });

  /// The day these slots belong to — "Tomorrow, September 3rd".
  final String? dateLabel;
  final List<AiUiTimeSlot> slots;

  /// Pre-selects a slot. An id matching no slot selects nothing.
  final String? selectedSlotId;
  final String confirmLabel;

  /// Posted as a user turn on confirm, with `{slot}` replaced by the selected
  /// slot's label. No placeholder means the template is sent verbatim.
  final String confirmTemplate;

  @override
  AiUiNodeType get type => AiUiNodeType.timeSlots;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    ...baseJson(AiUiNodeType.timeSlots.wire),
    if (dateLabel != null) 'dateLabel': dateLabel,
    'slots': [for (final slot in slots) slot.toJson()],
    if (selectedSlotId != null) 'selectedSlotId': selectedSlotId,
    'confirmLabel': confirmLabel,
    'confirmTemplate': confirmTemplate,
  };

  @override
  List<Object?> get props => [
    ...baseProps,
    dateLabel,
    slots,
    selectedSlotId,
    confirmLabel,
    confirmTemplate,
  ];
}

/// An invitation to review a finished service — Figma `review-card`.
///
/// The comment field is client-owned, exactly as [AiUiTimeSlotsNode]'s
/// selection is: submitting posts [submitTemplate] with `{comment}` replaced
/// by what the user typed. An empty comment substitutes an empty string, so
/// "submit without commenting" is expressible by the template alone.
final class AiUiReviewRequestNode extends AiUiNode {
  const AiUiReviewRequestNode({
    required super.id,
    required this.serviceName,
    required this.submitLabel,
    required this.submitTemplate,
    this.providerText,
    this.commentPlaceholder,
    this.maxCommentLength,
    this.maxRating,
    this.ratingRequired = false,
    super.a11yLabel,
    super.fallbackText,
  });

  final String serviceName;

  /// Who performed it — "Provided by CleanCo Marina".
  final String? providerText;
  final String? commentPlaceholder;

  /// Caps the comment. Clamped to the protocol's own ceiling, so the agent can
  /// ask for less than the limit but never more.
  final int? maxCommentLength;
  final String submitLabel;

  /// Posted as a user turn on submit, with `{comment}` replaced by the typed
  /// text and `{rating}` by the chosen number of stars.
  final String submitTemplate;

  /// How many stars the card offers. `null` means **no rating control at
  /// all** — the comment-only card the protocol has always had.
  ///
  /// A count rather than a boolean because the scale is a product decision
  /// the backend owns, and a card that draws five stars while the backend
  /// stores ten would silently discard half the range.
  final int? maxRating;

  /// Whether submitting requires a rating. Only meaningful with [maxRating].
  ///
  /// Defaults to `false`: an agent that adds stars to an existing card should
  /// not thereby make the submit button unreachable for a user who only wants
  /// to leave words.
  final bool ratingRequired;

  @override
  AiUiNodeType get type => AiUiNodeType.reviewRequest;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    ...baseJson(AiUiNodeType.reviewRequest.wire),
    'serviceName': serviceName,
    if (providerText != null) 'providerText': providerText,
    if (commentPlaceholder != null) 'commentPlaceholder': commentPlaceholder,
    if (maxCommentLength != null) 'maxCommentLength': maxCommentLength,
    if (maxRating != null) 'maxRating': maxRating,
    if (ratingRequired) 'ratingRequired': true,
    'submitLabel': submitLabel,
    'submitTemplate': submitTemplate,
  };

  @override
  List<Object?> get props => [
    ...baseProps,
    serviceName,
    providerText,
    commentPlaceholder,
    maxCommentLength,
    maxRating,
    ratingRequired,
    submitLabel,
    submitTemplate,
  ];
}

/// A place chooser — Figma `Choose Location`.
///
/// Offers the device's current location (through `request_location_share`,
/// which the app owns) alongside the user's saved places. Confirming a saved
/// place posts [confirmTemplate] with `{location}` replaced by its name.
///
/// The search field is presentational in this node: searching places needs a
/// places API the protocol has no business reaching, so the field hands its
/// query to the conversation rather than querying anything itself.
final class AiUiLocationPickerNode extends AiUiNode {
  const AiUiLocationPickerNode({
    required super.id,
    required this.title,
    required this.confirmLabel,
    required this.confirmTemplate,
    this.searchPlaceholder,
    this.useCurrentLabel,
    this.savedLabel,
    this.savedLocations = const [],
    super.a11yLabel,
    super.fallbackText,
  });

  final String title;
  final String? searchPlaceholder;

  /// Label for the "use my current location" row. Omitted means the row is not
  /// offered at all — which is the right payload when the agent already knows
  /// location sharing was declined.
  final String? useCurrentLabel;

  /// Section heading above [savedLocations].
  final String? savedLabel;
  final List<AiUiSavedLocation> savedLocations;
  final String confirmLabel;

  /// Posted as a user turn on confirm, with `{location}` replaced by the
  /// selected place's name.
  final String confirmTemplate;

  @override
  AiUiNodeType get type => AiUiNodeType.locationPicker;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    ...baseJson(AiUiNodeType.locationPicker.wire),
    'title': title,
    if (searchPlaceholder != null) 'searchPlaceholder': searchPlaceholder,
    if (useCurrentLabel != null) 'useCurrentLabel': useCurrentLabel,
    if (savedLabel != null) 'savedLabel': savedLabel,
    if (savedLocations.isNotEmpty)
      'savedLocations': [for (final place in savedLocations) place.toJson()],
    'confirmLabel': confirmLabel,
    'confirmTemplate': confirmTemplate,
  };

  @override
  List<Object?> get props => [
    ...baseProps,
    title,
    searchPlaceholder,
    useCurrentLabel,
    savedLabel,
    savedLocations,
    confirmLabel,
    confirmTemplate,
  ];
}

// ─── Prompts ────────────────────────────────────────────────────────────────

/// A time-sensitive heads-up — Figma `alert-card`.
final class AiUiReminderCardNode extends AiUiNode {
  const AiUiReminderCardNode({
    required super.id,
    required this.title,
    required this.body,
    this.subtitle,
    this.tone = AiUiTone.warning,
    this.actions = const [],
    super.a11yLabel,
    super.fallbackText,
  });

  final String title;

  /// What the reminder is about — "AC Maintenance".
  final String? subtitle;
  final String body;

  /// Tints the leading disc and the card's border. `warning` by default,
  /// because that is what a reminder is; `error` for something already overdue.
  final AiUiTone tone;

  /// Buttons drawn inside this card. See [AiUiCardAction].
  final List<AiUiCardAction> actions;

  @override
  AiUiNodeType get type => AiUiNodeType.reminderCard;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    ...baseJson(AiUiNodeType.reminderCard.wire),
    'title': title,
    if (subtitle != null) 'subtitle': subtitle,
    'body': body,
    'tone': tone.wire,
    if (actions.isNotEmpty)
      'actions': [for (final entry in actions) entry.toJson()],
  };

  @override
  List<Object?> get props => [
    ...baseProps,
    title,
    subtitle,
    body,
    tone,
    actions,
  ];
}

/// An offer of ways to supply a photo or video — Figma `bottom-sheet`.
///
/// Each option carries an [AiUiMediaSource] rather than an action, because the
/// action is always the same one (`request_image_upload`) and the app owns
/// every step after the tap: the permission prompt, the picker, validation and
/// the upload. The agent chooses *which sources to offer*, nothing more.
final class AiUiMediaRequestNode extends AiUiNode {
  const AiUiMediaRequestNode({
    required super.id,
    required this.title,
    required this.options,
    this.body,
    this.cancelLabel,
    this.actions = const [],
    super.a11yLabel,
    super.fallbackText,
  });

  final String title;
  final String? body;
  final List<AiUiMediaOption> options;

  /// Label for the dismiss control. Omitted means no dismiss control — the
  /// conversation itself is then the way out.
  final String? cancelLabel;

  /// Buttons drawn inside this card. See [AiUiCardAction].
  final List<AiUiCardAction> actions;

  @override
  AiUiNodeType get type => AiUiNodeType.mediaRequest;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    ...baseJson(AiUiNodeType.mediaRequest.wire),
    'title': title,
    if (body != null) 'body': body,
    'options': [for (final option in options) option.toJson()],
    if (cancelLabel != null) 'cancelLabel': cancelLabel,
    if (actions.isNotEmpty)
      'actions': [for (final entry in actions) entry.toJson()],
  };

  @override
  List<Object?> get props => [
    ...baseProps,
    title,
    body,
    options,
    cancelLabel,
    actions,
  ];
}

/// A rationale for a device permission the conversation needs next — Figma
/// `camera-access-bottom-sheet` and `Location Permission Request`.
///
/// One type, two variants, because the two Figma frames are the same component
/// with a different [permission] and an optional illustration. The allow
/// control fires `request_permission`; the app owns the platform prompt, so
/// this node cannot grant anything by itself.
final class AiUiPermissionRequestNode extends AiUiNode {
  const AiUiPermissionRequestNode({
    required super.id,
    required this.permission,
    required this.title,
    required this.allowLabel,
    this.body,
    this.image,
    this.denyLabel,
    this.actions = const [],
    super.a11yLabel,
    super.fallbackText,
  });

  final AiUiPermissionKind permission;
  final String title;
  final String? body;

  /// An illustration above the buttons — the map preview on the location
  /// variant. `assetId` only, like every other image in v1.
  final AiUiImageSource? image;
  final String allowLabel;
  final String? denyLabel;

  /// Buttons drawn inside this card. See [AiUiCardAction].
  final List<AiUiCardAction> actions;

  @override
  AiUiNodeType get type => AiUiNodeType.permissionRequest;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    ...baseJson(AiUiNodeType.permissionRequest.wire),
    'permission': permission.wire,
    'title': title,
    if (body != null) 'body': body,
    if (image != null) 'image': image!.toJson(),
    'allowLabel': allowLabel,
    if (denyLabel != null) 'denyLabel': denyLabel,
    if (actions.isNotEmpty)
      'actions': [for (final entry in actions) entry.toJson()],
  };

  @override
  List<Object?> get props => [
    ...baseProps,
    permission,
    title,
    body,
    image,
    allowLabel,
    denyLabel,
    actions,
  ];
}

/// A place read back for confirmation — Figma `Location Confirmation`.
///
/// [addressText] is prose the agent has resolved; the client does not geocode
/// it. The image is a preview only — an app that can draw a live map registers
/// its own renderer over this type rather than the protocol growing coordinates
/// it would then have to validate.
final class AiUiLocationConfirmNode extends AiUiNode {
  const AiUiLocationConfirmNode({
    required super.id,
    required this.title,
    required this.addressText,
    required this.confirmLabel,
    this.image,
    this.changeLabel,
    this.cancelLabel,
    this.actions = const [],
    super.a11yLabel,
    super.fallbackText,
  });

  final String title;
  final AiUiImageSource? image;
  final String addressText;
  final String confirmLabel;

  /// Offers to *re-run the location flow* — the app's own picker. Distinct
  /// from [cancelLabel], which abandons the question entirely.
  final String? changeLabel;

  /// Declines the address without proposing another. Answers as a
  /// `confirmation_resolved` interaction with `confirmed: false`, so the
  /// agent hears "not this one" rather than nothing.
  final String? cancelLabel;

  /// Buttons drawn inside this card. See [AiUiCardAction].
  final List<AiUiCardAction> actions;

  @override
  AiUiNodeType get type => AiUiNodeType.locationConfirm;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    ...baseJson(AiUiNodeType.locationConfirm.wire),
    'title': title,
    if (image != null) 'image': image!.toJson(),
    'addressText': addressText,
    'confirmLabel': confirmLabel,
    if (changeLabel != null) 'changeLabel': changeLabel,
    if (cancelLabel != null) 'cancelLabel': cancelLabel,
    if (actions.isNotEmpty)
      'actions': [for (final entry in actions) entry.toJson()],
  };

  @override
  List<Object?> get props => [
    ...baseProps,
    title,
    image,
    addressText,
    confirmLabel,
    changeLabel,
    cancelLabel,
    actions,
  ];
}

/// A destructive decision read back before it is taken — Figma
/// `cancel-confirmation-card`.
///
/// "Are you sure you want to cancel?" over the thing being cancelled, and two
/// controls where the *affirmative* one is the dangerous one.
///
/// Not a `booking_summary` with two buttons, and not a generic dialog node:
/// what makes this a type of its own is that the answer is a **decision about
/// an existing commitment**, carried back as a `confirmation_resolved`
/// interaction with the agent's own [AiUiConfirmChoice.reference]. A summary
/// says "here is what I am about to do"; this says "here is what I am about
/// to undo". The client also has to stop a second tap, which needs the node
/// in the ledger — something a pair of `send_message` buttons cannot give it.
final class AiUiConfirmPromptNode extends AiUiNode {
  const AiUiConfirmPromptNode({
    required super.id,
    required this.title,
    required this.confirm,
    this.body,
    this.subjectTitle,
    this.subjectSubtitle,
    this.tone = AiUiTone.warning,
    super.a11yLabel,
    super.fallbackText,
  });

  /// The question — "Are you sure you want to cancel?".
  final String title;

  /// Any consequence worth stating before the user answers — "Cancelling
  /// within 2 hours incurs a fee."
  final String? body;

  /// What is being decided about — "AC Maintenance". Drawn in its own tile so
  /// the user can see they are cancelling the right thing.
  final String? subjectTitle;

  /// The identifying detail under it — "Lina M • Tomorrow 10:00 AM". Prose
  /// the agent has already localized, because it is a *sentence about* the
  /// booking rather than a machine-typed instant.
  final String? subjectSubtitle;

  /// Tints the card. `warning` by default; `error` for something irreversible.
  final AiUiTone tone;

  /// The two controls and what each one answers.
  final AiUiConfirmChoice confirm;

  @override
  AiUiNodeType get type => AiUiNodeType.confirmPrompt;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    ...baseJson(AiUiNodeType.confirmPrompt.wire),
    'title': title,
    if (body != null) 'body': body,
    if (subjectTitle != null) 'subjectTitle': subjectTitle,
    if (subjectSubtitle != null) 'subjectSubtitle': subjectSubtitle,
    'tone': tone.wire,
    'confirm': confirm.toJson(),
  };

  @override
  List<Object?> get props => [
    ...baseProps,
    title,
    body,
    subjectTitle,
    subjectSubtitle,
    tone,
    confirm,
  ];
}

/// Something about an **existing request** changed what happens next — Figma
/// `system-context-router-card`.
///
/// One type for the three readings Figma draws from that one component, and
/// the reason is that they are one business fact with three shapes:
///
/// * the user asked for something new while an active request already owns
///   this conversation (the `contextLabel` chip and the saved `draftText`);
/// * the provider cancelled (`status` + `reference`);
/// * the provider has not arrived (`status` + `reference`).
///
/// In each case the agent is saying *this request's state changed, and here
/// are the ways forward*. Splitting it into three node types would make the
/// agent choose a component; a single node lets it state the facts it has and
/// omit the ones it does not.
///
/// **Not a [AiUiReminderCardNode]**, which is a time-sensitive heads-up drawn
/// as a tinted-edge alert and carries no request identity, no reference and no
/// draft. **Not a [AiUiBookingSummaryNode]** either: nothing here is a
/// label-and-value read-back, and forcing "Ahmed K. had to cancel" into a
/// `statusText` would leave the apology with nowhere to go.
///
/// The decision, where there is one, travels through [confirm] — the same
/// `confirmation_resolved` interaction every other yes-or-no in the protocol
/// uses, correlated by [AiUiConfirmChoice.reference] and un-repeatable through
/// the ledger. That is what stops a second tap on "Create replacement request"
/// opening a second request. [actions] stays for the controls that are *not*
/// an answer — "Contact Sanad Support" is a different destination, not a "no".
final class AiUiRequestNoticeNode extends AiUiNode {
  const AiUiRequestNoticeNode({
    required super.id,
    required this.title,
    this.body,
    this.requestId,
    this.reference,
    this.status,
    this.contextLabel,
    this.draftLabel,
    this.draftText,
    this.actions = const [],
    this.confirm,
    super.a11yLabel,
    super.fallbackText,
  });

  /// The headline — "New request detected", "Ahmed K. had to cancel",
  /// "Scheduled arrival: 10:00 AM".
  final String title;

  /// What it means and what follows from it, as prose the agent has already
  /// localized.
  final String? body;

  /// The request this notice is about, as the agent resolves it. Identity
  /// rather than only the printed [reference], so a continuation can name the
  /// same request without matching on display text.
  final String? requestId;

  /// The reference as the user recognises it. Rendered with Unicode bidi
  /// isolates, because a leading hash otherwise reorders to the far end under
  /// Arabic (the SAN-770 bug class).
  final String? reference;

  /// The state as a dot pill — "Booking Cancelled" (`error`), "Provider is
  /// late" (`warning`). Absent for a notice that is not about a status change.
  final AiUiBadge? status;

  /// The "this conversation already belongs to something" chip — "Tied to
  /// Active Request: Plumbing Repair (#SND-4821)".
  ///
  /// Prose the agent composes, because it names the *other* request and only
  /// the agent knows what to call it. [requestId] carries the identity beside
  /// it.
  final String? contextLabel;

  /// Heading on the saved-draft tile — "Draft Saved".
  final String? draftLabel;

  /// What the agent held onto, quoted back — "I also need to book an AC deep
  /// cleaning...".
  ///
  /// Reading the draft back is the whole point of the card in the
  /// already-active-request case: it is what tells the user they will not have
  /// to type it again.
  final String? draftText;

  /// Buttons drawn inside this card, for the controls that are not an answer.
  /// See [AiUiCardAction].
  final List<AiUiCardAction> actions;

  /// The decision the notice is asking for. See [AiUiConfirmChoice].
  final AiUiConfirmChoice? confirm;

  @override
  AiUiNodeType get type => AiUiNodeType.requestNotice;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    ...baseJson(AiUiNodeType.requestNotice.wire),
    'title': title,
    if (body != null) 'body': body,
    if (requestId != null) 'requestId': requestId,
    if (reference != null) 'reference': reference,
    if (status != null) 'status': status!.toJson(),
    if (contextLabel != null) 'contextLabel': contextLabel,
    if (draftLabel != null) 'draftLabel': draftLabel,
    if (draftText != null) 'draftText': draftText,
    if (actions.isNotEmpty)
      'actions': [for (final entry in actions) entry.toJson()],
    if (confirm != null) 'confirm': confirm!.toJson(),
  };

  @override
  List<Object?> get props => [
    ...baseProps,
    title,
    body,
    requestId,
    reference,
    status,
    contextLabel,
    draftLabel,
    draftText,
    actions,
    confirm,
  ];
}

/// The place the conversation is about is outside SANAD's coverage — Figma
/// `location-outside-service-area`.
///
/// **Not a [AiUiLocationConfirmNode].** That node asks "is this the right
/// place?" and its `confirmLabel` is required, because accepting is the whole
/// point of it. Here accepting is *impossible*: the agent is refusing an
/// address, and the only way forward is a different one. Expressing that as a
/// confirmation card with no way to confirm would make an invalid state
/// representable and leave every reader of the payload guessing which fields
/// still applied.
///
/// It reuses the rest of the location architecture rather than introducing a
/// second model: [addressText] is the same already-localized prose every other
/// location-bearing node carries, and [changeLabel] runs the app's own
/// location flow through the existing `request_location_share` action — so the
/// app owns the permission prompt, the picker and the lookup exactly as it
/// does for `location_confirm`'s own "Change location".
final class AiUiServiceAreaNoticeNode extends AiUiNode {
  const AiUiServiceAreaNoticeNode({
    required super.id,
    required this.title,
    required this.addressText,
    this.body,
    this.tone = AiUiTone.warning,
    this.changeLabel,
    this.actions = const [],
    super.a11yLabel,
    super.fallbackText,
  });

  /// The banner headline — "Location outside service area".
  final String title;

  /// The address that was refused, as the agent localized it. Shown verbatim
  /// in its own tile so the user can see *which* address is the problem.
  final String addressText;

  /// Why, in the agent's own words — "This address is currently outside our
  /// service area:".
  final String? body;

  /// Tints the banner. `warning` by default; `error` where coverage is not
  /// merely absent but the request cannot proceed at all.
  final AiUiTone tone;

  /// Label for the control that re-runs the app's location flow — "Change
  /// Location". Omitted means the card states the problem and the
  /// conversation is the way out.
  final String? changeLabel;

  /// Buttons drawn inside this card. See [AiUiCardAction].
  final List<AiUiCardAction> actions;

  @override
  AiUiNodeType get type => AiUiNodeType.serviceAreaNotice;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    ...baseJson(AiUiNodeType.serviceAreaNotice.wire),
    'title': title,
    'addressText': addressText,
    if (body != null) 'body': body,
    'tone': tone.wire,
    if (changeLabel != null) 'changeLabel': changeLabel,
    if (actions.isNotEmpty)
      'actions': [for (final entry in actions) entry.toJson()],
  };

  @override
  List<Object?> get props => [
    ...baseProps,
    title,
    addressText,
    body,
    tone,
    changeLabel,
    actions,
  ];
}

// ─── Status ─────────────────────────────────────────────────────────────────

/// The assistant is looking for providers — Figma `searching-providers-card`.
///
/// A semantic node rather than a `loading` primitive with a label, because the
/// agent uses it to say something specific: *a provider search is running for
/// this request*, and the conversation should expect offers next. A bare
/// `loading` says only "something is happening", which the client cannot
/// reason about and the user cannot distinguish from the reply still
/// streaming.
///
/// It is still built from the loading/progress primitives' own vocabulary —
/// [progress] is `null` for indeterminate exactly as `progress.value` is — so
/// there is one idea of "how far along" rather than two.
final class AiUiProviderSearchNode extends AiUiNode {
  const AiUiProviderSearchNode({
    required super.id,
    required this.title,
    this.state = AiUiProviderSearchState.searching,
    this.statusLabel,
    this.body,
    this.progress,
    this.actions = const [],
    this.confirm,
    super.a11yLabel,
    super.fallbackText,
  });

  /// Whether the search is still running or finished with nothing.
  ///
  /// The state a search is *in*, not a second component: Figma draws
  /// "Searching nearby providers" and "No Specialists Available" as the same
  /// `LoadingCard`, and an agent choosing between two node types for one
  /// search would have to decide which component the client should draw
  /// rather than simply stating what happened. See [AiUiProviderSearchState].
  final AiUiProviderSearchState state;

  /// The pill above the headline — "Finding providers...".
  final String? statusLabel;

  /// The headline — "Searching nearby providers".
  final String title;

  /// What is actually happening — "We're matching your request with available
  /// providers in your area."
  final String? body;

  /// `0.0..1.0` when the backend can say how far along the search is; `null`
  /// for indeterminate, which is the normal case and what Figma's three-dot
  /// indicator draws.
  final double? progress;

  /// Buttons drawn inside this card — a "Cancel search", where the backend
  /// supports one. See [AiUiCardAction].
  final List<AiUiCardAction> actions;

  /// The decision this card is asking for, when it is asking for one — the
  /// "Continue in Background" acknowledgement while a search runs, the
  /// "Change Time Slot or Cancel" either/or once it is [
  /// AiUiProviderSearchState.exhausted]. See [AiUiConfirmChoice].
  ///
  /// Here rather than as two more [actions] entries because both answers are
  /// decisions about *this* search: they travel as a `confirmation_resolved`
  /// interaction carrying the agent's own `reference`, and the ledger stops a
  /// second tap — which matters most for the one control that would otherwise
  /// start a second search.
  final AiUiConfirmChoice? confirm;

  @override
  AiUiNodeType get type => AiUiNodeType.providerSearch;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    ...baseJson(AiUiNodeType.providerSearch.wire),
    if (statusLabel != null) 'statusLabel': statusLabel,
    'title': title,
    'state': state.wire,
    if (body != null) 'body': body,
    if (progress != null) 'progress': progress,
    if (actions.isNotEmpty)
      'actions': [for (final entry in actions) entry.toJson()],
    if (confirm != null) 'confirm': confirm!.toJson(),
  };

  @override
  List<Object?> get props => [
    ...baseProps,
    statusLabel,
    title,
    state,
    body,
    progress,
    actions,
    confirm,
  ];
}

/// Where a job has got to, as an ordered progression — Figma `timeline-card`.
///
/// The lifecycle is [items], each carrying a closed [AiUiTimelineState]
/// alongside its display strings. That is the whole point of the type: an
/// agent that could only send "En Route — 17 Nov, 13:45" as five text nodes
/// would leave the client matching on prose to decide which step is current,
/// and would leave the agent unable to answer "where is my provider?" from
/// its own payload.
///
/// Order is the array's order — the agent knows the sequence, and inferring it
/// from timestamps would break for two steps logged in the same minute.
final class AiUiServiceTimelineNode extends AiUiNode {
  const AiUiServiceTimelineNode({
    required super.id,
    required this.items,
    this.title,
    this.status,
    this.statusTone = AiUiTone.info,
    this.actions = const [],
    super.a11yLabel,
    super.fallbackText,
  });

  /// The card's heading — "Timeline".
  final String? title;

  /// The badge opposite it — "In Progress". Summarises the whole job, where
  /// each item's [AiUiTimelineState] describes one step.
  final String? status;
  final AiUiTone statusTone;

  /// The steps, in order.
  final List<AiUiTimelineItem> items;

  /// Buttons drawn inside this card — "Mark as Complete". See
  /// [AiUiCardAction].
  final List<AiUiCardAction> actions;

  @override
  AiUiNodeType get type => AiUiNodeType.serviceTimeline;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    ...baseJson(AiUiNodeType.serviceTimeline.wire),
    if (title != null) 'title': title,
    if (status != null) 'status': status,
    'statusTone': statusTone.wire,
    'items': [for (final item in items) item.toJson()],
    if (actions.isNotEmpty)
      'actions': [for (final entry in actions) entry.toJson()],
  };

  @override
  List<Object?> get props => [
    ...baseProps,
    title,
    status,
    statusTone,
    items,
    actions,
  ];
}

/// A code the user reads out or shows to someone — Figma
/// `verification-code-card`.
///
/// **Display-only, deliberately.** The Figma frame is a completion code the
/// customer gives the provider once the job is done, so the user is the
/// *source* of the value, not its typist. Modelling it as an input would add a
/// keyboard, a validation state and a submit result for a flow where nothing
/// is submitted — and would make the far more dangerous mistake of letting an
/// agent put a code field in front of someone, which is what a phishing
/// payload looks like.
///
/// If a flow ever genuinely needs the user to *enter* a code, that is a
/// different node with a different interaction kind; it is not a flag on this
/// one.
final class AiUiVerificationCodeNode extends AiUiNode {
  const AiUiVerificationCodeNode({
    required super.id,
    required this.code,
    this.label,
    this.body,
    this.actions = const [],
    super.a11yLabel,
    super.fallbackText,
  });

  /// The pill above the code — "verification code".
  final String? label;

  /// The instruction — "Share this code with the service provider after
  /// completing the service for confirmation".
  final String? body;

  /// The code itself. Rendered one character per box, in a left-to-right
  /// isolate, so the digits keep their order under Arabic.
  final String code;

  /// Buttons drawn inside this card — a "Copy" through `copy_text`. See
  /// [AiUiCardAction].
  final List<AiUiCardAction> actions;

  @override
  AiUiNodeType get type => AiUiNodeType.verificationCode;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    ...baseJson(AiUiNodeType.verificationCode.wire),
    if (label != null) 'label': label,
    if (body != null) 'body': body,
    'code': code,
    if (actions.isNotEmpty)
      'actions': [for (final entry in actions) entry.toJson()],
  };

  @override
  List<Object?> get props => [...baseProps, label, body, code, actions];
}
