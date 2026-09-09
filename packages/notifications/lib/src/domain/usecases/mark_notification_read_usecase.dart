import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:notifications/src/domain/repositories/notifications_repository.dart';

class MarkNotificationReadUseCase implements UseCase<void, String> {
  const MarkNotificationReadUseCase(this._repository);

  final NotificationsRepository _repository;

  @override
  TaskEither<Failure, void> call(String params) => _repository.markRead(params);
}
