import 'package:activity_logs/src/cache/activity_log_cache_store.dart';
import 'package:activity_logs/src/domain/entities/activity_action.dart';
import 'package:activity_logs/src/domain/entities/activity_actor.dart';
import 'package:activity_logs/src/domain/entities/activity_log_entry.dart';
import 'package:activity_logs/src/domain/usecases/get_activity_logs_usecase.dart';
import 'package:activity_logs/src/presentation/bloc/recent_activity/recent_activity_cubit.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockGetActivityLogsUseCase extends Mock
    implements GetActivityLogsUseCase {}

void main() {
  late _MockGetActivityLogsUseCase useCase;

  final entry = ActivityLogEntry(
    action: ActivityAction.branchCreated,
    name: 'Added a new branch',
    timestamp: DateTime.utc(2026, 8, 20),
    actor: const ActivityActor(name: 'Owner', type: ActivityActorType.owner),
  );

  setUp(() {
    useCase = _MockGetActivityLogsUseCase();
    registerFallbackValue(const ActivityLogQuery());
  });

  RecentActivityCubit buildCubit({
    Duration staleness = const Duration(seconds: 60),
  }) => RecentActivityCubit(
    getActivityLogsUseCase: useCase,
    cacheStore: ActivityLogCacheStore(staleness: staleness),
  );

  blocTest<RecentActivityCubit, RecentActivityState>(
    'load emits loading then success on success',
    build: () {
      when(() => useCase(any())).thenReturn(
        TaskEither.right(Page(items: [entry], meta: const PageMeta.empty())),
      );
      return buildCubit();
    },
    act: (cubit) => cubit.load(languageCode: 'en'),
    expect: () => [
      predicate<RecentActivityState>((s) => s.status == RequestStatus.loading),
      predicate<RecentActivityState>(
        (s) => s.status == RequestStatus.success && s.items.single == entry,
      ),
    ],
  );

  blocTest<RecentActivityCubit, RecentActivityState>(
    'requests a global feed limited to 5, with no actor filter',
    build: () {
      when(() => useCase(any())).thenReturn(
        TaskEither.right(Page(items: [entry], meta: const PageMeta.empty())),
      );
      return buildCubit();
    },
    act: (cubit) => cubit.load(languageCode: 'en'),
    verify: (_) {
      final query =
          verify(() => useCase(captureAny())).captured.single
              as ActivityLogQuery;
      expect(query.limit, 5);
      expect(query.actorId, isNull);
    },
  );

  blocTest<RecentActivityCubit, RecentActivityState>(
    'load emits an empty success state when the feed has no rows',
    build: () {
      when(
        () => useCase(any()),
      ).thenReturn(TaskEither.right(const Page.empty()));
      return buildCubit();
    },
    act: (cubit) => cubit.load(languageCode: 'en'),
    verify: (cubit) {
      expect(cubit.state.isEmpty, isTrue);
    },
  );

  blocTest<RecentActivityCubit, RecentActivityState>(
    'load emits failure on error',
    build: () {
      when(
        () => useCase(any()),
      ).thenReturn(TaskEither.left(const ServerFailure(message: 'boom')));
      return buildCubit();
    },
    act: (cubit) => cubit.load(languageCode: 'en'),
    verify: (cubit) {
      expect(cubit.state.status, RequestStatus.failure);
      expect(cubit.state.failure, const ServerFailure(message: 'boom'));
    },
  );

  blocTest<RecentActivityCubit, RecentActivityState>(
    'a second load within the cache window skips the network call',
    build: () {
      when(() => useCase(any())).thenReturn(
        TaskEither.right(Page(items: [entry], meta: const PageMeta.empty())),
      );
      return buildCubit();
    },
    act: (cubit) async {
      await cubit.load(languageCode: 'en');
      await cubit.load(languageCode: 'en');
    },
    verify: (_) {
      verify(() => useCase(any())).called(1);
    },
  );

  blocTest<RecentActivityCubit, RecentActivityState>(
    'forceRefresh bypasses the cache even within the window',
    build: () {
      when(() => useCase(any())).thenReturn(
        TaskEither.right(Page(items: [entry], meta: const PageMeta.empty())),
      );
      return buildCubit();
    },
    act: (cubit) async {
      await cubit.load(languageCode: 'en');
      await cubit.load(languageCode: 'en', forceRefresh: true);
    },
    verify: (_) {
      verify(() => useCase(any())).called(2);
    },
  );

  test('global cache key is independent of a per-actor cache key', () {
    expect(
      ActivityLogCacheStore.keyFor(actorId: null, languageCode: 'en'),
      isNot(ActivityLogCacheStore.keyFor(actorId: 'w-1', languageCode: 'en')),
    );
  });
}
