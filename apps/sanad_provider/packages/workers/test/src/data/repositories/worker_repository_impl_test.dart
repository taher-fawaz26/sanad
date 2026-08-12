import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:workers/src/data/datasources/worker_remote_data_source.dart';
import 'package:workers/src/data/models/worker_dto.dart';
import 'package:workers/src/data/repositories/worker_repository_impl.dart';
import 'package:workers/src/domain/entities/worker_status.dart';
import 'package:workers/src/domain/usecases/workers_query.dart';

class _MockDataSource extends Mock implements WorkerRemoteDataSource {}

void main() {
  late _MockDataSource dataSource;
  late WorkerRepositoryImpl repository;

  setUp(() {
    dataSource = _MockDataSource();
    repository = WorkerRepositoryImpl(dataSource);
    registerFallbackValue(const WorkersQuery());
  });

  group('WorkerRepositoryImpl.getWorkers', () {
    test('maps each WorkerDto in the page to a WorkerEntity', () async {
      const dto = WorkerDto(
        id: 'w1',
        fullName: 'Ada',
        role: 'worker',
        initials: 'A',
        status: WorkerStatus.active,
      );
      const dtoPage = Page<WorkerDto>(
        items: [dto],
        meta: PageMeta(
          totalItems: 1,
          itemCount: 1,
          itemsPerPage: 10,
          totalPages: 1,
          currentPage: 1,
        ),
      );
      when(
        () => dataSource.getWorkers(any()),
      ).thenAnswer((_) => TaskEither.of(dtoPage));

      final result = await repository.getWorkers(const WorkersQuery()).run();

      expect(result.isRight(), isTrue);
      final page = result.getOrElse((_) => throw StateError('unreachable'));
      expect(page.items, hasLength(1));
      expect(page.items.single, isNot(isA<WorkerDto>()));
      expect(page.items.single.id, 'w1');
      expect(page.meta.totalItems, 1);
    });

    test('forwards the query unchanged to the data source', () async {
      when(() => dataSource.getWorkers(any())).thenAnswer(
        (_) => TaskEither.of(const Page<WorkerDto>.empty()),
      );
      const query = WorkersQuery(page: 2, search: 'ada');

      await repository.getWorkers(query).run();

      verify(() => dataSource.getWorkers(query)).called(1);
    });

    test('propagates a Failure from the data source', () async {
      const failure = ServerFailure(message: 'boom');
      when(
        () => dataSource.getWorkers(any()),
      ).thenAnswer((_) => TaskEither.left(failure));

      final result = await repository.getWorkers(const WorkersQuery()).run();

      expect(result.isLeft(), isTrue);
    });
  });
}
