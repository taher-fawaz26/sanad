/// API-level schedule mode for a branch.
enum BranchAvailabilityMode {
  /// Branch follows the company-wide schedule (`CORE_HOURS`).
  coreHours,

  /// Branch uses its own custom schedule (`CUSTOM`).
  custom
  ;

  String toApiString() => switch (this) {
    BranchAvailabilityMode.coreHours => 'CORE_HOURS',
    BranchAvailabilityMode.custom => 'CUSTOM',
  };

  static BranchAvailabilityMode fromApiString(String? value) =>
      value == 'CUSTOM'
      ? BranchAvailabilityMode.custom
      : BranchAvailabilityMode.coreHours;
}
