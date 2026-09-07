import 'package:app_animations/app_animations.dart';
import 'package:design_system/src/dimensions/responsive_dimension.dart';
import 'package:design_system/src/spacing/responsive_spacing.dart';
import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:design_system/src/theme/colors/field_tokens.dart';
import 'package:design_system/src/theme/typography/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Default OTP / PIN length used across the app.
///
/// The backend issues and expects a **6-digit** email OTP — this constant is
/// aligned to that contract (the source of truth), not to any mock design.
const int kDefaultOtpLength = 6;

// ─── Figma `7305:1726` / `7324:7328` / `7055:27323` — one-off cell values ──
//
// These belong to this single widget, not the shared design system: the
// digit/placeholder font sizes and caret geometry aren't reusable "type
// scale" or "dimension" tokens (see `AppDimension.otpCell*` for the values
// that ARE shared-dimension concerns — cell size/gap/radius/border-width).
//
// The empty-border and placeholder/caret colors below come from a legacy
// Figma variable collection ("02 - Dark/Color - Gray - *") distinct from the
// current `DarkPalette` — no existing design-system token matches their
// literal hex values (`#EEEEEE` sits between `DarkPalette.shade100` and
// `shade200`; `#A5A5A5` between `shade300` and `shade400`).

/// Empty-cell border color — Figma legacy `02 - Dark/Color - Gray - 100`.
const Color _kOtpEmptyBorderColor = Color(0xFFEEEEEE);

/// Placeholder text + caret color — Figma legacy `02 - Dark/Color - Gray -
/// 300`.
const Color _kOtpNeutralAccentColor = Color(0xFFA5A5A5);

/// The cell geometry and glyph sizing of one [AppOtpField] rendering.
///
/// Exists because the two products' OTP screens are drawn to genuinely
/// different cell specs in Figma, and the field is otherwise identical
/// between them — the editing model, keyboard handling, error semantics and
/// accessibility are all shared. Rather than fork the widget (or scatter a
/// dozen loose sizing parameters across its constructor), a caller picks a
/// named preset.
///
/// Every value is an **unscaled design-pixel base**: [AppOtpField] runs each
/// through `responsiveDimension` itself, exactly as it did when these numbers
/// were hardcoded.
@immutable
class AppOtpFieldMetrics {
  const AppOtpFieldMetrics({
    required this.cellSize,
    required this.cellGap,
    required this.cellRadius,
    required this.borderWidth,
    required this.digitFontSize,
    required this.digitLineHeightPx,
    required this.placeholderFontSize,
    required this.placeholderLineHeightPx,
    required this.caretHeight,
    required this.caretWidth,
  });

  /// Figma `7305:1726` / `7324:7328` — the client OTP screens' cell spec, and
  /// the historical default of this widget (every existing caller renders
  /// byte-for-byte as before).
  const AppOtpFieldMetrics.standard()
    : cellSize = 45.01,
      cellGap = 13.209,
      cellRadius = 9.907,
      borderWidth = 1.407,
      digitFontSize = 11.87,
      digitLineHeightPx = 17.313,
      placeholderFontSize = 25.32,
      placeholderLineHeightPx = 35.166,
      caretHeight = 21.1,
      caretWidth = 0.703;

  /// Figma `3809:18092` / `2142:14140` — the provider OTP screens' larger
  /// cell spec (54.5dp cells, 16dp gutters, 13.6dp radius).
  ///
  /// The caret is not dimensioned in those frames; it is scaled from
  /// [AppOtpFieldMetrics.standard] by the same 54.522/45.013 cell ratio so it
  /// keeps its proportion inside the taller cell.
  const AppOtpFieldMetrics.large()
    : cellSize = 54.522,
      cellGap = 16,
      cellRadius = 13.631,
      borderWidth = 1.704,
      digitFontSize = 20.45,
      digitLineHeightPx = 29.817,
      placeholderFontSize = 30.67,
      placeholderLineHeightPx = 42.596,
      caretHeight = 25.56,
      caretWidth = 0.851;

  /// Width and height of one square cell.
  final double cellSize;

  /// Gutter between two adjacent cells.
  final double cellGap;

  final double cellRadius;

  /// Border stroke of a cell in its resting state. A cell targeted for
  /// replacement draws at twice this width.
  final double borderWidth;

  /// Font size of a filled digit.
  final double digitFontSize;

  /// Filled-digit line height, in design pixels (converted to a ratio).
  final double digitLineHeightPx;

  /// Font size of the empty-cell `_` placeholder — larger than
  /// [digitFontSize] so it reads as a baseline dash, not a tiny mark.
  final double placeholderFontSize;

