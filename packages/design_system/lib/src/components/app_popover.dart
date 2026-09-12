import 'package:app_animations/app_animations.dart';
import 'package:design_system/src/components/app_button.dart';
import 'package:design_system/src/components/app_feature_icon.dart';
import 'package:design_system/src/components/app_text_field.dart';
import 'package:design_system/src/spacing/responsive_spacing.dart';
import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:design_system/src/theme/tokens/button_tokens.dart';
import 'package:design_system/src/theme/tokens/dialog_tokens.dart';
import 'package:design_system/src/theme/tokens/feature_icon_tokens.dart';
import 'package:design_system/src/theme/typography/app_typography.dart';
import 'package:flutter/material.dart';

/// Figma `Views / Popovers` action slot configuration (`40:10028`).
enum AppPopoverActions {
  /// Text-only popover (`40:10077`).
  none,

  /// Primary CTA only (`40:10069`).
  single,

  /// Primary + transparent secondary (`40:10029`).
  dual,

  /// Text field + dual buttons (`40:10048`).
  textInput,
}

/// How an [AppPopover]'s title, description and field label are aligned.
enum AppPopoverAlignment {
  /// Centered — Figma `Views / Popovers` (`40:10028`), the alert-style
  /// confirmations this component was built for.
  center,

  /// Leading-aligned — Figma's task modals (`8516:32425` "Delete
  /// conversation", `8516:32435` "Rename Conversation"), which read as a
  /// short form rather than an alert and put their copy on the same edge as
  /// the field label under it.
  ///
  /// `EdgeInsetsDirectional`-style: leading, so RTL mirrors with no branch.
  start,
}

/// Figma `Views / Popovers` (`40:10028`) — centered alert-style modal.
class AppPopover extends StatelessWidget {
  const AppPopover({
    required this.title,
    super.key,
    this.titleWidget,
    this.description,
    this.imageLayout = AppDialogImageLayout.none,
    this.image,
    this.featureIconColor,
    this.featureIconSize = AppFeatureIconSize.xl,
    this.featureIconTheme = AppFeatureIconTheme.lightCircle,
    this.featureIconAsset,
    this.featureIconBackgroundColor,
    this.actions = AppPopoverActions.dual,
    this.primaryLabel,
    this.onPrimary,
    this.primaryDestructive = false,
    this.secondaryLabel,
    this.onSecondary,
    this.secondaryOutlined = false,
    this.inputField,
    this.textFieldController,
    this.textFieldHint,
    this.textFieldLabel,
    this.onTextFieldChanged,
    this.alignment = AppPopoverAlignment.center,
  });

  final String title;

  /// Optional rich title — overrides [title] text when set.
  final Widget? titleWidget;
  final String? description;
  final AppDialogImageLayout imageLayout;
  final Widget? image;

  /// When [imageLayout] is [AppDialogImageLayout.iconSmall], renders a featured
  /// icon inside a circular ring (`194:5419`) instead of a clipped [image].
  final AppFeatureIconColor? featureIconColor;
  final AppFeatureIconSize featureIconSize;
  final AppFeatureIconTheme featureIconTheme;

  /// Optional SVG override for the featured icon (e.g. settings gear).
  final String? featureIconAsset;
  final Color? featureIconBackgroundColor;
  final AppPopoverActions actions;
  final String? primaryLabel;
  final VoidCallback? onPrimary;

  /// When `true`, primary CTA uses the red/danger palette.
  final bool primaryDestructive;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  /// Draws the secondary action as an outlined [AppButton] rather than the
  /// soft sky fill — Figma's task modals outline Cancel in the brand green
  /// (`8516:32425`), where the alert-style popovers fill it.
  final bool secondaryOutlined;

  final Widget? inputField;
  final TextEditingController? textFieldController;
  final String? textFieldHint;

  /// Label drawn above the built-in text field — Figma `New name`
  /// (`8516:32435`). Ignored when [inputField] supplies its own.
  final String? textFieldLabel;

  final ValueChanged<String>? onTextFieldChanged;

  /// See [AppPopoverAlignment]. Defaults to centered, which is every
  /// pre-existing caller.
  final AppPopoverAlignment alignment;

