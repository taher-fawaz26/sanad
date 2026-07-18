import 'package:core/core.dart';

class LocationsNoCountryFailure extends ServerFailure {
  const LocationsNoCountryFailure({
    super.message = 'No supported countries returned by the server',
    super.code = 'LOCATIONS_NO_COUNTRY',
  });
}

/// Returned when the backend returns more than one country and no country
/// selection UI exists yet. The caller should surface a fallback/error state.
class LocationsMultiCountryFailure extends ServerFailure {
  const LocationsMultiCountryFailure({
    super.message = 'Multi-country selection is not yet supported',
    super.code = 'LOCATIONS_MULTI_COUNTRY',
  });
}

class LocationsNetworkFailure extends NetworkFailure {
  const LocationsNetworkFailure({
    super.message = 'Locations network request failed',
    super.code = 'LOCATIONS_NETWORK_ERROR',
  });
}
