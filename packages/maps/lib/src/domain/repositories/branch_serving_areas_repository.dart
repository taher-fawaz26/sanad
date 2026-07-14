import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:maps/src/domain/entities/serving_area.dart';

/// Domain contract for loading branch serving areas during coverage edit mode.
///
/// Implemented by the branches feature package — maps must not depend on it.
abstract interface class BranchServingAreasRepository {
  TaskEither<Failure, List<ServingArea>> getServingAreas(String branchId);
}
