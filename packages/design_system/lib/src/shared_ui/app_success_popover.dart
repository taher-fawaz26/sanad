import 'package:app_assets/app_assets.dart';
import 'package:design_system/src/components/app_popover.dart';
import 'package:design_system/src/components/app_svg_picture.dart';
import 'package:design_system/src/dimensions/responsive_dimension.dart';
import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:design_system/src/theme/tokens/dialog_tokens.dart';
import 'package:flutter/material.dart';

/// Check illustration for the success popover — Figma `365:15054`.
///
/// Dark-green circle + light-green check inside the 100 dp success ring
/// (`1546:8473` / `194:5419`).
class AppSuccessPopoverIllustration extends StatelessWidget {
  const AppSuccessPopoverIllustration({super.key});

  static const double _iconSize = 60;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final outerSize = context.appDialogTheme.spec.featureIconOuterSize;
    final iconSize = responsiveDimension(_iconSize);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.successContainer,
        shape: BoxShape.circle,
      ),
      child: SizedBox(
        width: outerSize,
        height: outerSize,
        child: Center(
          child: AppSvgPicture.asset(
            AppSvgs.successCheck,
            width: iconSize,
            height: iconSize,
          ),
        ),
      ),
    );
  }
}

/// Figma success popover content (`1546:8473`).
///
/// Prefer [showAppSuccessPopover] for the full modal experience.
class AppSuccessPopover extends StatelessWidget {
  const AppSuccessPopover({
    required this.title,
    required this.primaryLabel,
    super.key,
    this.titleWidget,
    this.description,
    this.onPrimary,
  });

  final String title;

  /// Optional rich title — overrides [title] when set (e.g. split i18n spans).
  final Widget? titleWidget;
  final String? description;
  final String primaryLabel;
  final VoidCallback? onPrimary;

  /// Title style for success popovers — Figma `main/600` (`1546:8477`).
  static TextStyle titleStyleOf(BuildContext context) {
    final colors = context.appColors;
    final spec = context.appDialogTheme.spec;
    return spec.titleStyle.copyWith(color: colors.primary);
  }

  @override
  Widget build(BuildContext context) {
    return AppPopover(
      title: title,
      titleWidget: titleWidget ??
          Text(
            title,
            style: titleStyleOf(context),
            textAlign: TextAlign.center,
          ),
      description: description,
      imageLayout: AppDialogImageLayout.iconSmall,
      image: const AppSuccessPopoverIllustration(),
      actions: AppPopoverActions.single,
      primaryLabel: primaryLabel,
      onPrimary: onPrimary,
    );
  }
}

/// Shows the Figma success popover (`1546:8473`) — check illustration, primary
/// (main/600) title, muted description, single Okay CTA.
///
/// Use this everywhere a flow completes successfully (add branch, invite
/// worker, etc.) so the chrome stays identical app-wide.
Future<T?> showAppSuccessPopover<T>({
  required BuildContext context,
  required String title,
  Widget? titleWidget,
  String? description,
  String? primaryLabel,
  VoidCallback? onPrimary,
  bool barrierDismissible = false,
}) {
  return showAppPopover<T>(
    context: context,
    title: title,
    titleWidget: titleWidget ??
        (title.isEmpty
            ? null
            : Text(
                title,
                style: AppSuccessPopover.titleStyleOf(context),
                textAlign: TextAlign.center,
              )),
    description: description,
    imageLayout: AppDialogImageLayout.iconSmall,
    image: const AppSuccessPopoverIllustration(),
    actions: AppPopoverActions.single,
    primaryLabel: primaryLabel,
    onPrimary: onPrimary,
    barrierDismissible: barrierDismissible,
  );
}
