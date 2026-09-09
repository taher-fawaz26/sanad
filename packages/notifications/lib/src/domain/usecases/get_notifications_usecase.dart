import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:notifications/src/domain/repositories/notifications_repository.dart';
import 'package:notifications/src/domain/usecases/notifications_query.dart';

class GetNotificationsUseCase
    implements UseCase<NotificationsFeed, NotificationsQuery> {
  const GetNotificationsUseCase(this._repository);

  final NotificationsRepository _repository;

  @override
  TaskEither<Failure, NotificationsFeed> call(NotificationsQuery params) =>
      _repository.getNotifications(params);
}