  @override
  Widget build(BuildContext context) {
    final spec = context.appDialogTheme.spec;
    final isHero = imageLayout == AppDialogImageLayout.heroHeader;

    if (isHero) {
      return _buildHeroLayout(context, spec);
    }

    return _buildStandardLayout(context, spec);
  }

  Widget _buildStandardLayout(BuildContext context, DialogStyleSpec spec) {
    final hasInlineImage =
        imageLayout == AppDialogImageLayout.imageLarge ||
        imageLayout == AppDialogImageLayout.iconSmall;

    return Container(
      decoration: BoxDecoration(
        color: spec.backgroundColor,
        borderRadius: spec.borderRadius,
      ),
      padding: spec.paddingFor(imageLayout),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        // Only the leading-aligned layout stretches: a centered popover sizes
        // itself to its widest child, and widening every existing dialog to
        // fill the inset would be a redesign of all of them.
        crossAxisAlignment: alignment == AppPopoverAlignment.start
            ? CrossAxisAlignment.stretch
            : CrossAxisAlignment.center,
        children: [
          if (hasInlineImage) ...[
            _buildInlineImage(context, spec),
            SizedBox(height: spec.sectionGap),
          ],
          _buildTextBlock(spec),
          if (actions == AppPopoverActions.textInput) ...[
            SizedBox(height: spec.sectionGap),
            _buildInputField(context),
          ],
          if (_hasActions) ...[
            SizedBox(height: spec.sectionGap),
            _buildActions(context),
          ],
        ],
      ),
    );
  }

  Widget _buildHeroLayout(BuildContext context, DialogStyleSpec spec) {
    final radius = spec.borderRadius.topLeft.x;

    return Container(
      decoration: BoxDecoration(
        color: spec.backgroundColor,
        borderRadius: spec.borderRadius,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: spec.heroImageHeight,
            width: double.infinity,
            child: _buildHeroImage(spec, radius),
          ),
          Padding(
            padding: spec.contentPadding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextBlock(spec, fullWidth: true),
                if (actions == AppPopoverActions.textInput) ...[
                  SizedBox(height: spec.sectionGap),
                  _buildInputField(context),
                ],
                if (_hasActions) ...[
                  SizedBox(height: spec.sectionGap),
                  _buildActions(context),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInlineImage(BuildContext context, DialogStyleSpec spec) {
    if (imageLayout == AppDialogImageLayout.iconSmall &&
        featureIconColor != null) {
      return _buildFeatureIconIllustration(context, spec);
    }

    // Custom featured icon without the success-popover outer ring.
    if (image != null && imageLayout == AppDialogImageLayout.iconSmall) {
      return image!;
    }

    final size = spec.inlineImageSize(imageLayout);
    return ClipRRect(
      borderRadius: spec.imageBorderRadius,
      child: SizedBox(
        width: size,
        height: size,
        child:
            image ??
            ColoredBox(
              color: spec.imagePlaceholderColor,
              child: const Center(child: Icon(Icons.image_outlined)),
            ),
      ),
    );
  }

  Widget _buildFeatureIconIllustration(
    BuildContext context,
    DialogStyleSpec spec,
  ) {
    final colors = context.appColors;
    final icon = AppFeatureIcon(
      color: featureIconColor!,
      size: featureIconSize,
      theme: featureIconTheme,
      iconAsset: featureIconAsset,
    );

    // Outer ring is only for the success-style popover (`194:5419`).
    // Confirm dialogs pass [image] or omit [featureIconBackgroundColor]
    // and use the featured icon alone when no outer color is set and size
    // is not wrapped — keep outer ring when background color is provided
    // OR when using the default success path (background null → success).
    if (featureIconBackgroundColor == null &&
        featureIconColor != AppFeatureIconColor.success) {
      return icon;
    }

    final outerSize = spec.featureIconOuterSize;

    return SizedBox(
      width: outerSize,
      height: outerSize,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: featureIconBackgroundColor ?? colors.successContainer,
          shape: BoxShape.circle,
        ),
        child: Center(child: icon),
      ),
    );
  }

  Widget _buildHeroImage(DialogStyleSpec spec, double radius) {
    return image ??
        ColoredBox(
          color: spec.imagePlaceholderColor,
          child: const Center(
            child: Icon(Icons.image_outlined, size: 48),
          ),
        );
  }

  Widget _buildTextBlock(DialogStyleSpec spec, {bool fullWidth = false}) {
    final isStart = alignment == AppPopoverAlignment.start;
    final textAlign = isStart ? TextAlign.start : TextAlign.center;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: isStart
          ? CrossAxisAlignment.stretch
          : CrossAxisAlignment.center,
      children: [
        titleWidget ??
            Text(
              title,
              style: spec.titleStyle,
              textAlign: textAlign,
            ),
        if (description != null) ...[
          SizedBox(height: spec.textGap),
          Text(
            description!,
            style: spec.descriptionStyle,
            textAlign: textAlign,
          ),
        ],
      ],
    );
  }

  Widget _buildInputField(BuildContext context) {
    if (inputField != null) {
      return inputField!;
    }

    return AppTextField(
      controller: textFieldController,
      // `AppTextField` already draws its own label above the box with the
      // design system's field-label style, so there is nothing to compose
      // here — passing it through is the whole integration.
      label: textFieldLabel,
      hint: textFieldHint ?? 'Input text',
      onChanged: onTextFieldChanged,
    );
  }

  Widget _buildActions(BuildContext context) {
    final colors = context.appColors;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (primaryLabel != null)
          AppButton(
            label: primaryLabel!,
            onPressed: onPrimary,
            intent: primaryDestructive
                ? AppButtonIntent.destructive
                : AppButtonIntent.standard,
          ),
        if (actions == AppPopoverActions.dual ||
            actions == AppPopoverActions.textInput) ...[
          if (primaryLabel != null) SizedBox(height: AppSpacing.md),
          if (secondaryLabel != null)
            if (secondaryOutlined)
              AppButton(
                label: secondaryLabel!,
                onPressed: onSecondary,
                variant: AppButtonVariant.outline,
              )
            else
              _SecondaryAction(
                label: secondaryLabel!,
                onPressed: onSecondary,
                backgroundColor: colors.palettes.sky.shade50,
                foregroundColor: colors.textPrimary,
              ),
        ],
      ],
    );
  }

  bool get _hasActions =>
      actions == AppPopoverActions.single ||
      actions == AppPopoverActions.dual ||
      actions == AppPopoverActions.textInput;
}

