// blocTest act: lambdas prevent Dart from inferring const at call-sites.
// ignore_for_file: prefer_const_constructors

import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:services/src/domain/entities/category_record_entity.dart';
import 'package:services/src/domain/entities/category_ref_entity.dart';
import 'package:services/src/domain/entities/pagination_meta_entity.dart';
import 'package:services/src/domain/entities/service_request_entity.dart';
import 'package:services/src/domain/entities/service_request_status.dart';
import 'package:services/src/domain/repositories/categories_repository.dart';
import 'package:services/src/domain/repositories/service_requests_repository.dart';
import 'package:services/src/domain/usecases/create_service_request_usecase.dart';
import 'package:services/src/domain/usecases/get_categories_usecase.dart';
import 'package:services/src/presentation/bloc/request_new_service/request_new_service_bloc.dart';

class _MockRepo extends Mock implements ServiceRequestsRepository {}

class _MockCategoriesRepo extends Mock implements CategoriesRepository {}

CategoryRecordEntity _category(String id) => CategoryRecordEntity(
  id: id,
  slug: id,
  name: 'Car',
  description: 'Car services',
  icon: null,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

ServiceRequestEntity _request(String id) => ServiceRequestEntity(
  id: id,
  name: 'Bespoke tiling',
  unifiedRequestId: 'unified-$id',
  category: const CategoryRefEntity(
    id: 'cat-1',
    name: 'Home',
    description: null,
  ),
  status: ServiceRequestStatus.underReview,
  createdAt: DateTime(2024),
  updatedAt: DateTime(2024),
);

const _params = CreateServiceRequestParams(
  name: 'Bespoke tiling',
  categoryId: 'cat-1',
  description: 'desc',
);

void main() {
  late _MockRepo repo;
  late _MockCategoriesRepo categoriesRepo;

  setUp(() {
    repo = _MockRepo();
    categoriesRepo = _MockCategoriesRepo();
  });

  RequestNewServiceBloc buildBloc() => RequestNewServiceBloc(
    createServiceRequestUseCase: CreateServiceRequestUseCase(repo),
    getCategoriesUseCase: GetCategoriesUseCase(categoriesRepo),
  );

  group('RequestNewServiceBloc', () {
    blocTest<RequestNewServiceBloc, RequestNewServiceState>(
      'submit success emits the created request',
      setUp: () => when(
        () => repo.createServiceRequest(
          name: 'Bespoke tiling',
          categoryId: 'cat-1',
          description: 'desc',
          imageIds: null,
        ),
      ).thenAnswer((_) => TaskEither.of(_request('1'))),
      build: buildBloc,
      act: (bloc) => bloc.add(const RequestNewServiceSubmittedEvent(_params)),
      expect: () => [
        isA<RequestNewServiceState>().having(
          (s) => s.status,
          'status',
          RequestStatus.loading,
        ),
        isA<RequestNewServiceState>()
            .having((s) => s.status, 'status', RequestStatus.success)
            .having((s) => s.createdRequest?.id, 'createdRequest.id', '1'),
      ],
    );

    blocTest<RequestNewServiceBloc, RequestNewServiceState>(
      'submit failure surfaces the failure',
      setUp: () =>
          when(
            () => repo.createServiceRequest(
              name: 'Bespoke tiling',
              categoryId: 'cat-1',
              description: 'desc',
              imageIds: null,
            ),
          ).thenAnswer(
            (_) => TaskEither.left(const ServerFailure(message: 'boom')),
          ),
      build: buildBloc,
      act: (bloc) => bloc.add(const RequestNewServiceSubmittedEvent(_params)),
      verify: (bloc) {
        expect(bloc.state.status, RequestStatus.failure);
        expect(bloc.state.failure, const ServerFailure(message: 'boom'));
      },
    );

    // Regression for B3: without `droppable()` a double-tap on submit would
    // fire two concurrent `POST /service-requests` calls.
    blocTest<RequestNewServiceBloc, RequestNewServiceState>(
      'double-tap submit is dropped while one is in flight',
      setUp: () =>
          when(
            () => repo.createServiceRequest(
              name: 'Bespoke tiling',
              categoryId: 'cat-1',
              description: 'desc',
              imageIds: null,
            ),
          ).thenAnswer(
            (_) => TaskEither(() async {
              await Future<void>.delayed(const Duration(milliseconds: 50));
              return right(_request('1'));
            }),
          ),
      build: buildBloc,
      act: (bloc) {
        bloc
          ..add(const RequestNewServiceSubmittedEvent(_params))
          ..add(const RequestNewServiceSubmittedEvent(_params));
      },
      wait: const Duration(milliseconds: 100),
      verify: (bloc) {
        verify(
          () => repo.createServiceRequest(
            name: 'Bespoke tiling',
            categoryId: 'cat-1',
            description: 'desc',
            imageIds: null,
          ),
        ).called(1);
        expect(bloc.state.status, RequestStatus.success);
      },
    );
  });

  group('RequestNewServiceBloc — categories picker', () {
    blocTest<RequestNewServiceBloc, RequestNewServiceState>(
      'categories fetch success emits the loaded list',
      setUp: () => when(
        () => categoriesRepo.getCategories(limit: 100),
      ).thenAnswer(
        (_) => TaskEither.of(
          ServicesPagedResult(
            items: [_category('cat-car')],
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
      act: (bloc) => bloc.add(const RequestNewServiceCategoriesRequested()),
      expect: () => [
        isA<RequestNewServiceState>().having(
          (s) => s.categoriesStatus,
          'categoriesStatus',
          RequestNewServiceCategoriesStatus.loading,
        ),
        isA<RequestNewServiceState>()
            .having(
              (s) => s.categoriesStatus,
              'categoriesStatus',
              RequestNewServiceCategoriesStatus.success,
            )
            .having(
              (s) => s.categories.map((c) => c.id),
              'categories',
              ['cat-car'],
            ),
      ],
    );

    blocTest<RequestNewServiceBloc, RequestNewServiceState>(
      'categories fetch failure surfaces the failure',
      setUp: () => when(() => categoriesRepo.getCategories(limit: 100))
          .thenAnswer(
            (_) => TaskEither.left(const ServerFailure(message: 'boom')),
          ),
      build: buildBloc,
      act: (bloc) => bloc.add(const RequestNewServiceCategoriesRequested()),
      expect: () => [
        isA<RequestNewServiceState>().having(
          (s) => s.categoriesStatus,
          'categoriesStatus',
          RequestNewServiceCategoriesStatus.loading,
        ),
        isA<RequestNewServiceState>()
            .having(
              (s) => s.categoriesStatus,
              'categoriesStatus',
              RequestNewServiceCategoriesStatus.failure,
            )
            .having(
              (s) => s.categoriesFailure,
              'categoriesFailure',
              const ServerFailure(message: 'boom'),
            ),
      ],
    );
  });
}
