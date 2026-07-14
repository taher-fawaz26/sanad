import 'package:branches/src/di/branches_di.dart';
import 'package:branches/src/presentation/bloc/add_branch/add_branch_bloc.dart';
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
          builder: (context, state) => BlocProvider(
            create: (_) => sl<AddBranchBloc>()..add(const AddBranchStarted()),
            child: const AddBranchPage(),
          ),
        ),
        GoRoute(
          path: BranchRoutes.coverage,
          builder: (context, state) {
            final args = state.extra is CoverageAreaArgs
                ? state.extra! as CoverageAreaArgs
                : null;
            return BlocProvider(
              create: (_) => sl<CoverageAreaBloc>()
                ..add(
                  CoverageAreaStarted(
                    initialPosition: args?.position,
                    initialAddress: args?.address,
                    initialRadiusKm: args?.radiusKm,
                    initialServingAreas: args?.servingAreas ?? const [],
                    localeIdentifier: context.locale.toString(),
                  ),
                ),
              child: const CoverageAreaPage(),
            );
          },
        ),
        GoRoute(
          path: BranchRoutes.details,
          builder: (context, state) {
            final branchId = state.pathParameters['id']!;
            return BlocProvider(
              create: (_) => sl<BranchDetailsBloc>()
                ..add(BranchDetailsFetchEvent(branchId)),
              child: BranchDetailsPage(branchId: branchId),
            );
          },
        ),
      ];
}
