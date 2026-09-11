import 'package:ai_ui_protocol/src/domain/ai_ui_action.dart';
import 'package:ai_ui_protocol/src/domain/ai_ui_enums.dart';
import 'package:equatable/equatable.dart';

/// A monetary amount, sent *structured* rather than pre-formatted.
///
/// The agent never formats currency. Formatting a price correctly — the dirham
/// glyph, Arabic-Indic digits, symbol placement under RTL — is a client concern
/// and depends on the device locale, not on what the agent believes the locale
/// to be. The same principle applies to instants (ISO-8601 UTC) and distances
/// (metres): machine-typed data goes over the wire structured, free-form prose
/// goes over already localized.
final class AiUiMoney extends Equatable {
  const AiUiMoney({required this.amount, required this.currency});

  final num amount;

  /// ISO-4217, uppercase (e.g. `AED`).
  final String currency;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'amount': amount,
    'currency': currency,
  };

  @override
  List<Object?> get props => [amount, currency];
}

/// A short status pill attached to a card or list item.
final class AiUiBadge extends Equatable {
  const AiUiBadge({required this.label, this.tone = AiUiTone.neutral});

  final String label;
  final AiUiTone tone;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'label': label,
    'tone': tone.wire,
  };

  @override
  List<Object?> get props => [label, tone];
}

/// One run inside a `rich_text` node.
///
/// This is how the protocol expresses inline emphasis and inline links without
/// admitting Markdown as a UI transport.
final class AiUiRichSpan extends Equatable {
  const AiUiRichSpan({
    required this.text,
    this.emphasis = AiUiEmphasis.normal,
    this.action,
  });

  final String text;
  final AiUiEmphasis emphasis;

  /// When present the span renders as a tappable link. Subject to the same
  /// action allowlist as a `button`.
  final AiUiAction? action;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'text': text,
    'emphasis': emphasis.wire,
    if (action != null) 'action': action!.toJson(),
  };

  @override
  List<Object?> get props => [text, emphasis, action];
}

/// Where an image comes from — **one shape for every image in the protocol**.
///
/// ```text
/// image
///  ├── url      optional, preferred
///  └── assetId  optional, controlled local fallback
/// ```
///
/// Both fields are optional and both may be present. The precedence is fixed
/// and is the same for every image-bearing node — a `service_card` thumbnail,
/// a `provider_card` avatar, a `list_item` leading square, the `image`
/// primitive:
///
/// 1. a usable [url] renders from the network;
/// 2. otherwise a usable [assetId] renders the bundled asset;
/// 3. otherwise the node falls back to whatever it shows without an image.
///
/// There is deliberately no sealed either/or here. An earlier version modelled
/// the two as separate subtypes, which meant the renderer had to know which
/// kind it held and made "send both, prefer the URL" unrepresentable. One
/// object with two optional fields is what lets the backend attach a local
/// fallback to a remote image without the client changing behaviour.
///
/// **What each field is for.** [url] carries backend-owned, dynamic media: a
/// service photo, a provider portrait, business artwork. [assetId] names one
/// of a small, client-published set of static illustrations — the agent knows
/// only the canonical id, and the client alone decides which bundled file it
/// maps to. Neither field may carry a Flutter asset path, a package path, an
/// Android or iOS resource path, or any other local file reference; the
/// validator only admits an id the host has published.
final class AiUiImageSource extends Equatable {
  const AiUiImageSource({this.url, this.assetId});

  /// Convenience for the common single-source cases.
  const AiUiImageSource.url(String this.url) : assetId = null;
  const AiUiImageSource.asset(String this.assetId) : url = null;

  /// A remote image, already checked against the host's image URL policy
  /// during validation. Never an arbitrary string: an unparseable URL, a
  /// non-https scheme, embedded userinfo or a non-allowlisted host is stripped
  /// before this object is built.
  final String? url;

  /// A canonical id from the host's published asset catalog, already checked
  /// during validation when the host declared its catalog.
  final String? assetId;

  /// Whether [url] is present and non-empty. An empty string is treated as
  /// absent, which is what makes `{"url": "", "assetId": "..."}` fall through
  /// to the asset rather than rendering nothing.
  bool get hasUrl => (url ?? '').isNotEmpty;

