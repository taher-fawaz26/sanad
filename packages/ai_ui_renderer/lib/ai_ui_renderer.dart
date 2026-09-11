/// Renders a validated SANAD Chat UI Protocol document as native SANAD Design
/// System widgets, and dispatches its actions through a compile-time
/// allowlist.
///
/// This is the layer that can actually *do* something with an AI payload —
/// `ai_ui_protocol` is inert data by construction. The split matters: it means
/// the audit question "what can an AI payload reach?" has a single, small
/// answer, and it lives here.
///
/// ```text
/// AiUiDocument              (already parsed and validated)
///   → AiUiSurface
///   → AiUiRendererRegistry  (node type → renderer)
///   → App* widgets
///
/// AiUiAction
///   → AiActionRegistry      (allowlisted handlers, populated at DI)
///   → app code
/// ```
///
/// Wire the *same* registries into validation and rendering with
/// `validatorFor`, so an action with no handler or an asset with no file is
/// dropped before a widget exists rather than failing at tap time.
library;

export 'src/actions/ai_action_registry.dart';
export 'src/diagnostics/ai_ui_diagnostics_sink.dart';
export 'src/interaction/ai_interaction_gate.dart';
export 'src/interaction/ai_ui_interaction_id.dart';
export 'src/interaction/ai_ui_interaction_ledger.dart';
export 'src/interaction/ai_ui_interaction_sink.dart';
export 'src/rendering/ai_card_tokens.dart';
export 'src/rendering/ai_node_renderer.dart';
export 'src/rendering/ai_ui_default_renderers.dart';
export 'src/rendering/ai_ui_formatters.dart';
export 'src/rendering/ai_ui_markdown.dart';
export 'src/rendering/ai_ui_render_scope.dart';
export 'src/rendering/ai_ui_renderer_registry.dart';
export 'src/rendering/ai_ui_semantics.dart';
export 'src/rendering/ai_ui_strings.dart';
export 'src/rendering/ai_ui_surface.dart';
export 'src/rendering/ai_ui_tokens.dart';
export 'src/rendering/primitives/ai_card_content.dart';
export 'src/rendering/primitives/ai_card_surface.dart';
export 'src/rendering/primitives/ai_notice_parts.dart';
export 'src/rendering/primitives/ai_prompt_parts.dart';
export 'src/rendering/primitives/ai_status_parts.dart';
export 'src/rendering/primitives/ai_ui_image_view.dart';
export 'src/rendering/renderers/control_renderers.dart';
export 'src/rendering/renderers/fallback_renderer.dart';
export 'src/rendering/renderers/layout_renderers.dart';
export 'src/rendering/renderers/media_renderers.dart';
export 'src/rendering/renderers/semantic/confirmation.dart';
export 'src/rendering/renderers/semantic/entity_cards.dart';
export 'src/rendering/renderers/semantic/interactive.dart';
export 'src/rendering/renderers/semantic/notices.dart';
export 'src/rendering/renderers/semantic/prompts.dart';
export 'src/rendering/renderers/semantic/status.dart';
export 'src/rendering/renderers/semantic/summaries.dart';
export 'src/rendering/renderers/text_renderers.dart';
export 'src/resolvers/ai_asset_resolver.dart';
export 'src/resolvers/ai_icon_resolver.dart';
