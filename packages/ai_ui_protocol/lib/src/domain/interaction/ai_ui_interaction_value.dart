import 'package:equatable/equatable.dart';

/// Where a location answer came from.
///
/// The agent needs this to know whether it is holding a place it already knew
/// about (and can resolve by id) or free text the user typed, which it has to
/// interpret.
enum AiUiLocationSource {
  /// One of the `savedLocations` the agent itself supplied.
  saved('saved'),

  /// Free text the user typed into the picker's search field.
  typed('typed'),

  /// A place the user resolved on the app's own map — a search result, a
  /// dropped pin, or the device position — carrying the map layer's own
  /// identifier in `id` when one exists.
  ///
  /// Distinct from [typed] because the difference is what the agent may
  /// assume: typed text is a query it still has to interpret, where this is
  /// already resolved to a point and an address. Reporting a map selection as
  /// [typed] would have the agent re-interpret a location it has been handed
  /// precisely. An older consumer that does not know this member decodes it as
  /// [typed] (see `AiUiInteractionCodec`), so adding it broke nothing.
  map('map')
  ;

  const AiUiLocationSource(this.wire);

  /// The exact JSON value on the wire.
  final String wire;

  /// Resolves [value], or `null` when it names no member.
  static AiUiLocationSource? tryFromWire(String value) {
    for (final candidate in values) {
      if (candidate.wire == value) return candidate;
    }
    return null;
  }
}

/// The outcome of a capability request, expressed in protocol terms.
///
/// Deliberately **not** a platform permission status: nothing here names
/// `permission_handler`, `PermissionStatus`, or an Android/iOS concept. The
/// app maps its own gateway result onto this, so the agent reasons about
/// "may I proceed" and never about a plugin's vocabulary.
enum AiUiPermissionOutcome {
  /// The capability is available.
  granted('granted'),

  /// Refused this time. Asking again is allowed.
  denied('denied'),

  /// Refused for good — only the system settings screen can change it.
  permanentlyDenied('permanently_denied'),

  /// The device has no such capability, or the app cannot offer it at all.
  /// Asking again will never help.
  unavailable('unavailable'),

  /// The user backed out before the platform was asked.
  cancelled('cancelled')
  ;

  const AiUiPermissionOutcome(this.wire);

  /// The exact JSON value on the wire.
  final String wire;

  /// Whether the agent may proceed with whatever needed the capability.
  bool get isGranted => this == AiUiPermissionOutcome.granted;

  /// Resolves [value], or `null` when it names no member.
  static AiUiPermissionOutcome? tryFromWire(String value) {
    for (final candidate in values) {
      if (candidate.wire == value) return candidate;
    }
    return null;
  }
}

/// The payload half of an interaction result.
///
/// A closed hierarchy of typed value objects rather than a
/// `Map<String, dynamic>`: every other value in this package
/// (`ai_ui_values.dart`) is typed, and a sealed type is what lets a consumer
/// switch exhaustively instead of probing keys. Like every protocol value it
/// serialises one way — decoding belongs to `AiUiInteractionCodec` and is
/// driven by the owning interaction's kind, which is why the value carries no
/// discriminator of its own.
sealed class AiUiInteractionValue extends Equatable {
  /// Creates a value.
  const AiUiInteractionValue();

  /// The `value` object on the wire.
  Map<String, dynamic> toJson();
}

/// One thing was chosen from a list the agent supplied.
///
/// Used by `time_slots` and `quick_reply`. [id] is the agent's own identifier
/// where it published one, so it can resolve the choice without matching on
/// display text; [label] is what the user actually saw.
final class AiUiSelectionValue extends AiUiInteractionValue {
  /// Creates a selection value.
  const AiUiSelectionValue({required this.label, this.id});

  /// The agent's identifier for the chosen entry, when it published one.
  final String? id;

  /// The label the user saw and chose.
  final String label;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    if (id != null) 'id': id,
    'label': label,
  };

  @override
  List<Object?> get props => [id, label];
}

/// Free text the user wrote. Used by `review_request`.
final class AiUiTextValue extends AiUiInteractionValue {
  /// Creates a text value.
  const AiUiTextValue(this.text);

  /// The user's own words, trimmed. May be empty — an empty review is a
  /// legitimate answer and the agent should be told so rather than left
  /// waiting.
  final String text;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{'text': text};

  @override
  List<Object?> get props => [text];
}

/// A place the user provided.
///
/// Carries no coordinates today: the client resolves a location from the
/// agent's own `savedLocations` or from what the user typed, and never reads
/// the device position. A coordinate-bearing variant is additive when a
/// device-location capability exists — see `docs/ai-chat/PROTOCOL_V1.md` §13.
final class AiUiLocationValue extends AiUiInteractionValue {
  /// Creates a location value.
  const AiUiLocationValue({
    required this.name,
    required this.source,
    this.id,
    this.addressText,
  });

  /// The agent's identifier for the saved place, when one was chosen.
  final String? id;

  /// The place's display name, or the text the user typed.
  final String name;

  /// The fuller address, when the agent supplied one with the saved place.
  final String? addressText;

