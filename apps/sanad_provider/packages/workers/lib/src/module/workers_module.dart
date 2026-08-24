import 'package:core/core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:workers/src/di/workers_di.dart';
import 'package:workers/src/domain/entities/worker_entity.dart';
import 'package:workers/src/presentation/bloc/add_worker/add_worker_bloc.dart';
import 'package:workers/src/presentation/bloc/edit_worker/edit_worker_bloc.dart';
import 'package:workers/src/presentation/bloc/invitation_action/invitation_action_cubit.dart';
import 'package:workers/src/presentation/bloc/invitations_list/invitations_list_bloc.dart';
import 'package:workers/src/presentation/bloc/worker_action/worker_action_cubit.dart';
import 'package:workers/src/presentation/bloc/workers_list/workers_list_bloc.dart';
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

  // The route tree is contributed via [route], not here — same reasoning as
  // `ServicesModule`: it needs an `isOwner` callback (for the
  // Invitations/Roles tabs, RBAC Phase 7F) that the generic
  // `FeatureModule.routes(ctx)` signature has no way to carry.
  @override
  List<RouteBase> routes(FeatureRouteContext ctx) => const [];

  /// The `/workers` route tree. [isOwner] resolves whether the signed-in
  /// account may see the Invitations and Roles tabs — backed by
  /// `workers/invitations` and `provider/roles`, both of which the backend
  /// 403s for any worker/manager token regardless of granted permissions
  /// (RBAC Phase 7 finding F1). [canViewTeamActivity] resolves whether the
  /// signed-in account may see another worker's "Recent Activity" section on
  /// `:id` (owner/manager only — `actorId` is silently ignored for a worker
  /// token, so showing this to a plain worker would render *their own* feed
  /// under someone else's profile). Both are callbacks, not a `bool`, so
  /// they are read fresh on every navigation to this route — matching
  /// `ServicesModule.shellRoute`'s reasoning exactly.
  static GoRoute route({
    required bool Function() isOwner,
    required bool Function() canViewTeamActivity,
  }) => GoRoute(
    path: WorkerRoutes.list,
    builder: (context, state) {
      final owner = isOwner();
      return MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => sl<WorkersListBloc>()),
          BlocProvider(create: (_) => sl<WorkerActionCubit>()),
          if (owner) BlocProvider(create: (_) => sl<InvitationsListBloc>()),
          if (owner) BlocProvider(create: (_) => sl<InvitationActionCubit>()),
        ],
        child: WorkersPage(isOwner: owner),
      );
    },
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
        builder: (context, state) => BlocProvider(
          create: (_) => sl<WorkerActionCubit>(),
          child: WorkerDetailsPage(
            workerId: state.pathParameters['id']!,
            initialWorker: state.extra as WorkerEntity?,
            isOwner: isOwner(),
            canViewActivity: canViewTeamActivity(),
          ),
        ),
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
  );
}
