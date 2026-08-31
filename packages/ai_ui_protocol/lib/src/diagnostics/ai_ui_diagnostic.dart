import 'package:equatable/equatable.dart';

/// Why a payload, node, property or action was rejected, downgraded or
/// truncated.
enum AiUiDiagnosticCode {
  /// Not JSON, or JSON that is not an object.
  malformedPayload('malformed_payload'),

  /// `schemaVersion` missing, non-integer, or newer than this client supports.
  unsupportedSchemaVersion('unsupported_schema_version'),

  /// `type` names a node outside this client's catalog.
  unknownNodeType('unknown_node_type'),

  /// An action `type` outside the protocol catalog, or outside the set this
  /// host's action registry actually implements.
  unknownActionType('unknown_action_type'),

  /// A required field was absent or empty.
  missingRequiredProperty('missing_required_property'),

  /// A field was present but the wrong type, or an enum value outside the
  /// documented set (in which case the documented default was applied).
  invalidProperty('invalid_property'),

  /// A size, depth, count or length limit was hit. The container was
  /// truncated, or the payload rejected.
  limitExceeded('limit_exceeded'),

  /// A URL failed `AiUiUrlPolicy` — not https, or host not on the allowlist.
  blockedUrl('blocked_url'),

  /// An `assetId` the host does not publish.
  unknownAssetId('unknown_asset_id'),

  /// A field reserved for a future protocol version was sent.
  reservedProperty('reserved_property'),

  /// A renderer threw despite operating on validated input. Reported by the
  /// renderer package, never by the validator.
  rendererFailure('renderer_failure')
  ;

  const AiUiDiagnosticCode(this.wire);

  final String wire;
}

/// A single, privacy-safe observation about an AI payload.
///
/// **[detail] must never contain user or AI prose.** It carries field names,
/// type names, limit numbers and enum names only. This is the same discipline
/// the network `logging_interceptor` applies to request bodies: the shape of
/// the problem is diagnostic, the content is not ours to log.
final class AiUiDiagnostic extends Equatable {
  AiUiDiagnostic({
    required this.code,
    required this.path,
    this.nodeType,
    String? detail,
  }) : detail = _cap(detail);

  static const int maxDetailLength = 120;

  final AiUiDiagnosticCode code;

  /// Where in the document, e.g. `blocks[0].children[2]`.
  final String path;

  /// The wire `type` string of the offending node, when there is one.
  final String? nodeType;

  final String? detail;

  static String? _cap(String? value) {
    if (value == null) return null;
    return value.length <= maxDetailLength
        ? value
        : '${value.substring(0, maxDetailLength)}…';
  }

  @override
  String toString() =>
      'AiUiDiagnostic(${code.wire} at $path'
      '${nodeType != null ? ', type=$nodeType' : ''}'
      '${detail != null ? ', $detail' : ''})';

  @override
  List<Object?> get props => [code, path, nodeType, detail];
}
