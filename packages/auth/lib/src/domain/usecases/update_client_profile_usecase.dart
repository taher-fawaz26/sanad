import 'package:auth/src/domain/entities/client_profile_entity.dart';
import 'package:auth/src/domain/repositories/auth_repository.dart';
import 'package:auth/src/domain/usecases/usecase_params.dart';
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';

/// Sets the client display name / preferred language — `PATCH clients/me`.
/// Authenticated with the session established by verify. Replaces client use
/// of `PATCH account-settings`.
class UpdateClientProfileUseCase
    implements UseCase<ClientProfile, UpdateClientProfileParams> {
  const UpdateClientProfileUseCase(this._repository);

  final AuthRepository _repository;

  @override
  TaskEither<Failure, ClientProfile> call(UpdateClientProfileParams params) =>
      _repository.updateClientProfile(params);
}
