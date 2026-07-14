# Maps Platform — Testing

## Purpose
Testing strategy and patterns for the Maps Platform.

## Test Structure

```
test/
  src/
    data/cache/
      geocoding_cache_test.dart         (7 tests)
    presentation/
      bloc/
        coverage_area/
          coverage_area_bloc_test.dart  (15 tests)
        location_picker/
          location_picker_bloc_test.dart (15 tests)
      controllers/
        map_camera_follower_test.dart   (8 tests)
        map_overlay_controller_test.dart (11 tests)
        map_radius_controller_test.dart (10 tests)
      utils/
        geo_math_test.dart             (7 tests)
```

**Total: 73 tests**

## Dependencies

```yaml
dev_dependencies:
  bloc_test: ^10.0.0
  flutter_test: sdk
  mocktail: ^1.0.4
```

## Patterns

### Mocking Use Cases
```dart
class _MockGetCurrentLocation extends Mock
    implements GetCurrentLocationUseCase {}

// Register fallback values in setUpAll
setUpAll(() {
  registerFallbackValue(const NoParams());
  registerFallbackValue(ReverseGeocodeParams(position: position));
});

// Stub with TaskEither
when(() => useCase(any())).thenReturn(TaskEither.right(result));
when(() => useCase(any())).thenReturn(TaskEither.left(failure));
```

### BLoC Testing
```dart
blocTest<LocationPickerBloc, LocationPickerState>(
  'description',
  build: () {
    when(() => useCase(any())).thenReturn(TaskEither.right(value));
    return buildBloc();
  },
  act: (bloc) => bloc.add(Event()),
  expect: () => [
    isA<State>().having((s) => s.status, 'status', Status.ready),
  ],
);
```

### Controller Testing
```dart
test('notification batching', () {
  var count = 0;
  controller.addListener(() => count++);
  controller.update(center: position, radiusKm: 10);
  expect(count, 1); // Single notification for batched update
});
```

### Testing Optional Dependencies
```dart
// Places use cases are optional — test both paths
LocationPickerBloc buildBloc({bool withPlaces = false}) =>
    LocationPickerBloc(
      // ... required use cases
      searchPlacesUseCase: withPlaces ? searchPlaces : null,
      getPlaceDetailsUseCase: withPlaces ? getPlaceDetails : null,
    );
```

## Best Practices
- Mock at the use case level, not the service/provider level
- Use `verify`/`wait` for async BLoC tests with multiple sequential emissions
- Test no-notification paths (e.g., `clearMarkers` on empty controller)
- Test concurrency guards by checking op-id behavior
- Always `addTearDown(bloc.close)` for non-blocTest tests
