import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/entities/provider_overview_entity.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/usecases/get_provider_overview_usecase.dart';
import 'package:sanad_provider/src/features/organization_settings/src/presentation/bloc/provider_overview/provider_overview_bloc.dart';

class _MockGetOverview extends Mock implements GetProviderOverviewUseCase {}

void main() {
  late _MockGetOverview getOverview;

  const overview = ProviderOverviewEntity(
    branchesCount: 2,
    servicesCount: 5,
    teamCount: 3,
    invitationsCount: 1,
  );

  setUpAll(() {
    registerFallbackValue(const NoParams());
  });

  setUp(() {
    getOverview = _MockGetOverview();
  });

  ProviderOverviewBloc buildBloc() =>
      ProviderOverviewBloc(getOverview: getOverview);

  blocTest<ProviderOverviewBloc, ProviderOverviewState>(
    'Loaded: emits loading then success with the overview entity',
    setUp: () => when(
      () => getOverview(any()),
    ).thenAnswer((_) => TaskEither.right(overview)),
    build: buildBloc,
    act: (bloc) => bloc.add(const ProviderOverviewLoaded()),
    expect: () => [
      const ProviderOverviewState(status: RequestStatus.loading),
      const ProviderOverviewState(
        status: RequestStatus.success,
        overview: overview,
      ),
    ],
  );

  blocTest<ProviderOverviewBloc, ProviderOverviewState>(
    'Loaded: emits loading then failure on error, never fabricates data',
    setUp: () => when(() => getOverview(any())).thenAnswer(
      (_) => TaskEither.left(const NetworkFailure(message: 'boom')),
    ),
    build: buildBloc,
    act: (bloc) => bloc.add(const ProviderOverviewLoaded()),
    verify: (bloc) {
      expect(bloc.state.status, RequestStatus.failure);
      expect(bloc.state.overview, isNull);
      expect(bloc.state.failure, isA<NetworkFailure>());
    },
  );

  blocTest<ProviderOverviewBloc, ProviderOverviewState>(
    'Refreshed: re-runs the use case and clears a prior failure on success',
    setUp: () => when(
      () => getOverview(any()),
    ).thenAnswer((_) => TaskEither.right(overview)),
    build: buildBloc,
    seed: () => const ProviderOverviewState(
      status: RequestStatus.failure,
      failure: NetworkFailure(message: 'stale'),
    ),
    act: (bloc) => bloc.add(const ProviderOverviewRefreshed()),
    expect: () => [
      const ProviderOverviewState(status: RequestStatus.loading),
      const ProviderOverviewState(
        status: RequestStatus.success,
        overview: overview,
      ),
    ],
    verify: (bloc) {
      verify(() => getOverview(any())).called(1);
    },
  );

  blocTest<ProviderOverviewBloc, ProviderOverviewState>(
    'Refreshed: a failure after a prior success keeps the failure — no '
    'fabricated retry data, mirrors the completion bloc contract',
    setUp: () => when(() => getOverview(any())).thenAnswer(
      (_) => TaskEither.left(const NetworkFailure(message: 'boom')),
    ),
    build: buildBloc,
    seed: () => const ProviderOverviewState(
      status: RequestStatus.success,
      overview: overview,
    ),
    act: (bloc) => bloc.add(const ProviderOverviewRefreshed()),
    expect: () => [
      const ProviderOverviewState(
        status: RequestStatus.loading,
        overview: overview,
      ),
      isA<ProviderOverviewState>()
          .having((s) => s.status, 'status', RequestStatus.failure)
          .having((s) => s.failure, 'failure', isA<NetworkFailure>()),
    ],
  );
}
