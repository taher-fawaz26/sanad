part of 'package:ai_ui_protocol/src/domain/ai_ui_node.dart';

/// The seventeen business components — one per component the Figma library
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

/// The person or company assigned to a request — Figma `provider-card`.
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
    super.a11yLabel,
    super.fallbackText,
  });

  final String? title;
  final List<AiUiDetailItem> items;

  /// Buttons drawn inside this card. See [AiUiCardAction].
  final List<AiUiCardAction> actions;

  @override
  AiUiNodeType get type => AiUiNodeType.bookingSummary;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    ...baseJson(AiUiNodeType.bookingSummary.wire),
    if (title != null) 'title': title,
    'items': [for (final item in items) item.toJson()],
    if (actions.isNotEmpty)
      'actions': [for (final entry in actions) entry.toJson()],
  };

  @override
  List<Object?> get props => [...baseProps, title, items, actions];
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
  final List<AiUiCardAction> actions;

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
  };

  @override
  List<Object?> get props => [
    ...baseProps,
    items,
    summaryTitle,
    summaryText,
    location,
    actions,
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
  /// text.
  final String submitTemplate;

  @override
  AiUiNodeType get type => AiUiNodeType.reviewRequest;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    ...baseJson(AiUiNodeType.reviewRequest.wire),
    'serviceName': serviceName,
    if (providerText != null) 'providerText': providerText,
    if (commentPlaceholder != null) 'commentPlaceholder': commentPlaceholder,
    if (maxCommentLength != null) 'maxCommentLength': maxCommentLength,
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
    this.actions = const [],
    super.a11yLabel,
    super.fallbackText,
  });

  final String title;
  final AiUiImageSource? image;
  final String addressText;
  final String confirmLabel;
  final String? changeLabel;

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
    actions,
  ];
}
