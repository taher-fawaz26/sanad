// ignore_for_file: prefer_const_constructors

import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps/src/domain/entities/geocoded_address.dart';
import 'package:maps/src/domain/entities/place_prediction.dart';
import 'package:maps/src/domain/usecases/check_location_permission_usecase.dart';
import 'package:maps/src/domain/usecases/forward_geocode_usecase.dart';
import 'package:maps/src/domain/usecases/get_current_location_usecase.dart';
import 'package:maps/src/domain/usecases/get_place_details_usecase.dart';
import 'package:maps/src/domain/usecases/open_device_location_settings_usecase.dart';
import 'package:maps/src/domain/usecases/open_location_settings_usecase.dart';
import 'package:maps/src/domain/usecases/reverse_geocode_place_usecase.dart';
import 'package:maps/src/domain/usecases/reverse_geocode_usecase.dart';
import 'package:maps/src/domain/usecases/search_places_usecase.dart';
import 'package:maps/src/presentation/bloc/location_picker/location_picker_bloc.dart';
import 'package:maps/src/presentation/models/place_search_status.dart';
import 'package:maps/src/services/location_failure_codes.dart';
import 'package:maps/src/services/location_service.dart';
import 'package:mocktail/mocktail.dart';

class _MockReverseGeocode extends Mock implements ReverseGeocodeUseCase {}

class _MockForwardGeocode extends Mock implements ForwardGeocodeUseCase {}

class _MockOpenSettings extends Mock implements OpenLocationSettingsUseCase {}

class _MockOpenDeviceSettings extends Mock
    implements OpenDeviceLocationSettingsUseCase {}

class _MockGetCurrentLocation extends Mock
    implements GetCurrentLocationUseCase {}

class _MockReverseGeocodePlace extends Mock
    implements ReverseGeocodePlaceUseCase {}

class _MockSearchPlaces extends Mock implements SearchPlacesUseCase {}

class _MockGetPlaceDetails extends Mock implements GetPlaceDetailsUseCase {}

class _MockCheckLocationPermission extends Mock
    implements CheckLocationPermissionUseCase {}

const _tPosition = LatLng(25.0, 55.0);
const _tAddress = 'Dubai Marina, Dubai';
const _tGeocoded = GeocodedAddress(
  formattedAddress: _tAddress,
  areaName: 'Marina District',
);
const _tResolvedPlaceId = 'geo_place_123';
const _tResolvedPlace = GeocodedAddress(
  formattedAddress: _tAddress,
  isoCountryCode: 'AE',
  placeId: _tResolvedPlaceId,
);
const _tFailure = LocationFailure(
  message: 'denied',
  code: LocationFailureCodes.permissionDenied,
);
// Outside DefaultMapViewport.uaeBounds (22.5..26.5 lat, 51.0..56.5 lng).
const _tOutsidePosition = LatLng(48.85, 2.35);
const _tServiceDisabledFailure = LocationFailure(
  message: 'services off',
  code: LocationFailureCodes.serviceDisabled,
);

const _tPrediction = PlacePrediction(
  placeId: 'abc',
  description: 'Dubai Marina',
  mainText: 'Dubai Marina',
  secondaryText: 'Dubai',
);

