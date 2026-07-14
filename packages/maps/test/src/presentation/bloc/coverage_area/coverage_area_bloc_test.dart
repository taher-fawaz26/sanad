// ignore_for_file: prefer_const_constructors

import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps/src/domain/entities/place_prediction.dart';
import 'package:maps/src/domain/entities/serving_area.dart';
import 'package:maps/src/domain/usecases/forward_geocode_usecase.dart';
import 'package:maps/src/domain/usecases/get_current_location_usecase.dart';
import 'package:maps/src/domain/usecases/get_place_details_usecase.dart';
import 'package:maps/src/domain/usecases/reverse_geocode_usecase.dart';
import 'package:maps/src/domain/usecases/search_places_usecase.dart';
import 'package:maps/src/presentation/bloc/coverage_area/coverage_area_bloc.dart';
import 'package:maps/src/presentation/models/place_search_status.dart';
import 'package:mocktail/mocktail.dart';

class _MockGetCurrentLocation extends Mock
    implements GetCurrentLocationUseCase {}

class _MockReverseGeocode extends Mock implements ReverseGeocodeUseCase {}

class _MockForwardGeocode extends Mock implements ForwardGeocodeUseCase {}

class _MockSearchPlaces extends Mock implements SearchPlacesUseCase {}

class _MockGetPlaceDetails extends Mock implements GetPlaceDetailsUseCase {}

const _tPosition = LatLng(25.0, 55.0);
const _tPosition2 = LatLng(25.1, 55.1);
const _tAddress = 'Dubai Marina, Dubai';
const _tFailure = ServerFailure(message: 'error');

const _tServingArea = ServingArea(
  placeId: 'place_1',
  name: 'Dubai Marina',
  address: 'Dubai, UAE',
  latLng: _tPosition,
);

const _tServingArea2 = ServingArea(
  placeId: 'place_2',
  name: 'JBR',
  address: 'Dubai, UAE',
  latLng: _tPosition2,
);

const _tPrediction = PlacePrediction(
  placeId: 'pred_1',
  description: 'Dubai Marina, Dubai, UAE',
  mainText: 'Dubai Marina',
  secondaryText: 'Dubai, UAE',
);

