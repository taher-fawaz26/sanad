import 'package:core/core.dart';
import 'package:go_router/go_router.dart';
import 'package:sanad_provider/src/features/requests/src/di/provider_requests_di.dart';
import 'package:sanad_provider/src/features/requests/src/domain/usecases/provider_request_usecases.dart';
import 'package:sanad_provider/src/features/requests/src/presentation/bloc/detail/provider_request_detail_bloc.dart';
import 'package:sanad_provider/src/features/requests/src/presentation/bloc/workspace/provider_requests_workspace_bloc.dart';
import 'package:sanad_provider/src/features/requests/src/presentation/pages/provider_request_detail_page.dart';
import 'package:sanad_provider/src/features/requests/src/presentation/pages/provider_requests_page.dart';
import 'package:sanad_provider/src/features/requests/src/routes/provider_request_routes.dart';

/// Registers the provider request workspace.
///
/// Like `ServicesModule`, this returns `const []` from [routes] and exposes
/// [shellRoute] instead. `/requests` is a bottom-nav branch, and registering it
/// both ways shadows the branch on first visit — `StatefulNavigationShell`
/// re-matches the whole tree then, and the plain top-level registration wins,
/// rendering the page outside the shell with no bottom nav bar.
class ProviderRequestsModule extends FeatureModule {
  @override
  String get name => 'provider_requests';

  @override
  String get version => '0.1.0';

  /// Needs the session `auth` restores.
  @override
  List<String> get dependencies => const ['auth'];

  @override
  void registerDependencies() => ProviderRequestsDI.init();

  @override
  List<RouteBase> routes(FeatureRouteContext context) => const [];

  /// The `/requests` route tree, embedded in the bottom-nav shell branch so a
  /// push to a request detail stays inside the shell.
  static GoRoute shellRoute() => GoRoute(
    path: ProviderRequestRoutes.list,
    builder: (_, _) =>
        const ProviderRequestsPage(buildBloc: _buildWorkspaceBloc),
    routes: [
      GoRoute(
        path: ':id',
        builder: (context, state) => ProviderRequestDetailPage(
          buildBloc: () => _buildDetailBloc(state.pathParameters['id'] ?? ''),
        ),
      ),
    ],
  );

  static ProviderRequestsWorkspaceBloc _buildWorkspaceBloc() =>
      sl<ProviderRequestsWorkspaceBloc>();

  static ProviderRequestDetailBloc _buildDetailBloc(String requestId) =>
      ProviderRequestDetailBloc(
        requestId: requestId,
        getRequest: sl<GetProviderRequestUseCase>(),
        createOffer: sl<CreateProviderOfferUseCase>(),
        withdrawOffer: sl<WithdrawProviderOfferUseCase>(),
        acceptCounter: sl<AcceptClientCounterUseCase>(),
        declineCounter: sl<DeclineClientCounterUseCase>(),
        counterOffer: sl<CounterClientOfferUseCase>(),
        completeJob: sl<CompleteProviderJobUseCase>(),
        cancelJob: sl<CancelProviderJobUseCase>(),
      );
}
