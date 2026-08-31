import 'package:ai_ui_protocol/src/diagnostics/ai_ui_diagnostic.dart';
import 'package:ai_ui_protocol/src/domain/ai_ui_action.dart';
import 'package:ai_ui_protocol/src/domain/ai_ui_document.dart';
import 'package:ai_ui_protocol/src/domain/ai_ui_enums.dart';
import 'package:ai_ui_protocol/src/domain/ai_ui_node.dart';
import 'package:ai_ui_protocol/src/domain/ai_ui_node_type.dart';
import 'package:ai_ui_protocol/src/domain/ai_ui_values.dart';
import 'package:ai_ui_protocol/src/validation/ai_ui_codec.dart';
import 'package:ai_ui_protocol/src/validation/ai_ui_limits.dart';
import 'package:ai_ui_protocol/src/validation/ai_ui_parse_result.dart';
import 'package:ai_ui_protocol/src/validation/ai_ui_url_policy.dart';
import 'package:equatable/equatable.dart';

/// Host-specific knobs on validation behaviour.
final class AiUiValidatorOptions extends Equatable {
  const AiUiValidatorOptions({this.keepUnsupportedNodes = false});

  /// When set, a node type this client does not recognise (and which carried
  /// no `fallbackText`) survives as an [AiUiUnsupportedNode] so a developer
  /// can see what the agent sent. Callers pass `!kReleaseMode`; in release the
  /// node is dropped and users see nothing.
  final bool keepUnsupportedNodes;

  @override
  List<Object?> get props => [keepUnsupportedNodes];
}

/// Turns an untrusted AI payload into a typed, bounded, renderable document —
/// or into nothing, with an explanation.
///
/// The whole class is total: there is no input for which any public method
/// throws. That is the point. `.claude`-level rule for this feature is that a
/// malformed payload degrades the bubble, never the chat, and the cheapest way
/// to guarantee it is to make invalid states unrepresentable *before* the
/// widget layer rather than defending inside every renderer.
final class AiUiValidator {
  const AiUiValidator({
    this.limits = AiUiLimits.defaults,
    this.urlPolicy = AiUiUrlPolicy.denyAll,
    this.supportedActions,
    this.knownAssetIds,
    this.options = const AiUiValidatorOptions(),
  });

  final AiUiLimits limits;
  final AiUiUrlPolicy urlPolicy;

  /// The actions this host's registry actually implements. `null` means "the
  /// whole protocol catalog" — useful in protocol tests, wrong in an app,
  /// where it should be the registry's real key set so an action with no
  /// handler never reaches a button.
  final Set<AiUiActionType>? supportedActions;

  /// Asset ids this host publishes. `null` skips the check — the protocol
  /// package has no asset knowledge of its own.
  final Set<String>? knownAssetIds;

  final AiUiValidatorOptions options;

  /// Decode + validate in one step. The normal entry point.
  AiUiParseResult parse(String raw) {
    final decoded = AiUiCodec.decode(raw, limits: limits);
    return switch (decoded) {
      AiUiDecodeFailure(:final diagnostic) => AiUiParseResult.rejected([
        diagnostic,
      ]),
      AiUiDecodeSuccess(:final json) => validate(json),
    };
  }

  /// Validate an already-decoded payload.
  AiUiParseResult validate(Map<String, dynamic> json) {
    final run = _Run(
      limits: limits,
      urlPolicy: urlPolicy,
      supportedActions: supportedActions ?? AiUiActionType.all,
      knownAssetIds: knownAssetIds,
      options: options,
    );

    final rawVersion = json['schemaVersion'];
    if (rawVersion is! int) {
      run.add(
        AiUiDiagnosticCode.unsupportedSchemaVersion,
        r'$',
        detail: rawVersion == null
            ? 'schemaVersion missing'
            : 'schemaVersion is ${rawVersion.runtimeType}, expected int',
      );
      return AiUiParseResult.rejected(run.diagnostics);
    }
    if (!AiUiDocument.supportedSchemaVersions.contains(rawVersion)) {
      run.add(
        AiUiDiagnosticCode.unsupportedSchemaVersion,
        r'$',
        detail:
            'schemaVersion $rawVersion, '
            'supported ${AiUiDocument.supportedSchemaVersions.join(",")}',
      );
      return AiUiParseResult.rejected(run.diagnostics);
    }

    final rawBlocks = json['blocks'];
    if (rawBlocks is! List) {
      run.add(
        AiUiDiagnosticCode.malformedPayload,
        r'$.blocks',
        detail: rawBlocks == null
            ? 'blocks missing'
            : 'blocks is ${rawBlocks.runtimeType}, expected array',
      );
      return AiUiParseResult.rejected(run.diagnostics);
    }

    var entries = rawBlocks;
    if (entries.length > limits.maxBlocks) {
      run.add(
        AiUiDiagnosticCode.limitExceeded,
        r'$.blocks',
        detail: '${entries.length} blocks > ${limits.maxBlocks}, truncated',
      );
      entries = entries.sublist(0, limits.maxBlocks);
    }

    final blocks = <AiUiNode>[];
    for (var i = 0; i < entries.length; i++) {
      final node = run.node(entries[i], 'blocks[$i]', 1);
      if (run.aborted) return AiUiParseResult.rejected(run.diagnostics);
      if (node != null) blocks.add(node);
    }

    return AiUiParseResult(
      document: AiUiDocument(schemaVersion: rawVersion, blocks: blocks),
      diagnostics: run.diagnostics,
    );
  }
}

/// Mutable bookkeeping for one validation pass.
///
/// Split from [AiUiValidator] so the validator itself stays immutable and
/// shareable, while counters (nodes, actions, images) and the diagnostics list
/// live for exactly one payload.
class _Run {
  _Run({
    required this.limits,
    required this.urlPolicy,
    required this.supportedActions,
    required this.knownAssetIds,
    required this.options,
  });

  final AiUiLimits limits;
  final AiUiUrlPolicy urlPolicy;
  final Set<AiUiActionType> supportedActions;
  final Set<String>? knownAssetIds;
  final AiUiValidatorOptions options;

  final List<AiUiDiagnostic> diagnostics = [];
  int nodeCount = 0;
  int actionCount = 0;
  int imageCount = 0;

