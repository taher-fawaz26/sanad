import 'package:core/core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:workers/src/di/workers_di.dart';
import 'package:workers/src/domain/entities/worker_entity.dart';
import 'package:workers/src/presentation/bloc/add_worker/add_worker_bloc.dart';
import 'package:workers/src/presentation/bloc/edit_worker/edit_worker_bloc.dart';
import 'package:workers/src/presentation/bloc/workers/workers_bloc.dart';
import 'package:workers/src/presentation/pages/add_worker_page.dart';
import 'package:workers/src/presentation/pages/edit_worker_page.dart';
import 'package:workers/src/presentation/pages/worker_details_page.dart';
import 'package:workers/src/presentation/pages/workers_page.dart';
import 'package:workers/src/routes/worker_routes.dart';

class WorkersModule extends FeatureModule {
  @override
  String get name => 'workers';

  @override
  String get version => '0.1.0';

  @override
  List<String> get dependencies => const ['auth'];

  @override
  void registerDependencies() => WorkersDI.init();

  @override
  List<RouteBase> routes(FeatureRouteContext ctx) => [
    GoRoute(
      path: WorkerRoutes.list,
      builder: (context, state) => BlocProvider(
        create: (_) => sl<WorkersBloc>(),
        child: const WorkersPage(),
      ),
      routes: [
        GoRoute(
          path: 'add',
          builder: (context, state) => BlocProvider(
            create: (_) => sl<AddWorkerBloc>(),
            child: const AddWorkerPage(),
          ),
        ),
        GoRoute(
          path: ':id',
          builder: (context, state) {
            final worker = state.extra as WorkerEntity?;
            if (worker == null) return const SizedBox.shrink();
            return WorkerDetailsPage(worker: worker);
          },
          routes: [
            GoRoute(
              path: 'edit',
              builder: (context, state) {
                final worker = state.extra as WorkerEntity?;
                if (worker == null) return const SizedBox.shrink();
                return BlocProvider(
                  create: (_) => sl<EditWorkerBloc>(),
                  child: EditWorkerPage(worker: worker),
                );
              },
            ),
          ],
        ),
      ],
    ),
  ];
}
