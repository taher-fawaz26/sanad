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

const _tServingArea = ServingArea(
  placeId: 'place_extra',
  name: 'JBR',
  address: 'Dubai, UAE',
  latLng: _tPosition2,
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
      const CreateCoverageIntent(
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

      blocTest<CoverageAreaBloc, CoverageAreaState>(
        'elevates edit mode to recalculate on user move',
        build: () {
          when(() => resolveCoverageLocation(any())).thenAnswer((invocation) {
            final intent =
                invocation.positionalArguments.first as CoverageLocationIntent;
            expect(intent, isA<RecalculateCoverageIntent>());
            return TaskEither.right(
              const CoverageLocation(
                center: _tPosition2,
                address: 'New Address',
                nearbyAreas: ['New Area'],
              ),
            );
          });
          return buildBloc();
        },
        act: (bloc) async {
          when(() => resolveCoverageLocation(any()))
              .thenReturn(TaskEither.right(_tCoverageLocation));
          bloc.add(
            const CoverageAreaStarted(
              mode: CoverageMode.edit,
              branchId: 'branch-1',
              initialCenter: _tPosition,
            ),
          );
          await Future<void>.delayed(const Duration(milliseconds: 50));
          when(() => resolveCoverageLocation(any())).thenAnswer((invocation) {
            final intent =
                invocation.positionalArguments.first as CoverageLocationIntent;
            expect(intent, isA<RecalculateCoverageIntent>());
            return TaskEither.right(
              const CoverageLocation(
                center: _tPosition2,
                address: 'New Address',
                nearbyAreas: ['New Area'],
              ),
            );
          });
          bloc.add(const CoverageAreaMapMoved(_tPosition2));
        },
        wait: const Duration(milliseconds: 100),
        verify: (bloc) {
          expect(bloc.state.mode, CoverageMode.recalculate);
          expect(bloc.state.autoAreas, ['New Area']);
        },
      );
    });

    group('CoverageAreaExtraAreaSet', () {
      blocTest<CoverageAreaBloc, CoverageAreaState>(
        'sets extra area and enforces max one by replacement',
        build: buildBloc,
        seed: () => const CoverageAreaState(
          status: CoverageAreaStatus.ready,
        ),
        act: (bloc) {
          bloc.add(const CoverageAreaExtraAreaSet(_tServingArea));
          bloc.add(
            const CoverageAreaExtraAreaSet(
              ServingArea(
                placeId: 'place_other',
                name: 'Other',
                address: 'Dubai',
                latLng: _tPosition,
              ),
            ),
          );
        },
        verify: (bloc) {
          expect(bloc.state.extraArea?.placeId, 'place_other');
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
