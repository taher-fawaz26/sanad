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
                _destinationIcon(context, destination, selected: selected),
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

  static Widget _destinationIcon(
    BuildContext context,
    ProviderBottomNavDestination destination, {
    required bool selected,
  }) {
    final colors = context.appColors;
    final brightness = Theme.of(context).brightness;
    final unselectedColor = brightness == Brightness.dark
        ? colors.slate400
        : const Color(0xFF828A89);
    final color = selected ? colors.primary : unselectedColor;

    return AppSvgPicture.asset(
      destination.iconAsset,
      width: 24,
      height: 24,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }

  static Widget _actionIcon(
    BuildContext context,
    ProviderBottomNavDestination destination,
  ) {
    final colors = context.appColors;

    return AppSvgPicture.asset(
      destination.iconAsset,
      width: 24,
      height: 24,
      colorFilter: ColorFilter.mode(colors.white, BlendMode.srcIn),
    );
  }
}
