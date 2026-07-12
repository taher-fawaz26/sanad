import 'package:go_router/go_router.dart';

/// App-specific navigation bindings passed to feature modules when building routes.
class FeatureRouteContext {
  const FeatureRouteContext({
    required this.homeRoute,
    this.userType = FeatureUserType.client,
    this.protectedRoutes = const {},
  });

  /// Post-authentication landing route (e.g. `/home`).
  final String homeRoute;

  /// Whether this app registers users as client or provider.
  final FeatureUserType userType;

  /// Routes requiring authentication.
  final Set<String> protectedRoutes;
}

/// Simplified user type for route building without coupling to auth enums.
enum FeatureUserType { client, provider }

/// Contract implemented by every shared feature package.
///
/// Extend this class — do not `implements` — to inherit default lifecycle no-ops.
/// See `docs/FEATURE_GUIDE.md` and ADR-0008.
abstract class FeatureModule {
  /// Human-readable name used in logs and `melos doctor`.
  String get name;

  /// Semantic version for future dependency resolution.
  String get version;

  /// Other module names this module depends on (load-order enforcement).
  List<String> get dependencies;

  /// Register all GetIt dependencies. Called once during app bootstrap.
  void registerDependencies();

  /// Routes contributed to the app's GoRouter.
  List<RouteBase> routes(FeatureRouteContext context);

  /// Async post-DI initialisation.
  Future<void> initialize() async {}

  /// Optional lifecycle hook — app resume.
  void onAppResumed() {}

  /// Optional lifecycle hook — app pause.
  void onAppPaused() {}

  /// Clean up module resources on logout / dispose.
  void dispose() {}

  /// Metadata for debugging and `melos doctor`.
  Map<String, dynamic> get metadata => {'name': name, 'version': version};
}
