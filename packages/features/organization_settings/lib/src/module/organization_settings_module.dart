import 'package:core/core.dart';
import 'package:go_router/go_router.dart';
import 'package:organization_settings/src/di/organization_settings_di.dart';
import 'package:organization_settings/src/presentation/pages/general_settings_page.dart';
import 'package:organization_settings/src/routes/organization_settings_routes.dart';

/// Provider-only organization settings module.
///
/// The KPI hub at [OrganizationSettingsRoutes.hub] is hosted by the provider
/// shell branch; this module contributes the general-settings placeholder.
class OrganizationSettingsModule extends FeatureModule {
  @override
  String get name => 'organization_settings';

  @override
  String get version => '0.1.0';

  @override
  List<String> get dependencies => const ['account_settings'];

  @override
  void registerDependencies() => OrganizationSettingsDI.init();

  @override
  List<RouteBase> routes(FeatureRouteContext context) => [
    GoRoute(
      path: OrganizationSettingsRoutes.general,
      builder: (context, state) => const GeneralSettingsPage(),
    ),
  ];
}
