import 'package:bottom_nav_bar/bottom_nav_bar.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sanad_provider/src/routing/shell/provider_bottom_nav.dart';

/// Builds package navigation models from [ProviderBottomNavDestination].
abstract final class ProviderBottomNavItems {
  ProviderBottomNavItems._();

  /// Permanent bar destinations — Figma `1526:12109`.
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
                  selected: selected,
                ),
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

    // Same outline asset for both states — primary tint when selected.
    return AppSvgPicture.asset(
      destination.iconAsset,
      width: 24,
      height: 24,
      colorFilter: ColorFilter.mode(
        selected ? colors.primary : colors.palettes.sky.shade600,
        BlendMode.srcIn,
      ),
    );
  }
}
