import 'package:app_assets/app_assets.dart';
import 'package:bottom_nav_bar/bottom_nav_bar.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sanad_provider/src/routing/shell/provider_bottom_nav.dart';

/// Builds package navigation models from [ProviderBottomNavDestination].
abstract final class ProviderBottomNavItems {
  ProviderBottomNavItems._();

  /// Permanent bar destinations (Home, Settings).
  static List<BottomNavDestination<ProviderBottomNavDestination>> destinations(
    BuildContext context,
  ) {
    return ProviderBottomNavDestination.permanentTabs
        .map(
          (destination) => BottomNavDestination(
            item: destination,
            label: destination.labelKey.tr(),
            iconBuilder: (context, {required bool selected}) =>
                _destinationIcon(
              context,
              destination,
              selected: false,
            ),
            selectedIconBuilder: (context, {required bool selected}) =>
                _destinationIcon(
              context,
              destination,
              selected: true,
            ),
          ),
        )
        .toList(growable: false);
  }

  /// Expandable center actions (Services, Requests, Messages).
  static List<BottomNavAction<ProviderBottomNavDestination>> actions(
    BuildContext context,
  ) {
    return ProviderBottomNavDestination.fabActions
        .map(
          (destination) => BottomNavAction(
            item: destination,
            label: destination.labelKey.tr(),
            semanticLabel: destination.labelKey.tr(),
            iconBuilder: (context, {required bool selected}) =>
                _actionIcon(context, destination),
          ),
        )
        .toList(growable: false);
  }

  /// Custom center FAB face — plus when closed, X when open, or active action.
  static Widget centerFabFace(
    BuildContext context, {
    required ProviderBottomNavDestination? selectedItem,
    required bool isExpanded,
    required BottomNavThemeData theme,
    required List<BottomNavAction<ProviderBottomNavDestination>> actions,
  }) {
    if (isExpanded) {
      return AppSvgPicture.asset(
        AppNavigationIcons.expandOpen,
        width: theme.iconSize,
        height: theme.iconSize,
      );
    }

    if (selectedItem != null && selectedItem.isFabAction) {
      return AppSvgPicture.asset(
        selectedItem.selectedIconAsset!,
        width: theme.iconSize,
        height: theme.iconSize,
      );
    }

    return Icon(
      Icons.add,
      color: theme.resolveFabForegroundColor(context),
      size: theme.iconSize,
    );
  }

  static Widget _destinationIcon(
    BuildContext context,
    ProviderBottomNavDestination destination, {
    required bool selected,
  }) {
    if (selected) {
      return AppSvgPicture.asset(
        destination.selectedIconAsset!,
        width: 24,
        height: 24,
      );
    }

    final colors = context.appColors;
    final brightness = Theme.of(context).brightness;
    final unselectedColor = brightness == Brightness.dark
        ? colors.slate400
        : const Color(0xFFA2A2A2);

    return AppSvgPicture.asset(
      destination.iconAsset,
      width: 24,
      height: 24,
      colorFilter: ColorFilter.mode(unselectedColor, BlendMode.srcIn),
    );
  }

  static Widget _actionIcon(
    BuildContext context,
    ProviderBottomNavDestination destination,
  ) {
    return AppSvgPicture.asset(
      destination.selectedIconAsset!,
      width: 24,
      height: 24,
    );
  }
}
