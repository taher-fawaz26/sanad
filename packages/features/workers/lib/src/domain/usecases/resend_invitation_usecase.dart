import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:workers/src/domain/repositories/worker_repository.dart';

class ResendInvitationParams extends Equatable {
  const ResendInvitationParams({required this.id});

  final String id;

  @override
  List<Object?> get props => [id];
}

class ResendInvitationUseCase implements UseCase<Unit, ResendInvitationParams> {
  const ResendInvitationUseCase(this._repository);

  final WorkerRepository _repository;

  @override
  TaskEither<Failure, Unit> call(ResendInvitationParams params) =>
      _repository.resendInvitation(params.id);
}
