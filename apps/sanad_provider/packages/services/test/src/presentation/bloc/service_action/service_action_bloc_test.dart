// blocTest act: lambdas prevent Dart from inferring const at call-sites.
// ignore_for_file: prefer_const_constructors

import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:services/src/domain/entities/category_ref_entity.dart';
import 'package:services/src/domain/entities/provider_service_entity.dart';
import 'package:services/src/domain/entities/provider_service_status.dart';
import 'package:services/src/domain/repositories/provider_services_repository.dart';
import 'package:services/src/domain/usecases/delete_provider_service_usecase.dart';
import 'package:services/src/domain/usecases/set_provider_service_status_usecase.dart';
import 'package:services/src/presentation/bloc/service_action/service_action_bloc.dart';

class _MockRepo extends Mock implements ProviderServicesRepository {}

ProviderServiceEntity _service(
  String id, {
  ProviderServiceStatus status = ProviderServiceStatus.active,
}) => ProviderServiceEntity(
  id: id,
  serviceId: 'catalog-$id',
  serviceName: 'Service $id',
  category: const CategoryRefEntity(
    id: 'cat-1',
    name: 'Category',
    description: null,
  ),
  description: 'desc',
  status: status,
  images: const [],
  createdAt: DateTime(2024),
  updatedAt: DateTime(2024),
);

const _serverFailure = ServerFailure(message: 'boom');

void main() {
  late _MockRepo repo;

  setUp(() {
    repo = _MockRepo();
    registerFallbackValue(ProviderServiceStatus.active);
  });

  ServiceActionBloc buildBloc() => ServiceActionBloc(
    deleteProviderServiceUseCase: DeleteProviderServiceUseCase(repo),
    setProviderServiceStatusUseCase: SetProviderServiceStatusUseCase(repo),
  );

  group('ServiceActionBloc', () {
    blocTest<ServiceActionBloc, ServiceActionState>(
      'delete success emits deletedServiceId',
      setUp: () => when(
        () => repo.deleteProviderService('1'),
      ).thenAnswer((_) => TaskEither.of(unit)),
      build: buildBloc,
      act: (bloc) => bloc.add(const ServiceDeleteRequestedEvent('1')),
      expect: () => [
        isA<ServiceActionState>()
            .having((s) => s.status, 'status', RequestStatus.loading)
            .having((s) => s.processingId, 'processingId', '1'),
        isA<ServiceActionState>()
            .having((s) => s.status, 'status', RequestStatus.success)
            .having((s) => s.deletedServiceId, 'deletedServiceId', '1'),
      ],
    );

    blocTest<ServiceActionBloc, ServiceActionState>(
      'delete failure emits the failure and keeps processingId cleared '
      'of the successful marker',
      setUp: () => when(
        () => repo.deleteProviderService('1'),
      ).thenAnswer((_) => TaskEither.left(_serverFailure)),
      build: buildBloc,
      act: (bloc) => bloc.add(const ServiceDeleteRequestedEvent('1')),
      verify: (bloc) {
        expect(bloc.state.status, RequestStatus.failure);
        expect(bloc.state.failure, _serverFailure);
        expect(bloc.state.deletedServiceId, isNull);
      },
    );

    blocTest<ServiceActionBloc, ServiceActionState>(
      'double-tap delete is dropped while one is in flight',
      setUp: () => when(() => repo.deleteProviderService('1')).thenAnswer(
        (_) => TaskEither(() async {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          return right(unit);
        }),
      ),
      build: buildBloc,
      act: (bloc) {
        bloc
          ..add(const ServiceDeleteRequestedEvent('1'))
          ..add(const ServiceDeleteRequestedEvent('1'));
      },
      wait: const Duration(milliseconds: 100),
      verify: (bloc) {
        verify(() => repo.deleteProviderService('1')).called(1);
        expect(bloc.state.status, RequestStatus.success);
      },
    );

    blocTest<ServiceActionBloc, ServiceActionState>(
      'status toggle success emits the updated service',
      setUp: () =>
          when(
            () => repo.updateProviderServiceStatus(
              id: '1',
              status: ProviderServiceStatus.inactive,
            ),
          ).thenAnswer(
            (_) => TaskEither.of(
              _service('1', status: ProviderServiceStatus.inactive),
            ),
          ),
      build: buildBloc,
      act: (bloc) => bloc.add(
        const ServiceStatusToggleRequestedEvent(
          serviceId: '1',
          status: ProviderServiceStatus.inactive,
        ),
      ),
      verify: (bloc) {
        expect(bloc.state.status, RequestStatus.success);
        expect(bloc.state.updatedService?.id, '1');
        expect(
          bloc.state.updatedService?.status,
          ProviderServiceStatus.inactive,
        );
      },
    );

    blocTest<ServiceActionBloc, ServiceActionState>(
      'status toggle failure surfaces the failure',
      setUp: () => when(
        () => repo.updateProviderServiceStatus(
          id: '1',
          status: ProviderServiceStatus.inactive,
        ),
      ).thenAnswer((_) => TaskEither.left(_serverFailure)),
      build: buildBloc,
      act: (bloc) => bloc.add(
        const ServiceStatusToggleRequestedEvent(
          serviceId: '1',
          status: ProviderServiceStatus.inactive,
        ),
      ),
      verify: (bloc) {
        expect(bloc.state.status, RequestStatus.failure);
        expect(bloc.state.failure, _serverFailure);
        expect(bloc.state.updatedService, isNull);
      },
    );

    blocTest<ServiceActionBloc, ServiceActionState>(
      'externally-updated event re-broadcasts the service as an update',
      build: buildBloc,
      act: (bloc) => bloc.add(ServiceExternallyUpdatedEvent(_service('1'))),
      verify: (bloc) {
        expect(bloc.state.status, RequestStatus.success);
        expect(bloc.state.updatedService?.id, '1');
      },
    );
  });
}
