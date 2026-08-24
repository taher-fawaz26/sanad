import 'package:core/core.dart';
import 'package:go_router/go_router.dart';
import 'package:sanad_provider/src/features/home/src/di/home_di.dart';

/// Provider-only home dashboard module.
///
/// The `/home` route itself is hosted directly by the provider bottom-nav
/// shell (`StatefulShellRoute` in `provider_router.dart`), matching how
/// `OrganizationSettingsModule` hosts its KPI hub route — this module exists
/// to register the dashboard's own dependencies through the standard
/// `FeatureModule` lifecycle (including session-boundary `dispose()`).
class HomeModule extends FeatureModule {
  @override
  String get name => 'home';

  @override
  String get version => '0.1.0';

  @override
  List<String> get dependencies => const [];

  @override
  void registerDependencies() => HomeDI.init();

  @override
  List<RouteBase> routes(FeatureRouteContext context) => const [];
}
