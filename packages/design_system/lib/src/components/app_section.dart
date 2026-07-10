import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Figma section header size.
enum AppSectionSize {
  /// `_Partials / Tables` (`194:3008`) — compact in-content header.
  compact,

  /// `Bars / Nav Bars: Large` (`40:6931`) — large screen section header.
  large,
}

/// Reusable section header for any screen.
///
/// Supports all Figma variants:
/// - Large title only (`40:6932`)
/// - Large title + caption (`40:6939`)
/// - Large title + trailing button (`40:6947`, `40:6942`)
/// - Large title + trailing icon (`40:6955`, `40:6950`)
/// - Compact title only (`194:3012`)
/// - Compact title + caption (`194:3009`)
class AppSection extends StatelessWidget {
  const AppSection({
    required this.title,
    super.key,
    this.caption,
    this.size = AppSectionSize.large,
    this.trailingAction = AppNavBarTrailingAction.none,
    this.trailing,
    this.trailingButtonLabel,
    this.onTrailingTap,
    this.padding,
  });

  final String title;
  final String? caption;
  final AppSectionSize size;
  final AppNavBarTrailingAction trailingAction;
  final Widget? trailing;
  final String? trailingButtonLabel;
  final VoidCallback? onTrailingTap;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final effectivePadding = padding ?? _resolvePadding(context);

    return Padding(
      padding: effectivePadding,
      child: size == AppSectionSize.compact
          ? _CompactSection(
              title: title,
              caption: caption,
            )
          : _LargeSection(
              title: title,
              caption: caption,
              trailingAction: trailingAction,
              trailing: trailing,
              trailingButtonLabel: trailingButtonLabel,
              onTrailingTap: onTrailingTap,
            ),
    );
  }

  EdgeInsetsGeometry _resolvePadding(BuildContext context) {
    final horizontal = size == AppSectionSize.compact
        ? context.appTableTheme.row.horizontalPadding
        : context.appNavBarTheme.large.horizontalPadding;
    return EdgeInsets.symmetric(horizontal: horizontal);
  }
}

/// Compact section header implementation - extracted to reduce rebuild scope.
class _CompactSection extends StatelessWidget {
  const _CompactSection({
    required this.title,
    this.caption,
  });

  final String title;
  final String? caption;

  bool get _hasCaption => caption != null && caption!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final spec = context.appTableTheme.cell;

    return SizedBox(
      height: spec.height,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: spec.titleStyle),
          if (_hasCaption) ...[
            SizedBox(height: spec.textGap),
            Text(caption!, style: spec.captionStyle),
          ],
        ],
      ),
    );
  }
}

/// Large section header implementation - extracted to reduce rebuild scope.
class _LargeSection extends StatelessWidget {
  const _LargeSection({
    required this.title,
    this.caption,
    this.trailingAction = AppNavBarTrailingAction.none,
    this.trailing,
    this.trailingButtonLabel,
    this.onTrailingTap,
  });

  final String title;
  final String? caption;
  final AppNavBarTrailingAction trailingAction;
  final Widget? trailing;
  final String? trailingButtonLabel;
  final VoidCallback? onTrailingTap;

  bool get _hasCaption => caption != null && caption!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    // Single theme lookups
    final colors = context.appColors;
    final spec = context.appNavBarTheme.large;

    // Pre-calculate layout values
    final height = _hasCaption ? spec.heightExpanded : spec.heightCompact;
    final titleRightInset = _calculateTitleRightInset(spec);

    return SizedBox(
      height: height,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: titleRightInset,
            top: _hasCaption ? height / 2 - 34 : null,
            bottom: _hasCaption ? null : 0,
            child: _hasCaption
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(title, style: spec.titleStyle),
                      const SizedBox(height: 8),
                      Text(caption!, style: spec.captionStyle),
                    ],
                  )
                : Align(
                    alignment: Alignment.centerLeft,
                    child: Text(title, style: spec.titleStyle),
                  ),
          ),
          if (trailingAction != AppNavBarTrailingAction.none)
            Positioned(
              right: _calculateTrailingInset(spec),
              top: 0,
              bottom: 0,
              child: Center(
                child: _buildTrailing(spec, colors),
              ),
            ),
        ],
      ),
    );
  }

  double _calculateTitleRightInset(LargeNavBarStyleSpec spec) {
    return switch (trailingAction) {
      AppNavBarTrailingAction.icon =>
        spec.titleRightInsetIcon - spec.horizontalPadding,
      AppNavBarTrailingAction.button =>
        spec.titleRightInsetButton - spec.horizontalPadding,
      _ => 0.0,
    };
  }

  double _calculateTrailingInset(LargeNavBarStyleSpec spec) {
    return trailingAction == AppNavBarTrailingAction.icon
        ? spec.trailingIconInset - spec.horizontalPadding
        : spec.trailingButtonInset - spec.horizontalPadding;
  }

  Widget _buildTrailing(LargeNavBarStyleSpec spec, AppColors colors) {
    return switch (trailingAction) {
      AppNavBarTrailingAction.icon => GestureDetector(
        onTap: onTrailingTap,
        child:
            trailing ??
            Icon(
              Icons.person_outline,
              size: spec.iconSize,
              color: colors.primary,
            ),
      ),
      AppNavBarTrailingAction.button => AppButton(
        onPressed: onTrailingTap,
        label: trailingButtonLabel ?? 'Button',
        size: AppButtonSize.small,
      ),
      _ => const SizedBox.shrink(),
    };
  }
}
