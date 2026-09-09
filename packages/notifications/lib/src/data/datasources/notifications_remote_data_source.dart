import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:network/network.dart';
import 'package:notifications/src/data/endpoints/notifications_api_paths.dart';
import 'package:notifications/src/data/models/notification_dto.dart';
import 'package:notifications/src/data/models/register_device_request.dart';
import 'package:notifications/src/domain/usecases/notifications_query.dart';

/// The paginated notifications envelope, which carries an extra `unreadCount`
/// beside the standard `{data, meta}` pair.
class NotificationsPageDto {
  const NotificationsPageDto({required this.page, required this.unreadCount});

  final Page<NotificationDto> page;
  final int unreadCount;
}

abstract interface class NotificationsRemoteDataSource {
  TaskEither<Failure, NotificationsPageDto> getNotifications(
    NotificationsQuery query,
  );

  TaskEither<Failure, void> markRead(String id);

  TaskEither<Failure, void> markAllRead();

  TaskEither<Failure, void> registerDevice(RegisterDeviceRequest request);

  TaskEither<Failure, void> unregisterDevice(String token);
}

class NotificationsRemoteDataSourceImpl
    implements NotificationsRemoteDataSource {
  const NotificationsRemoteDataSourceImpl(this._apiClient);

  final BaseApiClient _apiClient;

  @override
  TaskEither<Failure, NotificationsPageDto> getNotifications(
    NotificationsQuery query,
  ) => _apiClient.request<NotificationsPageDto>(
    path: NotificationsApiPaths.notifications,
    method: RequestMethod.get,
    query: query.toQueryMap(),
    parser: (data) {
      final map = data as Map<String, dynamic>? ?? const {};
      return NotificationsPageDto(
        page: parsePage(map, NotificationDto.fromJson),
        unreadCount: (map['unreadCount'] as num?)?.toInt() ?? 0,
      );
    },
  );

  @override
  TaskEither<Failure, void> markRead(String id) => _apiClient.request<void>(
    path: NotificationsApiPaths.read(id),
    method: RequestMethod.patch,
    parser: (_) {},
  );

  @override
  TaskEither<Failure, void> markAllRead() => _apiClient.request<void>(
    path: NotificationsApiPaths.readAll,
    method: RequestMethod.patch,
    parser: (_) {},
  );

  // Both device calls answer `204 No Content`. `parser: (_) {}` with `T = void`
  // is the established convention for an empty body (see `auth/logout`).
  @override
  TaskEither<Failure, void> registerDevice(RegisterDeviceRequest request) =>
      _apiClient.request<void>(
        path: NotificationsApiPaths.devices,
        method: RequestMethod.post,
        body: request.toJson(),
        parser: (_) {},
      );

  @override
  TaskEither<Failure, void> unregisterDevice(String token) =>
      _apiClient.request<void>(
        path: NotificationsApiPaths.device(token),
        method: RequestMethod.delete,
        parser: (_) {},
      );
}