  /// Set when the payload as a whole is not worth walking further.
  bool aborted = false;

  static const Set<String> _baseKeys = {
    'type',
    'id',
    'a11yLabel',
    'fallbackText',
  };

  /// Fields accepted by a future protocol version but rejected in v1, so the
  /// agent gets a clear signal rather than silent no-ops.
  static const Set<String> _reservedKeys = {'textKey', 'textArgs'};

  void add(
    AiUiDiagnosticCode code,
    String path, {
    String? nodeType,
    String? detail,
  }) {
    diagnostics.add(
      AiUiDiagnostic(
        code: code,
        path: path,
        nodeType: nodeType,
        detail: detail,
      ),
    );
  }

  // ── Node dispatch ─────────────────────────────────────────────────────────

  AiUiNode? node(Object? raw, String path, int depth) {
    if (aborted) return null;

    if (raw is! Map<String, dynamic>) {
      add(
        AiUiDiagnosticCode.malformedPayload,
        path,
        detail: 'node is ${raw.runtimeType}, expected object',
      );
      return null;
    }

    if (depth > limits.maxDepth) {
      add(
        AiUiDiagnosticCode.limitExceeded,
        path,
        detail: 'depth $depth > ${limits.maxDepth}',
      );
      return null;
    }

    nodeCount++;
    if (nodeCount > limits.maxNodes) {
      add(
        AiUiDiagnosticCode.limitExceeded,
        path,
        detail: 'node count > ${limits.maxNodes}, payload rejected',
      );
      aborted = true;
      return null;
    }

    final rawType = raw['type'];
    if (rawType is! String || rawType.isEmpty) {
      add(
        AiUiDiagnosticCode.missingRequiredProperty,
        path,
        detail: 'type missing or not a string',
      );
      return null;
    }

    for (final reserved in _reservedKeys) {
      if (raw.containsKey(reserved)) {
        add(
          AiUiDiagnosticCode.reservedProperty,
          path,
          nodeType: rawType,
          detail: '$reserved is reserved for a future schemaVersion',
        );
      }
    }

    final id = _idFor(raw, path);
    final a11yLabel = _optionalString(raw, 'a11yLabel', path, rawType);
    final fallbackText = _optionalString(raw, 'fallbackText', path, rawType);

    final type = AiUiNodeType.tryFromWire(rawType);
    if (type == null) {
      return _degrade(
        path: path,
        rawType: rawType,
        id: id,
        a11yLabel: a11yLabel,
        fallbackText: fallbackText,
      );
    }

    return switch (type) {
      AiUiNodeType.text => _text(raw, path, id, a11yLabel, fallbackText),
      AiUiNodeType.richText => _richText(
        raw,
        path,
        id,
        a11yLabel,
        fallbackText,
      ),
      AiUiNodeType.icon => _icon(raw, path, id, a11yLabel, fallbackText),
      AiUiNodeType.image => _image(raw, path, id, a11yLabel, fallbackText),
      AiUiNodeType.divider => _divider(raw, path, id, a11yLabel, fallbackText),
      AiUiNodeType.spacer => _spacer(raw, path, id, a11yLabel, fallbackText),
      AiUiNodeType.row => _row(raw, path, depth, id, a11yLabel, fallbackText),
      AiUiNodeType.column => _column(
        raw,
        path,
        depth,
        id,
        a11yLabel,
        fallbackText,
      ),
      AiUiNodeType.card => _card(raw, path, depth, id, a11yLabel, fallbackText),
      AiUiNodeType.button => _button(raw, path, id, a11yLabel, fallbackText),
      AiUiNodeType.chip => _chip(raw, path, id, a11yLabel, fallbackText),
      AiUiNodeType.list => _list(raw, path, depth, id, a11yLabel, fallbackText),
      AiUiNodeType.listItem => _listItem(
        raw,
        path,
        id,
        a11yLabel,
        fallbackText,
      ),
      AiUiNodeType.progress => _progress(
        raw,
        path,
        id,
        a11yLabel,
        fallbackText,
      ),
      AiUiNodeType.loading => _loading(raw, path, id, a11yLabel, fallbackText),
      AiUiNodeType.serviceCard => _serviceCard(
        raw,
        path,
        id,
        a11yLabel,
        fallbackText,
      ),
      AiUiNodeType.appointmentCard => _appointmentCard(
        raw,
        path,
        id,
        a11yLabel,
        fallbackText,
      ),
      AiUiNodeType.branchCard => _branchCard(
        raw,
        path,
        id,
        a11yLabel,
        fallbackText,
      ),
      AiUiNodeType.documentCard => _documentCard(
        raw,
        path,
        id,
        a11yLabel,
        fallbackText,
      ),
      AiUiNodeType.quickReply => _quickReply(
        raw,
        path,
        id,
        a11yLabel,
        fallbackText,
      ),
    };
  }

  /// An unrecognised node type: render its `fallbackText` as plain text,
  /// otherwise drop it (or keep a dev-only marker).
  AiUiNode? _degrade({
    required String path,
    required String rawType,
    required String id,
    required String? a11yLabel,
    required String? fallbackText,
  }) {
    add(
      AiUiDiagnosticCode.unknownNodeType,
      path,
      nodeType: rawType,
      detail: fallbackText != null ? 'using fallbackText' : 'no fallbackText',
    );

    if (fallbackText != null && fallbackText.isNotEmpty) {
      return AiUiTextNode(id: id, text: fallbackText, a11yLabel: a11yLabel);
    }
    if (options.keepUnsupportedNodes) {
      return AiUiUnsupportedNode(
        id: id,
        rawType: rawType,
        a11yLabel: a11yLabel,
      );
    }
    return null;
  }

  // ── Primitive parsers ─────────────────────────────────────────────────────

