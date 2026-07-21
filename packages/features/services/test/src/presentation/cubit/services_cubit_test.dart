import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:services/src/domain/entities/service_entity.dart';
import 'package:services/src/domain/usecases/get_services_usecase.dart';
import 'package:services/src/presentation/cubit/services_cubit.dart';

class _FakeGetServices implements GetServicesUseCase {
  _FakeGetServices(this._result);

  final TaskEither<Failure, List<ServiceEntity>> _result;

  @override
  TaskEither<Failure, List<ServiceEntity>> call(NoParams params) => _result;
}

void main() {
  const service = ServiceEntity(id: '1', name: 'Plumbing', category: 'Home');

  test('load emits loading then success and exposes the services', () async {
    final cubit = ServicesCubit(
      _FakeGetServices(TaskEither.right(const [service])),
    );

    expectLater(
      cubit.stream.map((s) => s.status),
      emitsInOrder([ServicesStatus.loading, ServicesStatus.success]),
    );

    await cubit.load();

    expect(cubit.state.services, const [service]);
    expect(cubit.state.failure, isNull);
    await cubit.close();
  });

  test('load emits failure carrying the Failure object', () async {
    const failure = ServerFailure(message: 'boom', code: '500');
    final cubit = ServicesCubit(
      _FakeGetServices(TaskEither.left(failure)),
    );

    await cubit.load();

    expect(cubit.state.status, ServicesStatus.failure);
    expect(cubit.state.failure, failure);
    await cubit.close();
  });
}
