abstract final class ProviderRbacApiPaths {
  ProviderRbacApiPaths._();

  static const String roles = '/api/v1/provider/roles';
  static String role(String id) => '/api/v1/provider/roles/$id';
  static const String permissions = '/api/v1/provider/permissions';

  static String workerRoles(String workerId) =>
      '/api/v1/workers/$workerId/roles';
  static String workerRole(String workerId, String roleId) =>
      '/api/v1/workers/$workerId/roles/$roleId';
}
