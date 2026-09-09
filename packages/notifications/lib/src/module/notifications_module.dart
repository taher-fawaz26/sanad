import 'package:core/core.dart';
import 'package:go_router/go_router.dart';
import 'package:notifications/src/di/notifications_di.dart';
import 'package:notifications/src/domain/services/push_messaging_gateway.dart';
import 'package:notifications/src/navigation/notification_dedup_store.dart';
import 'package:notifications/src/navigation/notification_navigator.dart';
import 'package:notifications/src/presentation/bloc/notifications/notifications_bloc.dart';
import 'package:notifications/src/presentation/pages/notifications_page.dart';
import 'package:notifications/src/push/push_notification_router.dart';
import 'package:notifications/src/push/push_registration_coordinator.dart';
import 'package:notifications/src/routes/notifications_routes.dart';

/// Registers push and the notification inbox.
///
/// Add **once** per app, after `AuthModule` so the session exists by the time
/// [initialize] runs:
///
/// ```dart
/// NotificationsModule(resolveNavigator: () => clientNotificationNavigator)
/// ```
///
/// The module owns the whole push lifecycle for the app. Nothing else may
/// subscribe to token refreshes or to inbound messages — that is what keeps a
/// relaunch from producing duplicate registration callbacks.
///
/// It does **not** open the backend's SSE notification stream. That is a web
/// delivery channel; on mobile FCM covers background delivery and screens
/// re-read their resource when they become active.
class NotificationsModule extends FeatureModule {
  NotificationsModule({
    required NotificationNavigator? Function() resolveNavigator,
    PushMessagingGateway? gateway,
    bool presentForegroundNotifications = true,
  }) : _resolveNavigator = resolveNavigator,
       _gateway = gateway,
       _presentForegroundNotifications = presentForegroundNotifications;

  final NotificationNavigator? Function() _resolveNavigator;
  final PushMessagingGateway? _gateway;
  final bool _presentForegroundNotifications;

  @override
  String get name => 'notifications';

  @override
  String get version => '0.1.0';

  /// Needs the network stack and the session that `auth` restores.
  @override
  List<String> get dependencies => const ['auth'];

  @override
  void registerDependencies() => NotificationsDI.init(
    resolveNavigator: _resolveNavigator,
    gateway: _gateway,
    presentForegroundNotifications: _presentForegroundNotifications,
  );

  @override
  Future<void> initialize() async {
    // Attach the token-refresh listener and the three delivery paths exactly
    // once. Both calls are idempotent, so a re-entered bootstrap is safe.
    sl<PushRegistrationCoordinator>().start();
    await sl<PushNotificationRouter>().start();
  }

  /// Cleared at every session boundary (`ModuleRegistry.disposeAll` runs on
  /// login and on logout) so one account's handled-notification ids cannot
  /// suppress another's on a shared device.
  @override
  void dispose() {
    sl<NotificationDedupStore>().clear().ignore();
  }

  static NotificationsBloc _buildBloc() => sl<NotificationsBloc>();

  @override
  List<RouteBase> routes(FeatureRouteContext context) => [
    GoRoute(
      path: NotificationsRoutes.notifications,
      builder: (_, _) => NotificationsPage(
        bloc: _buildBloc,
        resolveNavigator: _resolveNavigator,
      ),
    ),
  ];
}