  bool get hasAssetId => (assetId ?? '').isNotEmpty;

  /// Nothing usable — the owning node shows its no-image state.
  bool get isEmpty => !hasUrl && !hasAssetId;

  Map<String, dynamic> toJson() => <String, dynamic>{
    if (hasUrl) 'url': url,
    if (hasAssetId) 'assetId': assetId,
  };

  @override
  List<Object?> get props => [url, assetId];
}

/// One suggested reply in a `quick_reply` node.
final class AiUiQuickReplyOption extends Equatable {
  const AiUiQuickReplyOption({required this.label, required this.action});

  final String label;
  final AiUiAction action;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'label': label,
    'action': action.toJson(),
  };

  @override
  List<Object?> get props => [label, action];
}

// ── Shared card action row ──────────────────────────────────────────────────

/// One button in a semantic card's attached `actions` row.
///
/// Every current Figma card places its calls to action **inside** the card's
/// own border — a shared bottom row, equal-width, sharing the card's padding.
/// Expressing that as sibling `row` + `button` primitives puts the buttons in
/// a separate block underneath, which is a different design.
///
/// Deliberately the same vocabulary as the `button` primitive
/// ([AiUiButtonVariant] / [AiUiButtonIntent]) rather than a new one: the agent
/// already knows how to ask for an outline destructive control, and the
/// renderer already knows how to draw one.
///
/// An entry whose action cannot be resolved is dropped exactly as a `button`
/// is — a dead control is worse than a missing one — while the card survives.
final class AiUiCardAction extends Equatable {
  const AiUiCardAction({
    required this.label,
    required this.action,
    this.variant = AiUiButtonVariant.primary,
    this.intent = AiUiButtonIntent.standard,
  });

  final String label;
  final AiUiAction action;
  final AiUiButtonVariant variant;
  final AiUiButtonIntent intent;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'label': label,
    'action': action.toJson(),
    'variant': variant.wire,
    'intent': intent.wire,
  };

  @override
  List<Object?> get props => [label, action, variant, intent];
}

// ── Summary / receipt building blocks ───────────────────────────────────────

/// One label-and-value row inside a summary, receipt or details card.
///
/// The value is **prose the agent has already localized** — a service name, a
/// masked card number, a formatted reference. Anything machine-typed (a price,
/// an instant, a distance) belongs in a structured field instead so the client
/// can format it for the reader's locale.
final class AiUiDetailItem extends Equatable {
  const AiUiDetailItem({
    required this.label,
    required this.value,
    this.valueTone = AiUiTone.neutral,
    this.isLtrValue = false,
  });

  final String label;
  final String value;

  /// Tints the value. `primary` is what Figma uses for the emphasised cost row.
  final AiUiTone valueTone;

  /// Set for an inherently left-to-right value — a reference id, a masked
  /// card, an IBAN — so the renderer wraps it in Unicode bidi isolates and a
  /// leading symbol does not reorder to the far end under RTL.
  final bool isLtrValue;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'label': label,
    'value': value,
    'valueTone': valueTone.wire,
    if (isLtrValue) 'isLtrValue': true,
  };

  @override
  List<Object?> get props => [label, value, valueTone, isLtrValue];
}

/// The emphasised bottom line of a receipt: a label plus a structured amount.
final class AiUiReceiptTotal extends Equatable {
  const AiUiReceiptTotal({required this.label, required this.amount});

  final String label;
  final AiUiMoney amount;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'label': label,
    'amount': amount.toJson(),
  };

  @override
  List<Object?> get props => [label, amount];
}

/// One figure in a provider card's stats strip — "Completed jobs / 340+".
final class AiUiStat extends Equatable {
  const AiUiStat({required this.label, required this.value});

  final String label;
  final String value;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'label': label,
    'value': value,
  };

  @override
  List<Object?> get props => [label, value];
}

/// A place the user can open in the platform maps app.
final class AiUiLocationRef extends Equatable {
  const AiUiLocationRef({required this.addressText, this.label, this.action});

  /// The address as the agent localized it.
  final String addressText;

  /// An optional name above the address — "Home", "Downtown branch".
  final String? label;