void main() {
  late _MockReverseGeocode reverseGeocode;
  late _MockForwardGeocode forwardGeocode;
  late _MockOpenSettings openSettings;
  late _MockOpenDeviceSettings openDeviceSettings;
  late _MockGetCurrentLocation getCurrentLocation;
  late _MockReverseGeocodePlace reverseGeocodePlace;
  late _MockSearchPlaces searchPlaces;
  late _MockGetPlaceDetails getPlaceDetails;
  late _MockCheckLocationPermission checkLocationPermission;

  LocationPickerBloc buildBloc({
    bool withPlaces = false,
    bool withPlaceResolver = false,
  }) => LocationPickerBloc(
    reverseGeocodeUseCase: reverseGeocode,
    forwardGeocodeUseCase: forwardGeocode,
    openLocationSettingsUseCase: openSettings,
    openDeviceLocationSettingsUseCase: openDeviceSettings,
    getCurrentLocationUseCase: getCurrentLocation,
    checkLocationPermissionUseCase: checkLocationPermission,
    searchPlacesUseCase: withPlaces ? searchPlaces : null,
    getPlaceDetailsUseCase: withPlaces ? getPlaceDetails : null,
    reverseGeocodePlaceUseCase: withPlaceResolver ? reverseGeocodePlace : null,
  );

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(
      ReverseGeocodeParams(position: _tPosition),
    );
    registerFallbackValue(
      ForwardGeocodeParams(address: ''),
    );
    registerFallbackValue(
      SearchPlacesParams(query: ''),
    );
    registerFallbackValue(
      GetPlaceDetailsParams(placeId: ''),
    );
    registerFallbackValue(
      ReverseGeocodePlaceParams(position: _tPosition),
    );
  });

  setUp(() {
    reverseGeocode = _MockReverseGeocode();
    forwardGeocode = _MockForwardGeocode();
    openSettings = _MockOpenSettings();
    openDeviceSettings = _MockOpenDeviceSettings();
    getCurrentLocation = _MockGetCurrentLocation();
    reverseGeocodePlace = _MockReverseGeocodePlace();
    searchPlaces = _MockSearchPlaces();
    getPlaceDetails = _MockGetPlaceDetails();
    checkLocationPermission = _MockCheckLocationPermission();
    when(() => checkLocationPermission(any())).thenReturn(
      TaskEither.right(LocationPermissionStatus.denied),
    );
    when(() => openDeviceSettings(any())).thenReturn(TaskEither.right(true));
  });

  group('LocationPickerBloc', () {
    test('initial state', () {
      final bloc = buildBloc();
      expect(bloc.state.status, LocationPickerStatus.initial);
      expect(bloc.state.position, isNull);
      expect(bloc.state.searchStatus, PlaceSearchStatus.idle);
      addTearDown(bloc.close);
    });

    group('LocationPickerStarted', () {
      blocTest<LocationPickerBloc, LocationPickerState>(
        'with initial position and address -> ready immediately',
        build: buildBloc,
        act: (bloc) => bloc.add(
          LocationPickerStarted(
            initialPosition: _tPosition,
            initialAddress: _tAddress,
          ),
        ),
        expect: () => [
          isA<LocationPickerState>()
              .having((s) => s.status, 'status', LocationPickerStatus.ready)
              .having((s) => s.position, 'position', _tPosition)
              .having((s) => s.address, 'address', _tAddress),
        ],
      );

      blocTest<LocationPickerBloc, LocationPickerState>(
        'with initial position only -> geocodes address',
        build: () {
          when(
            () => reverseGeocode(any()),
          ).thenReturn(TaskEither.right(_tGeocoded));
          return buildBloc();
        },
        act: (bloc) => bloc.add(
          LocationPickerStarted(initialPosition: _tPosition),
        ),
        expect: () => [
          isA<LocationPickerState>()
              .having(
                (s) => s.status,
                'status',
                LocationPickerStatus.geocoding,
              )
              .having((s) => s.position, 'position', _tPosition),
          isA<LocationPickerState>()
              .having((s) => s.status, 'status', LocationPickerStatus.ready)
              .having((s) => s.address, 'address', _tAddress),
        ],
      );

      blocTest<LocationPickerBloc, LocationPickerState>(
        'without initial position -> ready on UAE default, no GPS, no pin',
        build: buildBloc,
        act: (bloc) => bloc.add(LocationPickerStarted()),
        expect: () => [
          isA<LocationPickerState>()
              .having((s) => s.status, 'status', LocationPickerStatus.ready)
              .having((s) => s.position, 'position', isNull),
        ],
        verify: (_) {
          // The map must never reverse-geocode a device location on open.
          verifyNever(() => reverseGeocode(any()));
        },
      );
    });

    group('LocationPickerSearchSubmitted', () {
      blocTest<LocationPickerBloc, LocationPickerState>(
        'forward geocodes when Places is disabled',
        build: () {
          when(
            () => forwardGeocode(any()),
          ).thenReturn(TaskEither.right(_tPosition));
          when(
            () => reverseGeocode(any()),
          ).thenReturn(TaskEither.right(_tGeocoded));
          return buildBloc();
        },
        act: (bloc) => bloc.add(LocationPickerSearchSubmitted('Dubai Marina')),
        expect: () => [
          isA<LocationPickerState>().having(
            (s) => s.status,
            'status',
            LocationPickerStatus.geocoding,
          ),
          isA<LocationPickerState>()
              .having(
                (s) => s.status,
                'status',
                LocationPickerStatus.geocoding,
              )
              .having((s) => s.position, 'position', _tPosition),
          isA<LocationPickerState>().having(
            (s) => s.status,
            'status',
            LocationPickerStatus.ready,
          ),
        ],
      );

      blocTest<LocationPickerBloc, LocationPickerState>(
        'empty query is ignored',
        build: buildBloc,
        act: (bloc) => bloc.add(LocationPickerSearchSubmitted('  ')),
        expect: () => <LocationPickerState>[],
      );

      blocTest<LocationPickerBloc, LocationPickerState>(
        'no-op when Places enabled and predictions exist',
        build: () => buildBloc(withPlaces: true),
        seed: () => LocationPickerState(
          predictions: [_tPrediction],
        ),
        act: (bloc) => bloc.add(LocationPickerSearchSubmitted('Dubai Marina')),
        expect: () => <LocationPickerState>[],
        verify: (_) {
          verifyNever(() => forwardGeocode(any()));
          verifyNever(() => searchPlaces(any()));
        },
      );

      blocTest<LocationPickerBloc, LocationPickerState>(
        'forward geocodes when Places enabled but no predictions',
        build: () {
          when(
            () => forwardGeocode(any()),
          ).thenReturn(TaskEither.right(_tPosition));
          when(
            () => reverseGeocode(any()),
          ).thenReturn(TaskEither.right(_tGeocoded));
          return buildBloc(withPlaces: true);
        },
        act: (bloc) => bloc.add(LocationPickerSearchSubmitted('Dubai Marina')),
        expect: () => [
          isA<LocationPickerState>().having(
            (s) => s.status,
            'status',
            LocationPickerStatus.geocoding,
          ),
          isA<LocationPickerState>().having(
            (s) => s.position,
            'position',
            _tPosition,
          ),
          isA<LocationPickerState>().having(
            (s) => s.status,
            'status',
            LocationPickerStatus.ready,
          ),
        ],
      );
    });

    group('LocationPickerQueryChanged (Places)', () {
      blocTest<LocationPickerBloc, LocationPickerState>(
        'no-op when Places use case is null',
        build: buildBloc,
        act: (bloc) => bloc.add(LocationPickerQueryChanged('dubai')),
        expect: () => <LocationPickerState>[],
      );

      blocTest<LocationPickerBloc, LocationPickerState>(
        'clears predictions for short query',
        build: () => buildBloc(withPlaces: true),
        seed: () => LocationPickerState(
          predictions: [_tPrediction],
        ),
        act: (bloc) => bloc.add(LocationPickerQueryChanged('d')),
        expect: () => [
          isA<LocationPickerState>()
              .having((s) => s.predictions, 'predictions', isEmpty)
              .having(
                (s) => s.searchStatus,
                'searchStatus',
                PlaceSearchStatus.idle,
              ),
        ],
      );

      blocTest<LocationPickerBloc, LocationPickerState>(
        'returns predictions on valid query',
        build: () {
          when(
            () => searchPlaces(any()),
          ).thenReturn(TaskEither.right([_tPrediction]));
          return buildBloc(withPlaces: true);
        },
        act: (bloc) => bloc.add(LocationPickerQueryChanged('dubai')),
        expect: () => [
          isA<LocationPickerState>()
              .having(
                (s) => s.searchStatus,
                'searchStatus',
                PlaceSearchStatus.searching,
              )
              .having((s) => s.isSearching, 'isSearching', isTrue),
          isA<LocationPickerState>()
              .having(
                (s) => s.predictions,
                'predictions',
                [_tPrediction],
              )
              .having((s) => s.hasPredictions, 'hasPredictions', isTrue)
              .having(
                (s) => s.searchStatus,
                'searchStatus',
                PlaceSearchStatus.success,
              ),
        ],
      );

      blocTest<LocationPickerBloc, LocationPickerState>(
        'emits empty status when no predictions found',
        build: () {
          when(() => searchPlaces(any())).thenReturn(TaskEither.right([]));
          return buildBloc(withPlaces: true);
        },
        act: (bloc) => bloc.add(LocationPickerQueryChanged('xyz')),
        expect: () => [
          isA<LocationPickerState>().having(
            (s) => s.searchStatus,
            'searchStatus',
            PlaceSearchStatus.searching,
          ),
          isA<LocationPickerState>()
              .having(
                (s) => s.searchStatus,
                'searchStatus',
                PlaceSearchStatus.empty,
              )
              .having((s) => s.predictions, 'predictions', isEmpty),
        ],
      );

      blocTest<LocationPickerBloc, LocationPickerState>(
        'emits failure status on search error',
        build: () {
          when(
            () => searchPlaces(any()),
          ).thenReturn(TaskEither.left(_tFailure));
          return buildBloc(withPlaces: true);
        },
        act: (bloc) => bloc.add(LocationPickerQueryChanged('xyz')),
        expect: () => [
          isA<LocationPickerState>().having(
            (s) => s.searchStatus,
            'searchStatus',
            PlaceSearchStatus.searching,
          ),
          isA<LocationPickerState>()
              .having(
                (s) => s.searchStatus,
                'searchStatus',
                PlaceSearchStatus.failure,
              )
              .having((s) => s.searchError, 'searchError', 'denied'),
        ],
      );

      blocTest<LocationPickerBloc, LocationPickerState>(
        'tracks searchQuery in state',
        build: () {
          when(
            () => searchPlaces(any()),
          ).thenReturn(TaskEither.right([_tPrediction]));
          return buildBloc(withPlaces: true);
        },
        act: (bloc) => bloc.add(LocationPickerQueryChanged('dubai')),
        expect: () => [
          isA<LocationPickerState>().having(
            (s) => s.searchQuery,
            'searchQuery',
            'dubai',
          ),
          isA<LocationPickerState>().having(
            (s) => s.searchQuery,
            'searchQuery',
            'dubai',
          ),
        ],
      );
    });

    group('LocationPickerPredictionSelected', () {
      blocTest<LocationPickerBloc, LocationPickerState>(
        'uses place details when available',
        build: () {
          when(
            () => getPlaceDetails(any()),
          ).thenReturn(TaskEither.right(_tPosition));
          when(
            () => reverseGeocode(any()),
          ).thenReturn(TaskEither.right(_tGeocoded));
          return buildBloc(withPlaces: true);
        },
        act: (bloc) => bloc.add(
          LocationPickerPredictionSelected(_tPrediction),
        ),
        expect: () => [
          isA<LocationPickerState>()
              .having(
                (s) => s.status,
                'status',
                LocationPickerStatus.geocoding,
              )
              .having((s) => s.predictions, 'predictions', isEmpty),
          isA<LocationPickerState>().having(
            (s) => s.position,
            'position',
            _tPosition,
          ),
          isA<LocationPickerState>().having(
            (s) => s.status,
            'status',
            LocationPickerStatus.ready,
          ),
        ],
      );

      blocTest<LocationPickerBloc, LocationPickerState>(
        'captures the prediction place id (required for branch creation)',
        build: () {
          when(
            () => getPlaceDetails(any()),
          ).thenReturn(TaskEither.right(_tPosition));
          when(
            () => reverseGeocode(any()),
          ).thenReturn(TaskEither.right(_tGeocoded));
          return buildBloc(withPlaces: true);
        },
        act: (bloc) => bloc.add(
          LocationPickerPredictionSelected(_tPrediction),
        ),
        verify: (bloc) {
          expect(bloc.state.selectedPlaceId, _tPrediction.placeId);
        },
      );
    });

    group('LocationPickerCameraIdle', () {
      blocTest<LocationPickerBloc, LocationPickerState>(
        'dragging the map clears the place id (coordinates without a '
        'Google Place ID), forcing a new autocomplete selection',
        build: () {
          when(
            () => reverseGeocode(any()),
          ).thenReturn(TaskEither.right(_tGeocoded));
          return buildBloc();
        },
        seed: () => const LocationPickerState(
          status: LocationPickerStatus.ready,
          position: _tPosition,
          address: _tAddress,
          selectedPlaceId: 'abc',
        ),
        act: (bloc) => bloc.add(
          const LocationPickerCameraIdle(LatLng(26.0, 56.0)),
        ),
        expect: () => [
          isA<LocationPickerState>()
              .having(
                (s) => s.status,
                'status',
                LocationPickerStatus.geocoding,
              )
              .having((s) => s.selectedPlaceId, 'selectedPlaceId', isNull),
          isA<LocationPickerState>()
              .having((s) => s.status, 'status', LocationPickerStatus.ready)
              .having((s) => s.selectedPlaceId, 'selectedPlaceId', isNull),
        ],
      );

      // Regression: a prior "use my current location" failure (e.g.
      // serviceDisabled) must NOT linger into a fresh map selection. Selecting
      // a new point clears it, so the geocoding (resolving) state never shows a
      // stale "enable location services" panel.
      blocTest<LocationPickerBloc, LocationPickerState>(
        'selecting a new point clears a stale current-location failure so the '
        'resolving state shows no services-disabled error',
        build: () {
          when(
            () => reverseGeocode(any()),
          ).thenReturn(TaskEither.right(_tGeocoded));
          return buildBloc();
        },
        seed: () => const LocationPickerState(
          currentLocationFailure: _tServiceDisabledFailure,
        ),
        act: (bloc) => bloc.add(
          const LocationPickerCameraIdle(_tPosition),
        ),
        expect: () => [
          // The in-progress resolution carries NO current-location failure.
          isA<LocationPickerState>()
              .having(
                (s) => s.status,
                'status',
                LocationPickerStatus.geocoding,
              )
              .having(
                (s) => s.currentLocationFailure,
                'currentLocationFailure',
                isNull,
              ),
          isA<LocationPickerState>()
              .having((s) => s.status, 'status', LocationPickerStatus.ready)
              .having(
                (s) => s.currentLocationFailure,
                'currentLocationFailure',
                isNull,
              ),
        ],
      );
    });

    group('stale current-location failure is superseded by a new selection', () {
      blocTest<LocationPickerBloc, LocationPickerState>(
        'search (forward geocode) clears a stale current-location failure',
        build: () {
          when(
            () => forwardGeocode(any()),
          ).thenReturn(TaskEither.right(_tPosition));
          when(
            () => reverseGeocode(any()),
          ).thenReturn(TaskEither.right(_tGeocoded));
          return buildBloc();
        },
        seed: () => const LocationPickerState(
          currentLocationFailure: _tServiceDisabledFailure,
        ),
        act: (bloc) => bloc.add(LocationPickerSearchSubmitted('Dubai Marina')),
        expect: () => [
          isA<LocationPickerState>()
              .having(
                (s) => s.status,
                'status',
                LocationPickerStatus.geocoding,
              )
              .having(
                (s) => s.currentLocationFailure,
                'currentLocationFailure',
                isNull,
              ),
          isA<LocationPickerState>().having(
            (s) => s.currentLocationFailure,
            'currentLocationFailure',
            isNull,
          ),
          isA<LocationPickerState>()
              .having((s) => s.status, 'status', LocationPickerStatus.ready)
              .having(
                (s) => s.currentLocationFailure,
                'currentLocationFailure',
                isNull,
              ),
        ],
      );

      blocTest<LocationPickerBloc, LocationPickerState>(
        'choosing a search prediction clears a stale current-location failure',
        build: () {
          when(
            () => getPlaceDetails(any()),
          ).thenReturn(TaskEither.right(_tPosition));
          when(
            () => reverseGeocode(any()),
          ).thenReturn(TaskEither.right(_tGeocoded));
          return buildBloc(withPlaces: true);
        },
        seed: () => const LocationPickerState(
          currentLocationFailure: _tServiceDisabledFailure,
        ),
        act: (bloc) =>
            bloc.add(const LocationPickerPredictionSelected(_tPrediction)),
        expect: () => [
          isA<LocationPickerState>()
              .having(
                (s) => s.status,
                'status',
                LocationPickerStatus.geocoding,
              )
              .having(
                (s) => s.currentLocationFailure,
                'currentLocationFailure',
                isNull,
              ),
          isA<LocationPickerState>().having(
            (s) => s.currentLocationFailure,
            'currentLocationFailure',
            isNull,
          ),
          isA<LocationPickerState>()
              .having((s) => s.status, 'status', LocationPickerStatus.ready)
              .having(
                (s) => s.currentLocationFailure,
                'currentLocationFailure',
                isNull,
              ),
        ],
      );
    });

    group('LocationPickerPermissionChecked', () {
      blocTest<LocationPickerBloc, LocationPickerState>(
        'LocationPickerStarted checks permission without delaying ready state',
        build: () {
          when(() => checkLocationPermission(any())).thenReturn(
            TaskEither.right(LocationPermissionStatus.granted),
          );
          return buildBloc();
        },
        act: (bloc) => bloc.add(LocationPickerStarted()),
        wait: const Duration(milliseconds: 10),
        expect: () => [
          isA<LocationPickerState>()
              .having((s) => s.status, 'status', LocationPickerStatus.ready)
              .having(
                (s) => s.hasLocationPermission,
                'hasLocationPermission',
                isFalse,
              ),
          isA<LocationPickerState>().having(
            (s) => s.hasLocationPermission,
            'hasLocationPermission',
            isTrue,
          ),
        ],
      );

      blocTest<LocationPickerBloc, LocationPickerState>(
        'denied permission keeps hasLocationPermission false',
        build: buildBloc,
        act: (bloc) => bloc.add(
          const LocationPickerPermissionChecked(
            LocationPermissionStatus.denied,
          ),
        ),
        expect: () => [
          isA<LocationPickerState>().having(
            (s) => s.hasLocationPermission,
            'hasLocationPermission',
            isFalse,
          ),
        ],
      );
    });

    group('LocationPickerCurrentLocationRequested', () {
      blocTest<LocationPickerBloc, LocationPickerState>(
        'in-area success moves camera (programmatic) and reverse-geocodes',
        build: () {
          when(
            () => getCurrentLocation(any()),
          ).thenReturn(TaskEither.right(_tPosition));
          when(
            () => reverseGeocode(any()),
          ).thenReturn(TaskEither.right(_tGeocoded));
          return buildBloc();
        },
        act: (bloc) => bloc.add(const LocationPickerCurrentLocationRequested()),
        expect: () => [
          isA<LocationPickerState>().having(
            (s) => s.isLocating,
            'isLocating',
            isTrue,
          ),
          isA<LocationPickerState>()
              .having((s) => s.isLocating, 'isLocating', isFalse)
              .having(
                (s) => s.status,
                'status',
                LocationPickerStatus.geocoding,
              )
              .having((s) => s.position, 'position', _tPosition)
              .having(
                (s) => s.cameraSource,
                'cameraSource',
                LocationPickerCameraSource.programmatic,
              )
              .having(
                (s) => s.hasLocationPermission,
                'hasLocationPermission',
                isTrue,
              ),
          isA<LocationPickerState>()
              .having((s) => s.status, 'status', LocationPickerStatus.ready)
              .having((s) => s.address, 'address', _tAddress),
        ],
      );

      blocTest<LocationPickerBloc, LocationPickerState>(
        'out-of-area position is reported, never geocoded or moved to',
        build: () {
          when(
            () => getCurrentLocation(any()),
          ).thenReturn(TaskEither.right(_tOutsidePosition));
          return buildBloc();
        },
        act: (bloc) => bloc.add(const LocationPickerCurrentLocationRequested()),
        expect: () => [
          isA<LocationPickerState>().having(
            (s) => s.isLocating,
            'isLocating',
            isTrue,
          ),
          isA<LocationPickerState>()
              .having((s) => s.isLocating, 'isLocating', isFalse)
              .having(
                (s) => s.currentLocationFailure?.code,
                'failure code',
                LocationFailureCodes.outsideSupportedCountry,
              )
              .having((s) => s.position, 'position', isNull),
        ],
        verify: (_) {
          verifyNever(() => reverseGeocode(any()));
        },
      );

      blocTest<LocationPickerBloc, LocationPickerState>(
        'permission failure surfaces via currentLocationFailure, '
        'clears hasLocationPermission, keeps status',
        build: () {
          when(
            () => getCurrentLocation(any()),
          ).thenReturn(TaskEither.left(_tFailure));
          return buildBloc();
        },
        act: (bloc) => bloc.add(const LocationPickerCurrentLocationRequested()),
        expect: () => [
          isA<LocationPickerState>().having(
            (s) => s.isLocating,
            'isLocating',
            isTrue,
          ),
          isA<LocationPickerState>()
              .having((s) => s.isLocating, 'isLocating', isFalse)
              .having(
                (s) => s.currentLocationFailure?.code,
                'failure code',
                LocationFailureCodes.permissionDenied,
              )
              .having(
                (s) => s.hasLocationPermission,
                'hasLocationPermission',
                isFalse,
              ),
        ],
      );

      blocTest<LocationPickerBloc, LocationPickerState>(
        'a failed attempt NEVER clobbers a valid existing selection',
        build: () {
          when(
            () => getCurrentLocation(any()),
          ).thenReturn(TaskEither.left(_tServiceDisabledFailure));
          return buildBloc();
        },
        seed: () => const LocationPickerState(
          status: LocationPickerStatus.ready,
          position: _tPosition,
          address: _tAddress,
          selectedPlaceId: 'abc',
        ),
        act: (bloc) => bloc.add(const LocationPickerCurrentLocationRequested()),
        verify: (bloc) {
          // Selection intact, Confirm still valid, failure surfaced separately.
          expect(bloc.state.status, LocationPickerStatus.ready);
          expect(bloc.state.position, _tPosition);
          expect(bloc.state.address, _tAddress);
          expect(bloc.state.canConfirm, isTrue);
          expect(
            bloc.state.currentLocationFailure?.code,
            LocationFailureCodes.serviceDisabled,
          );
        },
      );

      blocTest<LocationPickerBloc, LocationPickerState>(
        'drops duplicate taps while a request is already in flight',
        build: buildBloc,
        seed: () => const LocationPickerState(isLocating: true),
        act: (bloc) => bloc.add(const LocationPickerCurrentLocationRequested()),
        expect: () => <LocationPickerState>[],
        verify: (_) {
          verifyNever(() => getCurrentLocation(any()));
        },
      );
    });

    group('LocationPickerRetryGeocode', () {
      blocTest<LocationPickerBloc, LocationPickerState>(
        're-resolves the address for the current pin after a geocode failure',
        build: () {
          when(
            () => reverseGeocode(any()),
          ).thenReturn(TaskEither.right(_tGeocoded));
          return buildBloc();
        },
        seed: () => const LocationPickerState(
          status: LocationPickerStatus.failure,
          position: _tPosition,
          failure: LocationFailure(
            message: 'x',
            code: LocationFailureCodes.geocodingFailed,
          ),
        ),
        act: (bloc) => bloc.add(const LocationPickerRetryGeocode()),
        expect: () => [
          isA<LocationPickerState>().having(
            (s) => s.status,
            'status',
            LocationPickerStatus.geocoding,
          ),
          isA<LocationPickerState>()
              .having((s) => s.status, 'status', LocationPickerStatus.ready)
              .having((s) => s.address, 'address', _tAddress),
        ],
      );

      blocTest<LocationPickerBloc, LocationPickerState>(
        'no-op when there is no position to resolve',
        build: buildBloc,
        act: (bloc) => bloc.add(const LocationPickerRetryGeocode()),
        expect: () => <LocationPickerState>[],
        verify: (_) {
          verifyNever(() => reverseGeocode(any()));
        },
      );
    });

    group('LocationPickerResumed', () {
      blocTest<LocationPickerBloc, LocationPickerState>(
        'clears a stale current-location failure and re-checks permission',
        build: () {
          when(() => checkLocationPermission(any())).thenReturn(
            TaskEither.right(LocationPermissionStatus.granted),
          );
          return buildBloc();
        },
        seed: () => const LocationPickerState(
          currentLocationFailure: _tServiceDisabledFailure,
        ),
        act: (bloc) => bloc.add(const LocationPickerResumed()),
        wait: const Duration(milliseconds: 10),
        expect: () => [
          isA<LocationPickerState>().having(
            (s) => s.currentLocationFailure,
            'currentLocationFailure',
            isNull,
          ),
          isA<LocationPickerState>().having(
            (s) => s.hasLocationPermission,
            'hasLocationPermission',
            isTrue,
          ),
        ],
      );
    });

    group('LocationPickerDeviceSettingsRequested', () {
      blocTest<LocationPickerBloc, LocationPickerState>(
        'opens the device location settings',
        build: buildBloc,
        act: (bloc) => bloc.add(const LocationPickerDeviceSettingsRequested()),
        verify: (_) {
          verify(() => openDeviceSettings(any())).called(1);
        },
      );
    });

    group('Place ID resolution (map / current-location converge)', () {
      blocTest<LocationPickerBloc, LocationPickerState>(
        'map drag resolves a real Place ID and invalidates the stale one',
        build: () {
          when(() => reverseGeocodePlace(any())).thenReturn(
            TaskEither.right(_tResolvedPlace),
          );
          return buildBloc(withPlaceResolver: true);
        },
        // Simulate a prior search selection that carried its own Place ID.
        seed: () => const LocationPickerState(
          status: LocationPickerStatus.ready,
          position: _tPosition,
          address: _tAddress,
          selectedPlaceId: 'stale_search_place_id',
        ),
        act: (bloc) =>
            bloc.add(const LocationPickerCameraIdle(LatLng(25.1, 55.2))),
        expect: () => [
          isA<LocationPickerState>()
              .having(
                (s) => s.status,
                'status',
                LocationPickerStatus.geocoding,
              )
              // Old Place ID invalidated the instant the pin moves.
              .having((s) => s.selectedPlaceId, 'selectedPlaceId', isNull),
          isA<LocationPickerState>()
              .having((s) => s.status, 'status', LocationPickerStatus.ready)
              .having(
                (s) => s.selectedPlaceId,
                'selectedPlaceId',
                _tResolvedPlaceId,
              )
              .having((s) => s.canConfirm, 'canConfirm', isTrue),
        ],
        verify: (_) {
          // Uses the Google resolver, not the platform geocoder.
          verifyNever(() => reverseGeocode(any()));
        },
      );

      blocTest<LocationPickerBloc, LocationPickerState>(
        'current location resolves a real Place ID',
        build: () {
          when(
            () => getCurrentLocation(any()),
          ).thenReturn(TaskEither.right(_tPosition));
          when(() => reverseGeocodePlace(any())).thenReturn(
            TaskEither.right(_tResolvedPlace),
          );
          return buildBloc(withPlaceResolver: true);
        },
        act: (bloc) => bloc.add(const LocationPickerCurrentLocationRequested()),
        verify: (bloc) {
          expect(bloc.state.status, LocationPickerStatus.ready);
          expect(bloc.state.selectedPlaceId, _tResolvedPlaceId);
          expect(bloc.state.canConfirm, isTrue);
        },
      );

      blocTest<LocationPickerBloc, LocationPickerState>(
        'a chosen search prediction keeps ITS Place ID (resolver not used)',
        build: () {
          when(
            () => getPlaceDetails(any()),
          ).thenReturn(TaskEither.right(_tPosition));
          when(
            () => reverseGeocode(any()),
          ).thenReturn(TaskEither.right(_tGeocoded));
          return buildBloc(withPlaces: true, withPlaceResolver: true);
        },
        act: (bloc) => bloc.add(
          LocationPickerPredictionSelected(_tPrediction),
        ),
        verify: (bloc) {
          expect(bloc.state.selectedPlaceId, _tPrediction.placeId);
          // The prediction already carries a Place ID — never overwrite it
          // with a reverse-geocoded (nearby) one.
          verifyNever(() => reverseGeocodePlace(any()));
        },
      );

      blocTest<LocationPickerBloc, LocationPickerState>(
        'no place for the coordinate -> failure, no fabricated Place ID',
        build: () {
          when(
            () => reverseGeocodePlace(any()),
          ).thenReturn(TaskEither.right(null));
          return buildBloc(withPlaceResolver: true);
        },
        act: (bloc) =>
            bloc.add(const LocationPickerCameraIdle(LatLng(25.1, 55.2))),
        expect: () => [
          isA<LocationPickerState>().having(
            (s) => s.status,
            'status',
            LocationPickerStatus.geocoding,
          ),
          isA<LocationPickerState>()
              .having((s) => s.status, 'status', LocationPickerStatus.failure)
              .having((s) => s.selectedPlaceId, 'selectedPlaceId', isNull)
              .having((s) => s.canConfirm, 'canConfirm', isFalse)
              // Pin kept — the coordinate is still valid, only the place
              // lookup failed.
              .having((s) => s.position, 'position', const LatLng(25.1, 55.2)),
        ],
      );

      blocTest<LocationPickerBloc, LocationPickerState>(
        'resolver network failure -> failure, Confirm stays disabled',
        build: () {
          when(() => reverseGeocodePlace(any())).thenReturn(
            TaskEither.left(const ServerFailure(message: 'boom')),
          );
          return buildBloc(withPlaceResolver: true);
        },
        act: (bloc) =>
            bloc.add(const LocationPickerCameraIdle(LatLng(25.1, 55.2))),
        expect: () => [
          isA<LocationPickerState>().having(
            (s) => s.status,
            'status',
            LocationPickerStatus.geocoding,
          ),
          isA<LocationPickerState>()
              .having((s) => s.status, 'status', LocationPickerStatus.failure)
              .having((s) => s.canConfirm, 'canConfirm', isFalse),
        ],
      );

      blocTest<LocationPickerBloc, LocationPickerState>(
        'edit-reopen with saved Place ID is confirmable immediately',
        build: () => buildBloc(withPlaceResolver: true),
        act: (bloc) => bloc.add(
          const LocationPickerStarted(
            initialPosition: _tPosition,
            initialAddress: _tAddress,
            initialPlaceId: 'saved_place_id',
          ),
        ),
        expect: () => [
          isA<LocationPickerState>()
              .having((s) => s.status, 'status', LocationPickerStatus.ready)
              .having(
                (s) => s.selectedPlaceId,
                'selectedPlaceId',
                'saved_place_id',
              )
              .having((s) => s.canConfirm, 'canConfirm', isTrue),
        ],
        verify: (_) {
          // No re-resolution — the saved selection is already complete.
          verifyNever(() => reverseGeocodePlace(any()));
          verifyNever(() => reverseGeocode(any()));
        },
      );
    });

    group('state helpers', () {
      test('canConfirm requires position + address + ready', () {
        const state = LocationPickerState(
          status: LocationPickerStatus.ready,
          position: _tPosition,
          address: _tAddress,
        );
        expect(state.canConfirm, isTrue);
      });

      test('canConfirm is false when geocoding', () {
        const state = LocationPickerState(
          status: LocationPickerStatus.geocoding,
          position: _tPosition,
          address: _tAddress,
        );
        expect(state.canConfirm, isFalse);
      });

      test('hasPermissionError', () {
        const state = LocationPickerState(
          status: LocationPickerStatus.permissionDenied,
        );
        expect(state.hasPermissionError, isTrue);
      });

      test('isSearching reflects searchStatus', () {
        const searching = LocationPickerState(
          searchStatus: PlaceSearchStatus.searching,
        );
        expect(searching.isSearching, isTrue);

        const idle = LocationPickerState(
          searchStatus: PlaceSearchStatus.idle,
        );
        expect(idle.isSearching, isFalse);
      });

      test('clearPredictions resets searchStatus to idle', () {
        const state = LocationPickerState(
          searchStatus: PlaceSearchStatus.success,
          predictions: [_tPrediction],
          searchError: 'some error',
        );
        final cleared = state.copyWith(clearPredictions: true);
        expect(cleared.predictions, isEmpty);
        expect(cleared.searchStatus, PlaceSearchStatus.idle);
        expect(cleared.searchError, isNull);
      });
    });

    // SAN-823. A build with no MAPS_API_KEY wires this bloc exactly as
    // `buildBloc()` does here: MapsDI passes null for all three Places use
    // cases when `MapsConfig.placesEnabled` is false. These tests pin down the
    // resulting behaviour — which is *correct* for the bloc, and is precisely
    // why the release-only symptom was so misleading: a pin drag still
    // produces a perfectly good address, so the screen looks functional while
    // being permanently unconfirmable.
    //
    // They exist so this failure mode is asserted and named rather than
    // rediscovered from a screenshot. The fix is a build-config one (Gradle now
    // derives the dart-define from local.properties); see
    // sanad_provider/test/src/build_config/maps_api_key_dart_define_test.dart.
    group('keyless build (no MAPS_API_KEY) — SAN-823', () {
      blocTest<LocationPickerBloc, LocationPickerState>(
        'a dragged pin resolves an address but NO place id, so a '
        'requirePlaceId picker can never enable Confirm',
        build: () {
          when(
            () => reverseGeocode(any()),
          ).thenReturn(TaskEither.right(_tGeocoded));
          // No place resolver and no Places use cases — a keyless build.
          return buildBloc();
        },
        act: (bloc) => bloc.add(
          const LocationPickerCameraIdle(_tPosition),
        ),
        verify: (bloc) {
          final state = bloc.state;
          // The address really does resolve — the platform geocoder needs no
          // API key. This is the part that made the bug look like a UI defect.
          expect(state.status, LocationPickerStatus.ready);
          expect(state.address, _tAddress);
          // ...but the canonical identity the branch payload needs is absent.
          expect(state.selectedPlaceId, isNull);
          // The bloc's own gate is satisfied; only the Place ID requirement
          // layered on top by MapLocationPicker(requirePlaceId: true) fails.
          expect(state.canConfirm, isTrue);
        },
      );

      blocTest<LocationPickerBloc, LocationPickerState>(
        'search is inert: a query emits nothing at all (no request, no error, '
        'no empty-results state)',
        build: buildBloc,
        act: (bloc) =>
            bloc.add(const LocationPickerQueryChanged('Dubai Marina')),
        expect: () => <LocationPickerState>[],
        verify: (_) => verifyNever(() => searchPlaces(any())),
      );

      blocTest<LocationPickerBloc, LocationPickerState>(
        'with the key present the same pin drag DOES yield a place id',
        build: () {
          when(
            () => reverseGeocodePlace(any()),
          ).thenReturn(TaskEither.right(_tResolvedPlace));
          return buildBloc(withPlaces: true, withPlaceResolver: true);
        },
        act: (bloc) => bloc.add(
          const LocationPickerCameraIdle(_tPosition),
        ),
        verify: (bloc) {
          final state = bloc.state;
          expect(state.status, LocationPickerStatus.ready);
          expect(state.address, _tAddress);
          expect(state.selectedPlaceId, _tResolvedPlaceId);
          expect(state.canConfirm, isTrue);
        },
      );
    });
  });
}
