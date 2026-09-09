import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:notifications/src/domain/repositories/notifications_repository.dart';

class MarkAllNotificationsReadUseCase implements UseCase<void, NoParams> {
  const MarkAllNotificationsReadUseCase(this._repository);

  final NotificationsRepository _repository;

  @override
  TaskEither<Failure, void> call(NoParams params) => _repository.markAllRead();
}
