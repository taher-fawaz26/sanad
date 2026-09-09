import 'package:ai_ui_protocol/src/domain/ai_ui_action.dart';
import 'package:ai_ui_protocol/src/domain/ai_ui_enums.dart';
import 'package:ai_ui_protocol/src/domain/ai_ui_node_type.dart';
import 'package:ai_ui_protocol/src/domain/ai_ui_values.dart';
import 'package:equatable/equatable.dart';

part 'package:ai_ui_protocol/src/domain/nodes/fallback_node.dart';
part 'package:ai_ui_protocol/src/domain/nodes/primitive_nodes.dart';
part 'package:ai_ui_protocol/src/domain/nodes/semantic_nodes.dart';

/// A validated node in a SANAD Chat UI Protocol document.
///
/// Reaching this type means the payload already survived
/// `AiUiCodec.decode` + `AiUiValidator.validate`: every required field is
/// present and correctly typed, every enum is a known member, every action is
/// on the host's allowlist, every URL passed the URL policy, and every limit
/// holds. Renderers can therefore be *total* functions over these values —
/// there is nothing left to be invalid at build time, which is what keeps a
/// malformed AI payload from ever throwing inside `build()`.
sealed class AiUiNode extends Equatable {
  const AiUiNode({required this.id, this.a11yLabel, this.fallbackText});

  /// Stable identity for widget keys. Supplied by the agent, or derived from
  /// the node's path in the document when the agent omits it.
  final String id;

  /// Screen-reader label override. When absent the renderer derives one from
  /// the node's own content.
  final String? a11yLabel;

  /// Rendered as plain text by a client that does not recognise this node
  /// type. This single field is the protocol's entire forward-compatibility
  /// strategy — see `AiUiDocument.schemaVersion`.
  final String? fallbackText;

  /// `null` only for [AiUiUnsupportedNode], which by definition names a type
  /// outside this client's catalog.
  AiUiNodeType? get type;

  /// Empty for every non-container node.
  List<AiUiNode> get children => const [];

  Map<String, dynamic> toJson();

  /// Fields shared by every node. Subclasses spread this into their own map.
  Map<String, dynamic> baseJson(String typeWire) => <String, dynamic>{
    'type': typeWire,
    'id': id,
    if (a11yLabel != null) 'a11yLabel': a11yLabel,
    if (fallbackText != null) 'fallbackText': fallbackText,
  };

  List<Object?> get baseProps => [id, a11yLabel, fallbackText];
}