  /// Usually an `open_map` action. Without one the row renders as static text
  /// rather than a tappable link.
  final AiUiAction? action;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'addressText': addressText,
    if (label != null) 'label': label,
    if (action != null) 'action': action!.toJson(),
  };

  @override
  List<Object?> get props => [addressText, label, action];
}

// ── Interactive building blocks ─────────────────────────────────────────────

/// One selectable slot in a `time_slots` node.
///
/// [id] is what the node reports back through its `confirmTemplate`, and what
/// `selectedSlotId` refers to. [enabled] `false` renders the slot visibly
/// unavailable rather than omitting it, so the user can see that 11:00 exists
/// and is taken.
final class AiUiTimeSlot extends Equatable {
  const AiUiTimeSlot({
    required this.id,
    required this.label,
    this.enabled = true,
  });

  final String id;
  final String label;
  final bool enabled;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'label': label,
    'enabled': enabled,
  };

  @override
  List<Object?> get props => [id, label, enabled];
}

/// One saved place offered by a `location_picker` node.
final class AiUiSavedLocation extends Equatable {
  const AiUiSavedLocation({
    required this.id,
    required this.name,
    required this.addressText,
    this.icon,
  });

  final String id;
  final String name;
  final String addressText;

  /// A SANAD icon token or Font Awesome class, resolved the same way as
  /// `icon.name`. Unresolvable simply renders no glyph.
  final String? icon;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'addressText': addressText,
    if (icon != null) 'icon': icon,
  };

  @override
  List<Object?> get props => [id, name, addressText, icon];
}

/// One way to supply media in a `media_request` node.
final class AiUiMediaOption extends Equatable {
  const AiUiMediaOption({required this.label, required this.source});

  final String label;
  final AiUiMediaSource source;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'label': label,
    'source': source.wire,
  };

  @override
  List<Object?> get props => [label, source];
}

// ── Provider offer building blocks ──────────────────────────────────────────

/// The person or company a card is *about*, when that card is not itself a
/// `provider_card`.
///
/// Exists so a `booking_summary` can name who is coming without either
/// restating the provider as two more [AiUiDetailItem] rows — which loses the
/// avatar and the verification mark — or nesting a whole `provider_card`
/// inside a summary, which would give the user two sets of controls for one
/// booking.
///
/// Carries identity ([providerId]) rather than only a name, so the agent can
/// resolve the same person across the conversation.
final class AiUiProviderRef extends Equatable {
  const AiUiProviderRef({
    required this.providerId,
    required this.name,
    this.roleText,
    this.image,
    this.verified = false,
  });

  final String providerId;
  final String name;

  /// What they do — "AC & Plumbing Specialist".
  final String? roleText;

  /// The portrait. The usual `{url?, assetId?}` contract; a failed or absent
  /// image falls back to the card's own person glyph.
  final AiUiImageSource? image;

  /// Whether SANAD has verified this provider. A *fact about the account*,
  /// which is why it is a boolean the agent asserts rather than a badge label
  /// it composes — the tick and its colour are the client's.
  final bool verified;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'providerId': providerId,
    'name': name,
    if (roleText != null) 'roleText': roleText,
    if (image != null) 'image': image!.toJson(),
    if (verified) 'verified': true,
  };

  @override
  List<Object?> get props => [providerId, name, roleText, image, verified];
}

/// The accept-or-decline pair on a `provider_card` that is an *offer*.
///
/// Separate from the card's generic `actions` row because the two mean
/// different things. An `actions` entry is a request to run an app action —
/// call, message, open. An offer is a **question the agent asked**, and its
/// answer is an `offer_resolved` interaction carrying the decision and the
/// provider it was about, so the agent never has to infer "they accepted"
/// from a sentence.
///
/// A card without one is a provider the user is merely being shown.
final class AiUiProviderOffer extends Equatable {
  const AiUiProviderOffer({
    required this.acceptLabel,
    required this.declineLabel,
    this.offerId,
    this.acceptTemplate,
    this.declineTemplate,
  });

  /// The agent's own identifier for this offer, when it has one. Travels back
  /// on the result so the agent resolves the offer rather than the provider.
  final String? offerId;

