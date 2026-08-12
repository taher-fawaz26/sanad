import 'package:core/core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:provider_rbac/src/di/provider_rbac_di.dart';
import 'package:provider_rbac/src/domain/entities/role_entity.dart';
import 'package:provider_rbac/src/presentation/bloc/role_form/role_form_bloc.dart';
import 'package:provider_rbac/src/presentation/pages/role_details_page.dart';
import 'package:provider_rbac/src/presentation/pages/role_form_page.dart';
import 'package:provider_rbac/src/presentation/pages/roles_list_page.dart';
import 'package:provider_rbac/src/routes/provider_rbac_routes.dart';

class ProviderRbacModule extends FeatureModule {
  @override
  String get name => 'provider_rbac';

  @override
  String get version => '0.1.0';

  @override
  List<String> get dependencies => const ['auth', 'workers'];

  @override
  void registerDependencies() => ProviderRbacDI.init();

  @override
  List<RouteBase> routes(FeatureRouteContext ctx) => [
    GoRoute(
      path: ProviderRbacRoutes.list,
      // RolesListPage → RolesContent self-provides its own BLoCs.
      builder: (context, state) => const RolesListPage(),
      routes: [
        GoRoute(
          path: 'add',
          builder: (context, state) => BlocProvider(
            create: (_) => sl<RoleFormBloc>(),
            child: const RoleFormPage(),
          ),
        ),
        GoRoute(
          path: ':id/edit',
          builder: (context, state) => BlocProvider(
            create: (_) => sl<RoleFormBloc>(),
            child: RoleFormPage(existingRole: state.extra as RoleEntity?),
          ),
        ),
        GoRoute(
          path: ':id',
          builder: (context, state) =>
              RoleDetailsPage(role: state.extra as RoleEntity),
        ),
      ],
    ),
  ];
}
