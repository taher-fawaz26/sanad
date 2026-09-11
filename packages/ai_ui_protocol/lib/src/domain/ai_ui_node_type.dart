/// The closed catalog of node types in SANAD Chat UI Protocol v1.
///
/// **15 primitives + 23 semantic.** The semantic half tracks the Figma
/// component library for the client AI surface: every component the design
/// publishes has exactly one type here, so the agent names a business concept
/// and the app owns how it looks.
///
/// Adding a member here is an *additive* protocol change and does not bump
/// `schemaVersion` — older clients degrade via `fallbackText` (see
/// `AiUiNode.fallbackText`).
enum AiUiNodeType {
  // ── Primitives (15) ───────────────────────────────────────────────────────
  text('text'),
  richText('rich_text'),
  icon('icon'),
  image('image'),
  divider('divider'),
  spacer('spacer'),
  row('row'),
  column('column'),
  card('card'),
  button('button'),
  chip('chip'),
  list('list'),
  listItem('list_item'),
  progress('progress'),
  loading('loading'),

  // ── Semantic, client domain (23) ──────────────────────────────────────────
  //
  // Entity cards — each carries a business id the app can open.
  serviceCard('service_card'),
  appointmentCard('appointment_card'),
  branchCard('branch_card'),
  documentCard('document_card'),
  orderCard('order_card'),
  providerCard('provider_card'),

  // Summaries — a labelled set of values the user reads or confirms.
  bookingSummary('booking_summary'),
  requestSummary('request_summary'),
  paymentReceipt('payment_receipt'),

  // Interactive — the user supplies a value, posted back as a normal user
  // turn. See the `*Template` fields on each of these nodes.
  quickReply('quick_reply'),
  timeSlots('time_slots'),
  reviewRequest('review_request'),
  locationPicker('location_picker'),

  // Prompts — the assistant asks for a decision or a capability.
  reminderCard('reminder_card'),
  mediaRequest('media_request'),
  permissionRequest('permission_request'),
  locationConfirm('location_confirm'),

  /// A destructive decision read back before it is taken — "are you sure you
  /// want to cancel?". Answers through the shared confirmation interaction.
  confirmPrompt('confirm_prompt'),

  /// Something about an *existing* request changed what happens next — it
  /// already owns this conversation, the provider cancelled, the provider is
  /// late — together with the ways forward. See `AiUiRequestNoticeNode` for
  /// why one type covers all three.
  requestNotice('request_notice'),

  /// The place the conversation is about is outside SANAD's coverage. See
  /// `AiUiServiceAreaNoticeNode` for why this is not a `location_confirm`.
  serviceAreaNotice('service_area_notice'),

  // Status — the assistant reports where a long-running thing has got to.
  //
  // Neither of these asks the user for anything, but both carry domain data
  // the agent reasons about, which is what keeps them out of `primitives`: a
  // hand-assembled `card` of `text` nodes says the same words and means
  // nothing.
  providerSearch('provider_search'),
  serviceTimeline('service_timeline'),
  verificationCode('verification_code')
  ;

  const AiUiNodeType(this.wire);

  /// The exact JSON `type` string the agent must send.
  final String wire;

  /// `null` for an unrecognised type. Callers turn that into a
  /// `fallbackText` render, a dropped node, or a dev-only marker — never a
  /// throw.
  static AiUiNodeType? tryFromWire(String value) {
    for (final candidate in values) {
      if (candidate.wire == value) return candidate;
    }
    return null;
  }

  /// Node types that accept a `children` array.
  bool get isContainer => switch (this) {
    AiUiNodeType.row ||
    AiUiNodeType.column ||
    AiUiNodeType.card ||
    AiUiNodeType.list => true,
    _ => false,
  };

  /// Node types that carry business identity and therefore *must* be preferred
  /// over hand-assembling the same card from primitives.
  bool get isSemantic => switch (this) {
    AiUiNodeType.serviceCard ||
    AiUiNodeType.appointmentCard ||
    AiUiNodeType.branchCard ||
    AiUiNodeType.documentCard ||
    AiUiNodeType.orderCard ||
    AiUiNodeType.providerCard ||
    AiUiNodeType.bookingSummary ||
    AiUiNodeType.requestSummary ||
    AiUiNodeType.paymentReceipt ||
    AiUiNodeType.quickReply ||
    AiUiNodeType.timeSlots ||
    AiUiNodeType.reviewRequest ||
    AiUiNodeType.locationPicker ||
    AiUiNodeType.reminderCard ||
    AiUiNodeType.mediaRequest ||
    AiUiNodeType.permissionRequest ||
    AiUiNodeType.locationConfirm ||
    AiUiNodeType.confirmPrompt ||
    AiUiNodeType.requestNotice ||
    AiUiNodeType.serviceAreaNotice ||
    AiUiNodeType.providerSearch ||
    AiUiNodeType.serviceTimeline ||
    AiUiNodeType.verificationCode => true,
    _ => false,
  };

  /// Semantic nodes that accept the shared `actions` array — an attached row
  /// of buttons drawn *inside* the card's own border, which is how every
  /// current Figma card places its calls to action.
  ///
  /// Not every semantic node takes one. The interactive nodes own their submit
  /// control (its label and its behaviour are part of the node), and
  /// `quick_reply` *is* a list of actions already.
  bool get acceptsCardActions => switch (this) {
    AiUiNodeType.serviceCard ||
    AiUiNodeType.appointmentCard ||
    AiUiNodeType.branchCard ||
    AiUiNodeType.documentCard ||
    AiUiNodeType.orderCard ||
    AiUiNodeType.providerCard ||
    AiUiNodeType.bookingSummary ||
    AiUiNodeType.requestSummary ||
    AiUiNodeType.paymentReceipt ||
    AiUiNodeType.reminderCard ||
    AiUiNodeType.mediaRequest ||
    AiUiNodeType.permissionRequest ||
    AiUiNodeType.locationConfirm ||
    AiUiNodeType.requestNotice ||
    AiUiNodeType.serviceAreaNotice ||
    AiUiNodeType.providerSearch ||
    AiUiNodeType.serviceTimeline ||
    AiUiNodeType.verificationCode => true,
    _ => false,
  };
}
