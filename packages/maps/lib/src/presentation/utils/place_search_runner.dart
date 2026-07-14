import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps/src/domain/entities/place_prediction.dart';
import 'package:maps/src/domain/usecases/search_places_usecase.dart';
import 'package:maps/src/presentation/utils/latest_operation.dart';

/// Shared Places autocomplete runner used by the location and area pickers.
///
/// Owns the "latest request wins" guard for autocomplete so both blocs get
/// identical concurrency behaviour without duplicating the plumbing. Callers
/// remain responsible for mapping the returned result into their own state and
/// for any status emissions.
class PlaceSearchRunner {
  PlaceSearchRunner({SearchPlacesUseCase? searchPlacesUseCase})
      : _searchPlacesUseCase = searchPlacesUseCase;

  final SearchPlacesUseCase? _searchPlacesUseCase;
  final LatestOperation _searchOp = LatestOperation();

  /// Whether Places autocomplete is available (the use case was provided).
  bool get isEnabled => _searchPlacesUseCase != null;

  /// Runs an autocomplete query. Returns the use-case result, or `null` when
  /// the request was superseded by a newer one (the caller should ignore it)
  /// or when search is disabled.
  Future<Either<Failure, List<PlacePrediction>>?> search({
    required String query,
    String? language,
    LatLng? biasLocation,
  }) async {
    final useCase = _searchPlacesUseCase;
    if (useCase == null) return null;

    final token = _searchOp.begin();
    final result = await useCase(
      SearchPlacesParams(
        query: query,
        language: language,
        biasLocation: biasLocation,
      ),
    ).run();
    if (!_searchOp.isCurrent(token)) return null;
    return result;
  }

  /// Invalidates any in-flight autocomplete request so its result is ignored.
  /// Called when a prediction is chosen or a manual submit supersedes search.
  void cancelPending() => _searchOp.begin();
}