  /// Whether this came from the agent's list or from the search field.
  final AiUiLocationSource source;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    if (id != null) 'id': id,
    'name': name,
    if (addressText != null) 'addressText': addressText,
    'source': source.wire,
  };

  @override
  List<Object?> get props => [id, name, addressText, source];
}

/// The outcome of a `permission_request` or a `request_permission` action.
final class AiUiPermissionValue extends AiUiInteractionValue {
  /// Creates a permission value.
  const AiUiPermissionValue({
    required this.permission,
    required this.outcome,
  });

  /// The capability that was asked for — the same wire value the node used.
  final String permission;

  /// What the platform, or the user, came back with.
  final AiUiPermissionOutcome outcome;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    'permission': permission,
    'outcome': outcome.wire,
  };

  @override
  List<Object?> get props => [permission, outcome];
}

/// The outcome of a `media_request`.
///
/// Only a count and the picker that was used. The files themselves travel as
/// the turn's `attachments`, already uploaded and addressable — duplicating
/// them here would give the agent two sources of truth for one upload.
final class AiUiMediaValue extends AiUiInteractionValue {
  /// Creates a media value.
  const AiUiMediaValue({required this.count, this.source});

  /// Which picker ran — `camera`, `gallery`, `video`, `document`.
  final String? source;

  /// How many files the user ended up staging. Zero means they backed out.
  final int count;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    if (source != null) 'source': source,
    'count': count,
  };

  @override
  List<Object?> get props => [source, count];
}

/// Which way an offer went.
enum AiUiOfferDecision {
  /// The user took the offer.
  accepted('accepted'),

  /// The user turned it down. Distinct from a *cancelled* interaction: the
  /// user answered the question, and the answer was no.
  declined('declined')
  ;

  const AiUiOfferDecision(this.wire);

  /// The exact JSON value on the wire.
  final String wire;

  /// Resolves [value], or `null` when it names no member.
  static AiUiOfferDecision? tryFromWire(String value) {
    for (final candidate in values) {
      if (candidate.wire == value) return candidate;
    }
    return null;
  }
}

/// A rating, with the words that came with it. Used by `review_request`.
///
/// Separate from [AiUiTextValue] rather than replacing it: a review with no
/// star rating — the card the agent has been sending since v1 — still travels
/// as plain text, so a backend reading `value.text` keeps working. A card that
/// asks for stars sends this instead, and `value.text` is still there.
final class AiUiReviewValue extends AiUiInteractionValue {
  /// Creates a review value.
  const AiUiReviewValue({required this.comment, this.rating});

  /// Whole stars, `1..maxRating`. `null` when the card offered no rating, or
  /// offered one the user did not set.
  final int? rating;

  /// The user's own words, trimmed. May be empty — an empty comment beside a
  /// five-star rating is a complete answer.
  final String comment;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    if (rating != null) 'rating': rating,
    // Under the same key `AiUiTextValue` uses, so a reader that only knows
    // the older shape still finds the comment where it expects it.
    'text': comment,
  };

  @override
  List<Object?> get props => [rating, comment];
}

/// A yes-or-no answer. Used by everything that carries an `AiUiConfirmChoice`.
final class AiUiConfirmationValue extends AiUiInteractionValue {
  /// Creates a confirmation value.
  const AiUiConfirmationValue({required this.confirmed, this.reference});

  /// `true` when the user took the affirmative control.
  ///
  /// Note this is *the answer*, not the interaction's status: declining is a
  /// deliberate answer (`submitted` + `confirmed: false`), where dismissing
  /// the card without choosing is a `cancelled` interaction. An agent that
  /// conflated the two would re-ask a question the user already said no to.
  final bool confirmed;

  /// The agent's own identifier for what was decided, echoed back from
  /// `AiUiConfirmChoice.reference`.
  final String? reference;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    'confirmed': confirmed,
    if (reference != null) 'reference': reference,
  };

  @override
  List<Object?> get props => [confirmed, reference];
}

/// How a `provider_card`'s offer was answered.
final class AiUiOfferValue extends AiUiInteractionValue {
  /// Creates an offer value.
  const AiUiOfferValue({
    required this.decision,
    this.providerId,
    this.offerId,
  });

  /// Accepted or declined.
  final AiUiOfferDecision decision;

  /// The provider the offer was for, from the card's own `providerId`.
  final String? providerId;

  /// The agent's identifier for the offer, when it published one.
  final String? offerId;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    'decision': decision.wire,
    if (providerId != null) 'providerId': providerId,
    if (offerId != null) 'offerId': offerId,
  };

  @override
  List<Object?> get props => [decision, providerId, offerId];
}

/// No payload.
///
/// The value of a cancellation, and of any acknowledgement whose meaning is
/// fully carried by the interaction's kind and status.
final class AiUiEmptyValue extends AiUiInteractionValue {
  /// Creates an empty value.
  const AiUiEmptyValue();

  @override
  Map<String, dynamic> toJson() => const <String, dynamic>{};

  @override
  List<Object?> get props => const [];
}
