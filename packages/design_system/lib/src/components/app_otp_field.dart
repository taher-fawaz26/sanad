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
    this.enabled = true,
    this.autofocus = false,
    this.forceErrorState = false,
    this.errorText,
    this.validator,
    this.onChanged,
    this.onCompleted,
    this.onSubmitted,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;

  /// Number of pin cells. Defaults to [kDefaultOtpLength] (6).
  final int length;
  final bool enabled;
  final bool autofocus;
  final bool forceErrorState;
  final String? errorText;
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
    final text = _controller.text;
    final textChanged = text != _lastText;
    final wasComplete = _lastText.length == widget.length;
    _lastText = text;

    if (mounted) setState(() {});
    if (!textChanged) return;

    HapticFeedback.lightImpact();
    _field?.didChange(text);
    widget.onChanged?.call(text);
    if (text.length == widget.length && !wasComplete) {
      widget.onCompleted?.call(text);
    }
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
      _controller.selection = index < text.length
          ? TextSelection(baseOffset: index, extentOffset: index + 1)
          : TextSelection.collapsed(offset: text.length);
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
                textAlign: TextAlign.center,
                style: FieldTokens.errorStyle(
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
    final designedCellSize = AppDimension.otpCellSize;
    final gap = AppSpacing.lg;
    return LayoutBuilder(
      builder: (context, constraints) {
        // Derive one `cellSize` for all six cells from the available width.
        // Every cell is built from the same value, so first/middle/last are
        // geometrically identical. When the row fits at its designed size,
        // that is the size we use; otherwise every cell shrinks by the same
        // amount, keeping the row balanced.
        var cellSize = designedCellSize;
        final gapsTotal = gap * (widget.length - 1);
        final maxCellFromWidth =
            (constraints.maxWidth - gapsTotal) / widget.length;
        if (maxCellFromWidth.isFinite && maxCellFromWidth < designedCellSize) {
          cellSize = maxCellFromWidth;
        }
        return Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < widget.length; i++) ...[
                if (i > 0) SizedBox(width: gap),
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
    final defaultWidth = responsiveDimension(FieldTokens.borderWidthDefault);
    final emphasisWidth = responsiveDimension(FieldTokens.borderWidthEmphasis);

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

    final baseTextStyle = typography.largeNormal.copyWith(
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
      color: FieldTokens.valueColor(
        colors,
        brightness,
        enabled: widget.enabled,
      ),
    );
    // Filled digits use the primary teal colour.
    final filledTextStyle = baseTextStyle.copyWith(color: colors.primary);

    final Color borderColor;
    var borderWidth = defaultWidth;
    if (!widget.enabled) {
      borderColor = FieldTokens.disabledBorder(colors, brightness);
    } else if (isSelectedDigit) {
      // Targeted for replacement — emphasise even in error state
      // so the user sees which cell gets their next keystroke.
      borderColor = colors.primary;
      borderWidth = emphasisWidth;
    } else if (hasError) {
      borderColor = FieldTokens.errorBorder(colors, brightness);
      borderWidth = emphasisWidth;
    } else if (hasDigit) {
      borderColor = colors.primary;
    } else {
      borderColor = FieldTokens.borderDefault(colors, brightness);
    }

    final caretHeight =
        (baseTextStyle.fontSize ?? responsiveDimension(20)) * 1.2;
    final caret = _OtpCaret(color: colors.primary, height: caretHeight);

    return Container(
      width: cellSize,
      height: cellSize * 1.5,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: FieldTokens.background(
          colors,
          brightness,
          enabled: widget.enabled,
        ),
        // --corner/large from the design system: 13.631 dp → 14 dp
        borderRadius: BorderRadius.circular(responsiveDimension(14)),
        border: Border.all(color: borderColor, width: borderWidth),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (hasDigit) Text(text[index], style: filledTextStyle),
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
  const _OtpCaret({required this.color, required this.height});

  final Color color;
  final double height;

  @override
  State<_OtpCaret> createState() => _OtpCaretState();
}

class _OtpCaretState extends State<_OtpCaret>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = responsiveDimension(2);
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
