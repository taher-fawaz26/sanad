import 'package:equatable/equatable.dart';

/// A tappable prompt shown before the user has said anything.
///
/// [labelKey] is an i18n key, never prose — the composer's suggestion row
/// only ever shows localized copy, matching every other user-facing string in
/// this feature.
///
/// Deliberately just an id and a key: this is a static, local list today (see
/// the default set), but the shape carries no assumption that it always will
/// be — swapping the source for a backend-driven list later is a change to
/// where these values come from, not to what a suggestion is or how the
/// widget that renders them works.
final class AiChatSuggestion extends Equatable {
  /// Creates a suggestion.
  const AiChatSuggestion({required this.id, required this.labelKey});

  /// Stable identifier — used as the tile's key, never shown.
  final String id;

  /// The prompt's i18n key.
  final String labelKey;

  @override
  List<Object?> get props => [id, labelKey];
}
