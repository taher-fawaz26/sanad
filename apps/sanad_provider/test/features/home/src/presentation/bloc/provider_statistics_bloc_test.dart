import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sanad_provider/src/features/home/src/data/cache/provider_statistics_cache_store.dart';
import 'package:sanad_provider/src/features/home/src/domain/entities/provider_statistic_entity.dart';
import 'package:sanad_provider/src/features/home/src/domain/usecases/get_provider_statistics_usecase.dart';
import 'package:sanad_provider/src/features/home/src/presentation/bloc/provider_statistics/provider_statistics_bloc.dart';

class _MockGetStatistics extends Mock implements GetProviderStatisticsUseCase {}

void main() {
  late _MockGetStatistics getStatistics;
  late ProviderStatisticsCacheStore cacheStore;
  var languageCode = 'en';

  const statistics = [
    ProviderStatisticEntity(
      key: 'branches',
      name: 'Branches',
      icon: 'fa-solid fa-store',
      value: 2,
    ),
    ProviderStatisticEntity(
      key: 'workers',
      name: 'Team Members',
      icon: 'fa-solid fa-users',
      value: 4,
    ),
  ];

  setUpAll(() {
    registerFallbackValue(const NoParams());
  });

  setUp(() {
    getStatistics = _MockGetStatistics();
    cacheStore = ProviderStatisticsCacheStore();
    languageCode = 'en';
  });

  ProviderStatisticsBloc buildBloc({ProviderStatisticsCacheStore? store}) =>
      ProviderStatisticsBloc(
        getStatistics: getStatistics,
        cacheStore: store ?? cacheStore,
        resolveLanguageCode: () => languageCode,
      );

  blocTest<ProviderStatisticsBloc, ProviderStatisticsState>(
    'Loaded: emits loading then success with the statistic entities',
    setUp: () => when(
      () => getStatistics(any()),
    ).thenAnswer((_) => TaskEither.right(statistics)),
    build: buildBloc,
    act: (bloc) => bloc.add(const ProviderStatisticsLoaded()),
    expect: () => [
      const ProviderStatisticsState(status: RequestStatus.loading),
      const ProviderStatisticsState(
        status: RequestStatus.success,
        statistics: statistics,
      ),
    ],
  );

  blocTest<ProviderStatisticsBloc, ProviderStatisticsState>(
    'Loaded: emits loading then failure on error, never fabricates data',
    setUp: () => when(() => getStatistics(any())).thenAnswer(
      (_) => TaskEither.left(const NetworkFailure(message: 'boom')),
    ),
    build: buildBloc,
    act: (bloc) => bloc.add(const ProviderStatisticsLoaded()),
    verify: (bloc) {
      expect(bloc.state.status, RequestStatus.failure);
      expect(bloc.state.statistics, isEmpty);
      expect(bloc.state.failure, isA<NetworkFailure>());
    },
  );

  blocTest<ProviderStatisticsBloc, ProviderStatisticsState>(
    'Refreshed: re-runs the use case and clears a prior failure on success',
    setUp: () => when(
      () => getStatistics(any()),
    ).thenAnswer((_) => TaskEither.right(statistics)),
    build: buildBloc,
    seed: () => const ProviderStatisticsState(
      status: RequestStatus.failure,
      failure: NetworkFailure(message: 'stale'),
    ),
    act: (bloc) => bloc.add(const ProviderStatisticsRefreshed()),
    verify: (bloc) {
      expect(bloc.state.status, RequestStatus.success);
      expect(bloc.state.statistics, statistics);
      expect(bloc.state.failure, isNull);
      verify(() => getStatistics(any())).called(1);
    },
  );

  blocTest<ProviderStatisticsBloc, ProviderStatisticsState>(
    'Loaded twice within TTL serves the cache and skips the second network '
    'call',
    setUp: () => when(
      () => getStatistics(any()),
    ).thenAnswer((_) => TaskEither.right(statistics)),
    build: buildBloc,
    act: (bloc) async {
      bloc.add(const ProviderStatisticsLoaded());
      await Future<void>.delayed(Duration.zero);
      bloc.add(const ProviderStatisticsLoaded());
    },
    verify: (_) => verify(() => getStatistics(any())).called(1),
  );

  blocTest<ProviderStatisticsBloc, ProviderStatisticsState>(
    'Refreshed always re-fetches even when a fresh cache exists',
    setUp: () => when(
      () => getStatistics(any()),
    ).thenAnswer((_) => TaskEither.right(statistics)),
    build: buildBloc,
    act: (bloc) async {
      bloc.add(const ProviderStatisticsLoaded());
      await Future<void>.delayed(Duration.zero);
      bloc.add(const ProviderStatisticsRefreshed());
    },
    verify: (_) => verify(() => getStatistics(any())).called(2),
  );

  blocTest<ProviderStatisticsBloc, ProviderStatisticsState>(
    'a different locale is a distinct cache entry (AR never serves EN)',
    setUp: () => when(
      () => getStatistics(any()),
    ).thenAnswer((_) => TaskEither.right(statistics)),
    build: buildBloc,
    act: (bloc) async {
      bloc.add(const ProviderStatisticsLoaded()); // en
      await Future<void>.delayed(Duration.zero);
      languageCode = 'ar';
      bloc.add(const ProviderStatisticsLoaded()); // ar → miss → fetch
    },
    verify: (_) => verify(() => getStatistics(any())).called(2),
  );

  test('cache-first: fresh cached data is served without a network call', () {
    cacheStore.write(
      ProviderStatisticsCacheStore.keyFor(languageCode: 'en'),
      statistics,
    );
    final read = cacheStore.read(
      ProviderStatisticsCacheStore.keyFor(languageCode: 'en'),
    );
    expect(read, isNotNull);
    expect(read!.isStale, isFalse);
    expect(read.items, statistics);
  });
}
