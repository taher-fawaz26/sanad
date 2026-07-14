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

- **Entities**: `PlacePrediction`, `ServingArea`, `MapAreaPickerResult`, `CoverageLocation`, `CoverageMode`, `MapRegion`
- **Repositories**: Abstract contracts (`PlacesRepository`, `GeocodingRepository`, `LocationRepository`)
- **Use Cases**: Single-responsibility classes following `UseCase<TResult, Params>` base from core
- **Failures**: Typed `PlacesFailure` hierarchy extending core `Failure` subtypes

### Data Layer

- **Repository Implementations**: Concrete implementations with session token management, caching
- **Cache**: LRU geocoding cache with coordinate rounding (~11m precision)

### Presentation Layer

- **BLoCs**: `LocationPickerBloc` (single-location selection with Places autocomplete), `CoverageAreaBloc` (radius-based coverage: auto areas + a list of extra areas), `MapAreaPickerBloc` (internal — powers the feature-agnostic single-area picker)
- **Controllers**: `MapCameraController`, `MapRadiusController`, `ServingAreaController`
- **Widgets**: Reusable catalog — `AppGoogleMap`, `showLocationPickerSheet`, `showMapAreaPicker`, `PlaceSearchBar`, `ServingAreaChips`, and internal map controls
- **Shared helpers**: `LatestOperation` (latest-request-wins guard) and `PlaceSearchRunner` (shared autocomplete plumbing) de-duplicate concurrency logic across the pickers
- **Models**: Configuration, labels, styles

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
2. **Custom widgets**: Compose `MapCameraController` / `MapRadiusController` and the BLoCs for new map experiences
3. **New feature flows**: Reuse `showMapAreaPicker` / `CoverageAreaBloc`, feeding feature data via bloc events and mapping the generic results back in the feature layer

## Best Practices

- Always use `MapsConfig` for configuration — never hardcode API keys
- Use `LocationPickerLabels` / `MapAreaPickerLabels` for all user-facing strings
- Prefer `MapCameraController` over raw `GoogleMapController`
- Register via `MapsDI.init()` — never register maps dependencies manually
- **Never** add feature-specific concepts (branch/warehouse/driver ids, feature
  repositories) to this package. Feed feature data in through bloc events;
  return generic results the feature maps into its own domain.
