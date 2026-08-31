import 'package:ai_ui_protocol/src/domain/ai_ui_node.dart';
import 'package:equatable/equatable.dart';

/// A validated structured-UI payload for one assistant message.
///
/// [blocks] is an ordered vertical sequence rendered inside the assistant
/// bubble. Modelling the root as a *list* rather than a single node is what
/// makes "text + card + buttons in one reply" natural without an artificial
/// wrapper column.
final class AiUiDocument extends Equatable {
  const AiUiDocument({required this.schemaVersion, required this.blocks});

  /// The only version this client understands.
  ///
  /// Additive changes — new node types, new action types, new optional
  /// properties — deliberately do **not** bump this. Older clients degrade
  /// through `AiUiNode.fallbackText`. The version moves only when the meaning
  /// of an existing node changes.
  static const int currentSchemaVersion = 1;

  static const Set<int> supportedSchemaVersions = {currentSchemaVersion};

  final int schemaVersion;
  final List<AiUiNode> blocks;

  bool get isEmpty => blocks.isEmpty;
  bool get isNotEmpty => blocks.isNotEmpty;

  /// Total node count including nested children. Useful in diagnostics and
  /// tests; the limit itself is enforced during validation.
  int get nodeCount => blocks.fold(0, (sum, node) => sum + _count(node));

  static int _count(AiUiNode node) =>
      1 + node.children.fold(0, (sum, child) => sum + _count(child));

  Map<String, dynamic> toJson() => <String, dynamic>{
    'schemaVersion': schemaVersion,
    'blocks': blocks.map((b) => b.toJson()).toList(),
  };

  @override
  List<Object?> get props => [schemaVersion, blocks];
}
