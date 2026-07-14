// ignore_for_file: prefer_const_constructors

import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps/src/domain/usecases/forward_geocode_usecase.dart';
import 'package:maps/src/domain/usecases/get_current_location_usecase.dart';
import 'package:maps/src/domain/usecases/get_nearby_areas_usecase.dart';
import 'package:maps/src/domain/usecases/reverse_geocode_usecase.dart';
import 'package:maps/src/presentation/bloc/coverage_area/coverage_area_bloc.dart';
import 'package:mocktail/mocktail.dart';

class _MockGetCurrentLocation extends Mock
    implements GetCurrentLocationUseCase {}

class _MockReverseGeocode extends Mock implements ReverseGeocodeUseCase {}

class _MockForwardGeocode extends Mock implements ForwardGeocodeUseCase {}

class _MockGetNearbyAreas extends Mock implements GetNearbyAreasUseCase {}

const _tPosition = LatLng(25.0, 55.0);
const _tAddress = 'Dubai Marina, Dubai';
const _tAreas = ['Dubai Marina', 'JBR', 'Media City'];
const _tFailure = ServerFailure(message: 'error');

void main() {
  late _MockGetCurrentLocation getCurrentLocation;
  late _MockReverseGeocode reverseGeocode;
  late _MockForwardGeocode forwardGeocode;
  late _MockGetNearbyAreas getNearbyAreas;

  CoverageAreaBloc buildBloc() => CoverageAreaBloc(
        getCurrentLocationUseCase: getCurrentLocation,
        reverseGeocodeUseCase: reverseGeocode,
        forwardGeocodeUseCase: forwardGeocode,
        getNearbyAreasUseCase: getNearbyAreas,
      );

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(ReverseGeocodeParams(position: _tPosition));
    registerFallbackValue(ForwardGeocodeParams(address: ''));
    registerFallbackValue(
      NearbyAreasParams(center: _tPosition, radiusKm: 5),
    );
  });

  setUp(() {
    getCurrentLocation = _MockGetCurrentLocation();
    reverseGeocode = _MockReverseGeocode();
    forwardGeocode = _MockForwardGeocode();
    getNearbyAreas = _MockGetNearbyAreas();
  });

  group('CoverageAreaBloc', () {
    test('initial state', () {
      final bloc = buildBloc();
      expect(bloc.state.status, CoverageAreaStatus.initial);
      expect(bloc.state.radiusKm, CoverageAreaState.defaultRadiusKm);
      addTearDown(bloc.close);
    });

    group('CoverageAreaStarted', () {
      blocTest<CoverageAreaBloc, CoverageAreaState>(
        'with initial position resolves address and areas',
        build: () {
          when(() => reverseGeocode(any()))
              .thenReturn(TaskEither.right(_tAddress));
          when(() => getNearbyAreas(any()))
              .thenReturn(TaskEither.right(_tAreas));
          return buildBloc();
        },
        act: (bloc) => bloc.add(
          CoverageAreaStarted(initialPosition: _tPosition),
        ),
        wait: const Duration(milliseconds: 50),
        verify: (bloc) {
          expect(bloc.state.status, CoverageAreaStatus.ready);
          expect(bloc.state.position, _tPosition);
          expect(bloc.state.address, _tAddress);
          expect(bloc.state.suggestedAreas, _tAreas);
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
          isA<CoverageAreaState>()
              .having((s) => s.status, 'status', CoverageAreaStatus.loading),
          isA<CoverageAreaState>()
              .having((s) => s.status, 'status', CoverageAreaStatus.failure),
        ],
      );
    });

    group('CoverageAreaAreaRemoved', () {
      blocTest<CoverageAreaBloc, CoverageAreaState>(
        'removes suggested area by adding to removedAreas',
        build: buildBloc,
        seed: () => CoverageAreaState(
          status: CoverageAreaStatus.ready,
          suggestedAreas: _tAreas,
        ),
        act: (bloc) =>
            bloc.add(CoverageAreaAreaRemoved('Dubai Marina')),
        verify: (bloc) {
          expect(bloc.state.removedAreas, contains('Dubai Marina'));
          expect(
            bloc.state.coveredAreas,
            isNot(contains('Dubai Marina')),
          );
        },
      );

      blocTest<CoverageAreaBloc, CoverageAreaState>(
        'removes custom area from customAreas list',
        build: buildBloc,
        seed: () => CoverageAreaState(
          status: CoverageAreaStatus.ready,
          customAreas: ['My Area'],
        ),
        act: (bloc) => bloc.add(CoverageAreaAreaRemoved('My Area')),
        verify: (bloc) {
          expect(bloc.state.customAreas, isEmpty);
        },
      );
    });

    group('CoverageAreaAreaAdded', () {
      blocTest<CoverageAreaBloc, CoverageAreaState>(
        'adds new custom area',
        build: buildBloc,
        seed: () => CoverageAreaState(
          status: CoverageAreaStatus.ready,
        ),
        act: (bloc) => bloc.add(CoverageAreaAreaAdded('My Area')),
        verify: (bloc) {
          expect(bloc.state.customAreas, contains('My Area'));
        },
      );

      blocTest<CoverageAreaBloc, CoverageAreaState>(
        'restores removed suggested area instead of adding duplicate',
        build: buildBloc,
        seed: () => CoverageAreaState(
          status: CoverageAreaStatus.ready,
          suggestedAreas: _tAreas,
          removedAreas: {'Dubai Marina'},
        ),
        act: (bloc) =>
            bloc.add(CoverageAreaAreaAdded('Dubai Marina')),
        verify: (bloc) {
          expect(bloc.state.removedAreas, isEmpty);
          expect(bloc.state.customAreas, isEmpty);
        },
      );

      blocTest<CoverageAreaBloc, CoverageAreaState>(
        'ignores empty area name',
        build: buildBloc,
        seed: () => CoverageAreaState(
          status: CoverageAreaStatus.ready,
        ),
        act: (bloc) => bloc.add(CoverageAreaAreaAdded('  ')),
        expect: () => <CoverageAreaState>[],
      );

      blocTest<CoverageAreaBloc, CoverageAreaState>(
        'ignores duplicate custom area',
        build: buildBloc,
        seed: () => CoverageAreaState(
          status: CoverageAreaStatus.ready,
          customAreas: ['My Area'],
        ),
        act: (bloc) => bloc.add(CoverageAreaAreaAdded('My Area')),
        expect: () => <CoverageAreaState>[],
      );
    });

    group('coveredAreas', () {
      test('merges suggested minus removed with custom', () {
        const state = CoverageAreaState(
          suggestedAreas: ['A', 'B', 'C'],
          customAreas: ['D'],
          removedAreas: {'B'},
        );
        expect(state.coveredAreas, ['A', 'C', 'D']);
      });
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
