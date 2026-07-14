// ignore_for_file: prefer_const_constructors

import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps/src/domain/entities/coverage_location.dart';
import 'package:maps/src/domain/entities/coverage_mode.dart';
import 'package:maps/src/domain/entities/serving_area.dart';
import 'package:maps/src/domain/usecases/coverage_location_intent.dart';
import 'package:maps/src/domain/usecases/get_current_location_usecase.dart';
import 'package:maps/src/domain/usecases/resolve_coverage_location_usecase.dart';
import 'package:maps/src/presentation/bloc/coverage_area/coverage_area_bloc.dart';
import 'package:mocktail/mocktail.dart';

class _MockResolveCoverageLocation extends Mock
    implements ResolveCoverageLocationUseCase {}

class _MockGetCurrentLocation extends Mock
    implements GetCurrentLocationUseCase {}

const _tPosition = LatLng(25.0, 55.0);
const _tPosition2 = LatLng(25.1, 55.1);
const _tAddress = 'Dubai Marina, Dubai';
const _tFailure = ServerFailure(message: 'error');

const _tAreaA = ServingArea(
  placeId: 'place_a',
  name: 'JBR',
  address: 'Dubai, UAE',
  latLng: _tPosition2,
);

const _tAreaB = ServingArea(
  placeId: 'place_b',
  name: 'Marina',
  address: 'Dubai, UAE',
  latLng: _tPosition,
);

const _tCoverageLocation = CoverageLocation(
  center: _tPosition,
  address: _tAddress,
  nearbyAreas: ['Dubai Marina', 'JBR'],
);

