import 'package:branches/src/presentation/widgets/branch_pin_empty_body.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:maps/maps.dart';

/// Add branch — Step 2 "Location access needed" state.
///
/// Shown whenever device location access isn't granted while the user tries
/// to configure branch coverage. Copy varies by [status]: a plain denial
/// explains why access is needed and invites an in-app retry (handled by the
/// footer's "Allow location access" button); a permanent denial or a
/// disabled location service point at OS settings instead.
///
/// Figma `location-permission-denied` (`1517:9804`, body `1563:10992`).
class AddBranchLocationPermissionBody extends StatelessWidget {
  const AddBranchLocationPermissionBody({required this.status, super.key});

  final LocationPermissionStatus status;

  @override
  Widget build(BuildContext context) {
    const prefix = 'branches.add_branch';
    final key = switch (status) {
      LocationPermissionStatus.serviceDisabled =>
        '$prefix.location_service_disabled',
      LocationPermissionStatus.permanentlyDenied => '$prefix.location_access',
      LocationPermissionStatus.denied ||
      LocationPermissionStatus.granted => '$prefix.location_permission',
    };

    return BranchPinEmptyBody(
      title: '${key}_title'.tr(),
      description: '${key}_description'.tr(),
    );
  }
}
