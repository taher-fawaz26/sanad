part of 'package:ai_ui_protocol/src/domain/ai_ui_node.dart';

/// The fifteen generic building blocks — layout, text, media and controls.
///
/// A `part` of `ai_ui_node.dart` rather than its own library: [AiUiNode] is
/// sealed, and a sealed type's subclasses must live in the same library as
/// the base. The split is purely so neither half of the catalog is buried in
/// a two-thousand-line file.
// ─── Primitives ─────────────────────────────────────────────────────────────

final class AiUiTextNode extends AiUiNode {
  const AiUiTextNode({
    required super.id,
    required this.text,
    this.style = AiUiTextStyleToken.body,
    this.emphasis = AiUiEmphasis.normal,
    this.align = AiUiMainAxisAlign.start,
    this.direction = AiUiTextDirectionHint.auto,
    this.maxLines,
    super.a11yLabel,
    super.fallbackText,
  });

  final String text;
  final AiUiTextStyleToken style;
  final AiUiEmphasis emphasis;
  final AiUiMainAxisAlign align;
  final AiUiTextDirectionHint direction;
  final int? maxLines;

  @override
  AiUiNodeType get type => AiUiNodeType.text;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    ...baseJson(AiUiNodeType.text.wire),
    'text': text,
    'style': style.wire,
    'emphasis': emphasis.wire,
    'align': align.wire,
    'direction': direction.wire,
    if (maxLines != null) 'maxLines': maxLines,
  };

  @override
  List<Object?> get props => [
    ...baseProps,
    text,
    style,
    emphasis,
    align,
    direction,
    maxLines,
  ];
}

final class AiUiRichTextNode extends AiUiNode {
  const AiUiRichTextNode({
    required super.id,
    required this.spans,
    this.align = AiUiMainAxisAlign.start,
    super.a11yLabel,
    super.fallbackText,
  });

  final List<AiUiRichSpan> spans;
  final AiUiMainAxisAlign align;

  @override
  AiUiNodeType get type => AiUiNodeType.richText;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    ...baseJson(AiUiNodeType.richText.wire),
    'spans': spans.map((s) => s.toJson()).toList(),
    'align': align.wire,
  };

  @override
  List<Object?> get props => [...baseProps, spans, align];
}

final class AiUiIconNode extends AiUiNode {
  const AiUiIconNode({
    required super.id,
    required this.name,
    this.size = AiUiIconSize.md,
    this.tone = AiUiTone.neutral,
    super.a11yLabel,
    super.fallbackText,
  });

  /// Either a SANAD icon token or a Font Awesome CSS class string
  /// (`"fa-solid fa-store"`), resolved by the renderer through
  /// `BackendIconResolver`. Unknown names resolve to nothing rather than
  /// throwing.
  final String name;
  final AiUiIconSize size;
  final AiUiTone tone;

  @override
  AiUiNodeType get type => AiUiNodeType.icon;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    ...baseJson(AiUiNodeType.icon.wire),
    'name': name,
    'size': size.wire,
    'tone': tone.wire,
  };

  @override
  List<Object?> get props => [...baseProps, name, size, tone];
}

final class AiUiImageNode extends AiUiNode {
  const AiUiImageNode({
    required super.id,
    required this.source,
    required this.alt,
    this.aspect = AiUiImageAspect.wide,
    this.fit = AiUiImageFit.cover,
    super.a11yLabel,
    super.fallbackText,
  });

  final AiUiImageSource source;

  /// Required — an image without alternative text is dropped during
  /// validation rather than rendered inaccessibly.
  final String alt;
  final AiUiImageAspect aspect;
  final AiUiImageFit fit;

  @override
  AiUiNodeType get type => AiUiNodeType.image;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    ...baseJson(AiUiNodeType.image.wire),
    ...source.toJson(),
    'alt': alt,
    'aspect': aspect.wire,
    'fit': fit.wire,
  };

  @override
  List<Object?> get props => [...baseProps, source, alt, aspect, fit];
}

final class AiUiDividerNode extends AiUiNode {
  const AiUiDividerNode({
    required super.id,
    this.spacing = AiUiSpacingStep.md,
    super.a11yLabel,
    super.fallbackText,
  });

  final AiUiSpacingStep spacing;

