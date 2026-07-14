import 'package:app_assets/app_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:services/services.dart';

/// Add branch — Step 3 services.
///
/// Empty: Figma `347:13888`.
/// Filled: Figma `966:3746`.
class AddBranchServicesStep extends StatelessWidget {
  const AddBranchServicesStep({
    required this.selectedServices,
    required this.onAddServices,
    super.key,
  });

  final List<ServiceEntity> selectedServices;
  final VoidCallback onAddServices;

  bool get _hasServices => selectedServices.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    if (_hasServices) {
      return _ServicesSetContent(
        selectedServices: selectedServices,
        onAddServices: onAddServices,
      );
    }

    return Center(
      child: AppEmptyState(
        illustration: AppSvgPicture.asset(
          AppImages.addServices,
          width: responsiveDimension(218),
          height: responsiveDimension(126),
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
  });

  final List<ServiceEntity> selectedServices;
  final VoidCallback onAddServices;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSection(
            title: 'branches.add_branch.added_services_section'.tr(
              namedArgs: {'count': '${selectedServices.length}'},
            ),
            size: AppSectionSize.compact,
            tone: AppSectionTone.primary,
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Column(
              children: [
                for (var i = 0; i < selectedServices.length; i++) ...[
                  if (i > 0) SizedBox(height: AppSpacing.sm),
                  ServiceListCard(service: selectedServices[i]),
                ],
                SizedBox(height: AppSpacing.md),
                AppButtonPresets.outline(
                  label: 'branches.add_branch.add_service_button'.tr(),
                  icon: const Icon(Icons.add, size: 20),
                  iconPosition: AppButtonIconPosition.left,
                  onPressed: onAddServices,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
