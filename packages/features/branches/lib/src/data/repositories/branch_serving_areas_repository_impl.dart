import 'package:branches/src/domain/repositories/branch_repository.dart';
import 'package:branches/src/domain/usecases/branch_usecase_params.dart';
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:maps/maps.dart';

class BranchServingAreasRepositoryImpl implements BranchServingAreasRepository {
  BranchServingAreasRepositoryImpl(this._branchRepository);

  final BranchRepository _branchRepository;
  final Map<String, List<ServingArea>> _cache = {};

  @override
  TaskEither<Failure, List<ServingArea>> getServingAreas(String branchId) {
    final cached = _cache[branchId];
    if (cached != null) {
      return TaskEither.right(cached);
    }

    return _branchRepository
        .getBranch(GetBranchParams(id: branchId))
        .map((branch) {
      final placeIds = branch.servingAreaPlaceIds ?? const [];
      final center = branch.lat != null && branch.lng != null
          ? LatLng(branch.lat!, branch.lng!)
          : const LatLng(0, 0);
      final areas = placeIds
          .map(
            (placeId) => ServingArea(
              placeId: placeId,
              name: placeId,
              address: branch.displayAddress,
              latLng: center,
            ),
          )
          .toList(growable: false);
      _cache[branchId] = areas;
      return areas;
    });
  }
}