  @override
  AiUiNodeType get type => AiUiNodeType.divider;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    ...baseJson(AiUiNodeType.divider.wire),
    'spacing': spacing.wire,
  };

  @override
  List<Object?> get props => [...baseProps, spacing];
}

final class AiUiSpacerNode extends AiUiNode {
  const AiUiSpacerNode({
    required super.id,
    this.size = AiUiSpacingStep.md,
    super.a11yLabel,
    super.fallbackText,
  });

  final AiUiSpacingStep size;

  @override
  AiUiNodeType get type => AiUiNodeType.spacer;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    ...baseJson(AiUiNodeType.spacer.wire),
    'size': size.wire,
  };

  @override
  List<Object?> get props => [...baseProps, size];
}

final class AiUiRowNode extends AiUiNode {
  const AiUiRowNode({
    required super.id,
    required this.children,
    this.align = AiUiMainAxisAlign.start,
    this.crossAlign = AiUiCrossAxisAlign.center,
    this.gap = AiUiSpacingStep.sm,
    this.wrap = false,
    super.a11yLabel,
    super.fallbackText,
  });

  @override
  final List<AiUiNode> children;

  /// Directional: `start`/`end` flip under RTL. The renderer owns direction —
  /// the protocol has no `left`/`right`.
  final AiUiMainAxisAlign align;
  final AiUiCrossAxisAlign crossAlign;
  final AiUiSpacingStep gap;
  final bool wrap;

  @override
  AiUiNodeType get type => AiUiNodeType.row;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    ...baseJson(AiUiNodeType.row.wire),
    'align': align.wire,
    'crossAlign': crossAlign.wire,
    'gap': gap.wire,
    'wrap': wrap,
    'children': children.map((c) => c.toJson()).toList(),
  };

  @override
  List<Object?> get props => [
    ...baseProps,
    children,
    align,
    crossAlign,
    gap,
    wrap,
  ];
}

final class AiUiColumnNode extends AiUiNode {
  const AiUiColumnNode({
    required super.id,
    required this.children,
    this.align = AiUiCrossAxisAlign.start,
    this.gap = AiUiSpacingStep.sm,
    super.a11yLabel,
    super.fallbackText,
  });

  @override
  final List<AiUiNode> children;

  final AiUiCrossAxisAlign align;
  final AiUiSpacingStep gap;

  @override
  AiUiNodeType get type => AiUiNodeType.column;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    ...baseJson(AiUiNodeType.column.wire),
    'align': align.wire,
    'gap': gap.wire,
    'children': children.map((c) => c.toJson()).toList(),
  };

  @override
  List<Object?> get props => [...baseProps, children, align, gap];
}

final class AiUiCardNode extends AiUiNode {
  const AiUiCardNode({
    required super.id,
    required this.children,
    this.title,
    this.tone = AiUiTone.neutral,
    this.action,
    super.a11yLabel,
    super.fallbackText,
  });

  @override
  final List<AiUiNode> children;

  final String? title;
  final AiUiTone tone;

  /// Whole-card tap target. Renders as a single `Semantics(button: true)` so a
  /// screen reader announces one destination rather than a pile of children.
  final AiUiAction? action;

  @override
  AiUiNodeType get type => AiUiNodeType.card;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    ...baseJson(AiUiNodeType.card.wire),
    if (title != null) 'title': title,
    'tone': tone.wire,
    if (action != null) 'action': action!.toJson(),
    'children': children.map((c) => c.toJson()).toList(),
  };

  @override
  List<Object?> get props => [...baseProps, children, title, tone, action];
}

final class AiUiButtonNode extends AiUiNode {
  const AiUiButtonNode({
    required super.id,
    required this.label,
    required this.action,
    this.variant = AiUiButtonVariant.primary,
    this.intent = AiUiButtonIntent.standard,
    this.size = AiUiButtonSize.block,
    this.icon,
    this.enabled = true,
    super.a11yLabel,
    super.fallbackText,
  });

  final String label;
  final AiUiAction action;
  final AiUiButtonVariant variant;
  final AiUiButtonIntent intent;
  final AiUiButtonSize size;
  final String? icon;
  final bool enabled;

