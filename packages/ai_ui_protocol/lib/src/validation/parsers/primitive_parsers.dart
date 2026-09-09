part of 'package:ai_ui_protocol/src/validation/ai_ui_validator.dart';

/// One parser per primitive node type.
///
/// An extension on the validator's private run state rather than a second
/// class: the parsers need `_requiredString`, `_enum`, `action` and the rest of
/// the shared helpers, and threading those through a constructor would buy
/// nothing. A `part` of the validator so the extension can see them, split out
/// so neither half of the catalog lives in a three-thousand-line file.
///
/// Every method here is **total**: no input makes one throw. A node that cannot
/// be built returns `null` (dropped, siblings kept) after recording a
/// diagnostic; a value that cannot be honoured is defaulted, clamped or
/// truncated.
extension _PrimitiveParsers on _Run {
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
}
