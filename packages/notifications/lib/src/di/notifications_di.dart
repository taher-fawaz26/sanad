import 'package:core/core.dart';
import 'package:network/network.dart';
import 'package:notifications/src/data/datasources/notifications_remote_data_source.dart';
import 'package:notifications/src/data/platform/firebase_push_messaging_gateway.dart';
import 'package:notifications/src/data/repositories/notifications_repository_impl.dart';
import 'package:notifications/src/domain/repositories/notifications_repository.dart';
import 'package:notifications/src/domain/services/push_messaging_gateway.dart';
import 'package:notifications/src/domain/usecases/get_notifications_usecase.dart';
import 'package:notifications/src/domain/usecases/mark_all_notifications_read_usecase.dart';
import 'package:notifications/src/domain/usecases/mark_notification_read_usecase.dart';
import 'package:notifications/src/domain/usecases/register_device_usecase.dart';
import 'package:notifications/src/domain/usecases/unregister_device_usecase.dart';
import 'package:notifications/src/navigation/notification_dedup_store.dart';
import 'package:notifications/src/navigation/notification_navigator.dart';
import 'package:notifications/src/presentation/bloc/notifications/notifications_bloc.dart';
import 'package:notifications/src/push/local_notification_presenter.dart';
import 'package:notifications/src/push/push_notification_router.dart';
import 'package:notifications/src/push/push_registration_coordinator.dart';
import 'package:storage/storage.dart';

/// Dependency registration for push and the notification inbox.
///
/// Registers exactly one [PushRegistrationCoordinator] and one
/// [PushNotificationRouter] for the whole app: duplicate token listeners and
/// duplicate tap handlers are the two failure modes this package exists to
/// prevent.
///
/// `resolveNavigator` is a resolver, not an instance, because the router is
/// built during DI while the app's navigator needs a live GoRouter. A push can
/// arrive before that exists, and the router tolerates a `null` answer.
abstract final class NotificationsDI {
  NotificationsDI._();

  static void init({
    required NotificationNavigator? Function() resolveNavigator,
    PushMessagingGateway? gateway,
    bool presentForegroundNotifications = true,
  }) {
    sl
      ..registerLazySingleton<PushMessagingGateway>(
        () => gateway ?? FirebasePushMessagingGateway(),
      )
      ..registerLazySingleton<NotificationsRemoteDataSource>(
        () => NotificationsRemoteDataSourceImpl(sl<BaseApiClient>()),
      )
      ..registerLazySingleton<NotificationsRepository>(
        () => NotificationsRepositoryImpl(sl<NotificationsRemoteDataSource>()),
      )
      ..registerLazySingleton(
        () => GetNotificationsUseCase(sl<NotificationsRepository>()),
      )
      ..registerLazySingleton(
        () => MarkNotificationReadUseCase(sl<NotificationsRepository>()),
      )
      ..registerLazySingleton(
        () => MarkAllNotificationsReadUseCase(sl<NotificationsRepository>()),
      )
      ..registerLazySingleton(
        () => RegisterDeviceUseCase(sl<NotificationsRepository>()),
      )
      ..registerLazySingleton(
        () => UnregisterDeviceUseCase(sl<NotificationsRepository>()),
      )
      ..registerLazySingleton(
        () => NotificationDedupStore(storage: sl<HiveLocalStorage>()),
      )
      ..registerLazySingleton(
        () => PushRegistrationCoordinator(
          gateway: sl<PushMessagingGateway>(),
          registerDevice: sl<RegisterDeviceUseCase>(),
          unregisterDevice: sl<UnregisterDeviceUseCase>(),
          storage: sl<HiveLocalStorage>(),
        ),
      )
      ..registerLazySingleton(
        () => PushNotificationRouter(
          gateway: sl<PushMessagingGateway>(),
          dedupStore: sl<NotificationDedupStore>(),
          resolveNavigator: resolveNavigator,
          presentForeground: presentForegroundNotifications
              ? (message) => sl<LocalNotificationPresenter>().show(message)
              : null,
        ),
      )
      ..registerLazySingleton(
        () => LocalNotificationPresenter(
          // A tap on the banner the app drew itself must reach the same
          // destination as a tap on an OS notification, dedup included.
          onTap: (message) =>
              sl<PushNotificationRouter>().handleTap(message).ignore(),
        ),
      )
      ..registerFactory(
        () => NotificationsBloc(
          getNotifications: sl<GetNotificationsUseCase>(),
          markRead: sl<MarkNotificationReadUseCase>(),
          markAllRead: sl<MarkAllNotificationsReadUseCase>(),
        ),
      );
  }
}