void main() {
  late _MockGetCurrentLocation getCurrentLocation;
  late _MockReverseGeocode reverseGeocode;
  late _MockForwardGeocode forwardGeocode;
  late _MockSearchPlaces searchPlaces;
  late _MockGetPlaceDetails getPlaceDetails;

  CoverageAreaBloc buildBloc({
    bool withPlaces = true,
  }) =>
      CoverageAreaBloc(
        getCurrentLocationUseCase: getCurrentLocation,
        reverseGeocodeUseCase: reverseGeocode,
        forwardGeocodeUseCase: forwardGeocode,
        searchPlacesUseCase: withPlaces ? searchPlaces : null,
        getPlaceDetailsUseCase: withPlaces ? getPlaceDetails : null,
      );

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(ReverseGeocodeParams(position: _tPosition));
    registerFallbackValue(ForwardGeocodeParams(address: ''));
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
    searchPlaces = _MockSearchPlaces();
    getPlaceDetails = _MockGetPlaceDetails();
  });

  group('CoverageAreaBloc', () {
    test('initial state', () {
      final bloc = buildBloc();
      expect(bloc.state.status, CoverageAreaStatus.initial);
      expect(bloc.state.radiusKm, CoverageAreaState.defaultRadiusKm);
      expect(bloc.state.servingAreas, isEmpty);
      expect(bloc.state.predictions, isEmpty);
      expect(
        bloc.state.searchStatus,
        PlaceSearchStatus.idle,
      );
      addTearDown(bloc.close);
    });

    group('CoverageAreaStarted', () {
      blocTest<CoverageAreaBloc, CoverageAreaState>(
        'with initial position resolves address',
        build: () {
          when(() => reverseGeocode(any()))
              .thenReturn(TaskEither.right(_tAddress));
          return buildBloc();
        },
        act: (bloc) => bloc.add(
          CoverageAreaStarted(initialPosition: _tPosition),
        ),
        wait: const Duration(milliseconds: 50),
        verify: (bloc) {
          expect(
            bloc.state.status,
            CoverageAreaStatus.ready,
          );
          expect(bloc.state.position, _tPosition);
          expect(bloc.state.address, _tAddress);
        },
      );

      blocTest<CoverageAreaBloc, CoverageAreaState>(
        'preserves initial serving areas',
        build: () {
          when(() => reverseGeocode(any()))
              .thenReturn(TaskEither.right(_tAddress));
          return buildBloc();
        },
        act: (bloc) => bloc.add(
          CoverageAreaStarted(
            initialPosition: _tPosition,
            initialServingAreas: [_tServingArea],
          ),
        ),
        wait: const Duration(milliseconds: 50),
        verify: (bloc) {
          expect(bloc.state.servingAreas, [_tServingArea]);
        },
      );

      blocTest<CoverageAreaBloc, CoverageAreaState>(
        'failure from getCurrentLocation -> failure status',
        build: () {
          when(() => getCurrentLocation(any()))
              .thenReturn(TaskEither.left(_tFailure));
          return buildBloc();
        },
        act: (bloc) => bloc.add(CoverageAreaStarted()),
        expect: () => [
          isA<CoverageAreaState>().having(
            (s) => s.status,
            'status',
            CoverageAreaStatus.loading,
          ),
          isA<CoverageAreaState>().having(
            (s) => s.status,
            'status',
            CoverageAreaStatus.failure,
          ),
        ],
      );
    });

    group('CoverageAreaServingAreaAdded', () {
      blocTest<CoverageAreaBloc, CoverageAreaState>(
        'adds new serving area',
        build: buildBloc,
        seed: () => CoverageAreaState(
          status: CoverageAreaStatus.ready,
        ),
        act: (bloc) => bloc.add(
          CoverageAreaServingAreaAdded(_tServingArea),
        ),
        verify: (bloc) {
          expect(
            bloc.state.servingAreas,
            [_tServingArea],
          );
        },
      );

      blocTest<CoverageAreaBloc, CoverageAreaState>(
        'ignores duplicate placeId',
        build: buildBloc,
        seed: () => CoverageAreaState(
          status: CoverageAreaStatus.ready,
          servingAreas: [_tServingArea],
        ),
        act: (bloc) => bloc.add(
          CoverageAreaServingAreaAdded(_tServingArea),
        ),
        expect: () => <CoverageAreaState>[],
      );
    });

    group('CoverageAreaServingAreaRemoved', () {
      blocTest<CoverageAreaBloc, CoverageAreaState>(
        'removes serving area by placeId',
        build: buildBloc,
        seed: () => CoverageAreaState(
          status: CoverageAreaStatus.ready,
          servingAreas: [_tServingArea, _tServingArea2],
        ),
        act: (bloc) => bloc.add(
          CoverageAreaServingAreaRemoved('place_1'),
        ),
        verify: (bloc) {
          expect(bloc.state.servingAreas, [_tServingArea2]);
        },
      );
    });

    group('CoverageAreaQueryChanged', () {
      blocTest<CoverageAreaBloc, CoverageAreaState>(
        'searches places and emits predictions',
        build: () {
          when(() => searchPlaces(any())).thenReturn(
            TaskEither.right([_tPrediction]),
          );
          return buildBloc();
        },
        seed: () => CoverageAreaState(
          status: CoverageAreaStatus.ready,
          position: _tPosition,
        ),
        act: (bloc) => bloc.add(
          CoverageAreaQueryChanged('Dubai'),
        ),
        wait: const Duration(milliseconds: 50),
        verify: (bloc) {
          expect(
            bloc.state.searchStatus,
            PlaceSearchStatus.success,
          );
          expect(bloc.state.predictions, [_tPrediction]);
        },
      );

      blocTest<CoverageAreaBloc, CoverageAreaState>(
        'empty query resets to idle',
        build: buildBloc,
        seed: () => CoverageAreaState(
          status: CoverageAreaStatus.ready,
          searchStatus: PlaceSearchStatus.success,
          predictions: [_tPrediction],
          searchQuery: 'Dubai',
        ),
        act: (bloc) => bloc.add(
          CoverageAreaQueryChanged(''),
        ),
        verify: (bloc) {
          expect(
            bloc.state.searchStatus,
            PlaceSearchStatus.idle,
          );
          expect(bloc.state.predictions, isEmpty);
        },
      );

      blocTest<CoverageAreaBloc, CoverageAreaState>(
        'emits empty status when no predictions found',
        build: () {
          when(() => searchPlaces(any())).thenReturn(
            TaskEither.right(const []),
          );
          return buildBloc();
        },
        seed: () => CoverageAreaState(
          status: CoverageAreaStatus.ready,
          position: _tPosition,
        ),
        act: (bloc) => bloc.add(
          CoverageAreaQueryChanged('zzzzz'),
        ),
        wait: const Duration(milliseconds: 50),
        verify: (bloc) {
          expect(
            bloc.state.searchStatus,
            PlaceSearchStatus.empty,
          );
        },
      );
    });

    group('CoverageAreaPredictionSelected', () {
      blocTest<CoverageAreaBloc, CoverageAreaState>(
        'resolves details and adds serving area',
        build: () {
          when(() => getPlaceDetails(any())).thenReturn(
            TaskEither.right(_tPosition),
          );
          return buildBloc();
        },
        seed: () => CoverageAreaState(
          status: CoverageAreaStatus.ready,
          position: _tPosition,
          predictions: [_tPrediction],
          searchStatus: PlaceSearchStatus.success,
        ),
        act: (bloc) => bloc.add(
          CoverageAreaPredictionSelected(_tPrediction),
        ),
        wait: const Duration(milliseconds: 50),
        verify: (bloc) {
          expect(bloc.state.servingAreas, hasLength(1));
          expect(
            bloc.state.servingAreas.first.placeId,
            _tPrediction.placeId,
          );
          expect(
            bloc.state.servingAreas.first.name,
            _tPrediction.mainText,
          );
          expect(
            bloc.state.searchStatus,
            PlaceSearchStatus.idle,
          );
          expect(bloc.state.predictions, isEmpty);
        },
      );
    });

    group('CoverageAreaPredictionsCleared', () {
      blocTest<CoverageAreaBloc, CoverageAreaState>(
        'clears predictions and resets search',
        build: buildBloc,
        seed: () => CoverageAreaState(
          status: CoverageAreaStatus.ready,
          predictions: [_tPrediction],
          searchStatus: PlaceSearchStatus.success,
          searchQuery: 'Dubai',
        ),
        act: (bloc) => bloc.add(
          CoverageAreaPredictionsCleared(),
        ),
        verify: (bloc) {
          expect(bloc.state.predictions, isEmpty);
          expect(
            bloc.state.searchStatus,
            PlaceSearchStatus.idle,
          );
          expect(bloc.state.searchQuery, isEmpty);
        },
      );
    });

    group('CoverageAreaRadiusChanged', () {
      blocTest<CoverageAreaBloc, CoverageAreaState>(
        'updates radius without side effects',
        build: buildBloc,
        seed: () => CoverageAreaState(
          status: CoverageAreaStatus.ready,
          position: _tPosition,
          address: _tAddress,
        ),
        act: (bloc) => bloc.add(
          CoverageAreaRadiusChanged(10),
        ),
        verify: (bloc) {
          expect(bloc.state.radiusKm, 10);
          expect(
            bloc.state.status,
            CoverageAreaStatus.ready,
          );
        },
      );
    });

    group('canConfirm', () {
      test('true when position + address + ready', () {
        const state = CoverageAreaState(
          status: CoverageAreaStatus.ready,
          position: _tPosition,
          address: _tAddress,
        );
        expect(state.canConfirm, isTrue);
      });

      test('false when loading', () {
        const state = CoverageAreaState(
          status: CoverageAreaStatus.loading,
          position: _tPosition,
          address: _tAddress,
        );
        expect(state.canConfirm, isFalse);
      });

      test('false when address is null', () {
        const state = CoverageAreaState(
          status: CoverageAreaStatus.ready,
          position: _tPosition,
        );
        expect(state.canConfirm, isFalse);
      });
    });
  });
}
