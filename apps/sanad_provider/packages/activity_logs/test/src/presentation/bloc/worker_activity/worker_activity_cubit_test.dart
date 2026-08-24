import 'package:activity_logs/src/cache/activity_log_cache_store.dart';
import 'package:activity_logs/src/domain/entities/activity_action.dart';
import 'package:activity_logs/src/domain/entities/activity_actor.dart';
import 'package:activity_logs/src/domain/entities/activity_log_entry.dart';
import 'package:activity_logs/src/domain/usecases/get_activity_logs_usecase.dart';
import 'package:activity_logs/src/presentation/bloc/worker_activity/worker_activity_cubit.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockGetActivityLogsUseCase extends Mock
    implements GetActivityLogsUseCase {}

void main() {
  late _MockGetActivityLogsUseCase useCase;
  late ActivityLogCacheStore cacheStore;

  final entry = ActivityLogEntry(
    action: ActivityAction.branchCreated,
    name: 'Added a new branch',
    timestamp: DateTime.utc(2026, 8, 20),
    actor: const ActivityActor(name: 'Owner', type: ActivityActorType.owner),
  );

  setUp(() {
    useCase = _MockGetActivityLogsUseCase();
    cacheStore = ActivityLogCacheStore();
    registerFallbackValue(const ActivityLogQuery());
  });

  WorkerActivityCubit buildCubit({
    Duration staleness = const Duration(seconds: 60),
  }) =>
      WorkerActivityCubit(
        getActivityLogsUseCase: useCase,
        cacheStore: ActivityLogCacheStore(staleness: staleness),
      );

  blocTest<WorkerActivityCubit, WorkerActivityState>(
    'load emits loading then success on success',
    build: () {
      when(() => useCase(any())).thenReturn(
        TaskEither.right(Page(items: [entry], meta: const PageMeta.empty())),
      );
      return buildCubit();
    },
    act: (cubit) => cubit.load(actorId: 'w-1', languageCode: 'en'),
    expect: () => [
      predicate<WorkerActivityState>((s) => s.status == RequestStatus.loading),
      predicate<WorkerActivityState>(
        (s) => s.status == RequestStatus.success && s.items.single == entry,
      ),
    ],
  );

  blocTest<WorkerActivityCubit, WorkerActivityState>(
    'load emits an empty success state when the feed has no rows',
    build: () {
      when(
        () => useCase(any()),
      ).thenReturn(TaskEither.right(const Page.empty()));
      return buildCubit();
    },
    act: (cubit) => cubit.load(actorId: 'w-1', languageCode: 'en'),
    verify: (cubit) {
      expect(cubit.state.isEmpty, isTrue);
    },
  );

  blocTest<WorkerActivityCubit, WorkerActivityState>(
    'load emits failure and preserves previously loaded items',
    build: () {
      var calls = 0;
      when(() => useCase(any())).thenAnswer((_) {
        calls++;
        return calls == 1
            ? TaskEither.right(
                Page(items: [entry], meta: const PageMeta.empty()),
              )
            : TaskEither.left(const ServerFailure(message: 'boom'));
      });
      return buildCubit();
    },
    act: (cubit) async {
      await cubit.load(actorId: 'w-1', languageCode: 'en');
      await cubit.load(actorId: 'w-1', languageCode: 'en', forceRefresh: true);
    },
    verify: (cubit) {
      expect(cubit.state.status, RequestStatus.failure);
      expect(cubit.state.items, [entry]);
      expect(cubit.state.failure, const ServerFailure(message: 'boom'));
    },
  );

  blocTest<WorkerActivityCubit, WorkerActivityState>(
    'a second load within the cache window skips the network call',
    build: () {
      when(() => useCase(any())).thenReturn(
        TaskEither.right(Page(items: [entry], meta: const PageMeta.empty())),
      );
      return buildCubit();
    },
    act: (cubit) async {
      await cubit.load(actorId: 'w-1', languageCode: 'en');
      await cubit.load(actorId: 'w-1', languageCode: 'en');
    },
    verify: (_) {
      verify(() => useCase(any())).called(1);
    },
  );

  blocTest<WorkerActivityCubit, WorkerActivityState>(
    'forceRefresh bypasses the cache even within the window',
    build: () {
      when(() => useCase(any())).thenReturn(
        TaskEither.right(Page(items: [entry], meta: const PageMeta.empty())),
      );
      return buildCubit();
    },
    act: (cubit) async {
      await cubit.load(actorId: 'w-1', languageCode: 'en');
      await cubit.load(actorId: 'w-1', languageCode: 'en', forceRefresh: true);
    },
    verify: (_) {
      verify(() => useCase(any())).called(2);
    },
  );

  test('cache is scoped by language code', () async {
    when(() => useCase(any())).thenReturn(
      TaskEither.right(Page(items: [entry], meta: const PageMeta.empty())),
    );
    final cubit = WorkerActivityCubit(
      getActivityLogsUseCase: useCase,
      cacheStore: cacheStore,
    );
    addTearDown(cubit.close);

    await cubit.load(actorId: 'w-1', languageCode: 'en');
    await cubit.load(actorId: 'w-1', languageCode: 'ar');

    verify(() => useCase(any())).called(2);
  });
}
