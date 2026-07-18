import 'package:app_assets/app_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:services/src/domain/entities/service_entity.dart';

/// Bordered service row — Figma add-branch services list (`966:3746`).
///
/// Layout: `[Icon container] [Name + Category] …… [trash]`
class ServiceListCard extends StatelessWidget {
  const ServiceListCard({
    required this.service,
    super.key,
    this.onTap,
    this.onRemove,
  });

  final ServiceEntity service;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    const iconContainerSize = 48.0;

    return AppListCard(
      title: service.name,
      caption: service.category,
      leading: SizedBox(
        width: iconContainerSize,
        height: iconContainerSize,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.palettes.sky.shade100,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Center(
            child: AppFeatureIcon(
              color: AppFeatureIconColor.primary,
              size: AppFeatureIconSize.md,
              theme: AppFeatureIconTheme.lightCircle,
            ),
          ),
        ),
      ),
      trailing: onRemove == null
          ? null
          : AppIconButton(
              iconAsset: AppSvgs.trashBold,
              size: AppIconButtonSize.small,
              semanticLabel: 'services.remove_service'.tr(),
              onTap: onRemove,
            ),
      onTap: onTap,
    );
  }
}
