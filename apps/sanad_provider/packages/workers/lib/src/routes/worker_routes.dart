abstract final class WorkerRoutes {
  WorkerRoutes._();

  static const String list = '/workers';
  static const String details = '/workers/:id';
  static const String add = '/workers/add';
  static const String edit = '/workers/:id/edit';

  static String detailsFor(String id) => '/workers/$id';

  static String editWorkerFor(String id) => '/workers/$id/edit';

  static Set<String> get protectedRoutes => {list};

  static bool isProtectedRoute(String location) =>
      protectedRoutes.contains(location) || location.startsWith('/workers/');

  /// Whether [location] is one of the Workers sub-surfaces the backend gates
  /// by owner persona rather than by a catalog permission (RBAC Phase 7E) —
  /// inviting a worker (`POST /workers/invitations`) and editing one
  /// (`PATCH /workers/:id`, no catalog permission exists for either write).
  /// [list] and [details] are deliberately excluded — those stay
  /// permission-gated on `WorkerPermissions.view`.
  static bool isOwnerOnlyRoute(String location) =>
      location == add ||
      (location.startsWith('$list/') && location.endsWith('/edit'));
}
