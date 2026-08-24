// blocTest act: lambdas prevent Dart from inferring const at call-sites.
// ignore_for_file: prefer_const_constructors

import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:services/src/domain/entities/catalog_service_entity.dart';
import 'package:services/src/domain/entities/category_record_entity.dart';
import 'package:services/src/domain/entities/category_ref_entity.dart';
import 'package:services/src/domain/entities/pagination_meta_entity.dart';
import 'package:services/src/domain/entities/provider_service_entity.dart';
import 'package:services/src/domain/entities/provider_service_status.dart';
import 'package:services/src/domain/repositories/catalog_repository.dart';
import 'package:services/src/domain/repositories/categories_repository.dart';
import 'package:services/src/domain/repositories/provider_services_repository.dart';
import 'package:services/src/domain/usecases/browse_catalog_usecase.dart';
import 'package:services/src/domain/usecases/create_provider_service_usecase.dart';
import 'package:services/src/domain/usecases/get_categories_usecase.dart';
import 'package:services/src/presentation/bloc/add_service/add_service_bloc.dart';

class _MockProviderServicesRepo extends Mock
    implements ProviderServicesRepository {}

class _MockCatalogRepo extends Mock implements CatalogRepository {}

class _MockCategoriesRepo extends Mock implements CategoriesRepository {}

const _category = CategoryRefEntity(
  id: 'cat-1',
  name: 'Car',
  description: null,
);

