// ignore_for_file: prefer_const_constructors

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps/src/domain/entities/geocoded_address.dart';
import 'package:maps/src/domain/entities/place_prediction.dart';
import 'package:maps/src/domain/usecases/get_place_details_usecase.dart';
import 'package:maps/src/domain/usecases/reverse_geocode_usecase.dart';
import 'package:maps/src/domain/usecases/search_places_usecase.dart';
import 'package:maps/src/presentation/bloc/map_area_picker/map_area_picker_bloc.dart';
import 'package:maps/src/presentation/models/place_search_status.dart';
import 'package:mocktail/mocktail.dart';

class _MockReverseGeocode extends Mock implements ReverseGeocodeUseCase {}

class _MockSearchPlaces extends Mock implements SearchPlacesUseCase {}

class _MockGetPlaceDetails extends Mock implements GetPlaceDetailsUseCase {}

const _tPosition = LatLng(25.0, 55.0);
const _tOtherPosition = LatLng(25.1, 55.1);
const _tAddress = 'Dubai Marina, Dubai';
const _tAreaName = 'Marina District';
const _tGeocoded = GeocodedAddress(
  formattedAddress: _tAddress,
  areaName: _tAreaName,
);

const _tPrediction = PlacePrediction(
  placeId: 'abc',
  description: 'Dubai Marina',
  mainText: 'Dubai Marina',
  secondaryText: 'Dubai',
);

