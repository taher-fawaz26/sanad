import 'package:branches/src/domain/entities/branch_type.dart';
import 'package:easy_localization/easy_localization.dart';

/// Localizes [BranchType] values for display.
///
/// Kept in the presentation layer (mirrors [BranchScheduleFormatter]) so the
/// domain entity stays free of `easy_localization`.
abstract final class BranchTypeFormatter {
  BranchTypeFormatter._();

  static String localizedLabel(BranchType type) => switch (type) {
    BranchType.mainBranch => 'branches.add_branch.branch_type_main_branch'.tr(),
    BranchType.headquarters =>
      'branches.add_branch.branch_type_headquarters'.tr(),
    BranchType.mainStore => 'branches.add_branch.branch_type_main_store'.tr(),
    BranchType.warehouse => 'branches.add_branch.branch_type_warehouse'.tr(),
  };
}
