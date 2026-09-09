import 'package:equatable/equatable.dart';

/// The handful of display strings the renderer needs but must not own.
///
/// `ai_ui_renderer` deliberately does not depend on `localization`: it is a
/// presentation library, and pulling easy_localization into it would make
/// every consumer inherit a translation bootstrap. Instead the host supplies
/// already-localized strings — in `sanad_client` that means `.tr()` against
/// the `ai_chat.*` namespace.
///
/// The defaults below are English and exist so tests and the design catalog
/// can render without wiring anything. **An app must override them.**
final class AiUiStrings extends Equatable {
  const AiUiStrings({
    this.metresSuffix = 'm',
    this.kilometresSuffix = 'km',
    this.unsupportedContent = 'Unsupported content',
    this.openInMaps = 'Open in maps',
    this.ratingOutOfFive = 'out of 5',
    this.distanceLabel = 'Distance',
  });

  static const AiUiStrings fallback = AiUiStrings();

  /// Distance unit for values under a kilometre.
  final String metresSuffix;

  final String kilometresSuffix;

  /// Shown in place of a node this client cannot draw, in dev builds only.
  final String unsupportedContent;

  /// The link line on a `request_summary`'s address row. Names a *client*
  /// capability — which maps app the tap reaches — so the agent does not
  /// author it.
  final String openInMaps;

  /// Read after a rating value by a screen reader, so "4.8" is announced as a
  /// score rather than a bare number.
  final String ratingOutOfFive;

  /// Prefixes a `branch_card`'s distance ("Distance: 450 m"). The number and
  /// its unit come from the client's own formatter, so the word does too —
  /// the agent never sends it.
  final String distanceLabel;

  @override
  List<Object?> get props => [
    metresSuffix,
    kilometresSuffix,
    unsupportedContent,
    openInMaps,
    ratingOutOfFive,
    distanceLabel,
  ];
}