  /// Placeholder line height, in design pixels (converted to a ratio).
  final double placeholderLineHeightPx;

  final double caretHeight;
  final double caretWidth;

  double get digitLineHeight => digitLineHeightPx / digitFontSize;

  double get placeholderLineHeight =>
      placeholderLineHeightPx / placeholderFontSize;
}

/// Key for the tappable region of the OTP cell at [index] (0-based).
///
/// Exposed so tests can target a specific digit position.
Key otpCellKey(int index) => ValueKey<String>('app_otp_field_cell_$index');

/// Reusable OTP pin field styled with design-system tokens.
///
/// Safe to use on full screens, bottom sheets, dialogs, or any other surface.
///
/// ### Editing model
///
/// There is exactly **one** source of truth: the [TextEditingController]'s
/// value and selection, driven by a single hidden [TextField]. The visible
/// digit cells are a pure projection of that value — they hold no state of
/// their own. Each cell maps to one character index, so tapping a cell moves
/// the selection onto that digit and the next keystroke replaces it in place.
///
/// This deliberately does not use the `pinput` package: it hardcodes its
/// active cell to `text.length` (`isActiveField = index == pin.length`) and
/// force-collapses any selection back to the end of the text, which makes
/// positional editing impossible — tapping an earlier digit did nothing.
class AppOtpField extends StatefulWidget {
  const AppOtpField({
    super.key,
    this.controller,
    this.focusNode,
    this.length = kDefaultOtpLength,
    this.metrics = const AppOtpFieldMetrics.standard(),
    this.enabled = true,
    this.autofocus = false,
    this.forceErrorState = false,
    this.errorText,
    this.errorTextStyle,
    this.validator,
    this.onChanged,
    this.onCompleted,
    this.onSubmitted,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;

  /// Number of pin cells. Defaults to [kDefaultOtpLength] (6).
  final int length;

  /// Cell geometry and glyph sizing. Defaults to
  /// [AppOtpFieldMetrics.standard] — the spec this widget has always drawn.
  /// The provider OTP screens pass [AppOtpFieldMetrics.large].
  final AppOtpFieldMetrics metrics;
  final bool enabled;
  final bool autofocus;
  final bool forceErrorState;
  final String? errorText;

  /// Overrides the error message's default [FieldTokens.errorStyle]. Every
  /// other field in the app shares that one error color; a caller only needs
  /// this when its own Figma spec calls for a genuinely different one (e.g.
  /// the OTP screen's caption red, distinct from both the shared field-error
  /// red and this field's own cell-border error red).
  final TextStyle? errorTextStyle;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onCompleted;
  final ValueChanged<String>? onSubmitted;

  @override
  State<AppOtpField> createState() => _AppOtpFieldState();
}

class _AppOtpFieldState extends State<AppOtpField> {
  /// Only set when this widget created the controller/focus node itself, so
  /// it disposes exactly what it owns and never a caller's instance.
  TextEditingController? _ownedController;
  FocusNode? _ownedFocusNode;

  FormFieldState<String>? _field;
  late String _lastText;

  /// Guards the re-entrant notification raised by [_armSelection]'s own write.
  bool _rearming = false;

  TextEditingController get _controller =>
      widget.controller ?? (_ownedController ??= TextEditingController());

  FocusNode get _focusNode =>
      widget.focusNode ?? (_ownedFocusNode ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _lastText = _controller.text;
    _controller.addListener(_handleControllerChanged);
    _focusNode.addListener(_handleFocusChanged);
  }

  @override
  void didUpdateWidget(AppOtpField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-subscribe if a caller swapped the controller/focus node identity.
    if (widget.controller != oldWidget.controller) {
      (oldWidget.controller ?? _ownedController)?.removeListener(
        _handleControllerChanged,
      );
      _lastText = _controller.text;
      _controller.addListener(_handleControllerChanged);
    }
    if (widget.focusNode != oldWidget.focusNode) {
      (oldWidget.focusNode ?? _ownedFocusNode)?.removeListener(
        _handleFocusChanged,
      );
      _focusNode.addListener(_handleFocusChanged);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerChanged);
    _focusNode.removeListener(_handleFocusChanged);
    _ownedController?.dispose();
    _ownedFocusNode?.dispose();
    super.dispose();
  }

  /// Single funnel for value changes.
  ///
  /// Listening on the controller (rather than only [TextField.onChanged])
  /// keeps programmatic mutations — a caller clearing the code, autofill, a
  /// paste — reported through [AppOtpField.onChanged] too. Selection-only
  /// changes repaint the cells but must not be reported as value changes.
  void _handleControllerChanged() {
    if (_rearming) return;

    final text = _controller.text;
    final previous = _lastText;
    final textChanged = text != previous;
    final wasComplete = previous.length == widget.length;
    _lastText = text;

    // A replacement leaves the platform cursor collapsed just after the digit
    // it overwrote. Left alone, the NEXT keystroke composes against that caret
    // — an insertion, which shifts every following digit right (and, on a full
    // code, loses the tail to the length limiter). Re-arm a one-character
    // selection on the digit the cursor advanced onto so that keystroke
    // replaces it instead.
    //
    // Gated on the length being unchanged: a deletion must keep its ordinary
    // collapsed caret, and an append already sits past the end. Deliberately
    // runs BEFORE the `textChanged` guard — retyping a digit over itself is a
    // no-op edit that must still advance and arm the next position.
    if (text.length == previous.length) _armSelection();

    if (mounted) setState(() {});
    if (!textChanged) return;

    HapticFeedback.lightImpact();
    _field?.didChange(text);
    widget.onChanged?.call(text);
    if (text.length == widget.length && !wasComplete) {
      widget.onCompleted?.call(text);
    }
  }

  /// Keeps the core OTP invariant true: **every cell is a fixed position**.
  ///
  /// While the field is focused and the caret is not past the end, a position
  /// is always *selected*, so every keystroke replaces rather than inserts.
  /// Idempotent, and clears any IME composing region so a pending composition
  /// cannot re-anchor the edit back to insert semantics.
  void _armSelection() {
    final selection = _controller.selection;
    if (!selection.isValid || !selection.isCollapsed) return;

    final offset = selection.baseOffset;
    if (offset < 0 || offset >= _controller.text.length) return;

    final armed = TextSelection(baseOffset: offset, extentOffset: offset + 1);
    if (selection == armed) return;

    _rearming = true;
    _controller.value = _controller.value.copyWith(
      selection: armed,
      composing: TextRange.empty,
    );
    _rearming = false;
  }

  void _handleFocusChanged() {
    if (mounted) setState(() {});
  }

  /// Moves the selection onto the digit at [index].
  ///
  /// A filled cell is *selected* (not just cursored) so the next keystroke
  /// replaces that digit in place via ordinary text-input semantics, rather
  /// than appending. Tapping past the last typed digit resumes appending.
  void _handleCellTap(int index) {
    if (!widget.enabled) return;

    final wasFocused = _focusNode.hasFocus;
    if (!wasFocused) {
      _focusNode.requestFocus();
    } else {
      // Dismissing the keyboard via the platform's down-chevron does NOT
      // unfocus the underlying TextField — the FocusNode still reports
      // hasFocus, so requestFocus() is a no-op and the keyboard stays
      // hidden when the user taps a cell to resume typing (SAN-569).
      // Explicitly re-open the input connection so tapping any cell always
      // brings the keyboard back.
      SystemChannels.textInput.invokeMethod<void>('TextInput.show');
    }

    void apply() {
      if (!mounted) return;
      final text = _controller.text;
      _rearming = true;
      _controller.value = _controller.value.copyWith(
        selection: index < text.length
            ? TextSelection(baseOffset: index, extentOffset: index + 1)
            : TextSelection.collapsed(offset: text.length),
        composing: TextRange.empty,
      );
      _rearming = false;
      if (mounted) setState(() {});
    }

    apply();
    // Attaching focus can make the editable reset its own selection to the
    // end, so re-apply once this frame has settled. Idempotent.
    if (!wasFocused) {
      WidgetsBinding.instance.addPostFrameCallback((_) => apply());
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      initialValue: _controller.text,
      validator: widget.validator,
      enabled: widget.enabled,
      builder: (field) {
        _field = field;

        final explicitError = widget.errorText;
        final resolvedError =
            (explicitError != null && explicitError.isNotEmpty)
            ? explicitError
            : field.errorText;
        final hasError =
            widget.forceErrorState ||
            (resolvedError != null && resolvedError.isNotEmpty);

        final colors = context.appColors;
        final typography = context.appTypography;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Directionality(
              // OTP digits stay LTR in Arabic layouts.
              textDirection: TextDirection.ltr,
              child: Stack(
                children: [
                  // The real input, kept invisible: it owns the keyboard,
                  // selection, backspace, paste and autofill. Listed first so
                  // the cells above win hit-testing — no gesture-arena race
                  // between our per-cell taps and the editable's own
                  // tap/drag recognizers.
                  Positioned.fill(child: _buildHiddenInput()),
                  _buildCells(hasError: hasError),
                ],
              ),
            ),
            if (hasError &&
                resolvedError != null &&
                resolvedError.isNotEmpty) ...[
              SizedBox(height: AppSpacing.sm),
              Text(
                resolvedError,
                textAlign: TextAlign.start,
                style:
                    widget.errorTextStyle ??
                    FieldTokens.errorStyle(
                      typography,
                      colors,
                      Theme.of(context).brightness,
                    ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildHiddenInput() {
    // The hidden TextField spans the full row, and any paint from its own
    // text layout (selection highlight, cursor rect) lands at CHARACTER
    // positions inside the field, which do NOT align with the visible cell
    // positions above. Setting a tap-driven `selection` on the controller
    // would then leak a rounded highlight over the leftmost cells.
    // Neutralise both paints so the field is truly invisible.
    return DefaultSelectionStyle(
      selectionColor: Colors.transparent,
      cursorColor: Colors.transparent,
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        enabled: widget.enabled,
        autofocus: widget.autofocus,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.done,
        autofillHints: const [AutofillHints.oneTimeCode],
        // No composing region, no autocorrect: a live composition would
        // re-anchor an edit and defeat the fixed-position invariant.
        autocorrect: false,
        enableSuggestions: false,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(widget.length),
        ],
        // Invisible — the cells above are the presentation layer.
        //
        // `fontSize` is set explicitly rather than inherited: `TextField`
        // merges the ambient theme text style, and `responsiveFontSize` yields
        // NaN on a zero-sized first frame (`base * scaleWidth / scaleHeight` →
        // 0/0, which its clamp cannot catch since NaN comparisons are always
        // false). A NaN font size reaching the editable trips framework
        // asserts in `WidgetSpan.extractFromInlineSpan` and `textScaler.scale`.
        style: const TextStyle(
          color: Colors.transparent,
          fontSize: 16,
          height: 1,
        ),
        cursorColor: Colors.transparent,
        showCursor: false,
        // Native handles/toolbar would fight the per-cell taps; OTP paste
        // arrives through the keyboard's autofill suggestion instead.
        enableInteractiveSelection: false,
        // `null` (not a blanked-out InputDecoration) so no `InputDecorator` is
        // built at all. This field is invisible and renders no label, border or
        // error of its own, and a decorator would inherit the app's
        // `InputDecorationTheme` — whose `errorStyle` can carry a NaN font size
        // that crashes `textScaler.scale()` during layout.
        decoration: null,
        onSubmitted: widget.onSubmitted,
      ),
    );
  }

  Widget _buildCells({required bool hasError}) {
    final designedCellSize = responsiveDimension(widget.metrics.cellSize);
    final gap = responsiveDimension(widget.metrics.cellGap);
    return LayoutBuilder(
      builder: (context, constraints) {
        // Derive one `cellSize` for all six cells from the available width.
        // Every cell is built from the same value, so first/middle/last are
        // geometrically identical. When the row fits at its designed size,
        // that is the size we use; otherwise the whole row — cells *and*
        // gutters — scales down by one shared factor, so an overflowing row
        // keeps the cell:gap proportion its Figma frame specifies instead of
        // letting fixed gutters eat into the cells.
        //
        // This matters because a frame is drawn with however many cells fit
        // its mock, while `length` follows the backend's contract: the
        // provider frames dimension five 54.5dp cells with 16dp gutters in
        // the same width the six-digit code actually needs.
        var cellSize = designedCellSize;
        var cellGap = gap;
        final designedRowWidth =
            designedCellSize * widget.length + gap * (widget.length - 1);
        if (constraints.maxWidth.isFinite &&
            constraints.maxWidth < designedRowWidth &&
            designedRowWidth > 0) {
          final scale = constraints.maxWidth / designedRowWidth;
          cellSize = designedCellSize * scale;
          cellGap = gap * scale;
        }
        return Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < widget.length; i++) ...[
                if (i > 0) SizedBox(width: cellGap),
                GestureDetector(
                  key: otpCellKey(i),
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _handleCellTap(i),
                  child: Semantics(
                    label: 'Digit ${i + 1} of ${widget.length}',
                    child: _buildCell(
                      i,
                      cellSize: cellSize,
                      hasError: hasError,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildCell(
    int index, {
    required double cellSize,
    required bool hasError,
  }) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final brightness = Theme.of(context).brightness;
    final defaultWidth = responsiveDimension(widget.metrics.borderWidth);
    // No Figma-defined "selected for replacement" state exists (a static
    // frame can't show a tap interaction) — this affordance predates the
    // redesign and is preserved at proportionally the same 2x emphasis the
    // old shared field-border tokens used.
    final emphasisWidth = defaultWidth * 2;

    final text = _controller.text;
    final selection = _controller.selection;
    final focused = _focusNode.hasFocus;
    final hasDigit = index < text.length;
    final isSelectedDigit =
        focused &&
        selection.isValid &&
        !selection.isCollapsed &&
        index >= selection.start &&
        index < selection.end;
    final isCaretHere =
        focused &&
        selection.isValid &&
        selection.isCollapsed &&
        selection.baseOffset == index;
    final showPlaceholder = !hasDigit && !isCaretHere;

    // Border color, border width, and (for a filled digit) text color all
    // follow the same precedence: a cell targeted for replacement always
    // shows the primary color, even in an error state, so the user can see
    // which cell their next keystroke will hit; otherwise error beats plain
    // filled beats empty.
    final Color borderColor;
    final Color filledDigitColor;
    var borderWidth = defaultWidth;
    if (!widget.enabled) {
      borderColor = FieldTokens.disabledBorder(colors, brightness);
      filledDigitColor = FieldTokens.valueColor(
        colors,
        brightness,
        enabled: false,
      );
    } else if (isSelectedDigit) {
      borderColor = colors.primary;
      filledDigitColor = colors.primary;
      borderWidth = emphasisWidth;
    } else if (hasError) {
      // Figma's error cells keep the same border width as every other
      // state — only the color changes, for both the border and the digit.
      borderColor = colors.palettes.red.shade500;
      filledDigitColor = colors.palettes.red.shade500;
    } else if (hasDigit) {
      borderColor = colors.primary;
      filledDigitColor = colors.primary;
    } else {
      borderColor = _kOtpEmptyBorderColor;
      filledDigitColor = colors.primary;
    }

    final baseTextStyle = typography.regularNormal.copyWith(
      fontSize: responsiveDimension(widget.metrics.digitFontSize),
      height: widget.metrics.digitLineHeight,
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
      color: FieldTokens.valueColor(
        colors,
        brightness,
        enabled: widget.enabled,
      ),
    );
    final filledTextStyle = baseTextStyle.copyWith(color: filledDigitColor);
    final placeholderTextStyle = baseTextStyle.copyWith(
      fontSize: responsiveDimension(widget.metrics.placeholderFontSize),
      height: widget.metrics.placeholderLineHeight,
      color: _kOtpNeutralAccentColor,
    );

    final caret = _OtpCaret(
      color: _kOtpNeutralAccentColor,
      height: responsiveDimension(widget.metrics.caretHeight),
      width: responsiveDimension(widget.metrics.caretWidth),
    );

    return Container(
      width: cellSize,
      height: cellSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: FieldTokens.background(
          colors,
          brightness,
          enabled: widget.enabled,
        ),
        borderRadius: BorderRadius.circular(
          responsiveDimension(widget.metrics.cellRadius),
        ),
        border: Border.all(color: borderColor, width: borderWidth),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (hasDigit)
            Text(text[index], style: filledTextStyle)
          else if (showPlaceholder)
            Text('_', style: placeholderTextStyle),
          if (isCaretHere)
            // On a filled cell the caret sits at the leading edge, so a
            // cursor placed *between* digits reads correctly.
            Align(
              alignment: hasDigit ? Alignment.centerLeft : Alignment.center,
              child: hasDigit
                  ? Padding(
                      padding: EdgeInsets.only(left: AppSpacing.xs),
                      child: caret,
                    )
                  : caret,
            ),
        ],
      ),
    );
  }
}

/// Blinking caret, matching the platform text-cursor feel.
///
/// Note: this animation repeats indefinitely, so tests must use bounded
/// `pump()` calls rather than `pumpAndSettle()` while the field has focus.
class _OtpCaret extends StatefulWidget {
  const _OtpCaret({
    required this.color,
    required this.height,
    required this.width,
  });

  final Color color;
  final double height;
  final double width;

  @override
  State<_OtpCaret> createState() => _OtpCaretState();
}

class _OtpCaretState extends State<_OtpCaret>
    with SingleTickerProviderStateMixin {
  // Coincides numerically with AppMotionDuration.emphasis (500ms) — reused
  // rather than a duplicate literal, though a blink rate isn't fundamentally
  // an "emphasis" motion; kept as its own bespoke controller (auth-critical,
  // see class doc) rather than migrated onto app_animations' effects.
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotionDuration.emphasis,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = widget.width;
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: width,
        height: widget.height,
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(width / 2),
        ),
      ),
    );
  }
}
