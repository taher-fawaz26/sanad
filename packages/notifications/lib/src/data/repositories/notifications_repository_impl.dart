import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:notifications/src/data/datasources/notifications_remote_data_source.dart';
import 'package:notifications/src/data/models/register_device_request.dart';
import 'package:notifications/src/domain/enums/device_platform.dart';
import 'package:notifications/src/domain/repositories/notifications_repository.dart';
import 'package:notifications/src/domain/usecases/notifications_query.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  const NotificationsRepositoryImpl(this._remote);

  final NotificationsRemoteDataSource _remote;

  @override
  TaskEither<Failure, NotificationsFeed> getNotifications(
    NotificationsQuery query,
  ) => _remote
      .getNotifications(query)
      .map(
        (dto) => NotificationsFeed(
          page: dto.page.mapItems((item) => item.toEntity()),
          unreadCount: dto.unreadCount,
        ),
      );

  @override
  TaskEither<Failure, void> markRead(String id) => _remote.markRead(id);

  @override
  TaskEither<Failure, void> markAllRead() => _remote.markAllRead();

  @override
  TaskEither<Failure, void> registerDevice({
    required String token,
    required DevicePlatform platform,
  }) => _remote.registerDevice(
    RegisterDeviceRequest(token: token, platform: platform),
  );

  @override
  TaskEither<Failure, void> unregisterDevice(String token) =>
      _remote.unregisterDevice(token);
}
