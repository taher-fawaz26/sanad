abstract final class BranchRoutes {
  BranchRoutes._();

  static const String list = '/branches';
  static const String add = '/branches/add';

  static Set<String> get protectedRoutes => {list, add};
}
