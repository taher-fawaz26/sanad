import 'package:branches/branches.dart';
import 'package:workers/workers.dart';

/// Maps a backend `ProviderStatisticEntity.key` to its existing destination
/// route, or `null` when no corresponding screen exists.
///
/// Never invents a route: an unrecognized key (including any key the
/// backend may add later) simply makes its card non-tappable rather than
/// guessing a destination.
String? statRouteForKey(String key) => switch (key) {
  'branches' => BranchRoutes.list,
  'coveredAreas' || 'covered_areas' => BranchRoutes.coverage,
  'workers' || 'teamMembers' || 'team_members' => WorkerRoutes.list,
  _ => null,
};
