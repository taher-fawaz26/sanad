import 'package:account_settings/src/di/account_settings_di.dart';
import 'package:account_settings/src/presentation/bloc/account_settings/account_settings_bloc.dart';
import 'package:account_settings/src/presentation/pages/account_settings_page.dart';
import 'package:account_settings/src/routes/account_settings_routes.dart';
import 'package:core/core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Shared account settings module — hub + logout today.
class AccountSettingsModule extends FeatureModule {
  @override
  String get name => 'account_settings';

  @override
  String get version => '0.1.0';

  @override
  List<String> get dependencies => const ['auth', 'contact_verification'];

  @override
  void registerDependencies() => AccountSettingsDI.init();

  @override
  List<RouteBase> routes(FeatureRouteContext context) => [
    GoRoute(
      path: AccountSettingsRoutes.hub,
      builder: (context, state) => BlocProvider<AccountSettingsBloc>(
        create: (_) =>
            sl<AccountSettingsBloc>()..add(const AccountSettingsLoaded()),
        child: const AccountSettingsPage(),
      ),
    ),
  ];
}
