import 'package:branches/src/presentation/widgets/branch_pin_empty_body.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Add branch — Step 2 coverage (Figma `1563:10977` / `1563:10978`).
///
/// Always shows the map-pin "Add Branch Coverage" prompt; the map picker
/// (opened via [onEditCoverage]) is the only way to set or edit coverage.
/// Once coverage is confirmed the wizard auto-advances, so this body is only
/// ever seen before coverage exists.
class AddBranchCoverageStep extends StatelessWidget {
  const AddBranchCoverageStep({
    required this.onEditCoverage,
    super.key,
  });

  /// Opens the coverage area map picker to add or edit coverage.
  final VoidCallback onEditCoverage;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onEditCoverage,
      behavior: HitTestBehavior.opaque,
      child: BranchPinEmptyBody(
        title: 'branches.add_branch.coverage_title'.tr(),
        description: 'branches.add_branch.coverage_description'.tr(),
      ),
    );
  }
}
