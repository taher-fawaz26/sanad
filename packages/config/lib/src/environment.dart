/// The deployment environment this build targets.
enum Environment {
  /// Local development environment.
  dev,

  /// Quality-assurance / testing environment.
  qa,

  /// Pre-production staging environment.
  stage,

  /// Live production environment.
  production;

  /// Whether this environment is the production environment.
  bool get isProduction => this == Environment.production;

  /// Whether this environment is the dev environment.
  bool get isDev => this == Environment.dev;

  /// Parses [value] (case-insensitive) into an [Environment].
  ///
  /// Throws [ArgumentError] if [value] does not match any environment name.
  static Environment fromString(String value) {
    return Environment.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => throw ArgumentError('Unknown environment: $value'),
    );
  }
}
