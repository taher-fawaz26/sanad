import 'package:core/core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:services/src/di/services_di.dart';
import 'package:services/src/presentation/bloc/add_service/add_service_bloc.dart';
import 'package:services/src/presentation/bloc/request_new_service/request_new_service_bloc.dart';
import 'package:services/src/presentation/bloc/service_action/service_action_bloc.dart';
import 'package:services/src/presentation/bloc/service_analytics/service_analytics_bloc.dart';
import 'package:services/src/presentation/bloc/service_requests_list/service_requests_list_bloc.dart';
import 'package:services/src/presentation/bloc/services_list/services_list_bloc.dart';
import 'package:services/src/presentation/pages/add_service_page.dart';
import 'package:services/src/presentation/pages/request_new_service_page.dart';
import 'package:services/src/presentation/pages/services_page.dart';
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

  @override
  List<RouteBase> routes(FeatureRouteContext ctx) => [
    GoRoute(
      path: ServiceRoutes.list,
      builder: (context, state) => MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => sl<ServicesListBloc>()),
          BlocProvider(create: (_) => sl<ServiceActionBloc>()),
          BlocProvider(create: (_) => sl<ServiceAnalyticsBloc>()),
          BlocProvider(create: (_) => sl<ServiceRequestsListBloc>()),
        ],
        child: const ProviderServicesPage(),
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
      ],
    ),
  ];
}
