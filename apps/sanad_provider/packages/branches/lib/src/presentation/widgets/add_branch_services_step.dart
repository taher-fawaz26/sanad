import 'package:app_assets/app_assets.dart';
import 'package:branches/src/presentation/widgets/branch_pin_empty_body.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:services/services.dart';

/// Add branch — Step 3 services.
///
/// Empty: Figma `347:13888` (body `1563:10998`).
/// Filled: Figma `966:3746`.
class AddBranchServicesStep extends StatelessWidget {
  const AddBranchServicesStep({
    required this.selectedServices,
    required this.onAddServices,
    this.onRemoveService,
    super.key,
  });

  final List<ServiceEntity> selectedServices;
  final VoidCallback onAddServices;
  final ValueChanged<ServiceEntity>? onRemoveService;

  bool get _hasServices => selectedServices.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    if (_hasServices) {
      return _ServicesSetContent(
        selectedServices: selectedServices,
        onAddServices: onAddServices,
        onRemoveService: onRemoveService,
      );
    }

    final iconSize = responsiveDimension(40);
    return GestureDetector(
      onTap: onAddServices,
      behavior: HitTestBehavior.opaque,
      child: BranchPinEmptyBody(
        icon: Image.asset(
          AppImages.serviceTools,
          package: AppAssets.package,
          width: iconSize,
          height: iconSize,
        ),
        title: 'branches.add_branch.services_title'.tr(),
        description: 'branches.add_branch.services_description'.tr(),
      ),
    );
  }
}

/// Figma filled services step (`966:3746`).
class _ServicesSetContent extends StatelessWidget {
  const _ServicesSetContent({
    required this.selectedServices,
    required this.onAddServices,
    this.onRemoveService,
  });

  final List<ServiceEntity> selectedServices;
  final VoidCallback onAddServices;
  final ValueChanged<ServiceEntity>? onRemoveService;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final onRemove = onRemoveService;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // "ADDED SERVICES (3)" — semibold 14, uppercase, dark/500.
          Text(
            'branches.add_branch.added_services_section'
                .tr(namedArgs: {'count': '${selectedServices.length}'})
                .toUpperCase(),
            style: typography
                .semiBold(typography.smallTight)
                .copyWith(
                  color: colors.textMuted,
                ),
          ),
          SizedBox(height: AppSpacing.md),
          for (final service in selectedServices) ...[
            ServiceListCard(
              service: service,
              onRemove: onRemove == null ? null : () => onRemove(service),
            ),
            SizedBox(height: AppSpacing.md),
          ],
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: AppButtonPresets.outline(
              label: 'branches.add_branch.add_service_button'.tr(),
              size: AppButtonSize.large,
              icon: const Icon(Icons.add_circle_outline),
              iconPosition: AppButtonIconPosition.left,
              onPressed: onAddServices,
            ),
          ),
        ],
      ),
    );
  }
}