  AiUiNode? _text(
    Map<String, dynamic> json,
    String path,
    String id,
    String? a11yLabel,
    String? fallbackText,
  ) {
    const wire = 'text';
    _unknownKeys(json, path, wire, const {
      'text',
      'style',
      'emphasis',
      'align',
      'direction',
      'maxLines',
    });

    final text = _requiredString(
      json,
      'text',
      path,
      wire,
      maxLength: limits.maxTextLength,
    );
    if (text == null) return null;

    return AiUiTextNode(
      id: id,
      text: text,
      style: _enum(
        json,
        'style',
        path,
        wire,
        AiUiTextStyleToken.tryFromWire,
        AiUiTextStyleToken.body,
      ),
      emphasis: _enum(
        json,
        'emphasis',
        path,
        wire,
        AiUiEmphasis.tryFromWire,
        AiUiEmphasis.normal,
      ),
      align: _enum(
        json,
        'align',
        path,
        wire,
        AiUiMainAxisAlign.tryFromWire,
        AiUiMainAxisAlign.start,
      ),
      direction: _enum(
        json,
        'direction',
        path,
        wire,
        AiUiTextDirectionHint.tryFromWire,
        AiUiTextDirectionHint.auto,
      ),
      maxLines: _boundedInt(json, 'maxLines', path, wire, 1, limits.maxLines),
      a11yLabel: a11yLabel,
      fallbackText: fallbackText,
    );
  }

  AiUiNode? _richText(
    Map<String, dynamic> json,
    String path,
    String id,
    String? a11yLabel,
    String? fallbackText,
  ) {
    const wire = 'rich_text';
    _unknownKeys(json, path, wire, const {'spans', 'align'});

    final rawSpans = json['spans'];
    if (rawSpans is! List || rawSpans.isEmpty) {
      add(
        AiUiDiagnosticCode.missingRequiredProperty,
        path,
        nodeType: wire,
        detail: 'spans missing or empty',
      );
      return null;
    }

    var entries = rawSpans;
    if (entries.length > limits.maxRichTextSpans) {
      add(
        AiUiDiagnosticCode.limitExceeded,
        '$path.spans',
        nodeType: wire,
        detail:
            '${entries.length} spans > ${limits.maxRichTextSpans}, '
            'truncated',
      );
      entries = entries.sublist(0, limits.maxRichTextSpans);
    }

    final spans = <AiUiRichSpan>[];
    for (var i = 0; i < entries.length; i++) {
      final spanPath = '$path.spans[$i]';
      final entry = entries[i];
      if (entry is! Map<String, dynamic>) {
        add(
          AiUiDiagnosticCode.invalidProperty,
          spanPath,
          nodeType: wire,
          detail: 'span is ${entry.runtimeType}, expected object',
        );
        continue;
      }
      final text = _requiredString(
        entry,
        'text',
        spanPath,
        wire,
        maxLength: limits.maxTextLength,
      );
      if (text == null) continue;
      spans.add(
        AiUiRichSpan(
          text: text,
          emphasis: _enum(
            entry,
            'emphasis',
            spanPath,
            wire,
            AiUiEmphasis.tryFromWire,
            AiUiEmphasis.normal,
          ),
          action: entry.containsKey('action')
              ? action(entry['action'], '$spanPath.action', wire)
              : null,
        ),
      );
    }

    if (spans.isEmpty) return null;

    return AiUiRichTextNode(
      id: id,
      spans: spans,
      align: _enum(
        json,
        'align',
        path,
        wire,
        AiUiMainAxisAlign.tryFromWire,
        AiUiMainAxisAlign.start,
      ),
      a11yLabel: a11yLabel,
      fallbackText: fallbackText,
    );
  }

  AiUiNode? _icon(
    Map<String, dynamic> json,
    String path,
    String id,
    String? a11yLabel,
    String? fallbackText,
  ) {
    const wire = 'icon';
    _unknownKeys(json, path, wire, const {'name', 'size', 'tone'});

    final name = _requiredString(json, 'name', path, wire, maxLength: 120);
    if (name == null) return null;

    return AiUiIconNode(
      id: id,
      name: name,
      size: _enum(
        json,
        'size',
        path,
        wire,
        AiUiIconSize.tryFromWire,
        AiUiIconSize.md,
      ),
      tone: _enum(
        json,
        'tone',
        path,
        wire,
        AiUiTone.tryFromWire,
        AiUiTone.neutral,
      ),
      a11yLabel: a11yLabel,
      fallbackText: fallbackText,
    );
  }

  AiUiNode? _image(
    Map<String, dynamic> json,
    String path,
    String id,
    String? a11yLabel,
    String? fallbackText,
  ) {
    const wire = 'image';
    _unknownKeys(json, path, wire, const {
      'assetId',
      'url',
      'alt',
      'aspect',
      'fit',
    });

    final alt = _requiredString(
      json,
      'alt',
      path,
      wire,
      maxLength: limits.maxLabelLength,
    );
    if (alt == null) return null;

    final source = imageSource(json, path, wire);
    if (source == null) return null;

    return AiUiImageNode(
      id: id,
      source: source,
      alt: alt,
      aspect: _enum(
        json,
        'aspect',
        path,
        wire,
        AiUiImageAspect.tryFromWire,
        AiUiImageAspect.wide,
      ),
      fit: _enum(
        json,
        'fit',
        path,
        wire,
        AiUiImageFit.tryFromWire,
        AiUiImageFit.cover,
      ),
      a11yLabel: a11yLabel,
      fallbackText: fallbackText,
    );
  }

  AiUiNode _divider(
    Map<String, dynamic> json,
    String path,
    String id,
    String? a11yLabel,
    String? fallbackText,
  ) {
    const wire = 'divider';
    _unknownKeys(json, path, wire, const {'spacing'});
    return AiUiDividerNode(
      id: id,
      spacing: _enum(
        json,
        'spacing',
        path,
        wire,
        AiUiSpacingStep.tryFromWire,
        AiUiSpacingStep.md,
      ),
      a11yLabel: a11yLabel,
      fallbackText: fallbackText,
    );
  }

  AiUiNode _spacer(
    Map<String, dynamic> json,
    String path,
    String id,
    String? a11yLabel,
    String? fallbackText,
  ) {
    const wire = 'spacer';
    _unknownKeys(json, path, wire, const {'size'});
    return AiUiSpacerNode(
      id: id,
      size: _enum(
        json,
        'size',
        path,
        wire,
        AiUiSpacingStep.tryFromWire,
        AiUiSpacingStep.md,
      ),
      a11yLabel: a11yLabel,
      fallbackText: fallbackText,
    );
  }

