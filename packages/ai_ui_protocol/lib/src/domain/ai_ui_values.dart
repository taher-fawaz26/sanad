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

/// Where an image comes from.
///
/// **schemaVersion 1 only ever produces [AiUiAssetImage].** The validator
/// rejects a `url` on an image node outright, so [AiUiRemoteImage] is not
/// reachable from a payload today — it exists so the sealed hierarchy and the
/// renderer's switch are already shaped for a future version that admits
/// allowlisted remote images.
sealed class AiUiImageSource extends Equatable {
  const AiUiImageSource();

  Map<String, dynamic> toJson();
}

/// A bundled asset referenced by a stable id the app resolves.
final class AiUiAssetImage extends AiUiImageSource {
  const AiUiAssetImage(this.assetId);

  final String assetId;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{'assetId': assetId};

  @override
  List<Object?> get props => [assetId];
}

/// A remote image.
///
/// **Not produced by schemaVersion 1.** No v1 payload can construct one: the
/// validator rejects `image.url` before this point. Kept as future-ready
/// infrastructure so admitting allowlisted remote images later is a validator
/// change, not a model change.
final class AiUiRemoteImage extends AiUiImageSource {
  const AiUiRemoteImage(this.url);

  final String url;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{'url': url};

  @override
  List<Object?> get props => [url];
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
