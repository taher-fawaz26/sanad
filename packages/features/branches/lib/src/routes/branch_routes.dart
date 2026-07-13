abstract final class BranchRoutes {
  BranchRoutes._();

  static const String list = '/branches';
  static const String add = '/branches/add';
  static const String details = '/branches/:id';

  static String detailsFor(String id) => '/branches/$id';

  static Set<String> get protectedRoutes => {list, add};

  static bool isProtectedRoute(String location) {
    if (protectedRoutes.contains(location)) return true;
    return _detailsRoutePattern.hasMatch(location);
  }

  static final _detailsRoutePattern = RegExp(r'^/branches/[^/]+$');
}
