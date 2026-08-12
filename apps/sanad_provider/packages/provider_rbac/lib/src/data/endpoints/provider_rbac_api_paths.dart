abstract final class ProviderRbacApiPaths {
  ProviderRbacApiPaths._();

  // Paths are RELATIVE — the API client's base URL already ends in `/api/v1`,
  // so a leading `/api/v1` here would double the prefix (→ 404). Matches the
  // `workers` convention (e.g. `workers`, `workers/$id`).
  static const String roles = 'provider/roles';
  static String role(String id) => 'provider/roles/$id';
  static const String permissions = 'provider/permissions';

  static String workerRoles(String workerId) => 'workers/$workerId/roles';
  static String workerRole(String workerId, String roleId) =>
      'workers/$workerId/roles/$roleId';
}
