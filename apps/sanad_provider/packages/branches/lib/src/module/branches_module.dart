import 'package:branches/src/di/branches_di.dart';
import 'package:branches/src/presentation/bloc/add_branch/add_branch_bloc.dart';
import 'package:branches/src/presentation/bloc/add_branch/add_branch_draft_cubit.dart';
import 'package:branches/src/presentation/bloc/add_branch/add_branch_location_cubit.dart';
import 'package:branches/src/presentation/bloc/add_branch/add_branch_wizard_cubit.dart';
import 'package:branches/src/presentation/bloc/branch_details/branch_details_bloc.dart';
import 'package:branches/src/presentation/bloc/branches/branches_bloc.dart';
import 'package:branches/src/presentation/models/coverage_area_args.dart';
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

  // `BranchRoutes.list` and `BranchRoutes.details` are NOT contributed
  // here — both need an `isOwner` callback (to gate the Delete swipe /
  // action-sheet item, which is persona-controlled — RBAC backend gap G2)
  // that the generic `FeatureModule.routes(ctx)` signature has no way to
  // carry. See `ownerAwareRoutes` below, wired directly in
  // `provider_router.dart` — same reasoning and pattern as
  // `ServicesModule.shellRoute`/`WorkersModule.route`. Add and Coverage
  // need no persona flag (Add is permission-gated on `branch:create`;
  // Coverage on `any(create, update)`), so they stay in the generic
  // registration.
  @override
  List<RouteBase> routes(FeatureRouteContext ctx) => [
    GoRoute(
      path: BranchRoutes.add,
      builder: (context, state) => MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => sl<AddBranchBloc>()..add(const AddBranchStarted()),
          ),
          BlocProvider(create: (_) => AddBranchDraftCubit()),
          BlocProvider(
            create: (_) => AddBranchWizardCubit(totalSteps: 4),
          ),
          BlocProvider(
            create: (_) => AddBranchLocationCubit(sl<LocationService>()),
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
  ];

  /// `/branches` (list) and `/branches/:id` (details) — contributed
  /// separately from [routes] because both need [isOwner] to gate the
  /// Delete swipe / action-sheet item (persona-controlled — RBAC backend
  /// gap G2). [isOwner] is a callback, not a `bool`, so it is read fresh
  /// on every navigation — matching `ServicesModule.shellRoute`'s
  /// reasoning exactly. Wired directly in `provider_router.dart` alongside
  /// the generic `moduleRoutes` spread.
  static List<RouteBase> ownerAwareRoutes({
    required bool Function() isOwner,
  }) => [
    GoRoute(
      path: BranchRoutes.list,
      builder: (context, state) => BlocProvider(
        create: (_) => sl<BranchesBloc>(),
        child: ProviderBranchesPage(isOwner: isOwner()),
      ),
    ),
    GoRoute(
      path: BranchRoutes.details,
      builder: (context, state) {
        final branchId = state.pathParameters['id']!;
        return BlocProvider(
          create: (_) =>
              sl<BranchDetailsBloc>()..add(BranchDetailsFetchEvent(branchId)),
          child: BranchDetailsPage(branchId: branchId, isOwner: isOwner()),
        );
      },
    ),
  ];
}