  @override
  AiUiNodeType get type => AiUiNodeType.button;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    ...baseJson(AiUiNodeType.button.wire),
    'label': label,
    'action': action.toJson(),
    'variant': variant.wire,
    'intent': intent.wire,
    'size': size.wire,
    if (icon != null) 'icon': icon,
    'enabled': enabled,
  };

  @override
  List<Object?> get props => [
    ...baseProps,
    label,
    action,
    variant,
    intent,
    size,
    icon,
    enabled,
  ];
}

final class AiUiChipNode extends AiUiNode {
  const AiUiChipNode({
    required super.id,
    required this.label,
    this.action,
    this.selected = false,
    this.tone = AiUiTone.neutral,
    this.icon,
    super.a11yLabel,
    super.fallbackText,
  });

  final String label;
  final AiUiAction? action;
  final bool selected;
  final AiUiTone tone;
  final String? icon;

  @override
  AiUiNodeType get type => AiUiNodeType.chip;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    ...baseJson(AiUiNodeType.chip.wire),
    'label': label,
    if (action != null) 'action': action!.toJson(),
    'selected': selected,
    'tone': tone.wire,
    if (icon != null) 'icon': icon,
  };

  @override
  List<Object?> get props => [
    ...baseProps,
    label,
    action,
    selected,
    tone,
    icon,
  ];
}

final class AiUiListNode extends AiUiNode {
  const AiUiListNode({
    required super.id,
    required this.children,
    this.variant = AiUiListVariant.plain,
    this.emptyText,
    super.a11yLabel,
    super.fallbackText,
  });

  /// Always [AiUiListItemNode]s — enforced during validation.
  ///
  /// Rendered as a bounded `Column`, never a nested scrollable: a chat bubble
  /// must not contain a second scroll axis.
  @override
  final List<AiUiListItemNode> children;

  final AiUiListVariant variant;
  final String? emptyText;

  @override
  AiUiNodeType get type => AiUiNodeType.list;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    ...baseJson(AiUiNodeType.list.wire),
    'variant': variant.wire,
    if (emptyText != null) 'emptyText': emptyText,
    'children': children.map((c) => c.toJson()).toList(),
  };

  @override
  List<Object?> get props => [...baseProps, children, variant, emptyText];
}

final class AiUiListItemNode extends AiUiNode {
  const AiUiListItemNode({
    required super.id,
    required this.title,
    this.subtitle,
    this.leadingIcon,
    this.leadingImage,
    this.badge,
    this.trailingText,
    this.action,
    super.a11yLabel,
    super.fallbackText,
  });

  final String title;
  final String? subtitle;
  final String? leadingIcon;
  final AiUiImageSource? leadingImage;
  final AiUiBadge? badge;
  final String? trailingText;
  final AiUiAction? action;

  @override
  AiUiNodeType get type => AiUiNodeType.listItem;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    ...baseJson(AiUiNodeType.listItem.wire),
    'title': title,
    if (subtitle != null) 'subtitle': subtitle,
    if (leadingIcon != null) 'leadingIcon': leadingIcon,
    if (leadingImage != null) 'leadingImage': leadingImage!.toJson(),
    if (badge != null) 'badge': badge!.toJson(),
    if (trailingText != null) 'trailingText': trailingText,
    if (action != null) 'action': action!.toJson(),
  };

  @override
  List<Object?> get props => [
    ...baseProps,
    title,
    subtitle,
    leadingIcon,
    leadingImage,
    badge,
    trailingText,
    action,
  ];
}

final class AiUiProgressNode extends AiUiNode {
  const AiUiProgressNode({
    required super.id,
    this.value,
    this.label,
    super.a11yLabel,
    super.fallbackText,
  });

  /// `null` means indeterminate. Otherwise clamped to `0.0..1.0`.
  final double? value;
  final String? label;

  @override
  AiUiNodeType get type => AiUiNodeType.progress;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    ...baseJson(AiUiNodeType.progress.wire),
    if (value != null) 'value': value,
    if (label != null) 'label': label,
  };

  @override
  List<Object?> get props => [...baseProps, value, label];
}

final class AiUiLoadingNode extends AiUiNode {
  const AiUiLoadingNode({
    required super.id,
    this.label,
    super.a11yLabel,
    super.fallbackText,
  });

  final String? label;

  @override
  AiUiNodeType get type => AiUiNodeType.loading;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    ...baseJson(AiUiNodeType.loading.wire),
    if (label != null) 'label': label,
  };

  @override
  List<Object?> get props => [...baseProps, label];
}
