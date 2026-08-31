import 'package:ai_ui_protocol/ai_ui_protocol.dart';

/// Host allowlist used across the suite. Deliberately narrow so the "blocked"
/// cases are the default and the "allowed" case has to be opted into.
const testUrlPolicy = AiUiUrlPolicy(allowedHosts: {'cdn.trysanad.us'});

/// schemaVersion 1 is assetId-only, so an image test names an asset the host
/// publishes. A URL is rejected regardless of host — see the `images` group.
const publishedAssetId = 'service_placeholder';
const rejectedImageUrl = 'https://cdn.trysanad.us/services/ac.jpg';

AiUiValidator validatorWith({
  AiUiLimits limits = AiUiLimits.defaults,
  AiUiUrlPolicy urlPolicy = testUrlPolicy,
  Set<AiUiActionType>? supportedActions,
  Set<String>? knownAssetIds,
  bool keepUnsupportedNodes = false,
}) => AiUiValidator(
  limits: limits,
  urlPolicy: urlPolicy,
  supportedActions: supportedActions,
  knownAssetIds: knownAssetIds,
  options: AiUiValidatorOptions(
    keepUnsupportedNodes: keepUnsupportedNodes,
  ),
);

/// Wraps [blocks] in a well-formed envelope so each test only has to express
/// the part it cares about.
Map<String, dynamic> payload(
  List<Map<String, dynamic>> blocks, {
  Object? schemaVersion = 1,
}) => <String, dynamic>{
  if (schemaVersion != null) 'schemaVersion': schemaVersion,
  'blocks': blocks,
};

Map<String, dynamic> textNode(String text, {String id = 'n1'}) =>
    <String, dynamic>{'type': 'text', 'id': id, 'text': text};

Map<String, dynamic> buttonNode({
  String label = 'Book',
  Map<String, dynamic>? action,
  String id = 'b1',
}) => <String, dynamic>{
  'type': 'button',
  'id': id,
  'label': label,
  'action':
      action ?? <String, dynamic>{'type': 'open_service', 'serviceId': 'svc_1'},
};

/// Builds a `column` nested [depth] levels deep with a text leaf at the
/// bottom, for exercising the depth limit.
Map<String, dynamic> nestedColumns(int depth) {
  var current = textNode('leaf', id: 'leaf');
  for (var i = depth; i > 0; i--) {
    current = <String, dynamic>{
      'type': 'column',
      'id': 'c$i',
      'children': [current],
    };
  }
  return current;
}

extension DiagnosticMatching on AiUiParseResult {
  bool hasCode(AiUiDiagnosticCode code) =>
      diagnostics.any((d) => d.code == code);

  Iterable<AiUiDiagnosticCode> get codes => diagnostics.map((d) => d.code);
}
