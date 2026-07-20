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
}
