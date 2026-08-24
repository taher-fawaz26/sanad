import 'package:activity_logs/src/data/datasources/activity_log_remote_data_source.dart';
import 'package:activity_logs/src/data/models/activity_log_dto.dart';
import 'package:activity_logs/src/data/repositories/activity_log_repository_impl.dart';
import 'package:activity_logs/src/domain/entities/activity_action.dart';
import 'package:activity_logs/src/domain/entities/activity_actor.dart';
import 'package:activity_logs/src/domain/usecases/activity_log_query.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockActivityLogRemoteDataSource extends Mock
    implements ActivityLogRemoteDataSource {}

void main() {
  late _MockActivityLogRemoteDataSource dataSource;
  late ActivityLogRepositoryImpl repository;

  setUp(() {
    dataSource = _MockActivityLogRemoteDataSource();
    repository = ActivityLogRepositoryImpl(dataSource);
    registerFallbackValue(const ActivityLogQuery());
  });

  final dto = ActivityLogDto(
    action: ActivityAction.branchCreated,
    name: 'Added a new branch',
    timestamp: DateTime.utc(2026, 8, 20),
    actor: const ActivityActor(name: 'Owner', type: ActivityActorType.owner),
  );

  test('maps a successful Page<Dto> to Page<Entity>', () async {
    when(() => dataSource.getActivityLogs(any())).thenReturn(
      TaskEither.right(
        Page(items: [dto], meta: const PageMeta.empty()),
      ),
    );

    final result = await repository
        .getActivityLogs(const ActivityLogQuery())
        .run();

    expect(result.isRight(), isTrue);
    result.match(
      (_) => fail('expected success'),
      (page) {
        expect(page.items, hasLength(1));
        expect(page.items.first, dto.toEntity());
      },
    );
  });

  test('propagates a Failure from the data source unchanged', () async {
    const failure = ServerFailure(message: 'boom');
    when(
      () => dataSource.getActivityLogs(any()),
    ).thenReturn(TaskEither.left(failure));

    final result = await repository
        .getActivityLogs(const ActivityLogQuery())
        .run();

    expect(result.isLeft(), isTrue);
    result.match((l) => expect(l, failure), (_) => fail('expected failure'));
  });
}
