import 'package:core/core.dart';
import 'package:go_router/go_router.dart';
import 'package:sanad_client/src/features/client_requests/src/di/client_requests_di.dart';
import 'package:sanad_client/src/features/client_requests/src/domain/usecases/client_request_usecases.dart';
import 'package:sanad_client/src/features/client_requests/src/presentation/bloc/client_request_detail/client_request_detail_bloc.dart';
import 'package:sanad_client/src/features/client_requests/src/presentation/bloc/client_requests_list/client_requests_list_bloc.dart';
import 'package:sanad_client/src/features/client_requests/src/presentation/bloc/request_draft/request_draft_bloc.dart';
import 'package:sanad_client/src/features/client_requests/src/presentation/pages/client_request_detail_page.dart';
import 'package:sanad_client/src/features/client_requests/src/presentation/pages/client_requests_page.dart';
import 'package:sanad_client/src/features/client_requests/src/presentation/pages/request_composer_page.dart';
import 'package:sanad_client/src/features/client_requests/src/routes/client_request_routes.dart';

/// Contributes the client request lifecycle.
///
/// Registered unconditionally, unlike the AI-chat prototype: these routes exist
/// in release builds because a push notification has to be able to open a
/// request in a shipped app.
class ClientRequestsModule extends FeatureModule {
  @override
  String get name => 'client_requests';

  @override
  String get version => '0.1.0';

  /// Needs the session `auth` restores, and the maps stack for the location
  /// picker.
  @override
  List<String> get dependencies => const ['auth', 'maps'];

  @override
  void registerDependencies() => ClientRequestsDI.init();

  @override
  List<RouteBase> routes(FeatureRouteContext context) => [
    GoRoute(
      path: ClientRequestRoutes.list,
      builder: (_, _) => const ClientRequestsPage(buildBloc: _buildListBloc),
      routes: [
        // Nested so `/requests/new` is matched before the `:id` pattern —
        // otherwise "new" would be read as a request id.
        GoRoute(
          path: 'new',
          builder: (_, _) => RequestComposerPage(
            buildBloc: _buildDraftBloc,
            browseServices: sl<BrowseCatalogueServicesUseCase>(),
          ),
        ),
        GoRoute(
          path: ':id',
          builder: (context, state) {
            final id = state.pathParameters['id'] ?? '';
            return ClientRequestDetailPage(
              buildBloc: () => _buildDetailBloc(id),
              // A `REQUEST_OFFER` notification carries the offer id; the
              // thread it belongs to is highlighted rather than opened on a
              // screen of its own.
              focusOfferId: state
                  .uri
                  .queryParameters[ClientRequestRoutes.offerQueryParam],
            );
          },
          routes: [
            GoRoute(
              path: 'edit',
              builder: (context, state) => RequestComposerPage(
                buildBloc: _buildDraftBloc,
                browseServices: sl<BrowseCatalogueServicesUseCase>(),
                requestId: state.pathParameters['id'],
              ),
            ),
          ],
        ),
      ],
    ),
  ];

  static ClientRequestsListBloc _buildListBloc() =>
      sl<ClientRequestsListBloc>();

  static RequestDraftBloc _buildDraftBloc() => sl<RequestDraftBloc>();

  static ClientRequestDetailBloc _buildDetailBloc(String requestId) =>
      ClientRequestDetailBloc(
        requestId: requestId,
        getRequest: sl<GetClientRequestUseCase>(),
        cancelRequest: sl<CancelClientRequestUseCase>(),
        confirmRequest: sl<ConfirmClientRequestUseCase>(),
        disputeRequest: sl<DisputeClientRequestUseCase>(),
        acceptOffer: sl<AcceptOfferUseCase>(),
        rejectOffer: sl<RejectOfferUseCase>(),
        counterOffer: sl<CounterOfferUseCase>(),
      );
}