  AiUiNode? _row(
    Map<String, dynamic> json,
    String path,
    int depth,
    String id,
    String? a11yLabel,
    String? fallbackText,
  ) {
    const wire = 'row';
    _unknownKeys(json, path, wire, const {
      'children',
      'align',
      'crossAlign',
      'gap',
      'wrap',
    });

    final kids = children(json, path, depth, AiUiNodeType.row, wire);
    if (aborted || kids.isEmpty) return null;

    return AiUiRowNode(
      id: id,
      children: kids,
      align: _enum(
        json,
        'align',
        path,
        wire,
        AiUiMainAxisAlign.tryFromWire,
        AiUiMainAxisAlign.start,
      ),
      crossAlign: _enum(
        json,
        'crossAlign',
        path,
        wire,
        AiUiCrossAxisAlign.tryFromWire,
        AiUiCrossAxisAlign.center,
      ),
      gap: _enum(
        json,
        'gap',
        path,
        wire,
        AiUiSpacingStep.tryFromWire,
        AiUiSpacingStep.sm,
      ),
      wrap: _bool(json, 'wrap', path, wire, defaultValue: false),
      a11yLabel: a11yLabel,
      fallbackText: fallbackText,
    );
  }

  AiUiNode? _column(
    Map<String, dynamic> json,
    String path,
    int depth,
    String id,
    String? a11yLabel,
    String? fallbackText,
  ) {
    const wire = 'column';
    _unknownKeys(json, path, wire, const {'children', 'align', 'gap'});

    final kids = children(json, path, depth, AiUiNodeType.column, wire);
    if (aborted || kids.isEmpty) return null;

    return AiUiColumnNode(
      id: id,
      children: kids,
      align: _enum(
        json,
        'align',
        path,
        wire,
        AiUiCrossAxisAlign.tryFromWire,
        AiUiCrossAxisAlign.start,
      ),
      gap: _enum(
        json,
        'gap',
        path,
        wire,
        AiUiSpacingStep.tryFromWire,
        AiUiSpacingStep.sm,
      ),
      a11yLabel: a11yLabel,
      fallbackText: fallbackText,
    );
  }

  AiUiNode? _card(
    Map<String, dynamic> json,
    String path,
    int depth,
    String id,
    String? a11yLabel,
    String? fallbackText,
  ) {
    const wire = 'card';
    _unknownKeys(json, path, wire, const {
      'children',
      'title',
      'tone',
      'action',
    });

    final kids = children(json, path, depth, AiUiNodeType.card, wire);
    if (aborted) return null;

    return AiUiCardNode(
      id: id,
      children: kids,
      title: _optionalString(
        json,
        'title',
        path,
        wire,
        maxLength: limits.maxLabelLength,
      ),
      tone: _enum(
        json,
        'tone',
        path,
        wire,
        AiUiTone.tryFromWire,
        AiUiTone.neutral,
      ),
      action: json.containsKey('action')
          ? action(json['action'], '$path.action', wire)
          : null,
      a11yLabel: a11yLabel,
      fallbackText: fallbackText,
    );
  }

  AiUiNode? _button(
    Map<String, dynamic> json,
    String path,
    String id,
    String? a11yLabel,
    String? fallbackText,
  ) {
    const wire = 'button';
    _unknownKeys(json, path, wire, const {
      'label',
      'action',
      'variant',
      'intent',
      'size',
      'icon',
      'enabled',
    });

    final label = _requiredString(
      json,
      'label',
      path,
      wire,
      maxLength: limits.maxLabelLength,
    );
    if (label == null) return null;

    // A button whose action we cannot honour is a dead control. Dropping the
    // whole node is better UX than rendering something that does nothing.
    final resolved = action(json['action'], '$path.action', wire);
    if (resolved == null) return null;

    return AiUiButtonNode(
      id: id,
      label: label,
      action: resolved,
      variant: _enum(
        json,
        'variant',
        path,
        wire,
        AiUiButtonVariant.tryFromWire,
        AiUiButtonVariant.primary,
      ),
      intent: _enum(
        json,
        'intent',
        path,
        wire,
        AiUiButtonIntent.tryFromWire,
        AiUiButtonIntent.standard,
      ),
      size: _enum(
        json,
        'size',
        path,
        wire,
        AiUiButtonSize.tryFromWire,
        AiUiButtonSize.block,
      ),
      icon: _optionalString(json, 'icon', path, wire, maxLength: 120),
      enabled: _bool(json, 'enabled', path, wire, defaultValue: true),
      a11yLabel: a11yLabel,
      fallbackText: fallbackText,
    );
  }

  AiUiNode? _chip(
    Map<String, dynamic> json,
    String path,
    String id,
    String? a11yLabel,
    String? fallbackText,
  ) {
    const wire = 'chip';
    _unknownKeys(json, path, wire, const {
      'label',
      'action',
      'selected',
      'tone',
      'icon',
    });

    final label = _requiredString(
      json,
      'label',
      path,
      wire,
      maxLength: limits.maxChipLabelLength,
    );
    if (label == null) return null;

    AiUiAction? resolved;
    if (json.containsKey('action')) {
      resolved = action(json['action'], '$path.action', wire);
      // Unlike a button, a chip is legible as a static label, so an
      // unresolvable action downgrades it rather than dropping it.
    }

    return AiUiChipNode(
      id: id,
      label: label,
      action: resolved,
      selected: _bool(json, 'selected', path, wire, defaultValue: false),
      tone: _enum(
        json,
        'tone',
        path,
        wire,
        AiUiTone.tryFromWire,
        AiUiTone.neutral,
      ),
      icon: _optionalString(json, 'icon', path, wire, maxLength: 120),
      a11yLabel: a11yLabel,
      fallbackText: fallbackText,
    );
  }

