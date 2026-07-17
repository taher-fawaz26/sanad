abstract final class BranchApiPaths {
  BranchApiPaths._();

  static const String branches = 'branches';

  static String branch(String id) => 'branches/$id';

  /// PATCH – toggle a branch between ACTIVE and MAINTENANCE.
  static String branchStatus(String id) => 'branches/$id/status';

  /// Company-wide working hours used as the default branch schedule.
  static const String companySchedule = 'company/schedule';

  /// Workers eligible to be assigned as branch managers.
  static const String branchManagers = 'workers';
}
