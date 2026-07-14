// ignore_for_file: prefer_const_constructors

import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps/src/domain/entities/place_prediction.dart';
import 'package:maps/src/domain/usecases/forward_geocode_usecase.dart';
import 'package:maps/src/domain/usecases/get_current_location_usecase.dart';
import 'package:maps/src/domain/usecases/get_place_details_usecase.dart';
import 'package:maps/src/domain/usecases/open_location_settings_usecase.dart';
import 'package:maps/src/domain/usecases/reverse_geocode_usecase.dart';
import 'package:maps/src/domain/usecases/search_places_usecase.dart';
import 'package:maps/src/presentation/bloc/location_picker/location_picker_bloc.dart';
import 'package:maps/src/presentation/models/place_search_status.dart';
import 'package:maps/src/services/location_failure_codes.dart';
import 'package:mocktail/mocktail.dart';

class _MockGetCurrentLocation extends Mock
    implements GetCurrentLocationUseCase {}

class _MockReverseGeocode extends Mock implements ReverseGeocodeUseCase {}

class _MockForwardGeocode extends Mock implements ForwardGeocodeUseCase {}

class _MockOpenSettings extends Mock implements OpenLocationSettingsUseCase {}

class _MockSearchPlaces extends Mock implements SearchPlacesUseCase {}

class _MockGetPlaceDetails extends Mock implements GetPlaceDetailsUseCase {}

const _tPosition = LatLng(25.0, 55.0);
const _tAddress = 'Dubai Marina, Dubai';
const _tFailure = LocationFailure(
  message: 'denied',
  code: LocationFailureCodes.permissionDenied,
);

const _tPrediction = PlacePrediction(
  placeId: 'abc',
  description: 'Dubai Marina',
  mainText: 'Dubai Marina',
  secondaryText: 'Dubai',
);

void main() {
  late _MockGetCurrentLocation getCurrentLocation;
  late _MockReverseGeocode reverseGeocode;
  late _MockForwardGeocode forwardGeocode;
  late _MockOpenSettings openSettings;
  late _MockSearchPlaces searchPlaces;
  late _MockGetPlaceDetails getPlaceDetails;

  LocationPickerBloc buildBloc({bool withPlaces = false}) =>
      LocationPickerBloc(
        getCurrentLocationUseCase: getCurrentLocation,
        reverseGeocodeUseCase: reverseGeocode,
        forwardGeocodeUseCase: forwardGeocode,
        openLocationSettingsUseCase: openSettings,
        searchPlacesUseCase: withPlaces ? searchPlaces : null,
        getPlaceDetailsUseCase: withPlaces ? getPlaceDetails : null,
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
  });

  setUp(() {
    getCurrentLocation = _MockGetCurrentLocation();
    reverseGeocode = _MockReverseGeocode();
    forwardGeocode = _MockForwardGeocode();
    openSettings = _MockOpenSettings();
    searchPlaces = _MockSearchPlaces();
    getPlaceDetails = _MockGetPlaceDetails();
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
          when(() => reverseGeocode(any()))
              .thenReturn(TaskEither.right(_tAddress));
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
        'without initial position -> gets current location',
        build: () {
          when(() => getCurrentLocation(any()))
              .thenReturn(TaskEither.right(_tPosition));
          when(() => reverseGeocode(any()))
              .thenReturn(TaskEither.right(_tAddress));
          return buildBloc();
        },
        act: (bloc) => bloc.add(LocationPickerStarted()),
        expect: () => [
          isA<LocationPickerState>().having(
            (s) => s.status,
            'status',
            LocationPickerStatus.loadingLocation,
          ),
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
        'permission denied -> permissionDenied status',
        build: () {
          when(() => getCurrentLocation(any()))
              .thenReturn(TaskEither.left(_tFailure));
          return buildBloc();
        },
        act: (bloc) => bloc.add(LocationPickerStarted()),
        expect: () => [
          isA<LocationPickerState>().having(
            (s) => s.status,
            'status',
            LocationPickerStatus.loadingLocation,
          ),
          isA<LocationPickerState>().having(
            (s) => s.status,
            'status',
            LocationPickerStatus.permissionDenied,
          ),
        ],
      );
    });

    group('LocationPickerSearchSubmitted', () {
      blocTest<LocationPickerBloc, LocationPickerState>(
        'forward geocodes when Places is disabled',
        build: () {
          when(() => forwardGeocode(any()))
              .thenReturn(TaskEither.right(_tPosition));
          when(() => reverseGeocode(any()))
              .thenReturn(TaskEither.right(_tAddress));
          return buildBloc();
        },
        act: (bloc) =>
            bloc.add(LocationPickerSearchSubmitted('Dubai Marina')),
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
          isA<LocationPickerState>()
              .having((s) => s.status, 'status', LocationPickerStatus.ready),
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
        act: (bloc) =>
            bloc.add(LocationPickerSearchSubmitted('Dubai Marina')),
        expect: () => <LocationPickerState>[],
        verify: (_) {
          verifyNever(() => forwardGeocode(any()));
          verifyNever(() => searchPlaces(any()));
        },
      );

      blocTest<LocationPickerBloc, LocationPickerState>(
        'forward geocodes when Places enabled but no predictions',
        build: () {
          when(() => forwardGeocode(any()))
              .thenReturn(TaskEither.right(_tPosition));
          when(() => reverseGeocode(any()))
              .thenReturn(TaskEither.right(_tAddress));
          return buildBloc(withPlaces: true);
        },
        act: (bloc) =>
            bloc.add(LocationPickerSearchSubmitted('Dubai Marina')),
        expect: () => [
          isA<LocationPickerState>().having(
            (s) => s.status,
            'status',
            LocationPickerStatus.geocoding,
          ),
          isA<LocationPickerState>()
              .having((s) => s.position, 'position', _tPosition),
          isA<LocationPickerState>()
              .having((s) => s.status, 'status', LocationPickerStatus.ready),
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
          when(() => searchPlaces(any()))
              .thenReturn(TaskEither.right([_tPrediction]));
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
          when(() => searchPlaces(any()))
              .thenReturn(TaskEither.right([]));
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
          when(() => searchPlaces(any()))
              .thenReturn(TaskEither.left(_tFailure));
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
          when(() => searchPlaces(any()))
              .thenReturn(TaskEither.right([_tPrediction]));
          return buildBloc(withPlaces: true);
        },
        act: (bloc) => bloc.add(LocationPickerQueryChanged('dubai')),
        expect: () => [
          isA<LocationPickerState>()
              .having((s) => s.searchQuery, 'searchQuery', 'dubai'),
          isA<LocationPickerState>()
              .having((s) => s.searchQuery, 'searchQuery', 'dubai'),
        ],
      );
    });

    group('LocationPickerPredictionSelected', () {
      blocTest<LocationPickerBloc, LocationPickerState>(
        'uses place details when available',
        build: () {
          when(() => getPlaceDetails(any()))
              .thenReturn(TaskEither.right(_tPosition));
          when(() => reverseGeocode(any()))
              .thenReturn(TaskEither.right(_tAddress));
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
          isA<LocationPickerState>()
              .having((s) => s.position, 'position', _tPosition),
          isA<LocationPickerState>()
              .having((s) => s.status, 'status', LocationPickerStatus.ready),
        ],
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
  });
}
