import 'package:design_system/src/spacing/responsive_spacing.dart';
import 'package:design_system/src/theme/tokens/snackbar_tokens.dart';
import 'package:flutter/material.dart';

/// Figma `Views / Snackbars` (`97:3434`).
class AppSnackbar extends StatelessWidget {
  const AppSnackbar({
    required this.title, super.key,
    this.caption,
    this.color = AppSnackbarColor.dark,
    this.layout = AppSnackbarLayout.box,
    this.action = AppSnackbarAction.none,
    this.actionLabel,
    this.onAction,
    this.leadingIcon,
    this.trailingIcon,
    this.onTrailingIconTap,
  });

  final String title;
  final String? caption;
  final AppSnackbarColor color;
  final AppSnackbarLayout layout;
  final AppSnackbarAction action;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? leadingIcon;
  final Widget? trailingIcon;
  final VoidCallback? onTrailingIconTap;

  bool get _hasCaption => caption != null && caption!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final theme = context.appSnackbarTheme;
    final spec = theme.specFor(color);
    final isFullWidth = layout == AppSnackbarLayout.fullWidth;

    final content = Row(
      children: [
        if (leadingIcon != null) ...[
          SizedBox(
            width: spec.iconSize,
            height: spec.iconSize,
            child: leadingIcon,
          ),
          SizedBox(width: spec.contentGap),
        ],
        Expanded(child: _buildTextBlock(spec)),
        if (action == AppSnackbarAction.text && actionLabel != null) ...[
          SizedBox(width: spec.contentGap),
          GestureDetector(
            onTap: onAction,
            child: Text(actionLabel!, style: spec.actionStyle),
          ),
        ],
        if (action == AppSnackbarAction.icon) ...[
          SizedBox(width: spec.contentGap),
          GestureDetector(
            onTap: onTrailingIconTap,
            child: SizedBox(
              width: spec.iconSize,
              height: spec.iconSize,
              child: trailingIcon ?? const Icon(Icons.close, size: 24),
            ),
          ),
        ],
      ],
    );

    return Container(
      width: isFullWidth ? double.infinity : spec.boxMaxWidth,
      padding: spec.padding(hasCaption: _hasCaption),
      decoration: BoxDecoration(
        color: spec.backgroundColor,
        borderRadius: isFullWidth ? null : spec.borderRadius,
      ),
      child: content,
    );
  }

  Widget _buildTextBlock(SnackbarStyleSpec spec) {
    if (!_hasCaption) {
      return Text(title, style: spec.titleStyle);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: spec.titleStyle),
        SizedBox(height: spec.textGap),
        Text(caption!, style: spec.captionStyle),
      ],
    );
  }
}

/// Shows a Figma-styled snackbar.
void showAppSnackbar({
  required BuildContext context,
  required String title,
  String? caption,
  AppSnackbarColor color = AppSnackbarColor.dark,
  AppSnackbarLayout layout = AppSnackbarLayout.box,
  AppSnackbarAction action = AppSnackbarAction.none,
  String? actionLabel,
  VoidCallback? onAction,
  Widget? leadingIcon,
  Widget? trailingIcon,
  VoidCallback? onTrailingIconTap,
  Duration duration = const Duration(seconds: 4),
}) {
  final theme = context.appSnackbarTheme;
  final spec = theme.specFor(color);
  final isFullWidth = layout == AppSnackbarLayout.fullWidth;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      padding: EdgeInsets.zero,
      duration: duration,
      behavior:
          isFullWidth ? SnackBarBehavior.fixed : SnackBarBehavior.floating,
      margin: isFullWidth ? null : EdgeInsets.all(AppSpacing.lg),
      content: AppSnackbar(
        title: title,
        caption: caption,
        color: color,
        layout: layout,
        action: action,
        actionLabel: actionLabel,
        onAction: onAction,
        leadingIcon: leadingIcon,
        trailingIcon: trailingIcon,
        onTrailingIconTap: onTrailingIconTap,
      ),
      shape: isFullWidth
          ? null
          : RoundedRectangleBorder(borderRadius: spec.borderRadius),
    ),
  );
}

/// Shows an error-styled snackbar ([AppSnackbarColor.error]).
///
/// Use this for failure feedback so errors are visually distinct from neutral
/// and success messages instead of sharing the default `dark` style.
void showAppErrorSnackbar({
  required BuildContext context,
  required String title,
  String? caption,
  AppSnackbarLayout layout = AppSnackbarLayout.box,
  Duration duration = const Duration(seconds: 4),
}) {
  showAppSnackbar(
    context: context,
    title: title,
    caption: caption,
    color: AppSnackbarColor.error,
    layout: layout,
    duration: duration,
  );
}
