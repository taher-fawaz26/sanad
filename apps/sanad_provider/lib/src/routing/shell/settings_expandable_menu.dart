import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';

/// Owns expandable Settings menu state and ExpandableFab control.
///
/// [isExpanded] is the single source of truth for overlay / nav gating in
/// [MainShell]. [close] clears that flag even though upstream
/// [ExpandableFabState.close] does not invoke `onClose`.
class SettingsExpandableMenuController {
  final GlobalKey<ExpandableFabState> _fabKey = GlobalKey<ExpandableFabState>();
  final ValueNotifier<bool> _isExpanded = ValueNotifier<bool>(false);

  /// Key wired into [SettingsExpandableMenu].
  GlobalKey<ExpandableFabState> get fabKey => _fabKey;

  /// Scaffold location for [SettingsExpandableMenu].
  FloatingActionButtonLocation get fabLocation => ExpandableFab.location;

  /// Whether the settings action menu is expanded.
  ValueListenable<bool> get isExpanded => _isExpanded;

  /// Called by [SettingsExpandableMenu] from ExpandableFab `onOpen`.
  void handleOpen() => _isExpanded.value = true;

  /// Called by [SettingsExpandableMenu] from ExpandableFab `onClose` (toggle).
  void handleClose() => _isExpanded.value = false;

  /// Opens the menu when closed; closes it when open.
  void toggle() => _fabKey.currentState?.toggle();

  /// Closes the menu and clears [isExpanded] immediately.
  ///
  /// Upstream [ExpandableFabState.close] does not fire `onClose`, so this
  /// method owns the notifier update.
  void close() {
    _isExpanded.value = false;
    _fabKey.currentState?.close();
  }

  /// Releases the expanded notifier.
  void dispose() {
    _isExpanded.dispose();
  }
}

/// Expandable action menu anchored to the Settings bottom-nav item.
///
/// Composed at the app layer using [ExpandableFab]. Expanded state is owned
/// by [SettingsExpandableMenuController] — not by [MainShell].
class SettingsExpandableMenu extends StatelessWidget {
  const SettingsExpandableMenu({
    required this.controller,
    required this.onGeneralSettings,
    required this.onAccountSettings,
    super.key,
  });

  final SettingsExpandableMenuController controller;
  final VoidCallback onGeneralSettings;
  final VoidCallback onAccountSettings;

  /// Shared with [MainShell] overlay timing.
  static const Duration animationDuration = Duration(milliseconds: 280);

  static const double _actionButtonSize = 48;
  static const double _actionSpacing = 12;
  static const double _fabMargin = 16;

  /// Distance between stacked actions (button height + spacing).
  static const double _stepDistance = _actionButtonSize + _actionSpacing;

  static EdgeInsets _anchorMargin(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final safe = MediaQuery.paddingOf(context);
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    final itemWidth = (width - BottomNavTokens.contentPadding * 2) / 5;
    final settingsCenterFromEdge =
        BottomNavTokens.contentPadding + itemWidth / 2;

    final edgeInset = isRtl ? safe.left : safe.right;
    final horizontalMargin = settingsCenterFromEdge - _fabMargin - edgeInset;

    final navBarHeight = BottomNavTokens.bottomBarHeight + safe.bottom;
    final defaultAnchorFromBottom = _fabMargin + navBarHeight;
    final settingsIconFromBottom =
        safe.bottom + BottomNavTokens.bottomBarHeight * 0.45;
    final verticalMargin = settingsIconFromBottom - defaultAnchorFromBottom;

    if (isRtl) {
      return EdgeInsets.only(
        left: horizontalMargin,
        bottom: verticalMargin,
      );
    }
    return EdgeInsets.only(
      right: horizontalMargin,
      bottom: verticalMargin,
    );
  }

  static ExpandableFabPos _fabPosition(BuildContext context) =>
      Directionality.of(context) == TextDirection.rtl
      ? ExpandableFabPos.left
      : ExpandableFabPos.right;

  static FloatingActionButtonBuilder _invisibleFabBuilder() {
    return FloatingActionButtonBuilder(
      size: _actionButtonSize,
      builder: (context, onPressed, progress) => IgnorePointer(
        child: Opacity(
          opacity: 0,
          child: SizedBox(
            width: _actionButtonSize,
            height: _actionButtonSize,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return ExpandableFab(
      key: controller.fabKey,
      childrenOffset: Offset(35, 0),
      type: ExpandableFabType.up,
      pos: _fabPosition(context),
      margin: _anchorMargin(context),
      distance: _stepDistance,
      duration: animationDuration,
      childrenAnimation: ExpandableFabAnimation.none,
      overlayStyle: null,
      openButtonBuilder: _invisibleFabBuilder(),
      closeButtonBuilder: _invisibleFabBuilder(),
      onOpen: controller.handleOpen,
      onClose: controller.handleClose,
      children: [
        _SettingsMenuAction(
          label: 'settings.general_settings'.tr(),
          icon: Icons.settings,
          colors: colors,
          typography: typography,
          isRtl: isRtl,
          onPressed: onGeneralSettings,
        ),
        _SettingsMenuAction(
          label: 'settings.account_settings'.tr(),
          icon: Icons.manage_accounts,
          colors: colors,
          typography: typography,
          isRtl: isRtl,
          onPressed: onAccountSettings,
        ),
      ],
    );
  }
}

class _SettingsMenuAction extends StatelessWidget {
  const _SettingsMenuAction({
    required this.label,
    required this.icon,
    required this.colors,
    required this.typography,
    required this.isRtl,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final AppColors colors;
  final AppTypography typography;
  final bool isRtl;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final labelWidget = Material(
      color: colors.surface,
      elevation: 0,
      shadowColor: Colors.transparent,
      borderRadius: BorderRadius.circular(AppDimension.radiusSm),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Text(
          label,
          style: typography.smallNormal.copyWith(
            fontWeight: FontWeight.w500,
            color: colors.textPrimary,
          ),
        ),
      ),
    );

    final button = _SettingsActionButton(
      icon: icon,
      colors: colors,
      onPressed: onPressed,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      children: [
        if (isRtl) ...[
          labelWidget,

          SizedBox(width: AppSpacing.xs),
          button,
        ] else ...[
          labelWidget,
          SizedBox(width: AppSpacing.xs),
          button,
        ],
      ],
    );
  }
}

class _SettingsActionButton extends StatelessWidget {
  const _SettingsActionButton({
    required this.icon,
    required this.colors,
    required this.onPressed,
  });

  final IconData icon;
  final AppColors colors;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colors.white,
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Ink(
          width: SettingsExpandableMenu._actionButtonSize,
          height: SettingsExpandableMenu._actionButtonSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colors.white,
            boxShadow: AppShadows.small,
          ),
          child: Icon(
            icon,
            size: 24,
            color: colors.primary,
          ),
        ),
      ),
    );
  }
}
