# Maps Platform — Places

## Purpose
Autocomplete place search and place details resolution with a provider-based architecture.

## Architecture

```
SearchPlacesUseCase / GetPlaceDetailsUseCase
        │
        ▼
PlacesRepository (session token management)
        │
        ▼
PlacesProvider (abstract)
        │
 ┌──────┼───────────────┐
 ▼      ▼               ▼
Google  Backend          OSM
```

## PlacesProvider Interface
Abstract contract for any Places backend:
- `autocomplete({query, sessionToken, language, location, radiusMeters})` → `TaskEither<Failure, List<PlacePrediction>>`
- `getPlaceDetails({placeId, sessionToken})` → `TaskEither<Failure, LatLng>`

## Providers

### GooglePlacesProvider
Production implementation using Google Places API via Dio HTTP client.
- Configurable via `MapsConfig(placesApiKey: ..., placesProvider: PlacesProviderType.google)`
- Maps Google API status codes to typed `PlacesFailure` classes
- Uses Dio with configurable timeouts for network requests

### BackendPlacesProvider
Stub for routing Places queries through your own backend API.
- Returns `UnknownFailure` with "not yet implemented" message
- Ready for implementation when backend Places proxy is available

### OsmPlacesProvider
Stub for OpenStreetMap Nominatim integration.
- Returns `UnknownFailure` with "not yet implemented" message

## Session Token Management
`PlacesRepositoryImpl` manages session tokens per Google's billing model:
- Token created on first autocomplete call (32-char hex)
- Same token reused across autocomplete calls in a session
- Token cleared after `getPlaceDetails` (ends billing session)
- `resetSession()` for manual token reset

## Typed Failures
All Places errors are mapped to typed failure classes:

| Failure | Parent | When |
|---------|--------|------|
| `PlacesApiKeyFailure` | `ServerFailure` | `REQUEST_DENIED` status |
| `PlacesQuotaExceededFailure` | `ServerFailure` | `OVER_QUERY_LIMIT` status |
| `PlacesNetworkFailure` | `NetworkFailure` | Dio connection/network error |
| `PlacesTimeoutFailure` | `TimeoutFailure` | Dio timeout |
| `PlacesInvalidRequestFailure` | `ServerFailure` | `INVALID_REQUEST` status |
| `PlacesUnknownFailure` | `UnknownFailure` | Any other error |

## Configuration

```dart
MapsDI.init(
  config: MapsConfig(
    placesApiKey: String.fromEnvironment('MAPS_API_KEY'),
    placesProvider: PlacesProviderType.google,
  ),
);
```

Places is fully opt-in — `null` key means graceful fallback to forward geocoding.

## Extension Points
Implement `PlacesProvider` for any backend, register it in `MapsDI._createPlacesProvider()`.
