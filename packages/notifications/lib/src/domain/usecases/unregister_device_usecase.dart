import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:notifications/src/domain/repositories/notifications_repository.dart';

/// Removes a token at logout.
///
/// Tokens belong to devices, not users: without this, the signed-out handset
/// keeps receiving the next user's notifications.
class UnregisterDeviceUseCase implements UseCase<void, String> {
  const UnregisterDeviceUseCase(this._repository);

  final NotificationsRepository _repository;

  @override
  TaskEither<Failure, void> call(String params) =>
      _repository.unregisterDevice(params);
}
