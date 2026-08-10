abstract final class ProviderRbacRoutes {
  ProviderRbacRoutes._();

  static const String list = '/roles-permissions';
  static const String add = '/roles-permissions/add';
  static String editFor(String roleId) => '/roles-permissions/$roleId/edit';
}
