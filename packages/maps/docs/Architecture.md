# Maps Platform — Architecture

## Purpose

The Maps Platform (`packages/maps`) is a **business-feature-agnostic** Flutter package that provides geographic capabilities to any feature in the Sanad monorepo. It encapsulates Google Maps, geocoding, Places search, location services, and reusable map widgets behind clean domain boundaries.

## Architecture

The package follows **Clean Architecture** with three layers:

```
┌─────────────────────────────────────────────────┐
│  Presentation                                   │
│  BLoCs, Controllers, Widgets, Models            │
├─────────────────────────────────────────────────┤
│  Domain                                         │
│  Entities, Repositories (abstract), Use Cases   │
│  Failures                                       │
├─────────────────────────────────────────────────┤
│  Data                                           │
│  Repository Implementations, Cache              │
├─────────────────────────────────────────────────┤
│  Services (Infrastructure)                      │
│  PlacesProvider, GeocodingService,              │
│  LocationService                                │
└─────────────────────────────────────────────────┘
```

### Domain Layer

- **Entities**: `MapPosition`, `MapRegion`, `PlacePrediction`, `MapEvent` (typed map events)
- **Repositories**: Abstract contracts (`PlacesRepository`, `GeocodingRepository`, `LocationRepository`)
- **Use Cases**: Single-responsibility classes following `UseCase<TResult, Params>` base from core
- **Failures**: Typed `PlacesFailure` hierarchy extending core `Failure` subtypes

### Data Layer

- **Repository Implementations**: Concrete implementations with session token management, caching
- **Cache**: LRU geocoding cache with coordinate rounding (~11m precision)

### Presentation Layer

- **BLoCs**: `LocationPickerBloc` (location selection with Places autocomplete), `CoverageAreaBloc` (radius-based area management)
- **Controllers**: `MapCameraController`, `MapRadiusController`, `MapOverlayController`, `MapCameraFollower`
- **Widgets**: Reusable widget catalog (LocationPicker, CoverageAreaPicker, PlaceSearchBar, RadiusSelector, NearbyPlacesSheet, map controls)
- **Models**: Configuration, labels, styles, presets

### Services Layer

- **PlacesProvider**: Abstract interface with provider-based architecture (Google, Backend, OSM)
- **GeocodingService**: Forward/reverse geocoding and nearby area discovery
- **LocationService**: GPS location and permission management

## Dependency Flow

```
Feature (branches, etc.)
    │
    ▼
maps (Platform Package)
    │
    ├── core (Failure, UseCase, DI)
    ├── design_system (UI tokens)
    ├── network (Dio, interceptors)
    ├── permissions (location permissions)
    └── google_maps_flutter (map widget)
```

Features depend on maps; maps never depends on features.

## Responsibilities

- Provide all geographic capabilities through a single barrel import (`package:maps/maps.dart`)
- Keep Google Maps implementation details internal
- Expose reusable, locale-agnostic widgets via parameterized labels
- Support opt-in Places API with configurable providers
- Manage concurrency with op-id guards in BLoCs
- Handle location permissions through the shared permissions package

## Extension Points

1. **New PlacesProvider**: Implement `PlacesProvider` for any Places backend
2. **Custom widgets**: Compose controllers and BLoCs for new map experiences
3. **New map events**: Extend the `MapEvent` sealed class for additional interactions
4. **Custom overlays**: Use `MapOverlayController` for markers, polygons, polylines

## Best Practices

- Always use `MapsConfig` for configuration — never hardcode API keys
- Use `LocationPickerLabels` / `CoverageAreaLabels` for all user-facing strings
- Prefer `MapCameraController` over raw `GoogleMapController`
- Use typed `PlacesFailure` classes for error handling, not raw HTTP errors
- Register via `MapsDI.init()` — never register maps dependencies manually
