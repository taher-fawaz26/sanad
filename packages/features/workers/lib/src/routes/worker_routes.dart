abstract final class WorkerRoutes {
  WorkerRoutes._();

  static const String list = '/workers';
  static const String details = '/workers/:id';

  static String detailsFor(String id) => '/workers/$id';

  static Set<String> get protectedRoutes => {list};

  static bool isProtectedRoute(String location) =>
      protectedRoutes.contains(location) ||
      location.startsWith('/workers/');
}
