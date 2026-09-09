part of 'package:ai_ui_protocol/src/domain/ai_ui_node.dart';

// ─── Degradation marker ─────────────────────────────────────────────────────

/// A node whose `type` this client does not recognise and which carried no
/// `fallbackText`.
///
/// The validator only emits this when
/// `AiUiValidatorOptions.keepUnsupportedNodes` is set — the renderer passes
/// `!kReleaseMode`, so users see nothing while developers see exactly which
/// type the agent sent. In release the node is dropped entirely.
final class AiUiUnsupportedNode extends AiUiNode {
  const AiUiUnsupportedNode({
    required super.id,
    required this.rawType,
    super.a11yLabel,
    super.fallbackText,
  });

  final String rawType;

  @override
  AiUiNodeType? get type => null;

  @override
  Map<String, dynamic> toJson() => baseJson(rawType);

  @override
  List<Object?> get props => [...baseProps, rawType];
}
