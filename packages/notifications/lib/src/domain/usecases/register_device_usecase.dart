import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:notifications/src/domain/enums/device_platform.dart';
import 'package:notifications/src/domain/repositories/notifications_repository.dart';

class RegisterDeviceParams extends Equatable {
  const RegisterDeviceParams({required this.token, required this.platform});

  final String token;
  final DevicePlatform platform;

  @override
  List<Object?> get props => [token, platform];
}

/// Upserts this installation's push token.
///
/// Not a one-time setup step: the backend also refreshes a last-seen timestamp
/// that keeps the token from being pruned, so this runs on every login, every
/// launch while signed in, and every token rotation.
class RegisterDeviceUseCase implements UseCase<void, RegisterDeviceParams> {
  const RegisterDeviceUseCase(this._repository);

  final NotificationsRepository _repository;

  @override
  TaskEither<Failure, void> call(RegisterDeviceParams params) =>
      _repository.registerDevice(
        token: params.token,
        platform: params.platform,
      );
}
