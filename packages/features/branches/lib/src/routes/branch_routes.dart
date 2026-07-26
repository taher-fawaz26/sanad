abstract final class BranchRoutes {
  BranchRoutes._();

  static const String list = '/branches';
  static const String add = '/branches/add';
  static const String coverage = '/branches/coverage';
  static const String details = '/branches/:id';
  static const String edit = '/branches/:id/edit';

  static String detailsFor(String id) => '/branches/$id';
  static String editFor(String id) => '/branches/$id/edit';

  static Set<String> get protectedRoutes => {list, add, coverage};

  static bool isProtectedRoute(String location) {
    if (protectedRoutes.contains(location)) return true;
    if (_editRoutePattern.hasMatch(location)) return true;
    return _detailsRoutePattern.hasMatch(location);
  }

  static final _detailsRoutePattern = RegExp(r'^/branches/[^/]+$');
  static final _editRoutePattern = RegExp(r'^/branches/[^/]+/edit$');
}
