/// Presentation *hints* the agent may send.
///
/// Every enum here is a closed, semantic vocabulary that the renderer maps onto
/// SANAD design tokens. The protocol deliberately has no way to express a hex
/// colour, a pixel value, a font family, or a Flutter alignment constant — the
/// agent describes intent, the app decides how that looks.
///
/// Each enum exposes:
///   * `wire`      — the exact JSON string the agent must send.
///   * `tryFromWire` — returns `null` for an unrecognised value so the caller
///                     can fall back to the documented default *and* emit a
///                     diagnostic. Never throws.
library;

/// Text role. Maps onto `context.appTypography` styles in the renderer.
enum AiUiTextStyleToken {
  title('title'),
  body('body'),
  caption('caption'),
  label('label')
  ;

  const AiUiTextStyleToken(this.wire);

  final String wire;

  static AiUiTextStyleToken? tryFromWire(String value) =>
      _lookup(values, value, (e) => e.wire);
}

/// Relative weight/prominence of a run of text.
enum AiUiEmphasis {
  normal('normal'),
  strong('strong'),
  muted('muted')
  ;

  const AiUiEmphasis(this.wire);

  final String wire;

  static AiUiEmphasis? tryFromWire(String value) =>
      _lookup(values, value, (e) => e.wire);
}

/// Alignment along the main axis. `start`/`end` are *directional* — they flip
/// under RTL. The protocol has no `left`/`right`.
enum AiUiMainAxisAlign {
  start('start'),
  center('center'),
  end('end'),
  spaceBetween('spaceBetween')
  ;

  const AiUiMainAxisAlign(this.wire);

  final String wire;

  static AiUiMainAxisAlign? tryFromWire(String value) =>
      _lookup(values, value, (e) => e.wire);
}

/// Alignment across the main axis.
enum AiUiCrossAxisAlign {
  start('start'),
  center('center'),
  end('end')
  ;

  const AiUiCrossAxisAlign(this.wire);

  final String wire;

  static AiUiCrossAxisAlign? tryFromWire(String value) =>
      _lookup(values, value, (e) => e.wire);
}

/// Semantic colour role. Maps onto `context.appColors` roles, never a raw
/// colour value.
enum AiUiTone {
  neutral('neutral'),
  primary('primary'),
  info('info'),
  success('success'),
  warning('warning'),
  error('error')
  ;

  const AiUiTone(this.wire);

  final String wire;

  static AiUiTone? tryFromWire(String value) =>
      _lookup(values, value, (e) => e.wire);
}

/// Spacing step. Maps onto `AppSpacing.*`.
enum AiUiSpacingStep {
  xs('xs'),
  sm('sm'),
  md('md'),
  lg('lg'),
  xl('xl')
  ;

  const AiUiSpacingStep(this.wire);

  final String wire;

  static AiUiSpacingStep? tryFromWire(String value) =>
      _lookup(values, value, (e) => e.wire);
}

/// Icon size step. Maps onto `AppDimension.icon*`.
enum AiUiIconSize {
  sm('sm'),
  md('md'),
  lg('lg')
  ;

  const AiUiIconSize(this.wire);

  final String wire;

  static AiUiIconSize? tryFromWire(String value) =>
      _lookup(values, value, (e) => e.wire);
}

/// Image shape hint. The agent never supplies pixel dimensions.
enum AiUiImageAspect {
  square('square'),
  wide('wide'),
  thumb('thumb')
  ;

  const AiUiImageAspect(this.wire);

  final String wire;

  static AiUiImageAspect? tryFromWire(String value) =>
      _lookup(values, value, (e) => e.wire);
}

enum AiUiImageFit {
  cover('cover'),
  contain('contain')
  ;

  const AiUiImageFit(this.wire);

  final String wire;

  static AiUiImageFit? tryFromWire(String value) =>
      _lookup(values, value, (e) => e.wire);
}

/// Mirrors `AppButtonVariant` in `design_system`.
enum AiUiButtonVariant {
  primary('primary'),
  secondary('secondary'),
  outline('outline'),
  transparent('transparent')
  ;

  const AiUiButtonVariant(this.wire);

  final String wire;

  static AiUiButtonVariant? tryFromWire(String value) =>
      _lookup(values, value, (e) => e.wire);
}

/// Mirrors `AppButtonIntent` in `design_system`. Orthogonal to
/// [AiUiButtonVariant].
enum AiUiButtonIntent {
  standard('standard'),
  warning('warning'),
  destructive('destructive'),
  neutral('neutral')
  ;

  const AiUiButtonIntent(this.wire);

  final String wire;

  static AiUiButtonIntent? tryFromWire(String value) =>
      _lookup(values, value, (e) => e.wire);
}

/// Mirrors `AppButtonSize` in `design_system`.
enum AiUiButtonSize {
  block('block'),
  large('large'),
  small('small')
  ;

  const AiUiButtonSize(this.wire);

  final String wire;

  static AiUiButtonSize? tryFromWire(String value) =>
      _lookup(values, value, (e) => e.wire);
}

enum AiUiListVariant {
  plain('plain'),
  sectioned('sectioned')
  ;

  const AiUiListVariant(this.wire);

  final String wire;

  static AiUiListVariant? tryFromWire(String value) =>
      _lookup(values, value, (e) => e.wire);
}

/// Direction handling for a single text value.
///
/// [auto] lets the platform resolve direction from the content (the normal
/// case). [ltrValue] marks an *inherently* LTR value — a phone number, email,
/// URL, IBAN or opaque ID — which the renderer wraps in `String.ltrIsolated`
/// so a leading `+` renders at the visual start under RTL rather than being
/// reordered to the end (the recurring SAN-770/771/775 bug class).
enum AiUiTextDirectionHint {
  auto('auto'),
  ltrValue('ltrValue')
  ;

  const AiUiTextDirectionHint(this.wire);

  final String wire;

  static AiUiTextDirectionHint? tryFromWire(String value) =>
      _lookup(values, value, (e) => e.wire);
}

T? _lookup<T>(List<T> values, String value, String Function(T) wireOf) {
  for (final candidate in values) {
    if (wireOf(candidate) == value) return candidate;
  }
  return null;
}
