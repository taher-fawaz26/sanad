/// The closed catalog of node types in SANAD Chat UI Protocol v1.
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

  // ── Semantic, client domain (5) ───────────────────────────────────────────
  serviceCard('service_card'),
  appointmentCard('appointment_card'),
  branchCard('branch_card'),
  documentCard('document_card'),
  quickReply('quick_reply')
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
    AiUiNodeType.quickReply => true,
    _ => false,
  };
}