void main() {
  late _MockResolveCoverageLocation resolveCoverageLocation;
  late _MockGetCurrentLocation getCurrentLocation;

  CoverageAreaBloc buildBloc() => CoverageAreaBloc(
        resolveCoverageLocationUseCase: resolveCoverageLocation,
        getCurrentLocationUseCase: getCurrentLocation,
      );

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(
      const CoverageLocationIntent(
        center: _tPosition,
        radiusKm: CoverageAreaState.defaultRadiusKm,
      ),
    );
  });

  setUp(() {
    resolveCoverageLocation = _MockResolveCoverageLocation();
    getCurrentLocation = _MockGetCurrentLocation();
  });

  group('CoverageAreaBloc', () {
    test('initial state', () {
      final bloc = buildBloc();
      expect(bloc.state.status, CoverageAreaStatus.initial);
      expect(bloc.state.radiusKm, CoverageAreaState.defaultRadiusKm);
      expect(bloc.state.autoAreas, isEmpty);
      expect(bloc.state.extraAreas, isEmpty);
      expect(bloc.state.mode, CoverageMode.create);
      addTearDown(bloc.close);
    });

    group('CoverageAreaStarted', () {
      blocTest<CoverageAreaBloc, CoverageAreaState>(
        'with initial center resolves location via use case',
        build: () {
          when(() => resolveCoverageLocation(any()))
              .thenReturn(TaskEither.right(_tCoverageLocation));
          return buildBloc();
        },
        act: (bloc) => bloc.add(
          const CoverageAreaStarted(
            mode: CoverageMode.create,
            initialCenter: _tPosition,
          ),
        ),
        wait: const Duration(milliseconds: 50),
        verify: (bloc) {
          expect(bloc.state.status, CoverageAreaStatus.ready);
          expect(bloc.state.center, _tPosition);
          expect(bloc.state.address, _tAddress);
          expect(bloc.state.autoAreas, ['Dubai Marina', 'JBR']);
          expect(bloc.state.mode, CoverageMode.create);
        },
      );

      blocTest<CoverageAreaBloc, CoverageAreaState>(
        'failure from getCurrentLocation -> failure status',
        build: () {
          when(() => getCurrentLocation(any()))
              .thenReturn(TaskEither.left(_tFailure));
          return buildBloc();
        },
        act: (bloc) => bloc.add(
          const CoverageAreaStarted(mode: CoverageMode.create),
        ),
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

      blocTest<CoverageAreaBloc, CoverageAreaState>(
        'edit mode seeds provided areas without resolving',
        build: buildBloc,
        act: (bloc) => bloc.add(
          const CoverageAreaStarted(
            mode: CoverageMode.edit,
            initialCenter: _tPosition,
            initialAddress: _tAddress,
            initialAutoAreas: ['Saved A', 'Saved B'],
          ),
        ),
        wait: const Duration(milliseconds: 50),
        verify: (bloc) {
          expect(bloc.state.status, CoverageAreaStatus.ready);
          expect(bloc.state.mode, CoverageMode.edit);
          expect(bloc.state.autoAreas, ['Saved A', 'Saved B']);
          verifyNever(() => resolveCoverageLocation(any()));
        },
      );

      blocTest<CoverageAreaBloc, CoverageAreaState>(
        'edit seed recalculates from geocoder on first map move',
        build: () {
          when(() => resolveCoverageLocation(any())).thenReturn(
            TaskEither.right(
              const CoverageLocation(
                center: _tPosition2,
                address: 'New Address',
                nearbyAreas: ['New Area'],
              ),
            ),
          );
          return buildBloc();
        },
        act: (bloc) async {
          bloc.add(
            const CoverageAreaStarted(
              mode: CoverageMode.edit,
              initialCenter: _tPosition,
              initialAddress: _tAddress,
              initialAutoAreas: ['Saved A', 'Saved B'],
            ),
          );
          await Future<void>.delayed(const Duration(milliseconds: 20));
          bloc.add(const CoverageAreaMapMoved(_tPosition2));
        },
        wait: const Duration(milliseconds: 80),
        verify: (bloc) {
          expect(bloc.state.mode, CoverageMode.recalculate);
          expect(bloc.state.autoAreas, ['New Area']);
        },
      );
    });

    group('CoverageAreaMapMoved', () {
      blocTest<CoverageAreaBloc, CoverageAreaState>(
        'skips redundant resolve for same center',
        build: () {
          when(() => resolveCoverageLocation(any()))
              .thenReturn(TaskEither.right(_tCoverageLocation));
          return buildBloc();
        },
        seed: () => const CoverageAreaState(
          status: CoverageAreaStatus.ready,
          center: _tPosition,
          address: _tAddress,
        ),
        act: (bloc) => bloc.add(
          const CoverageAreaMapMoved(_tPosition),
        ),
        expect: () => <CoverageAreaState>[],
      );
    });

    group('CoverageAreaExtraAreaSet', () {
      blocTest<CoverageAreaBloc, CoverageAreaState>(
        'adds multiple distinct extra areas sequentially',
        build: buildBloc,
        seed: () => const CoverageAreaState(status: CoverageAreaStatus.ready),
        act: (bloc) {
          bloc.add(const CoverageAreaExtraAreaSet(_tAreaA));
          bloc.add(const CoverageAreaExtraAreaSet(_tAreaB));
        },
        verify: (bloc) {
          expect(
            bloc.state.extraAreas.map((a) => a.placeId),
            ['place_a', 'place_b'],
          );
          expect(bloc.state.totalAreaCount, 2);
        },
      );

      blocTest<CoverageAreaBloc, CoverageAreaState>(
        'ignores a duplicate extra area',
        build: buildBloc,
        seed: () => const CoverageAreaState(status: CoverageAreaStatus.ready),
        act: (bloc) {
          bloc.add(const CoverageAreaExtraAreaSet(_tAreaA));
          bloc.add(const CoverageAreaExtraAreaSet(_tAreaA));
        },
        verify: (bloc) {
          expect(bloc.state.extraAreas.length, 1);
        },
      );
    });

    group('CoverageAreaExtraAreaRemoved', () {
      blocTest<CoverageAreaBloc, CoverageAreaState>(
        'removes the targeted area, keeps others, and can re-add',
        build: buildBloc,
        seed: () => const CoverageAreaState(status: CoverageAreaStatus.ready),
        act: (bloc) {
          bloc.add(const CoverageAreaExtraAreaSet(_tAreaA));
          bloc.add(const CoverageAreaExtraAreaSet(_tAreaB));
          bloc.add(const CoverageAreaExtraAreaRemoved(_tAreaA));
          bloc.add(const CoverageAreaExtraAreaSet(_tAreaA));
        },
        verify: (bloc) {
          expect(
            bloc.state.extraAreas.map((a) => a.placeId),
            ['place_b', 'place_a'],
          );
        },
      );
    });

    group('CoverageAreaAutoAreaRemoved', () {
      blocTest<CoverageAreaBloc, CoverageAreaState>(
        'removes auto area by name',
        build: buildBloc,
        seed: () => const CoverageAreaState(
          status: CoverageAreaStatus.ready,
          autoAreas: ['Dubai Marina', 'JBR'],
        ),
        act: (bloc) {
          bloc.autoAreasController.replace(['Dubai Marina', 'JBR']);
          bloc.add(const CoverageAreaAutoAreaRemoved('Dubai Marina'));
        },
        verify: (bloc) {
          expect(bloc.state.autoAreas, ['JBR']);
        },
      );

      blocTest<CoverageAreaBloc, CoverageAreaState>(
        'removed auto area is not resurrected by a later recompute',
        build: () {
          when(() => resolveCoverageLocation(any()))
              .thenReturn(TaskEither.right(_tCoverageLocation));
          return buildBloc();
        },
        act: (bloc) async {
          bloc.add(
            const CoverageAreaStarted(
              mode: CoverageMode.create,
              initialCenter: _tPosition,
            ),
          );
          await Future<void>.delayed(const Duration(milliseconds: 20));
          bloc.add(const CoverageAreaAutoAreaRemoved('Dubai Marina'));
          await Future<void>.delayed(const Duration(milliseconds: 10));
          // Recompute returns 'Dubai Marina' again; it must stay removed.
          bloc.add(const CoverageAreaRadiusChanged(10));
        },
        wait: const Duration(milliseconds: 80),
        verify: (bloc) {
          expect(bloc.state.autoAreas, ['JBR']);
        },
      );
    });

    group('CoverageAreaRadiusChanged', () {
      blocTest<CoverageAreaBloc, CoverageAreaState>(
        'updates radius and resolves nearby areas',
        build: () {
          when(() => resolveCoverageLocation(any()))
              .thenReturn(TaskEither.right(_tCoverageLocation));
          return buildBloc();
        },
        seed: () => const CoverageAreaState(
          status: CoverageAreaStatus.ready,
          center: _tPosition,
          address: _tAddress,
        ),
        act: (bloc) => bloc.add(
          const CoverageAreaRadiusChanged(10),
        ),
        wait: const Duration(milliseconds: 50),
        verify: (bloc) {
          expect(bloc.state.radiusKm, 10);
          expect(bloc.state.status, CoverageAreaStatus.ready);
        },
      );
    });

    group('canConfirm', () {
      test('true when center + address + ready', () {
        const state = CoverageAreaState(
          status: CoverageAreaStatus.ready,
          center: _tPosition,
          address: _tAddress,
        );
        expect(state.canConfirm, isTrue);
      });

      test('false when loading', () {
        const state = CoverageAreaState(
          status: CoverageAreaStatus.loading,
          center: _tPosition,
          address: _tAddress,
        );
        expect(state.canConfirm, isFalse);
      });
    });
  });
}