  AiUiNode? _list(
    Map<String, dynamic> json,
    String path,
    int depth,
    String id,
    String? a11yLabel,
    String? fallbackText,
  ) {
    const wire = 'list';
    _unknownKeys(json, path, wire, const {
      'children',
      'variant',
      'emptyText',
    });

    final kids = children(json, path, depth, AiUiNodeType.list, wire);
    if (aborted) return null;

    final items = <AiUiListItemNode>[];
    for (final child in kids) {
      if (child is AiUiListItemNode) {
        items.add(child);
      } else {
        add(
          AiUiDiagnosticCode.invalidProperty,
          '$path.children',
          nodeType: wire,
          detail: 'child ${child.type?.wire ?? "unknown"} is not list_item',
        );
      }
    }

    if (items.isEmpty) return null;

    return AiUiListNode(
      id: id,
      children: items,
      variant: _enum(
        json,
        'variant',
        path,
        wire,
        AiUiListVariant.tryFromWire,
        AiUiListVariant.plain,
      ),
      emptyText: _optionalString(
        json,
        'emptyText',
        path,
        wire,
        maxLength: limits.maxLabelLength,
      ),
      a11yLabel: a11yLabel,
      fallbackText: fallbackText,
    );
  }

  AiUiNode? _listItem(
    Map<String, dynamic> json,
    String path,
    String id,
    String? a11yLabel,
    String? fallbackText,
  ) {
    const wire = 'list_item';
    _unknownKeys(json, path, wire, const {
      'title',
      'subtitle',
      'leadingIcon',
      'leadingImage',
      'badge',
      'trailingText',
      'action',
    });

    final title = _requiredString(
      json,
      'title',
      path,
      wire,
      maxLength: limits.maxLabelLength,
    );
    if (title == null) return null;

    return AiUiListItemNode(
      id: id,
      title: title,
      subtitle: _optionalString(
        json,
        'subtitle',
        path,
        wire,
        maxLength: limits.maxTextLength,
      ),
      leadingIcon: _optionalString(
        json,
        'leadingIcon',
        path,
        wire,
        maxLength: 120,
      ),
      leadingImage: _nestedImage(json, 'leadingImage', path, wire),
      badge: _badge(json, 'badge', path, wire),
      trailingText: _optionalString(
        json,
        'trailingText',
        path,
        wire,
        maxLength: limits.maxLabelLength,
      ),
      action: json.containsKey('action')
          ? action(json['action'], '$path.action', wire)
          : null,
      a11yLabel: a11yLabel,
      fallbackText: fallbackText,
    );
  }

  AiUiNode _progress(
    Map<String, dynamic> json,
    String path,
    String id,
    String? a11yLabel,
    String? fallbackText,
  ) {
    const wire = 'progress';
    _unknownKeys(json, path, wire, const {'value', 'label'});

    double? value;
    final raw = json['value'];
    if (raw != null) {
      if (raw is num) {
        value = raw.toDouble().clamp(0, 1);
      } else {
        add(
          AiUiDiagnosticCode.invalidProperty,
          path,
          nodeType: wire,
          detail: 'value is ${raw.runtimeType}, expected number',
        );
      }
    }

    return AiUiProgressNode(
      id: id,
      value: value,
      label: _optionalString(
        json,
        'label',
        path,
        wire,
        maxLength: limits.maxLabelLength,
      ),
      a11yLabel: a11yLabel,
      fallbackText: fallbackText,
    );
  }

  AiUiNode _loading(
    Map<String, dynamic> json,
    String path,
    String id,
    String? a11yLabel,
    String? fallbackText,
  ) {
    const wire = 'loading';
    _unknownKeys(json, path, wire, const {'label'});
    return AiUiLoadingNode(
      id: id,
      label: _optionalString(
        json,
        'label',
        path,
        wire,
        maxLength: limits.maxLabelLength,
      ),
      a11yLabel: a11yLabel,
      fallbackText: fallbackText,
    );
  }

  // ── Semantic parsers ──────────────────────────────────────────────────────

  AiUiNode? _serviceCard(
    Map<String, dynamic> json,
    String path,
    String id,
    String? a11yLabel,
    String? fallbackText,
  ) {
    const wire = 'service_card';
    _unknownKeys(json, path, wire, const {
      'serviceId',
      'title',
      'subtitle',
      'price',
      'ratingValue',
      'image',
      'badge',
      'action',
    });

    final serviceId = _requiredString(json, 'serviceId', path, wire);
    final title = _requiredString(
      json,
      'title',
      path,
      wire,
      maxLength: limits.maxLabelLength,
    );
    if (serviceId == null || title == null) return null;

    return AiUiServiceCardNode(
      id: id,
      serviceId: serviceId,
      title: title,
      subtitle: _optionalString(
        json,
        'subtitle',
        path,
        wire,
        maxLength: limits.maxTextLength,
      ),
      price: _money(json, 'price', path, wire),
      ratingValue: _boundedDouble(json, 'ratingValue', path, wire, 0, 5),
      image: _nestedImage(json, 'image', path, wire),
      badge: _badge(json, 'badge', path, wire),
      action: json.containsKey('action')
          ? action(json['action'], '$path.action', wire)
          : null,
      a11yLabel: a11yLabel,
      fallbackText: fallbackText,
    );
  }

  AiUiNode? _appointmentCard(
    Map<String, dynamic> json,
    String path,
    String id,
    String? a11yLabel,
    String? fallbackText,
  ) {
    const wire = 'appointment_card';
    _unknownKeys(json, path, wire, const {
      'appointmentId',
      'title',
      'startsAt',
      'whereText',
      'status',
      'statusTone',
      'action',
    });

    final appointmentId = _requiredString(json, 'appointmentId', path, wire);
    final title = _requiredString(
      json,
      'title',
      path,
      wire,
      maxLength: limits.maxLabelLength,
    );
    final startsAt = _instant(json, 'startsAt', path, wire);
    if (appointmentId == null || title == null || startsAt == null) return null;

    return AiUiAppointmentCardNode(
      id: id,
      appointmentId: appointmentId,
      title: title,
      startsAt: startsAt,
      whereText: _optionalString(
        json,
        'whereText',
        path,
        wire,
        maxLength: limits.maxTextLength,
      ),
      status: _optionalString(
        json,
        'status',
        path,
        wire,
        maxLength: limits.maxChipLabelLength,
      ),
      statusTone: _enum(
        json,
        'statusTone',
        path,
        wire,
        AiUiTone.tryFromWire,
        AiUiTone.neutral,
      ),
      action: json.containsKey('action')
          ? action(json['action'], '$path.action', wire)
          : null,
      a11yLabel: a11yLabel,
      fallbackText: fallbackText,
    );
  }

