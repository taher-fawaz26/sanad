import 'dart:convert';

import 'package:ai_ui_protocol/src/domain/ai_ui_node_type.dart';
import 'package:ai_ui_protocol/src/domain/interaction/ai_ui_interaction.dart';
import 'package:ai_ui_protocol/src/domain/interaction/ai_ui_interaction_value.dart';
import 'package:ai_ui_protocol/src/validation/ai_ui_limits.dart';

/// Serialises and parses [AiUiInteraction].
///
/// **Total in both directions.** No input makes any method here throw:
/// encoding clamps over-long prose rather than refusing, and decoding returns
/// `null` for anything it cannot make sense of. That mirrors `AiUiCodec` and
/// `AiChatEventCodec` — a malformed frame is a dropped frame, never an
/// exception crossing a transport boundary.
///
/// Decoding exists because the mock transports *consume* interactions: the
/// mock agent has to read the user's answer to script a continuation, which is
/// what proves the loop closes without a backend. A production client only
/// ever encodes.
abstract final class AiUiInteractionCodec {
  AiUiInteractionCodec._();

  /// The wire object for [interaction], with prose clamped to
  /// [AiUiLimits.maxInteractionTextLength].
  static Map<String, dynamic> encodeMap(
    AiUiInteraction interaction, {
    AiUiLimits limits = AiUiLimits.defaults,
  }) => _clamp(interaction, limits).toJson();

  /// [encodeMap], JSON-encoded.
  static String encode(
    AiUiInteraction interaction, {
    AiUiLimits limits = AiUiLimits.defaults,
  }) => jsonEncode(encodeMap(interaction, limits: limits));

  /// Parses a raw JSON string. Returns `null` when it is not an interaction.
  static AiUiInteraction? tryDecode(
    String raw, {
    AiUiLimits limits = AiUiLimits.defaults,
  }) {
    if (raw.length > limits.maxPayloadBytes) return null;
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      return null;
    }
    if (decoded is! Map<String, dynamic>) return null;
    return tryDecodeMap(decoded, limits: limits);
  }

  /// Parses an already-decoded object. Returns `null` when a required field is
  /// missing or names something outside the catalog — an unknown `kind` is a
  /// result this build cannot reason about, and guessing would be worse than
  /// ignoring it.
  static AiUiInteraction? tryDecodeMap(
    Map<String, dynamic> json, {
    AiUiLimits limits = AiUiLimits.defaults,
  }) {
    final interactionId = _string(json['interactionId']);
    final nodeId = _string(json['nodeId']);
    final kindWire = _string(json['kind']);
    if (interactionId == null || nodeId == null || kindWire == null) {
      return null;
    }

    final kind = AiUiInteractionKind.tryFromWire(kindWire);
    if (kind == null) return null;

    final statusWire = _string(json['status']);
    // An absent status means the common case. An *unknown* one does not
    // degrade to `submitted`: "the user answered" is the reading with
    // consequences, so an unreadable status is dropped instead of assumed.
    final AiUiInteractionStatus status;
    if (statusWire == null) {
      status = AiUiInteractionStatus.submitted;
    } else {
      final parsed = AiUiInteractionStatus.tryFromWire(statusWire);
      if (parsed == null) return null;
      status = parsed;
    }

    final rawValue = json['value'];
    final value = rawValue is Map<String, dynamic>
        ? _value(kind, rawValue)
        : const AiUiEmptyValue();

    final nodeTypeWire = _string(json['nodeType']);
    final createdAtRaw = _string(json['createdAt']);

    return _clamp(
      AiUiInteraction(
        interactionId: interactionId,
        nodeId: nodeId,
        kind: kind,
        value: value,
        nodeType: nodeTypeWire == null
            ? null
            : AiUiNodeType.tryFromWire(nodeTypeWire),
        messageId: _string(json['messageId']),
        status: status,
        text: _string(json['text']),
        createdAt: createdAtRaw == null
            ? null
            : DateTime.tryParse(createdAtRaw)?.toUtc(),
      ),
      limits,
    );
  }

  /// The value shape is implied by [kind], so it carries no discriminator of
  /// its own. A shape that does not fit degrades to [AiUiEmptyValue] rather
  /// than dropping the whole result: knowing *that* the user answered is worth
  /// more than the payload it came with.
  static AiUiInteractionValue _value(
    AiUiInteractionKind kind,
    Map<String, dynamic> json,
  ) {
    switch (kind) {
      case AiUiInteractionKind.quickReplySelected:
      case AiUiInteractionKind.slotSelected:
        final label = _string(json['label']);
        if (label == null) return const AiUiEmptyValue();
        return AiUiSelectionValue(label: label, id: _string(json['id']));

      case AiUiInteractionKind.reviewSubmitted:
        final text = _string(json['text']);
        return text == null ? const AiUiEmptyValue() : AiUiTextValue(text);

      case AiUiInteractionKind.locationSelected:
      case AiUiInteractionKind.locationConfirmed:
        final name = _string(json['name']);
        if (name == null) return const AiUiEmptyValue();
        final sourceWire = _string(json['source']);
        return AiUiLocationValue(
          name: name,
          source: sourceWire == null
              ? AiUiLocationSource.typed
              : AiUiLocationSource.tryFromWire(sourceWire) ??
                    AiUiLocationSource.typed,
          id: _string(json['id']),
          addressText: _string(json['addressText']),
        );

      case AiUiInteractionKind.permissionResult:
        final permission = _string(json['permission']);
        final outcomeWire = _string(json['outcome']);
        if (permission == null || outcomeWire == null) {
          return const AiUiEmptyValue();
        }
        final outcome = AiUiPermissionOutcome.tryFromWire(outcomeWire);
        if (outcome == null) return const AiUiEmptyValue();
        return AiUiPermissionValue(permission: permission, outcome: outcome);

      case AiUiInteractionKind.mediaResult:
        final count = json['count'];
        if (count is! int) return const AiUiEmptyValue();
        return AiUiMediaValue(count: count, source: _string(json['source']));
    }
  }

  /// Clamps every free-text field to the limit.
  ///
  /// A backstop rather than the primary guard — the renderer caps what a user
  /// can type — but it is the only point every path goes through, so an
  /// unbounded search query cannot become an unbounded request body.
  static AiUiInteraction _clamp(
    AiUiInteraction interaction,
    AiUiLimits limits,
  ) {
    final max = limits.maxInteractionTextLength;
    final text = _truncate(interaction.text, max);
    final value = switch (interaction.value) {
      final AiUiTextValue v when v.text.length > max => AiUiTextValue(
        v.text.substring(0, max),
      ),
      final AiUiLocationValue v when v.name.length > max => AiUiLocationValue(
        name: v.name.substring(0, max),
        source: v.source,
        id: v.id,
        addressText: v.addressText,
      ),
      final AiUiInteractionValue v => v,
    };

    if (identical(value, interaction.value) && text == interaction.text) {
      return interaction;
    }

    return AiUiInteraction(
      interactionId: interaction.interactionId,
      nodeId: interaction.nodeId,
      kind: interaction.kind,
      value: value,
      nodeType: interaction.nodeType,
      messageId: interaction.messageId,
      status: interaction.status,
      text: text,
      createdAt: interaction.createdAt,
    );
  }

  static String? _truncate(String? value, int max) {
    if (value == null || value.length <= max) return value;
    return value.substring(0, max);
  }

  static String? _string(Object? value) {
    if (value is! String) return null;
    return value.isEmpty ? null : value;
  }
}
