import 'package:app_assets/app_assets.dart';
import 'package:design_system/src/components/app_button.dart';
import 'package:design_system/src/dimensions/responsive_dimension.dart';
import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:design_system/src/theme/tokens/button_tokens.dart';
import 'package:design_system/src/theme/tokens/empty_state_tokens.dart';
import 'package:design_system/src/theme/typography/app_typography.dart';
import 'package:flutter/material.dart';

/// Package-aware raster illustration for [AppEmptyState].
class AppEmptyStateImage extends StatelessWidget {
  const AppEmptyStateImage({
    required this.assetPath,
    super.key,
    this.package = AppAssets.package,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
  });

  final String assetPath;
  final String? package;
  final double? width;
  final double? height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      package: package,
      width: width,
      height: height,
      fit: fit,
    );
  }
}

/// Figma `empty states` (`321:8333`) — reusable centered illustration, copy,
/// and optional primary action.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    required this.title,
    required this.description,
    required this.illustration,
    super.key,
    this.actionLabel,
    this.onAction,
    this.actionIcon,
    this.actionIconPosition = AppButtonIconPosition.none,
  });

  final Widget illustration;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? actionIcon;
  final AppButtonIconPosition actionIconPosition;

  @override
  Widget build(BuildContext context) {
    final spec = EmptyStateTokens.resolve(
      colors: context.appColors,
      typography: context.appTypography,
    );

    final content = Padding(
      padding: EdgeInsets.fromLTRB(
        spec.horizontalPadding,
        spec.topPadding,
        spec.horizontalPadding,
        spec.bottomPadding,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          illustration,
          SizedBox(height: spec.sectionGap),
          SizedBox(
            width: spec.contentWidth,
            child: Column(
              children: [
                Text(
                  title,
                  style: spec.titleStyle,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: spec.textGap),
                Text(
                  description,
                  style: spec.descriptionStyle,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            SizedBox(height: spec.sectionGap),
            SizedBox(
              width: spec.contentWidth,
              child: AppButton(
                label: actionLabel!,
                onPressed: onAction,
                icon: actionIcon,
                iconPosition: actionIconPosition,
              ),
            ),
          ],
        ],
      ),
    );

    // When the parent gives a bounded (often tight) height — e.g. remaining
    // space below filters — scroll instead of overflowing the Column.
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.hasBoundedHeight) {
          return content;
        }

        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(child: content),
          ),
        );
      },
    );
  }
}

/// Figma `empty states / internet` (`321:8297`).
class AppNetworkFailureState extends StatelessWidget {
  const AppNetworkFailureState({
    required this.title,
    required this.description,
    required this.retryLabel,
    super.key,
    this.onRetry,
  });

  final String title;
  final String description;
  final String retryLabel;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final size = responsiveDimension(EmptyStateTokens.networkIllustrationSize);

    return AppEmptyState(
      illustration: AppEmptyStateImage(
        assetPath: AppImages.networkFailure,
        width: size,
        height: size,
      ),
      title: title,
      description: description,
      actionLabel: retryLabel,
      onAction: onRetry,
    );
  }
}

/// Figma `empty states / No branches yet` (`328:9898`) — generic empty preset
/// using the shared core illustration.
class AppGenericEmptyState extends StatelessWidget {
  const AppGenericEmptyState({
    required this.title,
    required this.description,
    super.key,
    this.actionLabel,
    this.onAction,
    this.actionIcon,
    this.actionIconPosition = AppButtonIconPosition.none,
  });

  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? actionIcon;
  final AppButtonIconPosition actionIconPosition;

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      illustration: AppEmptyStateImage(
        assetPath: AppImages.emptyState,
        width: responsiveDimension(EmptyStateTokens.emptyIllustrationWidth),
        height: responsiveDimension(EmptyStateTokens.emptyIllustrationHeight),
      ),
      title: title,
      description: description,
      actionLabel: actionLabel,
      onAction: onAction,
      actionIcon: actionIcon,
      actionIconPosition: actionIconPosition,
    );
  }
}
