abstract final class BranchApiPaths {
  BranchApiPaths._();

  static const String branches = 'provider/branches';

  static String branch(String id) => 'provider/branches/$id';
}
