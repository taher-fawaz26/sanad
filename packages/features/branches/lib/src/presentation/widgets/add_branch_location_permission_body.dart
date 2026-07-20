import 'package:branches/src/presentation/widgets/branch_pin_empty_body.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Add branch — Step 2 "Location access needed" state.
///
/// Shown when device location permission is permanently denied (or location
/// services are off) and the user tries to configure branch coverage.
///
/// Figma `location-permission-denied` (`1517:9804`, body `1563:10992`).
class AddBranchLocationPermissionBody extends StatelessWidget {
  const AddBranchLocationPermissionBody({super.key});

  @override
  Widget build(BuildContext context) {
    return BranchPinEmptyBody(
      title: 'branches.add_branch.location_access_title'.tr(),
      description: 'branches.add_branch.location_access_description'.tr(),
    );
  }
}
