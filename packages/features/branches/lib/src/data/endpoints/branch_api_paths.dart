abstract final class BranchApiPaths {
  BranchApiPaths._();

  static const String branches = 'provider/branches';

  static String branch(String id) => 'provider/branches/$id';

  /// Company-wide working hours used as the default branch schedule.
  static const String companySchedule = 'provider/company/schedule';

  /// Workers eligible to be assigned as branch managers.
  static const String branchManagers = 'provider/workers';
}