void main() {
  late _MockReverseGeocode reverseGeocode;
  late _MockSearchPlaces searchPlaces;
  late _MockGetPlaceDetails getPlaceDetails;

  MapAreaPickerBloc buildBloc({bool withPlaces = false}) =>
      MapAreaPickerBloc(
        reverseGeocodeUseCase: reverseGeocode,
        searchPlacesUseCase: withPlaces ? searchPlaces : null,
        getPlaceDetailsUseCase: withPlaces ? getPlaceDetails : null,
      );

  setUpAll(() {
    registerFallbackValue(
      ReverseGeocodeParams(position: _tPosition),
    );
    registerFallbackValue(
      SearchPlacesParams(query: ''),
    );
    registerFallbackValue(
      GetPlaceDetailsParams(placeId: ''),
    );
  });

  setUp(() {
    reverseGeocode = _MockReverseGeocode();
    searchPlaces = _MockSearchPlaces();
    getPlaceDetails = _MockGetPlaceDetails();
  });

  group('MapAreaPickerBloc', () {
    test('initial state', () {
      final bloc = buildBloc();
      expect(bloc.state.status, MapAreaPickerStatus.initial);
      expect(bloc.state.position, isNull);
      expect(bloc.state.searchStatus, PlaceSearchStatus.idle);
      addTearDown(bloc.close);
    });

    group('MapAreaPickerStarted', () {
      blocTest<MapAreaPickerBloc, MapAreaPickerState>(
        'with initial position and address -> ready immediately',
        build: buildBloc,
        act: (bloc) => bloc.add(
          MapAreaPickerStarted(
            initialPosition: _tPosition,
            initialAddress: _tAddress,
          ),
        ),
        expect: () => [
          isA<MapAreaPickerState>()
              .having((s) => s.status, 'status', MapAreaPickerStatus.ready)
              .having((s) => s.position, 'position', _tPosition)
              .having((s) => s.address, 'address', _tAddress),
        ],
      );

      blocTest<MapAreaPickerBloc, MapAreaPickerState>(
        'with initial position only -> geocodes address',
        build: () {
          when(() => reverseGeocode(any()))
              .thenReturn(TaskEither.right(_tGeocoded));
          return buildBloc();
        },
        act: (bloc) => bloc.add(
          MapAreaPickerStarted(initialPosition: _tPosition),
        ),
        expect: () => [
          isA<MapAreaPickerState>()
              .having(
                (s) => s.status,
                'status',
                MapAreaPickerStatus.geocoding,
              )
              .having((s) => s.position, 'position', _tPosition),
          isA<MapAreaPickerState>()
              .having((s) => s.status, 'status', MapAreaPickerStatus.ready)
              .having((s) => s.address, 'address', _tAddress),
        ],
      );
    });

    group('MapAreaPickerLocationChanged', () {
      blocTest<MapAreaPickerBloc, MapAreaPickerState>(
        'user move clears selected place and reverse geocodes',
        build: () {
          when(() => reverseGeocode(any()))
              .thenReturn(TaskEither.right(_tGeocoded));
          return buildBloc();
        },
        seed: () => const MapAreaPickerState(
          status: MapAreaPickerStatus.ready,
          position: _tPosition,
          address: _tAddress,
          selectedPlaceId: 'abc',
          selectedTitle: 'Dubai Marina',
        ),
        act: (bloc) => bloc.add(
          MapAreaPickerLocationChanged(_tOtherPosition),
        ),
        expect: () => [
          isA<MapAreaPickerState>()
              .having(
                (s) => s.status,
                'status',
                MapAreaPickerStatus.geocoding,
              )
              .having((s) => s.position, 'position', _tOtherPosition)
              .having((s) => s.selectedPlaceId, 'selectedPlaceId', isNull)
              .having((s) => s.selectedTitle, 'selectedTitle', isNull),
          isA<MapAreaPickerState>()
              .having((s) => s.status, 'status', MapAreaPickerStatus.ready)
              .having((s) => s.address, 'address', _tAddress),
        ],
      );
    });

    group('MapAreaPickerQueryChanged', () {
      blocTest<MapAreaPickerBloc, MapAreaPickerState>(
        'no-op when Places use case is null',
        build: buildBloc,
        act: (bloc) => bloc.add(MapAreaPickerQueryChanged('dubai')),
        expect: () => <MapAreaPickerState>[],
      );

      blocTest<MapAreaPickerBloc, MapAreaPickerState>(
        'returns predictions on success',
        build: () {
          when(() => searchPlaces(any()))
              .thenReturn(TaskEither.right([_tPrediction]));
          return buildBloc(withPlaces: true);
        },
        act: (bloc) => bloc.add(MapAreaPickerQueryChanged('dubai')),
        expect: () => [
          isA<MapAreaPickerState>()
              .having(
                (s) => s.searchStatus,
                'searchStatus',
                PlaceSearchStatus.searching,
              ),
          isA<MapAreaPickerState>()
              .having((s) => s.predictions, 'predictions', [_tPrediction])
              .having(
                (s) => s.searchStatus,
                'searchStatus',
                PlaceSearchStatus.success,
              ),
        ],
      );
    });

    group('MapAreaPickerPredictionSelected', () {
      blocTest<MapAreaPickerBloc, MapAreaPickerState>(
        'resolves place details and reverse geocodes',
        build: () {
          when(() => getPlaceDetails(any()))
              .thenReturn(TaskEither.right(_tPosition));
          when(() => reverseGeocode(any()))
              .thenReturn(TaskEither.right(_tGeocoded));
          return buildBloc(withPlaces: true);
        },
        act: (bloc) => bloc.add(
          MapAreaPickerPredictionSelected(_tPrediction),
        ),
        expect: () => [
          isA<MapAreaPickerState>()
              .having(
                (s) => s.status,
                'status',
                MapAreaPickerStatus.geocoding,
              )
              .having((s) => s.selectedPlaceId, 'selectedPlaceId', 'abc')
              .having((s) => s.selectedTitle, 'selectedTitle', 'Dubai Marina')
              .having((s) => s.predictions, 'predictions', isEmpty),
          isA<MapAreaPickerState>()
              .having((s) => s.position, 'position', _tPosition),
          isA<MapAreaPickerState>()
              .having((s) => s.status, 'status', MapAreaPickerStatus.ready)
              .having((s) => s.selectedPlaceId, 'selectedPlaceId', 'abc'),
        ],
      );
    });

    group('MapAreaPickerConfirmed', () {
      blocTest<MapAreaPickerBloc, MapAreaPickerState>(
        'emits result with null placeId for map-only selection',
        build: buildBloc,
        seed: () => const MapAreaPickerState(
          status: MapAreaPickerStatus.ready,
          position: _tPosition,
          address: _tAddress,
        ),
        act: (bloc) => bloc.add(const MapAreaPickerConfirmed()),
        expect: () => [
          isA<MapAreaPickerState>()
              .having((s) => s.pickedResult?.placeId, 'placeId', isNull)
              .having((s) => s.pickedResult?.areaName, 'areaName', _tAddress)
              .having((s) => s.pickedResult?.address, 'address', _tAddress)
              .having((s) => s.pickedResult?.position, 'position', _tPosition),
        ],
      );

      blocTest<MapAreaPickerBloc, MapAreaPickerState>(
        'uses the reverse-geocoded area name for a map-only pick',
        build: buildBloc,
        seed: () => const MapAreaPickerState(
          status: MapAreaPickerStatus.ready,
          position: _tPosition,
          address: _tAddress,
          resolvedAreaName: _tAreaName,
        ),
        act: (bloc) => bloc.add(const MapAreaPickerConfirmed()),
        expect: () => [
          isA<MapAreaPickerState>()
              .having((s) => s.pickedResult?.placeId, 'placeId', isNull)
              .having((s) => s.pickedResult?.areaName, 'areaName', _tAreaName)
              .having((s) => s.pickedResult?.address, 'address', _tAddress),
        ],
      );

      blocTest<MapAreaPickerBloc, MapAreaPickerState>(
        'emits result with real placeId after prediction selection',
        build: buildBloc,
        seed: () => const MapAreaPickerState(
          status: MapAreaPickerStatus.ready,
          position: _tPosition,
          address: _tAddress,
          selectedPlaceId: 'abc',
          selectedTitle: 'Dubai Marina',
        ),
        act: (bloc) => bloc.add(const MapAreaPickerConfirmed()),
        expect: () => [
          isA<MapAreaPickerState>()
              .having((s) => s.pickedResult?.placeId, 'placeId', 'abc')
              .having((s) => s.pickedResult?.areaName, 'areaName', 'Dubai Marina'),
        ],
      );
    });

    group('state helpers', () {
      test('canConfirm requires position + address + ready', () {
        const state = MapAreaPickerState(
          status: MapAreaPickerStatus.ready,
          position: _tPosition,
          address: _tAddress,
        );
        expect(state.canConfirm, isTrue);
      });

      test('canConfirm stays true while geocoding if address exists', () {
        const state = MapAreaPickerState(
          status: MapAreaPickerStatus.geocoding,
          position: _tPosition,
          address: _tAddress,
        );
        expect(state.canConfirm, isTrue);
      });

      test('canConfirm is false when address is missing', () {
        const state = MapAreaPickerState(
          status: MapAreaPickerStatus.ready,
          position: _tPosition,
        );
        expect(state.canConfirm, isFalse);
      });
    });
  });
}
