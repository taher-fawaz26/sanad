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
  });

  static const AiUiStrings fallback = AiUiStrings();

  /// Distance unit for values under a kilometre.
  final String metresSuffix;

  final String kilometresSuffix;

  /// Shown in place of a node this client cannot draw, in dev builds only.
  final String unsupportedContent;

  @override
  List<Object?> get props => [
    metresSuffix,
    kilometresSuffix,
    unsupportedContent,
  ];
}