/// Secondary popover action — soft sky fill (Figma cancel on confirm modals).
class _SecondaryAction extends StatelessWidget {
  const _SecondaryAction({
    required this.label,
    required this.onPressed,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    final typography = context.appTypography;
    final radius = ButtonTokens.borderRadius();

    return Material(
      color: backgroundColor,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        borderRadius: radius,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: ButtonTokens.minHeight(AppButtonSize.block),
          ),
          child: Center(
            child: Text(
              label,
              style: ButtonTokens.labelStyle(typography).copyWith(
                color: foregroundColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shows [builder] as a dialog with the app's shared dialog motion: a fade
/// paired with a subtle scale-up (`AppMotionDuration.quick`,
/// `AppMotionCurve.emphasizedDecelerate`), distinct from both the page
/// (shared-axis slide) and sheet (vertical slide) transitions so a dialog
/// reads as its own kind of surface.
///
/// The single entry point for every dialog in the app — [showAppPopover] and
/// `AppProgress` (`shared_ui`) both route through this instead of the plain
/// `showDialog`, which only ships Flutter's unstyled default transition.
Future<T?> showAppAnimatedDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  Color? barrierColor,
  bool useRootNavigator = true,
}) {
  final label = MaterialLocalizations.of(context).modalBarrierDismissLabel;
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: label,
    barrierColor: barrierColor ?? Colors.black54,
    useRootNavigator: useRootNavigator,
    // `AppMotionDuration.quick` (200ms) happens to equal Flutter's own
    // default here — kept explicit so the value is sourced from the shared
    // motion token, not an incidental match.
    // ignore: avoid_redundant_argument_values
    transitionDuration: AppMotionDuration.quick,
    pageBuilder: (dialogContext, animation, secondaryAnimation) =>
        builder(dialogContext),
    transitionBuilder: (dialogContext, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: AppMotionCurve.emphasizedDecelerate,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(
            begin: 0.94,
            end: 1,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// Shows a Figma-aligned popover dialog.
Future<T?> showAppPopover<T>({
  required BuildContext context,
  required String title,
  Widget? titleWidget,
  String? description,
  AppDialogImageLayout imageLayout = AppDialogImageLayout.none,
  Widget? image,
  AppFeatureIconColor? featureIconColor,
  AppFeatureIconSize featureIconSize = AppFeatureIconSize.xl,
  AppFeatureIconTheme featureIconTheme = AppFeatureIconTheme.lightCircle,
  String? featureIconAsset,
  Color? featureIconBackgroundColor,
  AppPopoverActions actions = AppPopoverActions.dual,
  String? primaryLabel,
  VoidCallback? onPrimary,
  bool primaryDestructive = false,
  String? secondaryLabel,
  VoidCallback? onSecondary,
  bool secondaryOutlined = false,
  Widget? inputField,
  TextEditingController? textFieldController,
  String? textFieldHint,
  String? textFieldLabel,
  ValueChanged<String>? onTextFieldChanged,
  AppPopoverAlignment alignment = AppPopoverAlignment.center,
  bool barrierDismissible = true,
}) {
  final spec = context.appDialogTheme.spec;

  return showAppAnimatedDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierColor: spec.barrierColor,
    builder: (dialogContext) {
      return Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: EdgeInsets.symmetric(horizontal: spec.horizontalInset),
        child: AppPopover(
          title: title,
          titleWidget: titleWidget,
          description: description,
          imageLayout: imageLayout,
          image: image,
          featureIconColor: featureIconColor,
          featureIconSize: featureIconSize,
          featureIconTheme: featureIconTheme,
          featureIconAsset: featureIconAsset,
          featureIconBackgroundColor: featureIconBackgroundColor,
          actions: actions,
          primaryLabel: primaryLabel,
          onPrimary: onPrimary ?? () => Navigator.of(dialogContext).pop(),
          primaryDestructive: primaryDestructive,
          secondaryLabel: secondaryLabel,
          onSecondary: onSecondary ?? () => Navigator.of(dialogContext).pop(),
          secondaryOutlined: secondaryOutlined,
          inputField: inputField,
          textFieldController: textFieldController,
          textFieldHint: textFieldHint,
          textFieldLabel: textFieldLabel,
          onTextFieldChanged: onTextFieldChanged,
          alignment: alignment,
        ),
      );
    },
  );
}

/// Alias for [AppPopover] — matches token naming in [DialogTokens].
typedef AppDialog = AppPopover;

/// Alias for [showAppPopover].
Future<T?> showAppDialog<T>({
  required BuildContext context,
  required String title,
  Widget? titleWidget,
  String? description,
  AppDialogImageLayout imageLayout = AppDialogImageLayout.none,
  Widget? image,
  AppFeatureIconColor? featureIconColor,
  AppFeatureIconSize featureIconSize = AppFeatureIconSize.xl,
  AppFeatureIconTheme featureIconTheme = AppFeatureIconTheme.lightCircle,
  String? featureIconAsset,
  Color? featureIconBackgroundColor,
  AppPopoverActions actions = AppPopoverActions.dual,
  String? primaryLabel,
  VoidCallback? onPrimary,
  bool primaryDestructive = false,
  String? secondaryLabel,
  VoidCallback? onSecondary,
  bool secondaryOutlined = false,
  Widget? inputField,
  TextEditingController? textFieldController,
  String? textFieldHint,
  String? textFieldLabel,
  ValueChanged<String>? onTextFieldChanged,
  AppPopoverAlignment alignment = AppPopoverAlignment.center,
  bool barrierDismissible = true,
}) {
  return showAppPopover<T>(
    context: context,
    title: title,
    titleWidget: titleWidget,
    description: description,
    imageLayout: imageLayout,
    image: image,
    featureIconColor: featureIconColor,
    featureIconSize: featureIconSize,
    featureIconTheme: featureIconTheme,
    featureIconAsset: featureIconAsset,
    featureIconBackgroundColor: featureIconBackgroundColor,
    actions: actions,
    primaryLabel: primaryLabel,
    onPrimary: onPrimary,
    primaryDestructive: primaryDestructive,
    secondaryLabel: secondaryLabel,
    onSecondary: onSecondary,
    secondaryOutlined: secondaryOutlined,
    inputField: inputField,
    textFieldController: textFieldController,
    textFieldHint: textFieldHint,
    textFieldLabel: textFieldLabel,
    onTextFieldChanged: onTextFieldChanged,
    alignment: alignment,
    barrierDismissible: barrierDismissible,
  );
}