  final String acceptLabel;
  final String declineLabel;

  /// Posted as the user turn on accept. Absent means the interaction travels
  /// with no prose and the host supplies its own words, exactly as a
  /// permission outcome does.
  final String? acceptTemplate;

  /// Posted as the user turn on decline.
  final String? declineTemplate;

  Map<String, dynamic> toJson() => <String, dynamic>{
    if (offerId != null) 'offerId': offerId,
    'acceptLabel': acceptLabel,
    'declineLabel': declineLabel,
    if (acceptTemplate != null) 'acceptTemplate': acceptTemplate,
    if (declineTemplate != null) 'declineTemplate': declineTemplate,
  };

  @override
  List<Object?> get props => [
    offerId,
    acceptLabel,
    declineLabel,
    acceptTemplate,
    declineTemplate,
  ];
}

/// A yes-or-no the agent is asking, as a pair of labelled controls.
///
/// **One block, reused wherever a card ends in "confirm or cancel"** — the
/// `request_summary` about to be submitted, the `confirm_prompt` asking
/// whether to cancel a booking, the `location_confirm` reading an address
/// back. All three answer through the same `confirmation_resolved`
/// interaction, so there is one result shape rather than one per card.
///
/// Why not three `actions` entries with `send_message`: a card whose answer
/// arrives only as prose leaves the agent parsing its own template to find out
/// whether the user agreed, and leaves the *client* with no structured record
/// that this particular node was answered. The ledger needs the latter to stop
/// a second tap.
final class AiUiConfirmChoice extends Equatable {
  const AiUiConfirmChoice({
    required this.confirmLabel,
    this.cancelLabel,
    this.confirmTemplate,
    this.cancelTemplate,
    this.reference,
    this.destructive = false,
  });

  final String confirmLabel;

  /// Omitted means the card offers no way to decline *here* — the
  /// conversation is then the way out.
  final String? cancelLabel;

  /// Posted as the user turn on confirm. No placeholder is substituted: there
  /// is nothing the user supplied to substitute.
  final String? confirmTemplate;

  /// Posted as the user turn on cancel.
  final String? cancelTemplate;

  /// The agent's identifier for the thing being decided — a request id, a
  /// booking reference. Travels back on the result so the answer is
  /// unambiguous even if the same question is asked twice.
  final String? reference;

  /// Draws the *confirm* control as destructive. Set when confirming is the
  /// damaging choice — "Yes, cancel my booking" — which is the one case where
  /// the affirmative button must not look like the safe one.
  final bool destructive;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'confirmLabel': confirmLabel,
    if (cancelLabel != null) 'cancelLabel': cancelLabel,
    if (confirmTemplate != null) 'confirmTemplate': confirmTemplate,
    if (cancelTemplate != null) 'cancelTemplate': cancelTemplate,
    if (reference != null) 'reference': reference,
    if (destructive) 'destructive': true,
  };

  @override
  List<Object?> get props => [
    confirmLabel,
    cancelLabel,
    confirmTemplate,
    cancelTemplate,
    reference,
    destructive,
  ];
}

// ── Timeline building blocks ────────────────────────────────────────────────

/// One step in a `service_timeline`.
///
/// [state] is the machine-readable half and drives every visual decision; the
/// strings beside it are what the reader sees. Both are needed: the agent
/// knows the lifecycle, the client owns the rail.
final class AiUiTimelineItem extends Equatable {
  const AiUiTimelineItem({
    required this.state,
    required this.title,
    this.description,
    this.at,
  });

  final AiUiTimelineState state;

  /// The step as the user recognises it — "Provider Assigned".
  final String title;

  /// One line of detail — "Ahmed K has been assigned".
  final String? description;

  /// When the step happened. Always UTC; the renderer converts to device time
  /// and formats it, so a timeline reads correctly in Dubai and in London.
  /// Absent for a step that has not happened yet.
  final DateTime? at;

  /// Whether this is the step the user is waiting on.
  bool get isCurrent => state.isActive;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'state': state.wire,
    'title': title,
    if (description != null) 'description': description,
    if (at != null) 'at': at!.toUtc().toIso8601String(),
  };

  @override
  List<Object?> get props => [state, title, description, at];
}
