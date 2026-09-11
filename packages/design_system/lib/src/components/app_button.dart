import 'package:app_animations/app_animations.dart';
import 'package:design_system/design_system.dart';
import 'package:design_system/src/spacing/responsive_spacing.dart';
import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:design_system/src/theme/tokens/button_tokens.dart';
import 'package:design_system/src/theme/typography/app_typography.dart';
import 'package:flutter/material.dart';

/// Figma `Controls / Buttons` (`30:1738`, `731:3785`).
///
/// [variant] is the visual form (primary/secondary/outline/transparent) and
/// [intent] is the semantic color (standard/warning/destructive) — the two
/// are orthogonal, so any combination (e.g. `outline` + `destructive`) is
/// valid.
///
/// Icon positions:
/// - [AppButtonIconPosition.none] — label only, centered
/// - [AppButtonIconPosition.left] — icon at leading edge, label centered
/// - [AppButtonIconPosition.right] — icon at trailing edge, label centered
/// - [AppButtonIconPosition.center] — icon + label grouped and centered
class AppButton extends StatefulWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.variant = AppButtonVariant.primary,
    this.intent = AppButtonIntent.standard,
    this.size = AppButtonSize.block,
    this.icon,
    this.iconPosition = AppButtonIconPosition.none,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonIntent intent;
  final AppButtonSize size;
  final Widget? icon;
  final AppButtonIconPosition iconPosition;
  final bool isLoading;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _pressed = false;

  bool get _hasIcon =>
      widget.icon != null && widget.iconPosition != AppButtonIconPosition.none;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final brightness = Theme.of(context).brightness;
    final enabled = widget.onPressed != null && !widget.isLoading;

    final states = <WidgetState>{
      if (!enabled) WidgetState.disabled,
      if (_pressed && enabled) WidgetState.pressed,
    };

    final surface = ButtonTokens.resolve(
      variant: widget.variant,
      intent: widget.intent,
      colors: colors,
      brightness: brightness,
      states: states,
    );

    final minHeight = ButtonTokens.minHeight(widget.size);
    final radius = ButtonTokens.borderRadius();
    final textStyle = ButtonTokens.labelStyle(typography).copyWith(
      color: surface.foreground,
    );

    final child = _buildContent(textStyle);

    final button = Material(
      color: surface.background,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: surface.hasBorder
            ? BorderSide(color: surface.border)
            : BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? widget.onPressed : null,
        onHighlightChanged: enabled
            ? (value) => setState(() => _pressed = value)
            : null,
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: minHeight),
          child: Padding(
            padding: ButtonTokens.padding(widget.size),
            child: child,
          ),
        ),
      ),
    );

    // Subtle tactile press feedback on top of the ripple, restrained enough
    // not to make repeated taps feel slow. A transform, so it is gated by
    // reduced motion (unlike the color change, which stays instant either
    // way via `ButtonTokens.resolve`).
    final canScale = _pressed && enabled && !AppMotion.reduceMotionOf(context);
    final pressedScale = canScale ? 0.97 : 1.0;
    final scaledButton = AnimatedScale(
      scale: pressedScale,
      duration: AppMotionDuration.fast,
      curve: AppMotionCurve.standard,
      child: button,
    );

    final semanticButton = Semantics(
      button: true,
      enabled: enabled,
      liveRegion: widget.isLoading,
      child: scaledButton,
    );

    if (widget.size == AppButtonSize.block) {
      return SizedBox(width: double.infinity, child: semanticButton);
    }

    return semanticButton;
  }

  Widget _buildContent(TextStyle textStyle) {
    if (widget.isLoading) {
      return Center(
        child: AppLoadingIndicator(
          size: ButtonTokens.spinnerSize(widget.size),
        ),
      );
    }

    final labelWidget = Text(
      widget.label,
      style: textStyle,
      textAlign: TextAlign.center,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    if (!_hasIcon) {
      return Center(child: labelWidget);
    }

    final iconWidget = SizedBox(
      width: ButtonTokens.iconBoxSize(),
      height: ButtonTokens.iconBoxSize(),
      child: IconTheme(
        data: IconThemeData(
          color: textStyle.color,
          size: ButtonTokens.iconBoxSize(),
        ),
        child: widget.icon!,
      ),
    );

    return switch (widget.iconPosition) {
      // Figma `Icon Position=Side` (`731:3785`) — icon + label centered as a group.
      AppButtonIconPosition.center => Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            iconWidget,
            SizedBox(width: AppSpacing.sm),
            Flexible(child: labelWidget),
          ],
        ),
      ),
      // Figma `Icon Position=Left` — icon at leading edge, label centered.
      AppButtonIconPosition.left => Stack(
        alignment: Alignment.center,
        children: [
          Center(child: labelWidget),
          Positioned(
            left: 0,
            child: iconWidget,
          ),
        ],
      ),
      // Figma `Icon Position=Right` — icon at trailing edge, label centered.
      AppButtonIconPosition.right => Stack(
        alignment: Alignment.center,
        children: [
          Center(child: labelWidget),
          Positioned(
            right: 0,
            child: iconWidget,
          ),
        ],
      ),
      AppButtonIconPosition.none => Center(child: labelWidget),
    };
  }
}

/// Convenience constructors for the most common Figma button presets — all
/// implicitly `intent: AppButtonIntent.standard`. For warning/destructive
/// CTAs, pass `intent:` directly to [AppButton].
extension AppButtonPresets on AppButton {
  static AppButton primary({
    required String label,
    required VoidCallback? onPressed,
    Key? key,
    AppButtonSize size = AppButtonSize.block,
    Widget? icon,
    AppButtonIconPosition iconPosition = AppButtonIconPosition.none,
    bool isLoading = false,
  }) {
    return AppButton(
      key: key,
      label: label,
      onPressed: onPressed,
      size: size,
      icon: icon,
      iconPosition: iconPosition,
      isLoading: isLoading,
    );
  }

  static AppButton secondary({
    required String label,
    required VoidCallback? onPressed,
    Key? key,
    AppButtonSize size = AppButtonSize.block,
    Widget? icon,
    AppButtonIconPosition iconPosition = AppButtonIconPosition.none,
    bool isLoading = false,
  }) {
    return AppButton(
      key: key,
      label: label,
      onPressed: onPressed,
      variant: AppButtonVariant.secondary,
      size: size,
      icon: icon,
      iconPosition: iconPosition,
      isLoading: isLoading,
    );
  }

  static AppButton outline({
    required String label,
    required VoidCallback? onPressed,
    Key? key,
    AppButtonSize size = AppButtonSize.block,
    Widget? icon,
    AppButtonIconPosition iconPosition = AppButtonIconPosition.none,
    bool isLoading = false,
  }) {
    return AppButton(
      key: key,
      label: label,
      onPressed: onPressed,
      variant: AppButtonVariant.outline,
      size: size,
      icon: icon,
      iconPosition: iconPosition,
      isLoading: isLoading,
    );
  }

  static AppButton transparent({
    required String label,
    required VoidCallback? onPressed,
    Key? key,
    AppButtonSize size = AppButtonSize.block,
    Widget? icon,
    AppButtonIconPosition iconPosition = AppButtonIconPosition.none,
    bool isLoading = false,
  }) {
    return AppButton(
      key: key,
      label: label,
      onPressed: onPressed,
      variant: AppButtonVariant.transparent,
      size: size,
      icon: icon,
      iconPosition: iconPosition,
      isLoading: isLoading,
    );
  }
}