  AiUiNode? _branchCard(
    Map<String, dynamic> json,
    String path,
    String id,
    String? a11yLabel,
    String? fallbackText,
  ) {
    const wire = 'branch_card';
    _unknownKeys(json, path, wire, const {
      'branchId',
      'name',
      'addressText',
      'distanceMeters',
      'status',
      'statusTone',
      'action',
    });

    final branchId = _requiredString(json, 'branchId', path, wire);
    final name = _requiredString(
      json,
      'name',
      path,
      wire,
      maxLength: limits.maxLabelLength,
    );
    if (branchId == null || name == null) return null;

    return AiUiBranchCardNode(
      id: id,
      branchId: branchId,
      name: name,
      addressText: _optionalString(
        json,
        'addressText',
        path,
        wire,
        maxLength: limits.maxTextLength,
      ),
      distanceMeters: _boundedDouble(
        json,
        'distanceMeters',
        path,
        wire,
        0,
        40000000,
      ),
      status: _optionalString(
        json,
        'status',
        path,
        wire,
        maxLength: limits.maxChipLabelLength,
      ),
      statusTone: _enum(
        json,
        'statusTone',
        path,
        wire,
        AiUiTone.tryFromWire,
        AiUiTone.neutral,
      ),
      action: json.containsKey('action')
          ? action(json['action'], '$path.action', wire)
          : null,
      a11yLabel: a11yLabel,
      fallbackText: fallbackText,
    );
  }

  AiUiNode? _documentCard(
    Map<String, dynamic> json,
    String path,
    String id,
    String? a11yLabel,
    String? fallbackText,
  ) {
    const wire = 'document_card';
    _unknownKeys(json, path, wire, const {
      'documentId',
      'title',
      'status',
      'statusTone',
      'action',
    });

    final documentId = _requiredString(json, 'documentId', path, wire);
    final title = _requiredString(
      json,
      'title',
      path,
      wire,
      maxLength: limits.maxLabelLength,
    );
    final status = _requiredString(
      json,
      'status',
      path,
      wire,
      maxLength: limits.maxChipLabelLength,
    );
    if (documentId == null || title == null || status == null) return null;

    return AiUiDocumentCardNode(
      id: id,
      documentId: documentId,
      title: title,
      status: status,
      statusTone: _enum(
        json,
        'statusTone',
        path,
        wire,
        AiUiTone.tryFromWire,
        AiUiTone.neutral,
      ),
      action: json.containsKey('action')
          ? action(json['action'], '$path.action', wire)
          : null,
      a11yLabel: a11yLabel,
      fallbackText: fallbackText,
    );
  }

  AiUiNode? _quickReply(
    Map<String, dynamic> json,
    String path,
    String id,
    String? a11yLabel,
    String? fallbackText,
  ) {
    const wire = 'quick_reply';
    _unknownKeys(json, path, wire, const {'options'});

    final raw = json['options'];
    if (raw is! List) {
      add(
        AiUiDiagnosticCode.missingRequiredProperty,
        path,
        nodeType: wire,
        detail: 'options missing or not an array',
      );
      return null;
    }

    var entries = raw;
    if (entries.length > limits.maxQuickReplyOptions) {
      add(
        AiUiDiagnosticCode.limitExceeded,
        '$path.options',
        nodeType: wire,
        detail:
            '${entries.length} options > ${limits.maxQuickReplyOptions}, '
            'truncated',
      );
      entries = entries.sublist(0, limits.maxQuickReplyOptions);
    }

    final options = <AiUiQuickReplyOption>[];
    for (var i = 0; i < entries.length; i++) {
      final optionPath = '$path.options[$i]';
      final entry = entries[i];
      if (entry is! Map<String, dynamic>) {
        add(
          AiUiDiagnosticCode.invalidProperty,
          optionPath,
          nodeType: wire,
          detail: 'option is ${entry.runtimeType}, expected object',
        );
        continue;
      }
      final label = _requiredString(
        entry,
        'label',
        optionPath,
        wire,
        maxLength: limits.maxChipLabelLength,
      );
      final resolved = action(entry['action'], '$optionPath.action', wire);
      if (label == null || resolved == null) continue;
      options.add(AiUiQuickReplyOption(label: label, action: resolved));
    }

    if (options.length < limits.minQuickReplyOptions) {
      add(
        AiUiDiagnosticCode.limitExceeded,
        '$path.options',
        nodeType: wire,
        detail:
            '${options.length} valid options < '
            '${limits.minQuickReplyOptions}',
      );
      return null;
    }

    return AiUiQuickReplyNode(
      id: id,
      options: options,
      a11yLabel: a11yLabel,
      fallbackText: fallbackText,
    );
  }

  // ── Shared parsing helpers ────────────────────────────────────────────────

  List<AiUiNode> children(
    Map<String, dynamic> json,
    String path,
    int depth,
    AiUiNodeType type,
    String wire,
  ) {
    final raw = json['children'];
    if (raw == null) return const [];
    if (raw is! List) {
      add(
        AiUiDiagnosticCode.invalidProperty,
        '$path.children',
        nodeType: wire,
        detail: 'children is ${raw.runtimeType}, expected array',
      );
      return const [];
    }

    final limit = limits.childLimitFor(type);
    var entries = raw;
    if (entries.length > limit) {
      add(
        AiUiDiagnosticCode.limitExceeded,
        '$path.children',
        nodeType: wire,
        detail: '${entries.length} children > $limit, truncated',
      );
      entries = entries.sublist(0, limit);
    }

    final result = <AiUiNode>[];
    for (var i = 0; i < entries.length; i++) {
      final child = node(entries[i], '$path.children[$i]', depth + 1);
      if (aborted) return result;
      if (child != null) result.add(child);
    }
    return result;
  }

