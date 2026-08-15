import 'package:core/core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:media_upload/media_upload.dart';
import 'package:services/src/di/services_di.dart';
import 'package:services/src/domain/entities/provider_service_entity.dart';
import 'package:services/src/domain/entities/service_request_entity.dart';
import 'package:services/src/presentation/bloc/add_service/add_service_bloc.dart';
import 'package:services/src/presentation/bloc/request_new_service/request_new_service_bloc.dart';
import 'package:services/src/presentation/bloc/service_action/service_action_bloc.dart';
import 'package:services/src/presentation/bloc/service_analytics/service_analytics_bloc.dart';
import 'package:services/src/presentation/bloc/service_requests_list/service_requests_list_bloc.dart';
import 'package:services/src/presentation/bloc/services_list/services_list_bloc.dart';
import 'package:services/src/presentation/bloc/edit_service/edit_service_bloc.dart';
import 'package:services/src/presentation/pages/add_service_page.dart';
import 'package:services/src/presentation/pages/edit_service_page.dart';
import 'package:services/src/presentation/pages/request_details_page.dart';
import 'package:services/src/presentation/pages/request_new_service_page.dart';
import 'package:services/src/presentation/pages/service_details_page.dart';
import 'package:services/src/presentation/pages/services_page.dart';
import 'package:services/src/presentation/widgets/manage_service_images_section.dart';
import 'package:services/src/routes/service_routes.dart';

class ServicesModule extends FeatureModule {
  @override
  String get name => 'services';

  @override
  String get version => '0.1.0';

  @override
  List<String> get dependencies => const ['auth'];

  @override
  void registerDependencies() => ServicesDI.init();

  // The `/services` tree is intentionally NOT contributed here as a
  // top-level route. It's embedded directly inside the provider app's
  // bottom-nav shell branch via [shellRoute] (see `provider_router.dart`).
  // Registering it both ways used to shadow the shell branch on first tab
  // visit — `StatefulNavigationShell.goBranch` re-matches the full route
  // tree the first time a branch is visited, so the plain top-level
  // registration (listed before the shell route) won the match and rendered
  // the page outside the shell, hiding the bottom nav bar.
  @override
  List<RouteBase> routes(FeatureRouteContext ctx) => const [];

  /// The `/services` route tree — embedded as-is inside the provider app's
  /// bottom-nav shell branch so pushes within it (details, edit, add, …)
  /// stay inside the shell and keep the bottom nav bar visible.
  static GoRoute shellRoute() => GoRoute(
    path: ServiceRoutes.list,
    builder: (context, state) => MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<ServicesListBloc>()),
        BlocProvider(create: (_) => sl<ServiceActionBloc>()),
        BlocProvider(create: (_) => sl<ServiceAnalyticsBloc>()),
        BlocProvider(create: (_) => sl<ServiceRequestsListBloc>()),
      ],
      child: ProviderServicesPage(
        initialTab: state.extra is int ? state.extra as int : 0,
      ),
    ),
    routes: [
      GoRoute(
        path: 'add',
        builder: (context, state) => BlocProvider(
          create: (_) => sl<AddServiceBloc>(),
          child: const AddServicePage(),
        ),
      ),
      GoRoute(
        path: 'request-new',
        builder: (context, state) => BlocProvider(
          create: (_) => sl<RequestNewServiceBloc>(),
          child: const RequestNewServicePage(),
        ),
      ),
      GoRoute(
        path: 'requests/:id',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is! ServiceRequestEntity) {
            return const _MissingRouteArgs();
          }
          return RequestDetailsPage(request: extra);
        },
      ),
      GoRoute(
        path: ':id',
        builder: (context, state) {
          final id = state.pathParameters['id'];
          if (id == null || id.isEmpty) {
            return const _MissingRouteArgs();
          }
          return BlocProvider(
            create: (_) => sl<ServiceActionBloc>(),
            child: ServiceDetailsPage(serviceId: id),
          );
        },
        routes: [
          GoRoute(
            path: 'edit',
            builder: (context, state) {
              final extra = state.extra;
              if (extra is! ProviderServiceEntity) {
                return const _MissingRouteArgs();
              }
              return MultiBlocProvider(
                providers: [
                  BlocProvider(create: (_) => sl<EditServiceBloc>()),
                  BlocProvider(
                    create: (_) => sl<MediaUploadBloc>(
                      param1: const MediaUploadConfig(
                        maxFileSize: 5 * 1024 * 1024,
                        maxFiles: kMaxServiceImages,
                        allowedMimeTypes: [
                          'image/jpeg',
                          'image/png',
                          'image/webp',
                        ],
                      ),
                    ),
                  ),
                ],
                child: EditServicePage(service: extra),
              );
            },
          ),
        ],
      ),
    ],
  );
}

/// Rendered instead of crashing when `:id`/`requests/:id` is reached without
/// its required `extra` payload (mirrors `invitation`'s equivalent guard).
class _MissingRouteArgs extends StatefulWidget {
  const _MissingRouteArgs();

  @override
  State<_MissingRouteArgs> createState() => _MissingRouteArgsState();
}

class _MissingRouteArgsState extends State<_MissingRouteArgs> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
