import 'package:core/core.dart';

class PlacesApiKeyFailure extends ServerFailure {
  const PlacesApiKeyFailure({
    super.message = 'Invalid or missing Places API key',
    super.code = 'PLACES_API_KEY_INVALID',
  });
}

class PlacesQuotaExceededFailure extends ServerFailure {
  const PlacesQuotaExceededFailure({
    super.message = 'Places API quota exceeded',
    super.code = 'PLACES_QUOTA_EXCEEDED',
  });
}

class PlacesNetworkFailure extends NetworkFailure {
  const PlacesNetworkFailure({
    super.message = 'Places network request failed',
    super.code = 'PLACES_NETWORK_ERROR',
  });
}

class PlacesTimeoutFailure extends TimeoutFailure {
  const PlacesTimeoutFailure({
    super.message = 'Places request timed out',
    super.code = 'PLACES_TIMEOUT',
  });
}

class PlacesInvalidRequestFailure extends ServerFailure {
  const PlacesInvalidRequestFailure({
    super.message = 'Invalid Places request',
    super.code = 'PLACES_INVALID_REQUEST',
  });
}

class PlacesUnknownFailure extends UnknownFailure {
  const PlacesUnknownFailure({
    super.message = 'Unknown Places error',
    super.code = 'PLACES_UNKNOWN',
    super.metadata,
  });
}