CategoryRecordEntity _categoryRecord(String id) => CategoryRecordEntity(
  id: id,
  slug: id,
  name: 'Car',
  description: 'Car services',
  icon: null,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

ProviderServiceEntity _service(String id) => ProviderServiceEntity(
  id: id,
  serviceId: 'catalog-1',
  serviceName: 'Wash Car',
  category: _category,
  description: 'desc',
  status: ProviderServiceStatus.active,
  images: const [],
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

CatalogServiceEntity _catalogService(String id) =>
    CatalogServiceEntity(id: id, name: 'Wash Car', category: _category);

const _params = CreateProviderServiceParams(
  serviceId: 'catalog-1',
  description: 'desc',
  imageIds: ['media-1'],
);

void main() {
  late _MockProviderServicesRepo repo;
  late _MockCatalogRepo catalogRepo;
  late _MockCategoriesRepo categoriesRepo;

  setUp(() {
    repo = _MockProviderServicesRepo();
    catalogRepo = _MockCatalogRepo();
    categoriesRepo = _MockCategoriesRepo();
  });

  AddServiceBloc buildBloc() => AddServiceBloc(
    createProviderServiceUseCase: CreateProviderServiceUseCase(repo),
    browseCatalogUseCase: BrowseCatalogUseCase(catalogRepo),
    getCategoriesUseCase: GetCategoriesUseCase(categoriesRepo),
  );

  group('AddServiceBloc — submit', () {
    blocTest<AddServiceBloc, AddServiceState>(
      'submit success emits the created service',
      setUp: () => when(
        () => repo.createProviderService(
          serviceId: 'catalog-1',
          description: 'desc',
          imageIds: ['media-1'],
        ),
      ).thenAnswer((_) => TaskEither.of(_service('1'))),
      build: buildBloc,
      act: (bloc) => bloc.add(const AddServiceSubmittedEvent(_params)),
      expect: () => [
        isA<AddServiceState>().having(
          (s) => s.status,
          'status',
          RequestStatus.loading,
        ),
        isA<AddServiceState>()
            .having((s) => s.status, 'status', RequestStatus.success)
            .having((s) => s.createdService?.id, 'createdService.id', '1'),
      ],
    );

    blocTest<AddServiceBloc, AddServiceState>(
      'submit failure surfaces the failure',
      setUp: () =>
          when(
            () => repo.createProviderService(
              serviceId: 'catalog-1',
              description: 'desc',
              imageIds: ['media-1'],
            ),
          ).thenAnswer(
            (_) => TaskEither.left(const ServerFailure(message: 'boom')),
          ),
      build: buildBloc,
      act: (bloc) => bloc.add(const AddServiceSubmittedEvent(_params)),
      verify: (bloc) {
        expect(bloc.state.status, RequestStatus.failure);
        expect(bloc.state.failure, const ServerFailure(message: 'boom'));
      },
    );

    // Double-tap guard, matching RequestNewServiceBloc/EditServiceBloc.
    blocTest<AddServiceBloc, AddServiceState>(
      'double-tap submit is dropped while one is in flight',
      setUp: () =>
          when(
            () => repo.createProviderService(
              serviceId: 'catalog-1',
              description: 'desc',
              imageIds: ['media-1'],
            ),
          ).thenAnswer(
            (_) => TaskEither(() async {
              await Future<void>.delayed(const Duration(milliseconds: 50));
              return right(_service('1'));
            }),
          ),
      build: buildBloc,
      act: (bloc) {
        bloc
          ..add(const AddServiceSubmittedEvent(_params))
          ..add(const AddServiceSubmittedEvent(_params));
      },
      wait: const Duration(milliseconds: 100),
      verify: (bloc) {
        verify(
          () => repo.createProviderService(
            serviceId: 'catalog-1',
            description: 'desc',
            imageIds: ['media-1'],
          ),
        ).called(1);
        expect(bloc.state.status, RequestStatus.success);
      },
    );
  });

  group('AddServiceBloc — categories picker (SAN-577 step 1)', () {
    blocTest<AddServiceBloc, AddServiceState>(
      'categories fetch success emits the loaded list',
      setUp: () =>
          when(() => categoriesRepo.getCategories(limit: 100)).thenAnswer(
            (_) => TaskEither.of(
              ServicesPagedResult(
                items: [_categoryRecord('cat-1')],
                meta: const PaginationMetaEntity(
                  totalItems: 1,
                  itemCount: 1,
                  itemsPerPage: 100,
                  totalPages: 1,
                  currentPage: 1,
                ),
              ),
            ),
          ),
      build: buildBloc,
      act: (bloc) => bloc.add(const AddServiceCategoriesRequested()),
      expect: () => [
        isA<AddServiceState>().having(
          (s) => s.categoriesStatus,
          'categoriesStatus',
          AddServiceCategoriesStatus.loading,
        ),
        isA<AddServiceState>()
            .having(
              (s) => s.categoriesStatus,
              'categoriesStatus',
              AddServiceCategoriesStatus.success,
            )
            .having(
              (s) => s.categories.map((c) => c.id),
              'categories',
              ['cat-1'],
            ),
      ],
    );

    blocTest<AddServiceBloc, AddServiceState>(
      'categories fetch failure surfaces the failure',
      setUp: () =>
          when(
            () => categoriesRepo.getCategories(limit: 100),
          ).thenAnswer(
            (_) => TaskEither.left(const ServerFailure(message: 'boom')),
          ),
      build: buildBloc,
      act: (bloc) => bloc.add(const AddServiceCategoriesRequested()),
      expect: () => [
        isA<AddServiceState>().having(
          (s) => s.categoriesStatus,
          'categoriesStatus',
          AddServiceCategoriesStatus.loading,
        ),
        isA<AddServiceState>()
            .having(
              (s) => s.categoriesStatus,
              'categoriesStatus',
              AddServiceCategoriesStatus.failure,
            )
            .having(
              (s) => s.categoriesFailure,
              'categoriesFailure',
              const ServerFailure(message: 'boom'),
            ),
      ],
    );
  });

  group(
    'AddServiceBloc — catalog picker (SAN-577 step 2, category-scoped)',
    () {
      blocTest<AddServiceBloc, AddServiceState>(
        'catalog fetch success emits the loaded list, scoped to categoryId',
        setUp: () =>
            when(
              () => catalogRepo.browseCatalog(limit: 100, categoryId: 'cat-1'),
            ).thenAnswer(
              (_) => TaskEither.of(
                ServicesPagedResult(
                  items: [_catalogService('svc-wash-car')],
                  meta: const PaginationMetaEntity(
                    totalItems: 1,
                    itemCount: 1,
                    itemsPerPage: 100,
                    totalPages: 1,
                    currentPage: 1,
                  ),
                ),
              ),
            ),
        build: buildBloc,
        act: (bloc) => bloc.add(const AddServiceCatalogRequested('cat-1')),
        expect: () => [
          isA<AddServiceState>().having(
            (s) => s.catalogStatus,
            'catalogStatus',
            AddServiceCatalogStatus.loading,
          ),
          isA<AddServiceState>()
              .having(
                (s) => s.catalogStatus,
                'catalogStatus',
                AddServiceCatalogStatus.success,
              )
              .having(
                (s) => s.catalogItems.map((c) => c.id),
                'catalogItems',
                ['svc-wash-car'],
              ),
        ],
      );

      blocTest<AddServiceBloc, AddServiceState>(
        'catalog fetch failure surfaces the failure',
        setUp: () =>
            when(
              () => catalogRepo.browseCatalog(limit: 100, categoryId: 'cat-1'),
            ).thenAnswer(
              (_) => TaskEither.left(const ServerFailure(message: 'boom')),
            ),
        build: buildBloc,
        act: (bloc) => bloc.add(const AddServiceCatalogRequested('cat-1')),
        expect: () => [
          isA<AddServiceState>().having(
            (s) => s.catalogStatus,
            'catalogStatus',
            AddServiceCatalogStatus.loading,
          ),
          isA<AddServiceState>()
              .having(
                (s) => s.catalogStatus,
                'catalogStatus',
                AddServiceCatalogStatus.failure,
              )
              .having(
                (s) => s.catalogFailure,
                'catalogFailure',
                const ServerFailure(message: 'boom'),
              ),
        ],
      );
    },
  );
}