  AiUiAction? action(Object? raw, String path, String? nodeType) {
    if (raw is! Map<String, dynamic>) {
      add(
        AiUiDiagnosticCode.missingRequiredProperty,
        path,
        nodeType: nodeType,
        detail: raw == null
            ? 'action missing'
            : 'action is ${raw.runtimeType}, expected object',
      );
      return null;
    }

    final rawType = raw['type'];
    if (rawType is! String) {
      add(
        AiUiDiagnosticCode.missingRequiredProperty,
        path,
        nodeType: nodeType,
        detail: 'action type missing or not a string',
      );
      return null;
    }

    final type = AiUiActionType.tryFromWire(rawType);
    if (type == null || !supportedActions.contains(type)) {
      add(
        AiUiDiagnosticCode.unknownActionType,
        path,
        nodeType: nodeType,
        detail: type == null
            ? 'action "$rawType" not in protocol catalog'
            : 'action "$rawType" not implemented by this host',
      );
      return null;
    }

    actionCount++;
    if (actionCount > limits.maxActions) {
      add(
        AiUiDiagnosticCode.limitExceeded,
        path,
        nodeType: nodeType,
        detail: 'action count > ${limits.maxActions}',
      );
      return null;
    }

    final params = <String, String>{};
    final routeParams = <String, String>{};
    for (final entry in raw.entries) {
      if (entry.key == 'type') continue;
      if (entry.key == 'params') {
        final nested = entry.value;
        if (nested is Map<String, dynamic>) {
          for (final param in nested.entries) {
            final coerced = _scalar(param.value);
            if (coerced != null) routeParams[param.key] = coerced;
          }
        } else {
          add(
            AiUiDiagnosticCode.invalidProperty,
            path,
            nodeType: nodeType,
            detail: 'action params is ${nested.runtimeType}, expected object',
          );
        }
        continue;
      }
      final coerced = _scalar(entry.value);
      if (coerced == null) {
        add(
          AiUiDiagnosticCode.invalidProperty,
          path,
          nodeType: nodeType,
          detail: 'action param "${entry.key}" is not a scalar',
        );
        continue;
      }
      params[entry.key] = coerced;
    }

    for (final required in type.requiredParams) {
      final value = params[required];
      if (value == null || value.isEmpty) {
        add(
          AiUiDiagnosticCode.missingRequiredProperty,
          path,
          nodeType: nodeType,
          detail: 'action "${type.wire}" needs "$required"',
        );
        return null;
      }
    }

    if (type == AiUiActionType.openUrl) {
      final reason = urlPolicy.reject(params['url']!);
      if (reason != null) {
        add(
          AiUiDiagnosticCode.blockedUrl,
          path,
          nodeType: nodeType,
          detail: 'open_url blocked: $reason',
        );
        return null;
      }
    }

    return AiUiAction(type: type, params: params, routeParams: routeParams);
  }

  /// Reads an image source from a map that carries an `assetId`.
  ///
  /// **schemaVersion 1 is `assetId`-only.** A `url` is rejected outright
  /// rather than host-checked: an agent-supplied image URL is a network and
  /// tracking surface, and every image v1 needs is something the app already
  /// ships. Semantic cards carry an entity id, so the app fetches the real
  /// artwork itself instead of trusting a URL in the payload.
  ///
  /// `AiUiUrlPolicy` still exists and still gates the `open_url` action; it is
  /// deliberately not consulted here.
  AiUiImageSource? imageSource(
    Map<String, dynamic> json,
    String path,
    String wire,
  ) {
    if (json.containsKey('url')) {
      add(
        AiUiDiagnosticCode.reservedProperty,
        path,
        nodeType: wire,
        detail: 'remote image url is not supported in schemaVersion 1',
      );
    }

    final assetId = json['assetId'];
    if (assetId == null) {
      add(
        AiUiDiagnosticCode.missingRequiredProperty,
        path,
        nodeType: wire,
        detail: 'assetId is required',
      );
      return null;
    }
    if (assetId is! String || assetId.isEmpty) {
      add(
        AiUiDiagnosticCode.invalidProperty,
        path,
        nodeType: wire,
        detail: 'assetId is ${assetId.runtimeType}, expected string',
      );
      return null;
    }

    final known = knownAssetIds;
    if (known != null && !known.contains(assetId)) {
      add(
        AiUiDiagnosticCode.unknownAssetId,
        path,
        nodeType: wire,
        detail: 'assetId "$assetId" not published by this host',
      );
      return null;
    }

    return _countedImage(AiUiAssetImage(assetId), path, wire);
  }

  AiUiImageSource? _countedImage(
    AiUiImageSource source,
    String path,
    String wire,
  ) {
    imageCount++;
    if (imageCount > limits.maxImages) {
      add(
        AiUiDiagnosticCode.limitExceeded,
        path,
        nodeType: wire,
        detail: 'image count > ${limits.maxImages}',
      );
      return null;
    }
    return source;
  }

  AiUiImageSource? _nestedImage(
    Map<String, dynamic> json,
    String key,
    String path,
    String wire,
  ) {
    final raw = json[key];
    if (raw == null) return null;
    if (raw is! Map<String, dynamic>) {
      add(
        AiUiDiagnosticCode.invalidProperty,
        '$path.$key',
        nodeType: wire,
        detail: '$key is ${raw.runtimeType}, expected object',
      );
      return null;
    }
    return imageSource(raw, '$path.$key', wire);
  }

  AiUiBadge? _badge(
    Map<String, dynamic> json,
    String key,
    String path,
    String wire,
  ) {
    final raw = json[key];
    if (raw == null) return null;
    if (raw is! Map<String, dynamic>) {
      add(
        AiUiDiagnosticCode.invalidProperty,
        '$path.$key',
        nodeType: wire,
        detail: '$key is ${raw.runtimeType}, expected object',
      );
      return null;
    }
    final label = _requiredString(
      raw,
      'label',
      '$path.$key',
      wire,
      maxLength: limits.maxChipLabelLength,
    );
    if (label == null) return null;
    return AiUiBadge(
      label: label,
      tone: _enum(
        raw,
        'tone',
        '$path.$key',
        wire,
        AiUiTone.tryFromWire,
        AiUiTone.neutral,
      ),
    );
  }

