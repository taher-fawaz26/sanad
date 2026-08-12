abstract final class ProviderRbacRoutes {
  ProviderRbacRoutes._();

  static const String list = '/roles-permissions';
  static const String add = '/roles-permissions/add';
  static String editFor(String roleId) => '/roles-permissions/$roleId/edit';
  static String detailsFor(String roleId) => '/roles-permissions/$roleId';

  static Set<String> get protectedRoutes => {list, add};

  static bool isProtectedRoute(String location) =>
      protectedRoutes.contains(location) ||
      location.startsWith('/roles-permissions/');
}
