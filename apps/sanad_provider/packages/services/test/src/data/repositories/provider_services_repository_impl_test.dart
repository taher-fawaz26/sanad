// ignore_for_file: prefer_const_constructors

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:services/src/data/datasources/provider_services_remote_data_source.dart';
import 'package:services/src/data/models/category_ref_dto.dart';
import 'package:services/src/data/models/provider_service_dto.dart';
import 'package:services/src/data/models/provider_service_overview_dto.dart';
import 'package:services/src/data/repositories/provider_services_repository_impl.dart';
import 'package:services/src/domain/entities/provider_service_status.dart';

class _MockDataSource extends Mock
    implements ProviderServicesRemoteDataSource {}

ProviderServiceDto _serviceDto(String id) => ProviderServiceDto(
  id: id,
  serviceId: 'catalog-$id',
  serviceName: 'Service $id',
  category: const CategoryRefDto(id: 'cat-1', name: 'Home', description: null),
  description: 'desc',
  status: ProviderServiceStatus.active,
  images: const [],
  createdAt: DateTime(2024),
  updatedAt: DateTime(2024),
);

void main() {
  late _MockDataSource dataSource;
  late ProviderServicesRepositoryImpl repo;

  setUp(() {
    dataSource = _MockDataSource();
    repo = ProviderServicesRepositoryImpl(dataSource);
  });

  group('getOverview', () {
    test('maps the overview DTO to a plain entity via toEntity()', () async {
      const dto = ProviderServiceOverviewDto(
        dataAvailable: true,
        totalRequests: 12,
        completedCount: 8,
        cancelledCount: 2,
        completionRate: 0.75,
      );
      when(dataSource.getOverview).thenAnswer((_) => TaskEither.of(dto));

      final result = await repo.getOverview().run();

      final entity = result.getOrElse(
        (_) => throw StateError('expected right'),
      );
      // Must be a plain entity, not the DTO subtype, matching every other
      // repo method's DTO->entity mapping convention.
      expect(entity.runtimeType, isNot(ProviderServiceOverviewDto));
      expect(entity.dataAvailable, isTrue);
      expect(entity.totalRequests, 12);
      expect(entity.completionRate, 0.75);
    });
  });

  group('addImage', () {
    test(
      'maps the single POST /images response without a follow-up '
      'getProviderService refetch',
      () async {
        when(
          () => dataSource.addImage('svc-1', 'media-1'),
        ).thenAnswer((_) => TaskEither.of(_serviceDto('svc-1')));

        final result = await repo
            .addImage(id: 'svc-1', mediaId: 'media-1')
            .run();

        expect(result.getOrElse((_) => throw StateError('x')).id, 'svc-1');
        verify(() => dataSource.addImage('svc-1', 'media-1')).called(1);
        verifyNever(() => dataSource.getProviderService(any()));
      },
    );
  });

  group('deleteImage', () {
    test(
      'returns the updated service entity from the DELETE response '
      'instead of Unit',
      () async {
        when(
          () => dataSource.deleteImage('svc-1', 'img-1'),
        ).thenAnswer((_) => TaskEither.of(_serviceDto('svc-1')));

        final result = await repo
            .deleteImage(id: 'svc-1', imageId: 'img-1')
            .run();

        expect(result.getOrElse((_) => throw StateError('x')).id, 'svc-1');
        verify(() => dataSource.deleteImage('svc-1', 'img-1')).called(1);
      },
    );
  });
}
