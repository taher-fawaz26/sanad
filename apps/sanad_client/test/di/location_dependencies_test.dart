// Regression for C-01: opening the request composer's location step threw
// `GetIt: Object/factory with type GeocodingService is not registered inside
// GetIt` because `sanad_client` registered `MapsModule` without the two
// platform services `MapsDI` builds its repositories on top of.
//
// `MapsDI.init` *consumes* `GeocodingService` and `LocationService`; it does
// not own them. The app that registers Maps has to supply them (which
// `sanad_provider` always did). This test asserts the client's half of that
// contract by resolving the exact object the location sheet resolves —
// `sl<LocationPickerBloc>()`, from `MapLocationPicker` — through the same
// registration sequence `configureDependencies()` performs.
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maps/maps.dart';
import 'package:permissions/permissions.dart';

/// A stand-in for the platform permission gateway.
///
/// `LocationServiceImpl` only holds a reference to it during construction, and
/// this test never asks for a fix, so nothing here is ever called. A plain
/// stub rather than a mock keeps the test free of a mocking dependency it does
/// not need.
class _StubPermissionService implements PermissionService {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not used here');
}

/// The maps wiring `configureDependencies()` performs, in the same order.
///
/// Deliberately mirrors `app_di.dart` rather than calling it: the real
/// bootstrap needs Firebase, Hive and secure storage, none of which a unit
/// test can stand up, and none of which this regression is about.
void _registerClientMapsStack({required MapsConfig config}) {
  sl
    ..registerLazySingleton<PermissionService>(_StubPermissionService.new)
    ..registerLazySingleton<LocationService>(
      () => LocationServiceImpl(sl<PermissionService>()),
    )
    ..registerLazySingleton<GeocodingService>(
      () => const GeocodingServiceImpl(),
    );
  MapsDI.init(config: config);
}

void main() {
  tearDown(sl.reset);

  group('client maps dependencies', () {
    test('LocationPickerBloc resolves — what the location sheet builds', () {
      _registerClientMapsStack(config: const MapsConfig());

      // Resolving is the assertion: before the fix this threw
      // `GetIt: GeocodingService is not registered`.
      final bloc = sl<LocationPickerBloc>();
      addTearDown(bloc.close);
      expect(bloc, isA<LocationPickerBloc>());
    });

    test('resolves with a Places key, which widens the graph', () {
      // The keyed configuration registers SearchPlacesUseCase,
      // GetPlaceDetailsUseCase and ReverseGeocodePlaceUseCase and injects all
      // three into the bloc, so it exercises a strictly larger graph than the
      // keyless build above. Both must resolve.
      _registerClientMapsStack(
        config: const MapsConfig(placesApiKey: 'test-key'),
      );

      // Resolving is the assertion: before the fix this threw
      // `GetIt: GeocodingService is not registered`.
      final bloc = sl<LocationPickerBloc>();
      addTearDown(bloc.close);
      expect(bloc, isA<LocationPickerBloc>());
    });

    test(
      'every service MapsDI consumes but does not register is registered',
      () {
        _registerClientMapsStack(config: const MapsConfig());

        // Named individually so a future addition to MapsDI's external
        // requirements fails here with the missing type, rather than as an
        // opaque GetIt error the first time a user opens the picker.
        expect(sl<GeocodingService>(), isA<GeocodingService>());
        expect(sl<LocationService>(), isA<LocationService>());
      },
    );
  });
}
