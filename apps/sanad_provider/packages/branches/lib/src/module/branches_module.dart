import 'package:branches/src/di/branches_di.dart';
import 'package:branches/src/domain/entities/branch_entity.dart';
import 'package:branches/src/presentation/bloc/add_branch/add_branch_bloc.dart';
import 'package:branches/src/presentation/bloc/add_branch/add_branch_draft_cubit.dart';
import 'package:branches/src/presentation/bloc/add_branch/add_branch_draft_state.dart';
import 'package:branches/src/presentation/bloc/add_branch/add_branch_wizard_cubit.dart';
import 'package:branches/src/presentation/bloc/branch_details/branch_details_bloc.dart';
import 'package:branches/src/presentation/bloc/branches/branches_bloc.dart';
import 'package:branches/src/presentation/models/branch_form_mode.dart';
import 'package:branches/src/presentation/models/coverage_area_args.dart';
import 'package:branches/src/presentation/utils/branch_draft_seeder.dart';
import 'package:maps/maps.dart';
import 'package:branches/src/presentation/pages/add_branch_page.dart';
import 'package:branches/src/presentation/pages/branch_details_page.dart';
import 'package:branches/src/presentation/pages/branches_page.dart';
import 'package:branches/src/presentation/pages/coverage_area_page.dart';
import 'package:branches/src/routes/branch_routes.dart';
import 'package:core/core.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class BranchesModule extends FeatureModule {
  @override
  String get name => 'branches';

  @override
  String get version => '0.1.0';

  @override
  List<String> get dependencies => const ['auth'];

  @override
  void registerDependencies() => BranchesDI.init();

  @override
  List<RouteBase> routes(FeatureRouteContext ctx) => [
    GoRoute(
      path: BranchRoutes.list,
      builder: (context, state) => BlocProvider(
        create: (_) => sl<BranchesBloc>(),
        child: const ProviderBranchesPage(),
      ),
    ),
    GoRoute(
      path: BranchRoutes.add,
      builder: (context, state) => MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => sl<AddBranchBloc>()..add(const AddBranchStarted()),
          ),
          BlocProvider(create: (_) => AddBranchDraftCubit()),
          BlocProvider(
            create: (_) => AddBranchWizardCubit(isEdit: false, totalSteps: 4),
          ),
        ],
        child: const AddBranchPage(),
      ),
    ),
    GoRoute(
      path: BranchRoutes.coverage,
      builder: (context, state) {
        final args = state.extra is CoverageAreaArgs
            ? state.extra! as CoverageAreaArgs
            : null;
        final locale = context.locale.toString();
        return MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (_) => sl<CoverageAreaBloc>()
                ..add(
                  CoverageAreaStarted(
                    mode: args?.mode ?? CoverageMode.create,
                    initialCenter: args?.position,
                    initialAddress: args?.address,
                    initialRadiusKm: args?.radiusKm,
                    initialAutoAreas: args?.servingAreas ?? const [],
                    localeIdentifier: locale,
                  ),
                ),
            ),
            BlocProvider(
              create: (_) => sl<LocationPickerBloc>(),
            ),
          ],
          child: const CoverageAreaPage(),
        );
      },
    ),
    GoRoute(
      path: BranchRoutes.edit,
      builder: (context, state) {
        final branchId = state.pathParameters['id']!;
        // Branch Details passes the already-loaded branch to avoid a refetch;
        // deep links (id only) fall back to loading it in the wizard.
        final branch = state.extra is BranchEntity
            ? state.extra! as BranchEntity
            : null;
        return MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (_) => sl<AddBranchBloc>()..add(const AddBranchStarted()),
            ),
            BlocProvider(
              // Seed the draft (and its change-tracking baseline) from the
              // pre-loaded branch when available; the id-only path seeds later,
              // once the wizard fetches the branch.
              create: (_) => AddBranchDraftCubit(
                initial: branch != null
                    ? BranchDraftSeeder.fromBranch(branch)
                    : const AddBranchDraft(),
              ),
            ),
            BlocProvider(
              create: (_) => AddBranchWizardCubit(isEdit: true, totalSteps: 4),
            ),
          ],
          child: AddBranchPage(
            mode: BranchFormMode.edit,
            branchId: branchId,
            initialBranch: branch,
          ),
        );
      },
    ),
    GoRoute(
      path: BranchRoutes.details,
      builder: (context, state) {
        final branchId = state.pathParameters['id']!;
        return BlocProvider(
          create: (_) =>
              sl<BranchDetailsBloc>()..add(BranchDetailsFetchEvent(branchId)),
          child: BranchDetailsPage(branchId: branchId),
        );
      },
    ),
  ];
}
