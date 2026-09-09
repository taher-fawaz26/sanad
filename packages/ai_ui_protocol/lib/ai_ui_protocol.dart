/// SANAD Chat UI Protocol v1.
///
/// Transport-agnostic models, codec, validator and diagnostics for
/// AI-generated structured UI.
///
/// This package is **pure Dart with no Flutter dependency** — not by
/// convention but as a `pubspec.yaml` fact. An AI payload parsed here cannot
/// reference a `Widget`, a `Color`, a route, or the network, because none of
/// those types are reachable. Rendering and action execution live in
/// `ai_ui_renderer`, which owns those concerns and is the only place that can
/// act on a payload.
///
/// The pipeline:
/// ```text
/// raw string
///   → AiUiCodec.decode      (size guard, JSON decode — never throws)
///   → AiUiValidator.validate (version, catalog, props, actions, limits)
///   → AiUiParseResult        (AiUiDocument? + AiUiDiagnostic list)
/// ```
library;

export 'src/diagnostics/ai_ui_diagnostic.dart';
export 'src/domain/ai_ui_action.dart';
export 'src/domain/ai_ui_document.dart';
export 'src/domain/ai_ui_enums.dart';
export 'src/domain/ai_ui_node.dart';
export 'src/domain/ai_ui_node_type.dart';
export 'src/domain/ai_ui_values.dart';
export 'src/domain/events/ai_chat_event.dart';
export 'src/domain/interaction/ai_ui_interaction.dart';
export 'src/domain/interaction/ai_ui_interaction_value.dart';
export 'src/validation/ai_chat_event_codec.dart';
export 'src/validation/ai_ui_codec.dart';
export 'src/validation/ai_ui_interaction_codec.dart';
export 'src/validation/ai_ui_limits.dart';
export 'src/validation/ai_ui_parse_result.dart';
export 'src/validation/ai_ui_url_policy.dart';
export 'src/validation/ai_ui_validator.dart';