  AiUiMoney? _money(
    Map<String, dynamic> json,
    String key,
    String path,
    String wire,
  ) {
    final raw = json[key];
    if (raw == null) return null;
    if (raw is! Map<String, dynamic>) {
      add(
        AiUiDiagnosticCode.invalidProperty,
        '$path.$key',
        nodeType: wire,
        detail: '$key is ${raw.runtimeType}, expected object',
      );
      return null;
    }
    final amount = raw['amount'];
    final currency = raw['currency'];
    if (amount is! num) {
      add(
        AiUiDiagnosticCode.invalidProperty,
        '$path.$key',
        nodeType: wire,
        detail: 'amount is ${amount.runtimeType}, expected number',
      );
      return null;
    }
    if (currency is! String || currency.trim().length != 3) {
      add(
        AiUiDiagnosticCode.invalidProperty,
        '$path.$key',
        nodeType: wire,
        detail: 'currency must be a 3-letter ISO-4217 code',
      );
      return null;
    }
    return AiUiMoney(amount: amount, currency: currency.trim().toUpperCase());
  }

  DateTime? _instant(
    Map<String, dynamic> json,
    String key,
    String path,
    String wire,
  ) {
    final raw = json[key];
    if (raw is! String || raw.isEmpty) {
      add(
        AiUiDiagnosticCode.missingRequiredProperty,
        path,
        nodeType: wire,
        detail: '$key missing or not a string',
      );
      return null;
    }
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) {
      add(
        AiUiDiagnosticCode.invalidProperty,
        path,
        nodeType: wire,
        detail: '$key is not a valid ISO-8601 instant',
      );
      return null;
    }
    return parsed.toUtc();
  }

  String _idFor(Map<String, dynamic> json, String path) {
    final raw = json['id'];
    if (raw is String && raw.isNotEmpty) return raw;
    return path;
  }

  String? _requiredString(
    Map<String, dynamic> json,
    String key,
    String path,
    String wire, {
    int? maxLength,
  }) {
    final raw = json[key];
    if (raw is! String || raw.trim().isEmpty) {
      add(
        AiUiDiagnosticCode.missingRequiredProperty,
        path,
        nodeType: wire,
        detail: raw == null
            ? '$key missing'
            : '$key is ${raw.runtimeType}, expected non-empty string',
      );
      return null;
    }
    return _truncate(raw, key, path, wire, maxLength);
  }

  String? _optionalString(
    Map<String, dynamic> json,
    String key,
    String path,
    String? wire, {
    int? maxLength,
  }) {
    final raw = json[key];
    if (raw == null) return null;
    if (raw is! String) {
      add(
        AiUiDiagnosticCode.invalidProperty,
        path,
        nodeType: wire,
        detail: '$key is ${raw.runtimeType}, expected string',
      );
      return null;
    }
    if (raw.isEmpty) return null;
    return _truncate(raw, key, path, wire, maxLength);
  }

  String _truncate(
    String value,
    String key,
    String path,
    String? wire,
    int? maxLength,
  ) {
    if (maxLength == null || value.length <= maxLength) return value;
    add(
      AiUiDiagnosticCode.limitExceeded,
      path,
      nodeType: wire,
      detail: '$key ${value.length} chars > $maxLength, truncated',
    );
    return value.substring(0, maxLength);
  }

  bool _bool(
    Map<String, dynamic> json,
    String key,
    String path,
    String wire, {
    required bool defaultValue,
  }) {
    final raw = json[key];
    if (raw == null) return defaultValue;
    if (raw is bool) return raw;
    add(
      AiUiDiagnosticCode.invalidProperty,
      path,
      nodeType: wire,
      detail: '$key is ${raw.runtimeType}, expected bool',
    );
    return defaultValue;
  }

  int? _boundedInt(
    Map<String, dynamic> json,
    String key,
    String path,
    String wire,
    int min,
    int max,
  ) {
    final raw = json[key];
    if (raw == null) return null;
    if (raw is! int) {
      add(
        AiUiDiagnosticCode.invalidProperty,
        path,
        nodeType: wire,
        detail: '$key is ${raw.runtimeType}, expected int',
      );
      return null;
    }
    if (raw < min || raw > max) {
      add(
        AiUiDiagnosticCode.limitExceeded,
        path,
        nodeType: wire,
        detail: '$key $raw outside $min..$max, clamped',
      );
      return raw.clamp(min, max);
    }
    return raw;
  }

  double? _boundedDouble(
    Map<String, dynamic> json,
    String key,
    String path,
    String wire,
    double min,
    double max,
  ) {
    final raw = json[key];
    if (raw == null) return null;
    if (raw is! num) {
      add(
        AiUiDiagnosticCode.invalidProperty,
        path,
        nodeType: wire,
        detail: '$key is ${raw.runtimeType}, expected number',
      );
      return null;
    }
    return raw.toDouble().clamp(min, max);
  }

  T _enum<T>(
    Map<String, dynamic> json,
    String key,
    String path,
    String wire,
    T? Function(String) tryFromWire,
    T fallback,
  ) {
    final raw = json[key];
    if (raw == null) return fallback;
    if (raw is! String) {
      add(
        AiUiDiagnosticCode.invalidProperty,
        path,
        nodeType: wire,
        detail: '$key is ${raw.runtimeType}, expected string',
      );
      return fallback;
    }
    final parsed = tryFromWire(raw);
    if (parsed == null) {
      add(
        AiUiDiagnosticCode.invalidProperty,
        path,
        nodeType: wire,
        detail: '$key "$raw" unknown, using default',
      );
      return fallback;
    }
    return parsed;
  }

  void _unknownKeys(
    Map<String, dynamic> json,
    String path,
    String wire,
    Set<String> allowed,
  ) {
    for (final key in json.keys) {
      if (_baseKeys.contains(key)) continue;
      if (allowed.contains(key)) continue;
      if (_reservedKeys.contains(key)) continue;
      add(
        AiUiDiagnosticCode.invalidProperty,
        path,
        nodeType: wire,
        detail: 'unknown property "$key" ignored',
      );
    }
  }

  static String? _scalar(Object? value) => switch (value) {
    final String s => s,
    final num n => '$n',
    final bool b => '$b',
    _ => null,
  };
}
