/// API-level branch type.
enum BranchType {
  mainBranch,
  headquarters,
  mainStore,
  warehouse;

  String toApiString() => switch (this) {
        BranchType.mainBranch => 'MAIN_BRANCH',
        BranchType.headquarters => 'HEADQUARTERS',
        BranchType.mainStore => 'MAIN_STORE',
        BranchType.warehouse => 'WAREHOUSE',
      };

  static BranchType fromApiString(String? value) => switch (value) {
        'HEADQUARTERS' => BranchType.headquarters,
        'MAIN_STORE' => BranchType.mainStore,
        'WAREHOUSE' => BranchType.warehouse,
        _ => BranchType.mainBranch,
      };
}
